function gtData = loadGT(loadPath)
%LOADPHY Load and return Phy-formatted .npy files
gtData = struct();

if exist('readNPY', 'file') ~= 2
    warning('Please make sure you have npy-matlab installed (https://github.com/kwikteam/npy-matlab)');
    return;
end

loadPath_ = jrclust.utils.absPath(loadPath);
if isempty(loadPath_)
    error('Could not find path ''%s''', loadPath);
elseif exist(loadPath, 'dir') ~= 7
    error('''%s'' is not a directory', loadPath);
end

loadPath = loadPath_;
ls = dir(loadPath);

% find the binary
cd(loadPath);
ls_bin = dir('*.bin');

nbin = numel(ls_bin);

if nbin == 0
    error('Could not find a binary file in path ''%s''', loadPath);
elseif nbin == 1
    gtData.binfile = ls_bin.name;
    baseName = extractBefore(ls_bin.name,'.ap.bin');
    chanMapName = sprintf( '%s_kilosortChanMap.mat', baseName);
else
    error('More than one binary file path ''%s''', loadPath);
end

gtData.spike_clusters = readNPY(fullfile(loadPath,'gt_spike_clusters.npy'));
gtData.spike_times = readNPY(fullfile(loadPath,'gt_spike_times.npy'));
gtData.clus_Table = readNPY(fullfile(loadPath,'gt_clus_Table.npy'));

cMap = load(chanMapName);
gtData.channelMap = cMap.chanMap;
gtData.nChans = numel(gtData.channelMap);


minX = min(cMap.xcoords);
if minX < 0
    cMap.xcoords = cMap.xcoords - minX;
end
gtData.channelPositions(:,2) = cMap.ycoords;
minY = min(cMap.ycoords);
if minY < 0
    cMap.ycoords = cMap.ycoords - minY;
end
gtData.channelPositions = zeros(int32(gtData.nChans),2);
gtData.channelPositions(:,1) = cMap.xcoords;
gtData.channelPositions(:,2) = cMap.ycoords;

gtData.loadPath = loadPath;
end  % function

