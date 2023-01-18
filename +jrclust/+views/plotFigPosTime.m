function hFigPosTime = plotFigPosTime(hFigPosTime, hClust, hCfg, selected )
    %DOPLOTFIGTIME Plot features vs. time
    timeLimits = double([abs(hClust.spikeTimes(1))/hCfg.sampleRate, abs(hClust.spikeTimes(end))/hCfg.sampleRate]);

    % construct plot for the first time
    if ~hFigPosTime.hasAxes('default')
        hFigPosTime.addAxes('default');
        hFigPosTime.axApply('default', @set, 'Position', [0.03 0.2 0.9 0.7], 'XLimMode', 'manual', 'YLimMode', 'manual');

        % trial time indicators
        if isempty(hCfg.trialFile)
            trialTimes=[];
        else
            trialTimes = jrclust.utils.loadTrialFile(hCfg.trialFile);
            if iscell(trialTimes)
                trialTimes = trialTimes{1};
            end
        end
        
        if ~isempty(trialTimes)
            if 	hCfg.plotTrialTime
                hFigPosTime.addPlot('trialTimes',@line,repmat(trialTimes,1,2),[0 abs(maxAmp)],'linewidth',0.1,'color',[0.5 0.7 0.5]);
            end
        elseif ~isempty(hCfg.trialFile)
           warning('Could not load trial times from %s.',hCfg.trialFile);
        end        
        
        % first time
        hFigPosTime.addPlot('background', @line, nan, nan, 'Marker', '.', 'Color', hCfg.colorMap(4, :), 'MarkerSize', 5, 'LineStyle', 'none');
        hFigPosTime.addPlot('foreground', @line, nan, nan, 'Marker', '.', 'Color', hCfg.colorMap(2, :), 'MarkerSize', 5, 'LineStyle', 'none');
        hFigPosTime.addPlot('foreground2', @line, nan, nan, 'Marker', '.', 'Color', hCfg.colorMap(3, :), 'MarkerSize', 5, 'LineStyle', 'none');
        hFigPosTime.axApply('default', @xlabel, 'Time (s)');
        hFigPosTime.axApply('default', @grid, 'on');

        % rectangle plot
        rectPos = [timeLimits(1), 250, diff(timeLimits), 250];
        hFigPosTime.addPlot('hRect', @imrect, rectPos);
        hFigPosTime.plotApply('hRect', @setColor, 'r');
        hFigPosTime.plotApply('hRect', @setPositionConstraintFcn, makeConstrainToRectFcn('imrect', timeLimits, [-4000 4000]));

        hFigPosTime.setHideOnDrag('background'); % hide background spikes when dragging
        
    end
    [bgPos, bgAmp, bgLabel, bgTimes, bgUnits, ~, ~] = getFigTimePos(hClust, selected(1), 1); % background points
    [fgPos, fgAmp, fgLabel, fgTimes, ~, YLabel, ~] = getFigTimePos(hClust, selected(1), 0); % selected cluster points

    if numel(selected) == 2
        [fgPos2, fgAmp2, fgLabel2, fgTimes2] = getFigTimePos(hClust, selected(2), 0);
        figTitle = sprintf('Unit %d (black), Unit %d (red); (press [H] for help)', selected(1), selected(2));
    else        
        fgPos2 = [];
        fgTimes2 = [];
        fgLabels2 = [];
        if ~isempty(bgUnits)
            bgStr = '; back units: ';
            for ib = 1:numel(bgUnits)
                bgStr = sprintf('%s%d ', bgStr, bgUnits(ib));
            end
        else
            bgStr = '';
        end
        figTitle = sprintf('Unit %d (black)%s; (press [H] for help)', selected(1), bgStr);
    end
   
    if ~isempty(bgPos)
        posLim = [min(min(bgPos),min(fgPos)), max(max(bgPos),max(fgPos))];
    else
        posLim = [min(fgPos), max(fgPos)];
    end
    if posLim(2) == posLim(1)
        posLim(1) = posLim(1) - 5;
        posLim(2) = posLim(1) + 10;
    end

    %update scatter plots
    hFigPosTime.updatePlot('background', bgTimes, bgPos);
    hFigPosTime.updatePlot('foreground', fgTimes, fgPos);
    hFigPosTime.updatePlot('foreground2', fgTimes2, fgPos2);
    imrectSetPosition(hFigPosTime, 'hRect', timeLimits, posLim);

    % update histograms
    
%     n_hist_bins=100; % seems to work nicely
%     % add eps so as not to plot background spikes with feature projection of 0. 
%     % Sometimes there are a lot of these and they make the other points hard to see in the histogram.
%     histcountfun = @(features)histcounts(features,n_hist_bins,'BinLimits',binlimits,'Normalization','probability');
%     updateplotfun = @(tag,N,edges)hFigTime.updatePlot(tag,[0 N 0],[edges edges(end)+eps]); % feeding stairs the output of histcounts in this way exactly reproduces the output of matlab histogram, rotated on its side
%     [N,edges] = histcountfun(bgFeatures);
%     updateplotfun('background_hist',N,edges);
%     [N,edges] = histcountfun(fgFeatures);
%     updateplotfun('foreground_hist',N,edges);
%     [N,edges] = histcountfun(fgFeatures2);    
%     updateplotfun('foreground_hist2',N,edges);


%     if isfield(S_fig, 'vhAx_track')
%         toggleVisible_({S_fig.vhAx_track, S_fig.hPlot0_track, S_fig.hPlot1_track, S_fig.hPlot2_track}, 0);
%         toggleVisible_({S_fig.hAx, S_fig.hRect, S_fig.hPlot1, S_fig.hPlot2, S_fig.hPlot0}, 1);
%     end
%
    if ~isfield(hFigPosTime.figData, 'doPlotBG')
        hFigPosTime.figData.doPlotBG = 1;
    end

    hFigPosTime.axApply('default', @axis, [timeLimits, posLim]);
    hFigPosTime.axApply('default', @title, figTitle);
    hFigPosTime.axApply('default', @ylabel, YLabel);
end
