function keyPressFigCorr(obj, ~, hEvent)
    %KEYPRESSFIGSHist Handle callbacks for keys pressed in quality scores
    if obj.isWorking
        jrclust.utils.qMsgBox('An operation is in progress.');
        return;
    end

    hFigCorr = obj.hFigs('FigCorr');

    switch hEvent.Key

        case 'h' % help
            jrclust.utils.qMsgBox(hFigCorr.figData.helpText, 1);

        case 'm' % merge
            hFigCorr.wait(1);
            obj.mergeSelected();
            hFigCorr.wait(0);

        case 's' % split
            hFigCorr.wait(1);
            obj.autoSplit(1);
            hFigCorr.wait(0);

    end % switch
end