function updateFigPosTime(obj)
    %UPDATEFIGPOSTIME
    if ~obj.hasFig('FigPosTime')
        return;
    end

    hFigTime = obj.hFigs('FigPosTime');
    jrclust.views.plotFigPosTime(hFigTime, obj.hClust, obj.hCfg, obj.selected );
    hFigTime.setMouseable(); % no special mouse function
    
   
%     if doAutoscale
%         jrclust.views.autoScaleFigTime(hFigTime, obj.hClust, obj.selected, obj.currentSite, obj.channel_idx);
%     end
end