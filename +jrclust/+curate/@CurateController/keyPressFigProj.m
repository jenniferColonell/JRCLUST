function keyPressFigProj(obj, ~, hEvent)
    %KEYPRESSFIGPROJ Handle callbacks for keys pressed in feature view
    if obj.isWorking
        jrclust.utils.qMsgBox('An operation is in progress.');
        return;
    end

    hFigProj = obj.hFigs('FigProj');
    factor = 4^double(jrclust.utils.keyMod(hEvent, 'shift')); % 1 or 4

    switch lower(hEvent.Key)
        case 'uparrow'
            projScale = hFigProj.figData.boundScale*sqrt(2)^-factor;
            jrclust.views.rescaleFigProj(hFigProj, projScale, obj.hCfg);

        case 'downarrow'
            projScale = hFigProj.figData.boundScale*sqrt(2)^factor;
            jrclust.views.rescaleFigProj(hFigProj, projScale, obj.hCfg);

        case 'leftarrow' % go down one site in sites as currently ordered
            % projSites one-based indices of the sites the proj view grid
            % in the original binary file.
            % projSite(1) is the lower left in proj grid. 
            % Shift to next factor 'down' in the curent site order, then get the nearest sites
            iSite = obj.projSites(1);
            iSite = obj.spatial_idx(max((obj.channel_idx(iSite) - factor),1)); % get index for nearest site in current order
            nSites = numel(obj.projSites);
            obj.projSites = obj.hCfg.siteNeighbors(1:nSites,iSite); % precalculated neighbors of this site
            obj.updateFigProj(0);

        case 'rightarrow' % go up one channel
            iSite = obj.projSites(1);
            iSite = obj.spatial_idx(min((obj.channel_idx(iSite) + factor),max(obj.channel_idx))); % get index for nearest site in current order
            nSites = numel(obj.projSites);
            obj.projSites = obj.hCfg.siteNeighbors(1:nSites,iSite); % precalculated neighbors of this site
            obj.updateFigProj(0);

        case 'b' % background spikes
            hFigProj.toggleVisible('background');
            
%         case {'d', 'backspace', 'delete'} % delete
%             hFigProj.wait(1);
%             obj.deleteClusters();
%             hFigProj.wait(0);

        case 'f' % toggle feature display
            if strcmp(obj.hCfg.dispFeature, 'vpp')
% JIC: really never want to show template projections, comment this out
%                 if isa(obj.hClust, 'jrclust.sort.TemplateClustering')
%                     obj.updateProjection('template');
%                 else
%                     obj.updateProjection(obj.hCfg.clusterFeature);
%                end
                obj.updateProjection(obj.hCfg.clusterFeature);
            else
                obj.updateProjection('vpp');
            end

        case 'h' % help
            jrclust.utils.qMsgBox(hFigProj.figData.helpText, 1);

        case 'm' % merge clusters
            hFigProj.wait(1);
            obj.mergeSelected();
            hFigProj.wait(0);

        case 'p' % toggle PCi v. PCj
            if ismember(obj.hCfg.dispFeature, {'pca', 'ppca', 'gpca', 'template'})
                % [1, 2] => [1, 3] => [2, 3] => [1, 2] => ...
                obj.hCfg.pcPair = sort(mod(obj.hCfg.pcPair + 1, 3) + 1);
                obj.updateFigProj(0);
            end

        case 'r' %reset view
            obj.updateFigProj(1);

        case 's' %split
            obj.splitPoly(hFigProj, jrclust.utils.keyMod(hEvent, 'shift'));
            
        case 'u' %toggle showing unit (foreground) spikes
            hFigProj.toggleVisible('foreground');
            hFigProj.toggleVisible('foreground2');
        
    end % switch
end