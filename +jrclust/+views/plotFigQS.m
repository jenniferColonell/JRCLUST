function plotFigQS(hFigQS, hClust, hCfg, selected, maxAmp)
    %PLOTFIGQS Simple table of quality scores + recommended annotation
    c1Data = hClust.exportUnitInfo(selected(1));
    nSpikes = hClust.unitCount(c1Data.cluster);
    c1Data.times = hClust.spikeTimes(hClust.spikeClusters == c1Data.cluster);
      
    if isfield(c1Data,'SNR')
        bSNR = true;
    else
        bSNR = false;
    end
    
    if numel(selected) > 1
        c2Data = hClust.exportUnitInfo(selected(2));
    end

    c1Col = qualityScoreStrings (c1Data, nSpikes, hClust, hCfg, bSNR);
    
    unitStr = sprintf('Unit %d', c1Data.cluster);
    
    tbl = uitable(hFigQS.hFig);
    
    if bSNR
        tbl.RowName = {'Firing (Hz)', 'Vpp', 'SNR', '%ISI', 'ISI Viol', 'IsoDist', 'FiringStd'};
    else
        tbl.RowName = {'Firing (Hz)', 'Vpp', '%ISI', 'ISI Viol', 'IsoDist', 'FiringStd'};
    end
    
    if hCfg.annotFunc ~= "None"
        tbl.RowName{end + 1} = 'AutoCall';
    end
    
    tbl.FontSize = 14;
    tbl.Units = 'normalized';
    tbl.Position = [0.05,0.10,0.90,0.90];

    
    if numel(selected) == 1
        % add if block to test for SNR field
        tbl.ColumnName = {unitStr};
        tbl.ColumnWidth = {95};
        tbl.Data = c1Col;
    else
        
        nSpikes2 = hClust.unitCount(c2Data.cluster);
        unitStr2 = sprintf('Unit %d', c2Data.cluster);
        c2Data.times = hClust.spikeTimes(hClust.spikeClusters == c2Data.cluster);
        c2Col = qualityScoreStrings (c2Data, nSpikes2, hClust, hCfg, bSNR); 
        mergeCol = mergeQS(hClust, hCfg, selected, bSNR);
        tbl.ColumnName = {unitStr, unitStr2, 'merged'};
        tbl.ColumnWidth = {95,95,95};
        tbl.Data = [c1Col, c2Col, mergeCol];

    end

end

%% LOCAL FUNCTIONS

function colData = qualityScoreStrings (cData, nSpikes, hClust, hCfg, bSNR)
    % build a column of quality score data for the table
    % includes calculating a few extra quantities that are useful for
    % autoCall function
    
    expTime = single(max(hClust.spikeTimes))/hCfg.sampleRate;
    firingRate = single(nSpikes)/expTime; 
    
    % first three rows, which may or may not include SNR        
    if bSNR
       colData = {sprintf('%.2f',firingRate); sprintf('%.1f', cData.vpp); ...
           sprintf('%.1f', cData.SNR)}; 
    else
       colData = {sprintf('%d',nSpikes); sprintf('%.1f', cData.vpp)}; 
    end
    
    % rest of the rows:
    rows = {sprintf('%.2f', cData.ISIRatio*100); ...
           sprintf('%d', cData.ISIViolations); ...
           sprintf('%.1f', cData.IsoDist); ...
           sprintf('%.2f', cData.firingStd)};
        
    colData = [colData; rows];
    
    if hCfg.annotFunc ~= "None"      
        autoCall = feval( hCfg.annotFunc, firingRate, cData.vpp, cData.SNR, ...
                cData.ISIRatio, cData.ISIViolations, cData.IsoDist, cData.firingStd );
        callCell = {sprintf('%s', autoCall)};
        colData = [colData; callCell];
    end
    
end

function mergeCol = mergeQS( hClust, hCfg, selected, bSNR)
    % calculate a subset of the quality scores for a unit formed by merging
    % the two selected units
    
    c1 = selected(1);
    c2 = selected(2);
    nSpikes1 = hClust.unitCount(c1);
    nSpikes2 = hClust.unitCount(c2);
    nSpikesM = nSpikes1 + nSpikes2;
    %fprintf( 'c1 site, c2 site: %d, %d\n', hClust.clusterSites(c1),  hClust.clusterSites(c2));
    
    % estimate site for merged cluster
    if nSpikes1 >= nSpikes2
        mSite = hClust.clusterSites(c1);
    else
        mSite = hClust.clusterSites(c2);
    end
    
    meanWf1 = squeeze(hClust.meanWfGlobal(:,:,c1));
    meanWf2 = squeeze(hClust.meanWfGlobal(:,:,c2));
    meanWfMerge = ((nSpikes1/nSpikesM).*meanWf1 + (nSpikes2/nSpikesM).*meanWf2);
    
%     h = figure(1001);
%     [nt,ns] = size(meanWfMerge);
%     plot( 1:nt, meanWf1(:,mSite), 1:nt, meanWf2(:,mSite), 1:nt, meanWfMerge(:,mSite) );

    % min, max over time in waveforms, one value per site
    mergedVmin = squeeze(min(meanWfMerge));
    mergedVmax = squeeze(max(meanWfMerge));
    
    mData.vpp = mergedVmax(mSite) - mergedVmin(mSite);
    
    if bSNR
        % this clusstering object should have siteRMS
        siteRMS = jrclust.utils.bit2uV(single(hClust.siteThresh(mSite))/hCfg.qqFactor, hCfg);
        mData.SNR = abs(mergedVmin(mSite))/siteRMS;
    end
    
    % spikes in the merged unit
    mergedSpikes = [hClust.spikesByCluster{c1}; hClust.spikesByCluster{c2}];
    
    % ISIviolations    
    mData.times = sort(hClust.spikeTimes(mergedSpikes)); 
    diffCtimes = diff(mData.times);
    
    nSamples2ms = round(hCfg.sampleRate * .002);
    nSamples20ms = round(hCfg.sampleRate * .02);
    
    mData.ISIRatio = sum(diffCtimes <= nSamples2ms)./sum(diffCtimes <= nSamples20ms);
    mData.ISIViolations = sum(diffCtimes <= nSamples2ms);
    
    % Histogram spike times into 100 bins (arbitrary)
    timeHist = histcounts(mData.times, 100);  %Fixed 100 bins
    mData.firingStd = std(timeHist)/mean(timeHist);
    
    % Iso distance
    mSite1Spikes = hClust.spikesBySite{mSite};      %all spikes on main site of this cluster
    if isprop(hClust, 'spikesBySite2') && ~isempty(obj.spikesBySite2{mSite})
        mSite2Spikes = hClust.spikesBySite2{mSite};
        siteFeatures = [squeeze(hClust.spikeFeatures(:, 1, mSite1Spikes)), squeeze(hClust.spikeFeatures(:, 2, mSite2Spikes))];
        mSiteSpikes = [mSite1Spikes(:); mSite2Spikes(:)];
    else
        siteFeatures = squeeze(hClust.spikeFeatures(:, 1, mSite1Spikes));
        mSiteSpikes = mSite1Spikes(:);
    end


    isOnSite = logical((hClust.spikeClusters(mSiteSpikes) == c1) + (hClust.spikeClusters(mSiteSpikes) == c2));
    
    nSpikesOnSite = sum(isOnSite);

    mData.LRatio = nan;
    mData.IsoDist = nan;
    
    warning off;
    try
        lastwarn(''); % reset last warning to catch it
        mDists = mahal(siteFeatures', siteFeatures(:, isOnSite)');

        [wstr, wid] = lastwarn();
        if strcmp(wid, 'MATLAB:nearlySingularMatrix')
            error(wstr);
        end
        mDistsOutside = mDists(~isOnSite);
    catch
       % couldn't compute distances, set to empty array
       mDistsOutside = [];
    end
    

    if ~isempty(mDistsOutside)
        mData.LRatio = sum(1 - chi2cdf(mDistsOutside, size(siteFeatures,2)))/nSpikesOnSite;

        % compute isolation distance
        if mean(isOnSite) < .5
            sorted12 = sort(mDistsOutside);
            mData.IsoDist = sorted12(nSpikesOnSite);
        end
    end    
    warning on;

    
    mergeCol = qualityScoreStrings(mData, nSpikesM, hClust, hCfg, bSNR);
    
    

end

