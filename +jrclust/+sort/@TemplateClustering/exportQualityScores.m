function success = exportQualityScores(obj, zeroIndex, fGui)
    %EXPORTQUALITYSCORES Export cluster quality scores to CSV
    if nargin < 2
        zeroIndex = 0;
    end
    if nargin < 3
        fGui = 0;
    end

    
    ID = (1:obj.nClusters)';
    varNames{1} = 'CluID';
    SNR = obj.unitSNR(:);
    varNames{2} = 'SNR',
    centerSite = obj.clusterSites(:) - double(zeroIndex);
    varNames{3} = 'centerSite';
    nSpikes = obj.unitCount(:);
    varNames{4} = 'nSpikes';
    xPos = obj.clusterCentroids(:, 1);
    varNames{5} = 'xPos_um';
    yPos = obj.clusterCentroids(:, 2);
    varNames{6} = 'yPos_um';
    uVmin = obj.unitPeaksRaw(:);
    varNames{7} = 'uVmin';
    uVpp = obj.unitVppRaw(:);
    varNames{8} = 'uVpp';
    IsoDist = obj.unitIsoDist(:);
    varNames{9} = 'IsoDist';
    LRatio = obj.unitLRatio(:);
    varNames{10} = 'LRatio';
    ISIRatio = obj.unitISIRatio(:);
    varNames{11} = ('ISIRatio_2ms_20ms');
    ISIViolations = obj.unitISIViolations(:);
    ref_ms = obj.hCfg.refracInt;
    varNames{12} = sprintf('ISIViolations_%.2fms', ref_ms);
    FP = obj.unitFP(:);
    varNames{13} = sprintf('FP_%.2fms', ref_ms);
    dup = obj.unitDup(:);
    varNames{14} = sprintf('Num duplicates');
    note = obj.clusterNotes(:);
    varNames{15} = sprintf('curator_note');
    
    filename = jrclust.utils.subsExt(obj.hCfg.configFile, '_quality.csv');
    
    obj.unitFields.vectorFields
    try

        table_ = table(ID, SNR, centerSite, nSpikes, xPos, yPos, uVmin,...
                 uVpp, IsoDist, LRatio, ISIRatio, ISIViolations, FP, dup, ...
                 note, 'VariableNames', varNames);

        writetable(table_, filename);
    catch ME
        warning('Failed to export: %s', ME.message);
        success = 0;
        return;
    end

    if obj.hCfg.verbose
        disp(table_);

        helpText = {sprintf('Wrote to %s. Columns:', filename), ...
                    sprintf('\tColumn 1: ID: Unit ID'), ...
                    sprintf('\tColumn 2: SNR: |Vp/Vrms|; Vp: negative peak amplitude of the peak site; Vrms: SD of the Gaussian noise (estimated from MAD)'), ...
                    sprintf('\tColumn 3: centerSite: Peak site number which contains the most negative peak amplitude'), ...
                    sprintf('\tColumn 4: nSpikes: Number of spikes'), ...
                    sprintf('\tColumn 5: xPos: x position (width dimension) (center-of-mass'), ...
                    sprintf('\tColumn 6: yPos: y position (depth dimension) (center-of-mass, referenced from the tip'), ...
                    sprintf('\tColumn 7: uVmin: Min. voltage (uV) of the mean raw waveforms at the peak site (microvolts)'), ...
                    sprintf('\tColumn 8: uVpp: peak-to-peak voltage (microvolts)'), ...
                    sprintf('\tColumn 9: IsoDist: Isolation distance quality metric'), ...
                    sprintf('\tColumn 10: LRatio: L-ratio quality metric'), ...
                    sprintf('\tColumn 11: ISIViolations: number of ISI violations'), ...
                    sprintf('\tColumn 12: ISIRatio: ISI-ratio quality metric'), ...
                    sprintf('\tColumn 13: FP: rate of false positives estimated from ISI violations'), ...
                    sprintf('\tColumn 14: Dup: spikes with ISI < 0.167 ms'), ...
                    sprintf('\tColumn 15: note: user comments')};

        cellfun(@(x) fprintf('%s\n', x), helpText);
        if fGui
            jrclust.utils.qMsgBox(helpText);
        end
    end

    success = 1;
end

