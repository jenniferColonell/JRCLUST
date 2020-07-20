function keyPressFigISI(obj, ~, hEvent)
    %KEYPRESSFIGSISI Handle callbacks for keys pressed in quality scores
    if obj.isWorking
        jrclust.utils.qMsgBox('An operation is in progress.');
        return;
    end

    hFigISI = obj.hFigs('FigISI');

    switch hEvent.Key

        case 'h' % help
            jrclust.utils.qMsgBox(hFigISI.figData.helpText, 1);

        case 'm' % merge
            hFigISI.wait(1);
            obj.mergeSelected();
            hFigISI.wait(0);

        case 's' % split
            hFigISI.wait(1);
            obj.autoSplit(1);
            hFigISI.wait(0);

    end % switch
end