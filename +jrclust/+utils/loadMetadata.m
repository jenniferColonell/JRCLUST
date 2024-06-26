function S = loadMetadata(metafile)
    %LOADMETADATA convert SpikeGLX metadata to struct
    %   TODO: build into Config workflow to cut down on specified parameters

    % get absolute path of metafile
    metafile_ = jrclust.utils.absPath(metafile);
    if isempty(metafile_)
        error('could not find meta file %s', metafile);
    end

    try
        S = jrclust.utils.metaToStruct(metafile_);
    catch ME
        error('could not read meta file %s: %s', metafile, ME.message);
    end

    S.adcBits = 16;
    S.probe = '';
    S.isImec = 0;

    %convert new fields to old fields
    if isfield(S, 'niSampRate') % SpikeGLX
        S.nChans = S.nSavedChans;
        S.sampleRate = S.niSampRate;
        S.rangeMax = S.niAiRangeMax;
        S.rangeMin = S.niAiRangeMin;
        S.gain = S.niMNGain;
        try
            S.outputFile = S.fileName;
            S.sha1 = S.fileSHA1;
            S.probe = 'imec2';
        catch
            S.outputFile = '';
            S.sha1 = [];
        end
    elseif isfield(S, 'imSampRate') % IMEC probe
        S.nChans = S.nSavedChans;
        S.sampleRate = S.imSampRate;
        S.rangeMax = S.imAiRangeMax;
        S.rangeMin = S.imAiRangeMin;
        S.isImec = 1;
        S.probeOpt = [];

        % Determine probe type: 3A (0), 3B (1), or NP2.0 (2)
        if isfield(S,'imProbeOpt')
            probeType = '3A';
            S.probeOpt = S.imProbeOpt;
        elseif isfield(S,'imDatPrb_type')
            if S.imDatPrb_type == 0 || S.imDatPrb_type == 1100 
                probeType = 'NP1'; 
            elseif S.imDatPrb_type == 21 || S.imDatPrb_type == 24  ||  S.imDatPrb_type == 2013          
                probeType = 'NP2';
            elseif S.imDatPrb_type == 1110
                % UHD2, active version, needs it's own type because it has
                % a unique imro table.
                probeType = 'NP1110';
            else
                probeType = 'unknown';
            end
        else
            probeType = 'unknown';
        end
        
        if isfield(S,'imChan0apGain')
            % Newer metadata, read gain from file
            S.gain = S.imChan0apGain;
            if isfield(S,'imChan0lfGain')
                S.gainLFP = S.imChan0lfGain;
            end
            maxInt_arr = pow2((0:16));
            S.adcBits = find(maxInt_arr == S.imMaxInt);
  
        else
            % older metadata, derive from probe type
            if strcmp(probeType,'3A') || strcmp(probeType, 'NP1')
                % NP1-like or 3B data; both have 10 bit adc, gain specified in imro
                S.adcBits = 10; % 10 bit adc but 16 bit saved
                % read data from ~imroTbl
                imroTbl = strsplit(S.imroTbl(2:end-1), ')(');
                % parse first channel entry
                imroTblChan = cellfun(@str2double, strsplit(imroTbl{2}, ' '));
                S.gain = imroTblChan(4);
                S.gainLFP = imroTblChan(5);
            elseif strcmp(probeType, 'NP1110')
                S.adcBits = 10;
                imroTbl = strsplit(S.imroTbl(2:end-1), ')(');
                imroTblHeader = cellfun(@str2double, strsplit(imroTbl{1}, ','));
                S.gain = imroTblHeader(4);
                S.gainLFP = imroTblHeader(5);
            elseif strcmp(probeType,'NP2')
                % NP 2.0 -- headstage has two docks          
                S.adcBits = 14; % 14 bit adc but 16 bit saved
                S.gain = 80; % constant gain
            end
        end
            
    end
    

    % Read shank index for all saved channels from snsGeomMap or
    % snsShankMap
    if isfield(S,'snsGeomMap')
            C = textscan(S.snsGeomMap, '(%d:%d:%d:%d', ...
        'EndOfLine', ')', 'HeaderLines', 1 );
    else 
        % older metadata, read from snsShankMap
        C = textscan(S.snsShankMap, '(%d:%d:%d:%d', ...
            'EndOfLine', ')', 'HeaderLines', 1 );
    end
    S.shanks = double(cell2mat(C(1)));
    
  

    %number of bits of ADC [was 16 in Chongxi original]
    try
        S.scale = ((S.rangeMax - S.rangeMin)/(2^S.adcBits))/S.gain * 1e6; %uVolts
    catch
        S.scale = 1;
    end

    S.bitScaling = S.scale;
    if isfield(S, 'gainLFP')
        S.bitScalingLFP = S.scale * S.gain / S.gainLFP;
    end

    % set probe pad size to 6 um for type 1100 and 1110 (actual pad size is 
    % 5 um, but the map is more attractive without the gaps
    if S.imDatPrb_type == 1100 || S.imDatPrb_type == 1110
        S.probePad = [6,6];
    else
        S.probePad = [12,12];
    end

end
