function [hCfg, res] = kilosort(loadPath,confirm_flag)
%KILOSORT Import a Kilosort session from NPY files

if nargin<2
    confirm_flag=true;
else
    if strcmp(confirm_flag,'0') || strcmp(confirm_flag,'false') || strcmp(confirm_flag, 'False')
        confirm_flag = false;
    end
end

[hCfg, res] = deal([]);

phyData = loadPhy(loadPath);
if ~isfield(phyData, 'loadPath')
    return;
end
loadPath = phyData.loadPath;

cfgData = struct();
cfgData.outputDir = loadPath;

% load params and set them in cfgData
params = phyData.params;
channelMap = phyData.channel_map + 1;
channelPositions = phyData.channel_positions;

cfgData.sampleRate = params.sample_rate;
cfgData.nChans = params.n_channels_dat;
cfgData.dataType = params.dtype;
cfgData.headerOffset = params.offset;
cfgData.siteMap = channelMap;
cfgData.siteLoc = channelPositions;
cfgData.shankMap = ones(size(channelMap), 'like', channelMap); % this can change with a prm or metadata file
cfgData.rawRecordings = {params.dat_path};

% check for existence of .prm file. if exists use it as a template.
[a,b,~] = fileparts(params.dat_path);
prm_path = [a,filesep,b,'.prm'];
if exist(prm_path,'file')
    cfgData.template_file = prm_path;
end


% load spike data
amplitudes = phyData.amplitudes;
spikeTimes = phyData.spike_times + 1;
spikeTemplates = phyData.spike_templates + 1;
spikeClusters = phyData.spike_clusters + 1;
simScore = phyData.similar_templates;
templates = phyData.templates; % nTemplates x nSamples x nChannels


% feature projections calculated by phy aren't used in the JRClust interface.
% Rather, it extracts filtered waveforms to do its own calculations.
% Since they aren't used, code to load them is commented out for now.
% if isfield(phyData, 'template_features')
%     cProj = phyData.template_features';
%     iNeigh = phyData.template_feature_ind';    
% end
% if isfield(phyData, 'pc_features')
%     cProjPC = permute(phyData.pc_features, [2 3 1]); % nFeatures x nSites x nSpikes
%     iNeighPC = phyData.pc_feature_ind';
% end

nTemplates = size(templates, 1);
spikeSites = zeros(size(spikeClusters), 'like', spikeClusters);
% If there is a mean waveforms file available, extract peak site from the
% mean waveform for each unit, set spikeSites using peak of mean waveform
if isfield(phyData, 'mean_waveforms')
    % take only channels that were included in the sort
    % phy indices for channels are zero based, so add 1
    curr_mw = phyData.mean_waveforms(:,phyData.channel_map+1,:);
    unitMaxAll = squeeze(max(curr_mw,[],3));
    unitMinAll = squeeze(min(curr_mw,[],3));
    unitPPAll = unitMaxAll - unitMinAll;
    [~, tSite] = max(unitPPAll,[],2);
    for iCluster = 1:max(spikeClusters)
        spikeSites(spikeClusters == iCluster) = tSite(iCluster);
    end
else
    for iTemplate = 1:nTemplates
        template = squeeze(templates(iTemplate, :, :));
        template = template*phyData.whitening_mat_inv;
        [~, tSite] = min(min(template));
        spikeSites(spikeTemplates == iTemplate) = tSite;
    end
end

% KS2 and later don't have any junk clusters, but this removes any cluster
% labels with zero spikes
[clusterIDs, ~, indices] = unique(spikeClusters);
goodClusters = clusterIDs(clusterIDs > 0);
junkClusters = setdiff(clusterIDs, goodClusters);
clusterIDsNew = [junkClusters' 1:numel(goodClusters)]';
spikeClusters = clusterIDsNew(indices);

nClusters = numel(goodClusters);



%%% try to detect the recording file
% first check for a .meta file
binfile = params.dat_path;
metafile = jrclust.utils.absPath(jrclust.utils.subsExt(binfile, '.meta'));
if isempty(metafile)
    dlgAns = questdlg('Do you want to import the original metadata and binfile?', 'Import', 'No');

    switch dlgAns
        case 'Yes' % select .meta file
            [metafile, loadPath] = jrclust.utils.selectFile({'*.meta', 'SpikeGLX meta files (*.meta)'; '*.*', 'All Files (*.*)'}, 'Select a .meta file', loadPath, 0);
            if isempty(metafile)
                return;
            end
            % assume user wants to use the binfile that matches the meta
            % (rather than the corrected file created by KS2.5 or KS3)
            binfile = jrclust.utils.subsExt(metafile, '.bin');
            

        case 'No' % select recording file
            return;
            % assume user is using binfile + associated parameters
            % in params.py
%             if isempty(binfile)
%                 [binfile, loadPath] = jrclust.utils.selectFile({'*.bin;*.dat', 'SpikeGLX recordings (*.bin, *.dat)'; '*.*', 'All Files (*.*)'}, 'Select a raw recording', loadPath, 0);
%                 if isempty(binfile)
%                     return;
%                 end
%             end

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
    cfgData.shankMap = SMeta_.shanks(channelMap) + 1;
    hCfg = jrclust.Config(cfgData);
    hCfg.bitScaling = SMeta_.bitScaling;
    hCfg.shankMap = SMeta_.shanks(hCfg.siteMap) + 1;
    hCfg.probePad = SMeta_.probePad;

else
    hCfg = jrclust.Config(cfgData);
    hCfg.bitScaling = 1;
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
    if isfield(phyData, 'pc_features')
        cProj = cProj(:, ~oob);
        cProjPC = cProjPC(:, :, ~oob);
    end
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
%hCfg.corrRange = [0.75 1];

% save out param file
hCfg.save();

%%% detect and extract spikes/features
hDetect = jrclust.detect.DetectController(hCfg, spikeTimes, spikeSites);
dRes = hDetect.detect();
dRes.spikeSites = spikeSites;
if isfield(phyData, 'templateFeatures') && isfield(phyData, 'pc_features')

    sRes = struct('spikeClusters', spikeClusters, ...
                  'spikeTemplates', spikeTemplates, ...
                  'simScore', simScore, ...
                  'amplitudes', amplitudes, ...
                  'templateFeatures', cProj, ...
                  'templateFeatureInd', iNeigh, ...
                  'pcFeatures', cProjPC, ...
                  'pcFeatureInd', iNeighPC);
else
    % KS3-like output, with no feature info saved
    sRes = struct('spikeClusters', spikeClusters, ...
                  'spikeTemplates', spikeTemplates, ...
                  'simScore', simScore, ...
                  'amplitudes', amplitudes);

end

hClust = jrclust.sort.TemplateClustering(hCfg, sRes, dRes);

res = jrclust.utils.mergeStructs(dRes, sRes);
res.hClust = hClust;
end  % function
