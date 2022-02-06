function updateFigCurNote(obj)
    %UPDATE FigCurNote displaying curator notes
    if isempty(obj.selected) || ~obj.hasFig('FigCurNote')
        return;
    end
    
    hFigCurNote = obj.hFigs('FigCurNote');
    jrclust.views.plotFigCurNote(hFigCurNote, obj.hClust);
    %hFigPos.hFunKey = @(hO, hE) []; % do-nothing function
    %hFigPos.setMouseable();
    
end
