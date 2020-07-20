function updateFigQS(obj)
    %UPDATE FigQS table of quality scores
    if isempty(obj.selected) || ~obj.hasFig('FigQS')
        return;
    end
    
    hFigQS = obj.hFigs('FigQS');
    jrclust.views.plotFigQS(hFigQS, obj.hClust, obj.hCfg, obj.selected, obj.maxAmp);
    %hFigPos.hFunKey = @(hO, hE) []; % do-nothing function
    %hFigPos.setMouseable();
    
end
