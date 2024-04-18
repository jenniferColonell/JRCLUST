function validateParams(obj)
    %VALIDATEPARAMS Validate parameters and compute others
    if obj.nSites == 0
        obj.error('No siteMap specified', 'Bad probe configuration');
    end
    obj.nSites
    size(obj.siteLoc,1)

    if isempty(obj.nSitesEvt)
        fprintf('no nSitesEvt specified\n');
    else
        fprintf('obj.nSitesEvt at start of validateParams = %d\n', obj.nSitesEvt);
    end
%     if isempty(obj.nSiteDir)
%         fprintf('no nSiteDir specified\n');
%     else
%         fprintf('obj.nSiteDir = %d\n', obj.nSiteDir);
%     end
    if size(obj.siteLoc, 1) ~= obj.nSites
        obj.error('Malformed probe geometry', 'Bad probe configuration');
        return;
    end

    if numel(obj.shankMap) ~= obj.nSites
        obj.error('Malformed shank indexing', 'Bad probe configuration');
        return;
    end

    if max(obj.siteMap) > obj.nChans
        obj.error('siteMap refers to channels larger than indexed by nChans', 'Bad probe configuration');
        return;
    end
    
    % make sure shankMap to a column vector 
    [r, c] = size(obj.shankMap);
    if r == 1
        obj.shankMap = obj.shankMap';
    end

    % nSiteDir and/or nSitesExcl may not have been specified
    if isempty(obj.nSiteDir) || isempty(obj.nSitesExcl)
        siteDists = pdist2(obj.siteLoc, obj.siteLoc);

        % max over all sites of number of neighbors in detect radius
        nNeighDetect = max(sum(siteDists <= obj.evtDetectRad)); % 11/7/17 JJJ: med to max

        if isempty(obj.nSitesExcl)
            % max over all sites of number of neighbors in extract radius
            nNeighExtract = max(sum(siteDists <= obj.evtGroupRad)); % 11/7/17 JJJ: med to max
            nsd = (nNeighExtract - 1)/2; 
            obj.nSitesExcl = nNeighExtract - nNeighDetect;
        else
            nNeighExtract = nNeighDetect + obj.nSitesExcl;
            nsd = (nNeighExtract - 1)/2;
        end

        if isempty(obj.nSiteDir)
            obj.nSiteDir = nsd;
            fprintf('obj.evtDetRad, nNeighDetect, obj.nSitesExcl, nNeighExtract: %d, %d, %d, %d\n', ...
                obj.evtDetectRad, nNeighDetect, obj.nSitesExcl, nNeighExtract);
            fprintf('setting obj.nSiteDir: %.1f\n', obj.nSiteDir);
        end
    end
    
    if isempty(obj.nSitesEvt)
        fprintf('no nSitesEvt specified\n');
    else
        fprintf('obj.nSitesEvt at end of validateParams = %d\n', obj.nSitesEvt);
    end
    
    if obj.nSitesEvt <= 0
        obj.error('nSitesExcl is too large or nSiteDir is too small', 'Bad configuration');
    end

    % we can't compute secondary peaks off of sites we don't have
    obj.nPeaksFeatures = min(obj.nPeaksFeatures, obj.nSitesEvt);

    % ignoreSites/ignoreChans
    obj.ignoreChans = obj.ignoreChans(ismember(obj.ignoreChans, obj.siteMap));
    obj.ignoreSites = intersect(obj.ignoreSites, 1:numel(obj.siteMap));
    obj.ignoreSites = union(obj.ignoreSites, find(ismember(obj.siteMap, obj.ignoreChans)));

    obj.siteNeighbors = findSiteNeighbors(obj.siteLoc, 2*obj.nSiteDir + 1, obj.ignoreSites, obj.shankMap);

    % boost that gain
    obj.bitScaling = obj.bitScaling/obj.gainBoost;

    if strcmp(obj.clusterFeature, 'gpca')
        obj.setCustomProp('extractAfterDetect', 1);
    end
    
    % validate figures
    obj.validateFigs;
    
end