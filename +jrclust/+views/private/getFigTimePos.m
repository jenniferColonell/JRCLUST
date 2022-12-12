function [dispPos, dispAmp, spikeTimesSecs, YLabel, dispSpikes] = getFigTimePos(hClust, iCluster, bBack)
    %GETFIGTIMEPOS Collect positions of spikes on iCluster or nearby clusters (background) for display
    if bBack % get positions of 'background' spikes from clusters with centroids w/in 15 um
        d2_thresh = 15^2;
        currX = hClust.clusterCentroids(iCluster,1);
        currY = hClust.clusterCentroids(iCluster,2);
        dist2 = (hClust.clusterCentroids(:,1)-currX).^2 + (hClust.clusterCentroids(:,2)-currY).^2;
        cluList = dist2 < d2_thresh;
        cluList(iCluster) = 0;  % for background spikes, remove center cluster
    else
        cluList = iCluster;
    end
    
    hCfg = hClust.hCfg;
    [dispPos, dispAmp, dispSpikes] = getClusterPos(hClust, cluList);
    spikeTimesSecs = double(hClust.spikeTimes(dispSpikes))/hCfg.sampleRate;
    YLabel = 'spike z (um)';

end

%% LOCAL FUNCTIONS
function [sampledPos, sampledAmp, sampledSpikes] = getClusterPos(hClust, cluList)
    %getClusterPos Get display positions for a cluster or
    %background cluster (those within 15 um)
    MAX_SAMPLE = 10000; % max points to display

    hCfg = hClust.hCfg;
    
    %collect up all spikes belonging to cluList
    sampledSpikes = jrclust.utils.neCell2mat(hClust.spikesByCluster(cluList));
    sampledSpikes = jrclust.utils.subsample(sampledSpikes, MAX_SAMPLE);
    sampledPos = hClust.spikePositions(sampledSpikes,2);
    sampledAmp = abs(hClust.spikeAmps(sampledSpikes));


    
%     if isempty(iCluster) % select spikes based on sites
%         nSites = 1 + round(hCfg.nSiteDir);
%         neighbors = hCfg.siteNeighbors(1:nSites, iSite);
% 
%         if isempty(hClust.spikesBySite)
%             sampledSpikes = find(ismember(spikeSites, neighbors));
%         else
%             sampledSpikes = jrclust.utils.neCell2mat(hClust.spikesBySite(neighbors)');            
%         end
% 
%         sampledSpikes = jrclust.utils.subsample(sampledSpikes, MAX_SAMPLE);
%     else % get all sites from the cluster
%         sampledSpikes = hClust.spikesByCluster{iCluster};
%     end
% 
%     if strcmp(hCfg.dispFeature, 'vpp')
%         sampledWaveforms = squeeze(hClust.getSpikeWindows(sampledSpikes, iSite, 0, 1)); % use voltages
%         sampledFeatures = max(sampledWaveforms) - min(sampledWaveforms);
%     elseif strcmp(hCfg.dispFeature, 'cov')
%         sampledFeatures = getSpikeCov(hClust, sampledSpikes, iSite);
%     elseif strcmp(hCfg.dispFeature, 'pca') || (strcmp(hCfg.dispFeature, 'ppca') && isempty(iCluster)) % TODO: need a better mech for bg spikes
%         sampledWindows = permute(hClust.getSpikeWindows(sampledSpikes, iSite, 0, 0), [1, 3, 2]); % nSamples x nSpikes x nSites
%         prVecs1 = jrclust.features.getPVSpikes(sampledWindows);
%         sampledFeatures = jrclust.features.pcProjectSpikes(sampledWindows, prVecs1);
%     elseif strcmp(hCfg.dispFeature, 'ppca')
%         sampledWindows = permute(hClust.getSpikeWindows(sampledSpikes, iSite, 0, 0), [1, 3, 2]); % nSamples x nSpikes x nSites
%         prVecs1 = jrclust.features.getPVClusters(hClust, iSite, iCluster);
%         sampledFeatures = jrclust.features.pcProjectSpikes(sampledWindows, prVecs1);
%     elseif strcmp(hCfg.dispFeature, 'template')
%         sampledFeatures = hClust.templateFeaturesBySpike(sampledSpikes, iSite);
%     else
%         error('not implemented yet');
%     end
% 
%     sampledFeatures = squeeze(abs(sampledFeatures));
end

