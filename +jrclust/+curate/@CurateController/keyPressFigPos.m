function keyPressFigPos(obj, ~, hEvent)
    %KEYPRESSFigPos Handle callbacks for keys pressed in quality scores
    if obj.isWorking
        jrclust.utils.qMsgBox('An operation is in progress.');
        return;
    end

    hFigPos = obj.hFigs('FigPos');

    switch hEvent.Key

        case 'h' % help
            jrclust.utils.qMsgBox(hFigPos.figData.helpText, 1);

        case 'm' % merge
            hFigPos.wait(1);
            obj.mergeSelected();
            hFigPos.wait(0);

        case 's' % split
            hFigPos.wait(1);
            obj.autoSplit(1);
            hFigPos.wait(0);

    end % switch
end