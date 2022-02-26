function addCurNote(obj)
    %ANNOTATEUNIT Add a note to a cluster
    if obj.isWorking
        jrclust.utils.qMsgBox('An operation is in progress.');
        return;
    end

%     iCluster = obj.selected(1);
% 
%     % set equal to another cluster?
%     if strcmp(note, '=') && numel(obj.selected) == 2
%         note = sprintf('=%d', obj.selected(2));
%     elseif strcmp(note, '=')
%         msgbox('Right-click another unit to set equal to selected unit');
%         return;
%     end
    
    obj.hClust
    if ~isempty (obj.hClust.curNote)
        note = sprintf('%s', obj.hClust.curNote{1});
    else 
        note = '';
    end

    obj.isWorking = 1;
    try
        newNote = inputdlg(sprintf('Curator Note'), 'Curator Note', 1, {note});
        if 1
            if ~isempty(newNote)
                obj.hClust.curNote = newNote;
            end
        else
            obj.hClust.curNote = note;
        end

    catch ME
        warning('Failed to annotate: %s', ME.message);
        jrclust.utils.qMsgBox('Operation failed.');
    end

    obj.isWorking = 0;
end