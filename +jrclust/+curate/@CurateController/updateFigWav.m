function updateFigWav(obj)
    %UPDATEFIGWAV
    if ~obj.hasFig('FigWav')
        return;
    end
    
    hFigWav = obj.hFigs('FigWav');
    if isempty(obj.showSubset)
        obj.showSubset = 1:obj.hClust.nClusters;
    end
    jrclust.views.plotFigWav(hFigWav, obj.hClust, obj.maxAmp, obj.channel_idx, obj.showSubset);
    setFigWavXTicks(hFigWav, obj.hClust, obj.hCfg.showSpikeCount);
end
