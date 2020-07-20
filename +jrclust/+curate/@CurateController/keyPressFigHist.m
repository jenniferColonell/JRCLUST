function keyPressFigHist(obj, ~, hEvent)
    %KEYPRESSFIGSHist Handle callbacks for keys pressed in quality scores
    if obj.isWorking
        jrclust.utils.qMsgBox('An operation is in progress.');
        return;
    end

    hFigHist = obj.hFigs('FigHist');

    switch hEvent.Key

        case 'h' % help
            jrclust.utils.qMsgBox(hFigHist.figData.helpText, 1);

        case 'm' % merge
            hFigHist.wait(1);
            obj.mergeSelected();
            hFigHist.wait(0);

        case 's' % split
            hFigHist.wait(1);
            obj.autoSplit(1);
            hFigHist.wait(0);

    end % switch
end