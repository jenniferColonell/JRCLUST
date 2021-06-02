function [hCfg, res] = ground_truth(loadPath,confirm_flag)
% Import ground truth data from a folder (loadpath) containing
%     -SpikeGLX binary
%     -SpikeGLX metadata file
%     -spike_times.npy file
%     -spike_clusters.npy file
%     -clus_Table.npy file, with #of spikes and max site (used for C_Waves also)
%     -Kilosort chan_map file for the data, which includes the chan map and channel positions

if nargin<2
    confirm_flag=true;
end
[hCfg, res] = deal([]);

gtData = loadGT(loadPath);
if ~isfield(gtData, 'loadPath')
    return;
end
loadPath = gtData.loadPath;
dat_path = fullfile(loadPath,gtData.binfile);

cfgData = struct();
cfgData.outputDir = loadPath;

% load params and set them in cfgData
channelMap = gtData.channelMap;
channelPositions = gtData.channelPositions;

cfgData.nChans = gtData.nChans;
cfgData.dataType = 'int16';         %this is only implemented for spikeGLX data
cfgData.headerOffset = 0;
cfgData.siteMap = channelMap;
cfgData.siteLoc = channelPositions;
cfgData.shankMap = ones(size(channelMap), 'like', channelMap); % this can change with a prm or metadata file
cfgData.rawRecordings = {dat_path};

% check for existence of .prm file. if exists use it as a template.
[a,b,~] = fileparts(dat_path);
prm_path = [a,filesep,b,'.prm'];
if exist(prm_path,'file')
    cfgData.template_file = prm_path;
end
hCfg = jrclust.Config(cfgData);

% load spike data
spikeTimes = gtData.spike_times + 1;
spikeClusters = gtData.spike_clusters + 1;

[clusterIDs, ~, indices] = unique(spikeClusters);
% goodClusters = clusterIDs(clusterIDs > 0);
% junkClusters = setdiff(clusterIDs, goodClusters);
% clusterIDsNew = [junkClusters' 1:numel(goodClusters)]';
% spikeClusters = clusterIDsNew(indices);

nClusters = numel(clusterIDs);

spikeSites = zeros(size(spikeClusters), 'like', spikeClusters);
for iCluster = 1:nClusters
    spikeSites(spikeClusters == iCluster) = gtData.clus_Table(iCluster, 2) + 1;
end

spikeTemplates = spikeClusters; %these are redundant in GT data

%%% try to detect the recording file
% first check for a .meta file
binfile = dat_path;
metafile = jrclust.utils.absPath(jrclust.utils.subsExt(binfile, '.meta'));
if isempty(metafile)
    dlgAns = questdlg('Do you have a .meta file?', 'Import', 'No');

    switch dlgAns
        case 'Yes' % select .meta file
            [metafile, loadPath] = jrclust.utils.selectFile({'*.meta', 'SpikeGLX meta files (*.meta)'; '*.*', 'All Files (*.*)'}, 'Select a .meta file', loadPath, 0);
            if isempty(metafile)
                return;
            end

            if isempty(binfile)
                binfile = jrclust.utils.subsExt(metafile, '.bin');
            end

        case 'No' % select recording file
            if isempty(binfile)
                [binfile, loadPath] = jrclust.utils.selectFile({'*.bin;*.dat', 'SpikeGLX recordings (*.bin, *.dat)'; '*.*', 'All Files (*.*)'}, 'Select a raw recording', loadPath, 0);
                if isempty(binfile)
                    return;
                end
            end

        case {'Cancel', ''}
            return;
    end
end

% check for missing binary file
binfile = jrclust.utils.absPath(binfile);
if isempty(jrclust.utils.absPath(binfile))
    binfile = jrclust.utils.selectFile({'*.bin;*.dat', 'SpikeGLX recordings (*.bin, *.dat)'; '*.*', 'All Files (*.*)'}, 'Select a raw recording', loadPath, 0);
    if isempty(binfile)
        return;
    end
end

% load metafile, set bitScaling
if ~isempty(metafile)
    SMeta_ = jrclust.utils.loadMetadata(metafile);
    hCfg.bitScaling = SMeta_.bitScaling;
    hCfg.shankMap = SMeta_.shanks(hCfg.siteMap) + 1;
    hCfg.sampleRate = SMeta_.sampleRate;
else
    hCfg.bitScaling = 1;
    hCfg.sampleRate = 30000;
end

while 1
    % confirm with the user if confirm_flag is true
    [~, sessionName, ~] = fileparts(hCfg.rawRecordings{1});
    configFile = fullfile(hCfg.outputDir, [sessionName, '.prm']);

    dlgFieldNames = {'Config filename', ...
                     'Raw recording file(s)', ...
                     'Sampling rate (Hz)', ...
                     'Number of channels in file', ...
                     sprintf('%sV/bit', char(956)), ...
                     'Header offset (bytes)', ...
                     'Data Type (int16, uint16, single, double)'};
    dlgFieldVals = {configFile, ...
                    strjoin(hCfg.rawRecordings, ','), ...
                    num2str(hCfg.sampleRate), ...
                    num2str(hCfg.nChans), ...
                    num2str(hCfg.bitScaling), ...
                    num2str(hCfg.headerOffset), ...
                    hCfg.dataType};
    if confirm_flag
        dlgAns = inputdlg(dlgFieldNames, 'Does this look correct?', 1, dlgFieldVals, struct('Resize', 'on', 'Interpreter', 'tex'));
    else
        dlgAns = dlgFieldVals;
    end
    if isempty(dlgAns)
        return;
    end
    try
        if ~exist(dlgAns{1}, 'file')
            fclose(fopen(dlgAns{1}, 'w'));
        end
        hCfg.setConfigFile(dlgAns{1}, 0);
    catch ME
        errordlg(ME.message);
        continue;
    end

    try
        hCfg.rawRecordings = cellfun(@strip, strsplit(dlgAns{2}, ','), 'UniformOutput', 0);
    catch ME
        errordlg(ME.message);
        continue;
    end

    try
        hCfg.sampleRate = str2double(dlgAns{3});
    catch ME
        errordlg(ME.message);
        continue;
    end

    try
        hCfg.nChans = str2double(dlgAns{4});
    catch ME
        errordlg(ME.message);
        continue;
    end

    try
        hCfg.bitScaling = str2double(dlgAns{5});
    catch ME
        errordlg(ME.message);
        continue;
    end

    try
        hCfg.headerOffset = str2double(dlgAns{6});
    catch ME
        errordlg(ME.message);
        continue;
    end

    try
        hCfg.dataType = dlgAns{7};
    catch ME
        errordlg(ME.message);
        continue;
    end

    break;
end
    
% remove out-of-bounds spike times
d = dir(hCfg.rawRecordings{1});
nSamples = d.bytes / jrclust.utils.typeBytes(hCfg.dataType) / hCfg.nChans;
oob = spikeTimes > nSamples;
if any(oob)
    warning('Removing %d/%d spikes after the end of the recording', sum(oob), numel(oob));
    spikeTimes = spikeTimes(~oob);
    spikeTemplates = spikeTemplates(~oob);
    spikeSites = spikeSites(~oob);
    spikeClusters = spikeClusters(~oob);
end

% set some specific params
hCfg.nPeaksFeatures = 1; % don't find secondary peaks
% remove FigRD
if ismember(hCfg.figList,'FigRD')
    keepFigIdx = ~ismember(hCfg.figList,'FigRD');
    hCfg.figList = hCfg.figList(keepFigIdx);
    if ~isempty(hCfg.figPos)
        hCfg.figPos = hCfg.figPos(keepFigIdx);
    end
end
hCfg.corrRange = [0.75 1];

% save out param file
hCfg.save();

%%% detect and extract spikes/features
hDetect = jrclust.detect.DetectController(hCfg, spikeTimes, spikeSites);
dRes = hDetect.detect();
dRes.spikeSites = spikeSites;
sRes = struct('spikeClusters', spikeClusters, ...
          'spikeTemplates', spikeTemplates, ...
          'simScore', eye(nClusters), ...
          'amplitudes', ones(nClusters,1));
              
% if isfield(phyData, 'templateFeatures') && isfield(phyData, 'templateFeatures')
%     sRes = struct('spikeClusters', spikeClusters, ...
%                   'spikeTemplates', spikeTemplates, ...
%                   'simScore', simScore, ...
%                   'amplitudes', amplitudes, ...
%                   'templateFeatures', cProj, ...
%                   'templateFeatureInd', iNeigh, ...
%                   'pcFeatures', cProjPC, ...
%                   'pcFeatureInd', iNeighPC);
% else
%         sRes = struct('spikeClusters', spikeClusters, ...
%                   'spikeTemplates', spikeTemplates, ...
%                   'simScore', simScore, ...
%                   'amplitudes', amplitudes);
% 
% end

hClust = jrclust.sort.TemplateClustering(hCfg, sRes, dRes);

res = jrclust.utils.mergeStructs(dRes, sRes);
res.hClust = hClust;
end  % function
