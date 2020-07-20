function keyPressFigQS(obj, ~, hEvent)
    %KEYPRESSFIGSQS Handle callbacks for keys pressed in quality scores
    if obj.isWorking
        jrclust.utils.qMsgBox('An operation is in progress.');
        return;
    end

    hFigQS = obj.hFigs('FigQS');

    switch hEvent.Key

        case 'h' % help
            jrclust.utils.qMsgBox(hFigQS.figData.helpText, 1);

        case 'm' % merge
            hFigQS.wait(1);
            obj.mergeSelected();
            hFigQS.wait(0);

        case 's' % split
            hFigQS.wait(1);
            obj.autoSplit(1);
            hFigQS.wait(0);

    end % switch
end