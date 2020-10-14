function computeQualityScores(obj, updateMe)
    %COMPUTEQUALITYSCORES Get cluster quality scores
    fprintf('parent computeQualityScores\n');
    if nargin < 2
        updateMe = [];
    end

    obj.hCfg.updateLog('qualScores', 'Computing cluster quality scores', 1, 0);

    unitVmin = squeeze(min(obj.meanWfGlobal));
    unitVmax = squeeze(max(obj.meanWfGlobal));
    unitVminRaw = squeeze(min(obj.meanWfGlobalRaw));
    unitVmaxRaw = squeeze(max(obj.meanWfGlobalRaw));

    unitVpp_ = jrclust.utils.rowColSelect(unitVmax - unitVmin, obj.clusterSites, 1:obj.nClusters);
    unitVppRaw_ = jrclust.utils.rowColSelect(unitVmaxRaw - unitVminRaw, obj.clusterSites, 1:obj.nClusters);
    unitPeaksRaw_ = jrclust.utils.rowColSelect(unitVminRaw, obj.clusterSites, 1:obj.nClusters);

    % compute unitIsoDist_, unitLRatio_, unitISIRatio_
    nSamples2ms = round(obj.hCfg.sampleRate * .002);
    nSamples20ms = round(obj.hCfg.sampleRate * .02);
    
    refPeriod = obj.hCfg.refracInt/1000;
    minISIPeriod = 0.0001667; % in seconds
    nSamplesMinISI = round(minISIPeriod*obj.hCfg.sampleRate);
    nSamplesRefPeriod = round(obj.hCfg.sampleRate * refPeriod);
    expTime = single(max(obj.spikeTimes))/obj.hCfg.sampleRate;
    
    if isempty(updateMe)
        [unitIsoDist_, unitLRatio_, unitISIRatio_] = deal(nan(obj.nClusters, 1));
        updateMe = 1:obj.nClusters;
    else
        unitIsoDist_ = obj.unitIsoDist;
        unitLRatio_ = obj.unitLRatio;
        unitISIRatio_ = obj.unitISIRatio;
        unitISIViolations_ = obj.unitISIViolations;
        unitFP_ = obj.unitFP;
        unitFiringStd_ = obj.unitFiringStd;
        updateMe = updateMe(:)';
    end

    % This is troubling:
    % Warning: Matrix is close to singular or badly scaled. Results may be inaccurate.
    % > In mahal (line 49)
    % TODO: investigate
    warning off;
    for iCluster = updateMe
        clusterSpikes_ = obj.spikesByCluster{iCluster};
        % Compute ISI ratio
        clusterTimes_ = obj.spikeTimes(clusterSpikes_);
        diffCtimes = diff(clusterTimes_);
        
        % define ISI ratio as #(ISI <= 2ms)/#(ISI <= 20ms)
        unitISIRatio_(iCluster) = sum(diffCtimes <= nSamples2ms)./sum(diffCtimes <= nSamples20ms);
        unitISIViolations_(iCluster) = ...
            sum((diffCtimes <= nSamplesRefPeriod) & (diffCtimes >= nSamplesMinISI ));
        
        % Histogram spike times into 100 bins (arbitrary)
        timeHist = histcounts(clusterTimes_, 100);  %Fixed 100 bins
        unitFiringStd_(iCluster) = std(timeHist)/mean(timeHist);
        
        % Fraction of False postive events (fp), following calculation in
        % in Hill (J. Neuroscience, 2011)
        nSpike = numel(clusterSpikes_);
        c = unitISIViolations_(iCluster)*expTime/(2*(refPeriod - minISIPeriod) * nSpike * nSpike );
        
        if c < 0.25
            unitFP_(iCluster) = (1 - sqrt(1 - 4*c))/2;
        else
            unitFP_(iCluster) = 1;
        end
        
        % Compute L-ratio and isolation distance (use neighboring features)
        iSite = obj.clusterSites(iCluster);

        % find spikes whose primary or secondary spikes live on iSite
        iSite1Spikes = obj.spikesBySite{iSite};
        if isprop(obj, 'spikesBySite2') && ~isempty(obj.spikesBySite2{iSite})
            iSite2Spikes = obj.spikesBySite2{iSite};
            siteFeatures = [squeeze(obj.spikeFeatures(:, 1, iSite1Spikes)), squeeze(obj.spikeFeatures(:, 2, iSite2Spikes))];
            iSiteSpikes = [iSite1Spikes(:); iSite2Spikes(:)];
        else
            siteFeatures = squeeze(obj.spikeFeatures(:, 1, iSite1Spikes));
            iSiteSpikes = iSite1Spikes(:);
        end

        isOnSite = (obj.spikeClusters(iSiteSpikes) == iCluster);
        nSpikesOnSite = sum(isOnSite);

        [unitLRatio_(iCluster), unitIsoDist_(iCluster)] = deal(nan);

        try
            lastwarn(''); % reset last warning to catch it
            mDists = mahal(siteFeatures', siteFeatures(:, isOnSite)');

            [wstr, wid] = lastwarn();
            if strcmp(wid, 'MATLAB:nearlySingularMatrix')
                error(wstr);
            end
        catch
            continue;
        end

        mDistsOutside = mDists(~isOnSite);
        if isempty(mDistsOutside)
            continue;
        end

        unitLRatio_(iCluster) = sum(1 - chi2cdf(mDistsOutside, size(siteFeatures,2)))/nSpikesOnSite;

        % compute isolation distance
        if mean(isOnSite) > .5
            continue;
        end

        sorted12 = sort(mDistsOutside);
        unitIsoDist_(iCluster) = sorted12(nSpikesOnSite);
    end % for
    warning on;

    obj.unitISIRatio = unitISIRatio_;
    obj.unitISIViolations = unitISIViolations_;
    obj.unitFP = unitFP_;
    obj.unitIsoDist = unitIsoDist_;
    obj.unitLRatio = unitLRatio_;
    obj.unitPeaksRaw = unitPeaksRaw_; % unitPeaks is set elsewhere
    obj.unitVpp = unitVpp_;
    obj.unitVppRaw = unitVppRaw_;
    
    unitVmin = squeeze(min(obj.meanWfGlobal));
    unitPeaks_ = jrclust.utils.rowColSelect(unitVmin, obj.clusterSites, 1:obj.nClusters);

    try
        siteRMS_ = jrclust.utils.bit2uV(single(obj.siteThresh(:))/obj.hCfg.qqFactor, obj.hCfg);
        unitSNR_ = abs(unitPeaks_)./siteRMS_(obj.clusterSites);
        nSitesOverThresh_ = sum(bsxfun(@lt, unitVmin, - siteRMS_*obj.hCfg.qqFactor), 1)';
    catch ME
        [siteRMS_, unitSNR_, nSitesOverThresh_] = deal([]);
        warning('RMS, SNR, nSitesOverThresh not set: %s', ME.message);
    end

    obj.unitSNR = unitSNR_;
    obj.nSitesOverThresh = nSitesOverThresh_;
    obj.siteRMS = siteRMS_;
    obj.unitFiringStd = unitFiringStd_;

    obj.hCfg.updateLog('qualScores', 'Finished computing cluster quality scores', 0, 1);
end