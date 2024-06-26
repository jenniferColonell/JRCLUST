function updateSubset(obj, showSubset, silent, targetAnnotation)
%UPDATESUBSET Update the subset of units to show
if nargin < 3
    silent = 0;
end
if nargin > 3
    if strcmp(targetAnnotation,'userSet')
        % input dialog to get an annotation from user
        user_rsp = inputdlg('Annotation to show','Input annotation to show',[1,75]);
        if isempty(user_rsp)
            return;
        else
            targetAnnotation = user_rsp;
        end
    end
    % make a new subset of units with clusterNote = targetAnnotation
    showSubset = find(cellfun(@(c) strcmp(c,targetAnnotation), obj.hClust.clusterNotes));
   
end
    
showSubset = intersect(1:obj.hClust.nClusters, showSubset);

if isempty(showSubset) && ~silent
    jrclust.utils.qMsgBox('Subset is empty; selecting all units');
    showSubset = obj.showSubset;
elseif jrclust.utils.isEqual(1:obj.hClust.nClusters, showSubset(:)') && ~silent
    jrclust.utils.qMsgBox('All units selected');
end

if ~jrclust.utils.isEqual(obj.showSubset(:), showSubset(:))
    obj.showSubset = showSubset;
    obj.replot();
    if ~silent
        jrclust.utils.qMsgBox('Replotted with new subset');
    end
end
end % function

