classdef TemplateClustering < jrclust.interfaces.Clustering
    %TEMPLATECLUSTERING A Kilosort(2) clustering    
    %% TEMPLATE-MATCHING PROPERTIES
    properties (Dependent, SetObservable)
        amplitudes;         % extracted amplitude for each spike
        templateFeatures;   % matrix giving the magnitude of the projection of each spike onto nTempFeatures other features
        templateFeatureInd; % for each template, the channels with largest amplitudes are indexed in order
        pcFeatures;         % projections of each detected spike onto the top templates most similar to the spike's assigned template
        pcFeatureInd;       % for each template, the other templates with largest similarity are indexed in order
        simScore;           % template-template correlation matrix
        spikeTemplates;     % template assignments for each spike
    end

    properties (SetObservable)
        templatesByCluster; % cell array of unique template values by cluster
        templateSim;        % template-based similarity score
    end
    
    %% QUALITY METRICS
    properties (SetObservable)
        nSitesOverThresh;   % number of sites exceeding the detection threshold, per cluster
        siteRMS;            % site-wise threshold/qqFactor
        unitSNR;            % signal-to-noise ratio at peak site (peak/RMS)
    end
    %% DETECTION RESULTS (IMMUTABLE)
    properties (Dependent, Transient)
        meanSiteThresh;     % mean sitewise detection threshold over all chunks
        siteThresh;         % sitewise detection threshold over all chunks
%         spikesBySite2;      % aggregate of secondary spike indices by site
%         spikesBySite3;      % aggregate of tertiary spike indices by site
%         spikeSites2;        % secondary sites on which spikes occur
    end
    
    %% LIFECYCLE
    methods
        function obj = TemplateClustering(hCfg, sRes, dRes)
            %TEMPLATECLUSTERING
            if nargin < 2
                sRes = struct();
            end
            if nargin < 3
                dRes = struct();
            end

            obj.hCfg = hCfg;
            obj.dRes = dRes;
            obj.sRes = sRes;

            if isfield(sRes, 'spikeClusters')
                obj.spikeClusters = sRes.spikeClusters;
                
                obj.syncHistFile();
                obj.commit(obj.spikeClusters, struct(), 'initial commit');
            end
            
            
        end
    end

    %% UTILITY METHODS
    methods (Access=protected, Hidden)
        nMerged = mergeBySim(obj);
    end
    
    %% STATIC METHODS
    methods(Static)
        [simScoreCorr,simScoreAmp,bestLag] = waveformSimScore(means,max_lag,sites);        
    end

    %% GETTERS/SETTERS
    methods
        % amplitudes
        function vals = get.amplitudes(obj)
            if isfield(obj.sRes, 'amplitudes')
                vals = obj.sRes.amplitudes;
            else
                vals = [];
            end
        end
        function set.amplitudes(obj, vals)
            obj.sRes.amplitudes = vals;
        end

        % templateFeatures
        function vals = get.templateFeatures(obj)
            if isfield(obj.sRes, 'templateFeatures')
                vals = obj.sRes.templateFeatures;
            else
                vals = [];
            end
        end
        function set.templateFeatures(obj, vals)
            obj.sRes.templateFeatures = vals;
        end

        % pcFeatures
        function vals = get.pcFeatures(obj)
            if isfield(obj.sRes, 'pcFeatures')
                vals = obj.sRes.pcFeatures;
            else
                vals = [];
            end
        end
        function set.pcFeatures(obj, vals)
            obj.sRes.pcFeatures = vals;
        end

        % templateFeatureInd
        function vals = get.templateFeatureInd(obj)
            if isfield(obj.sRes, 'templateFeatureInd')
                vals = obj.sRes.templateFeatureInd;
            else
                vals = [];
            end
        end
        function set.templateFeatureInd(obj, vals)
            obj.sRes.templateFeatureInd = vals;
        end

        % pcFeatureInd
        function vals = get.pcFeatureInd(obj)
            if isfield(obj.sRes, 'pcFeatureInd')
                vals = obj.sRes.pcFeatureInd;
            else
                vals = [];
            end
        end
        function set.pcFeatureInd(obj, vals)
            obj.sRes.pcFeatureInd = vals;
        end

        % simScore
        function vals = get.simScore(obj)
            if isfield(obj.sRes, 'simScore')
                vals = obj.sRes.simScore;
            else
                vals = [];
            end
        end
        function set.simScore(obj, vals)
            obj.sRes.simScore = vals;
        end

        % spikeTemplates
        function vals = get.spikeTemplates(obj)
            if isfield(obj.sRes, 'spikeTemplates')
                vals = obj.sRes.spikeTemplates;
            else
                vals = [];
            end
        end
        function set.spikeTemplates(obj, vals)
            obj.sRes.spikeTemplates = vals;
        end
        
        % meanSiteThresh
        function st = get.meanSiteThresh(obj)
            if isfield(obj.dRes, 'meanSiteThresh')
                st = obj.dRes.meanSiteThresh;
            else
                st = [];
            end
        end
        function set.meanSiteThresh(obj, val)
            obj.dRes.meanSiteThresh = val;
        end
        
        % siteThresh
        function st = get.siteThresh(obj)
            if isfield(obj.dRes, 'meanSiteThresh') && ~isempty(obj.dRes.meanSiteThresh)
                st = obj.dRes.meanSiteThresh;
            elseif isfield(obj.dRes, 'siteThresh') % backwards compatibility
                st = obj.dRes.siteThresh;
            else
                st = [];
            end
        end
        function set.siteThresh(obj, val)
            obj.dRes.siteThresh = val;
        end
        
    end
end

