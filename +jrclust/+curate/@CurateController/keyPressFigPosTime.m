function keyPressFigPosTime(obj, ~, hEvent)
    %KEYPRESSFIGTIME Handle callbacks for keys pressed in position vs time view
    if obj.isWorking
        jrclust.utils.qMsgBox('An operation is in progress.');
        return;
    end

    hFigPosTime = obj.hFigs('FigPosTime');
    factor = 4^double(jrclust.utils.keyMod(hEvent, 'shift')); % 1 or 4

    switch hEvent.Key

        case 'b' % toggle background spikes
            hFigPosTime.figData.doPlotBG = hFigPosTime.toggleVisible('background');
            %hFigTime.toggleVisible('background_hist');

        case 'h' % help
            jrclust.utils.qMsgBox(hFigPosTime.figData.helpText, 1);

        case 'm' % merge
            hFigTime.wait(1);
            obj.mergeSelected();
            hFigTime.wait(0);

        case 'r' % reset view
            obj.updateFigPosTime(1);

        case 's' % split
            obj.splitPoly(hFigPosTime, jrclust.utils.keyMod(hEvent, 'shift'));

    end % switch
end