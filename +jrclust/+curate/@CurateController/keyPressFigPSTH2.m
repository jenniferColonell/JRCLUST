function keyPressFigPSTH2(obj, ~, hEvent)
    %KEYPRESSFIGSQS Handle callbacks for keys pressed in PSTH plot
    if obj.isWorking
        jrclust.utils.qMsgBox('An operation is in progress.');
        return;
    end

    hFigPSTH = obj.hFigs('FigTrial2');

    switch hEvent.Key

        case 'h' % help
            jrclust.utils.qMsgBox(hFigPSTH.figData.helpText, 1);

        case 'm' % merge
            hFigPSTH.wait(1);
            obj.mergeSelected();
            hFigPSTH.wait(0);

    end % switch
end