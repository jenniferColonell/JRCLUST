function plotFigCurNote(hFigCurNote, hClust)
    %PLOTFIGCurNote Simple display of curator note, set from File menu
    tbl = uitable(hFigCurNote.hFig);

    %highest index annotation:
    %lastOp = hClust.history{nOp}
    nClu = numel(hClust.clusterNotes);
    nCluStr = sprintf('%d',nClu);
    lastNoteStr = sprintf('None');
    for i = 1:nClu
        if ~isempty(hClust.clusterNotes{i})
            lastNoteStr = sprintf('%d',i);
        end
    end

    %curator note, if present
    if isempty(hClust.curNote)
        curNoteStr = sprintf('None');
    else
        curNoteStr = hClust.curNote{1};
    end
    
    tbl.FontSize = 14;
    tbl.Units = 'normalized';
    tbl.Position = [0.05,0.10,0.90,0.90];
    tbl.RowName = {'Cur Note (File)', 'Last annotation', 'Total Units'};
    tbl.ColumnWidth = {256};
    
    % table column = vertical cell array (semicolon separated) of character arrays
    tbl.Data = {curNoteStr; lastNoteStr; nCluStr};

end

