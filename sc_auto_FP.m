function autoCall = sc_auto( firingRate, vpp, SNR, FP, ISIViolations, IsoDist, firing_std ) 
    SNR_high_thresh = 6;
    SNR_low_thresh = 2.5; %for low > SNR > high, check the isolation distance
    %SNR_multi_thresh = 2; %Too little signal to be sure of separation from background, useful if uniform firing
    FP_single_thresh = 0.03; %(max 0.5%)
    FP_ok_thresh = 0.15; 
    ISIViolations_thresh = 5;
    ISIViolations_ok_thresh = 10;
    iso_thresh = 100;
    firingRate_thresh = 0.05;      %in Hz
    
    firing_std_thresh = 0.5;
    
    autoCall = "None";
    if firingRate < firingRate_thresh
        if( (SNR > SNR_high_thresh) || (FP <= FP_single_thresh) || (ISIViolations <= ISIViolations_thresh) )
             autoCall = "single";
             return;
        else
            return;
        end
    end
     
    if (SNR >= SNR_high_thresh) 
        % call a single if ISI conditions are met
        % check the ISI
        if ( (FP <= FP_single_thresh) || (ISIViolations <= ISIViolations_thresh) )
           autoCall = "single";
           return;
        elseif (FP <= FP_ok_thresh)
           autoCall = "ok";
        else
               if firing_std < 0.5*firing_std_thresh
                    autoCall = "multi";
               elseif firing_std < firing_std_thresh
                    autoCall = "multi/None";
               end      
        end
    
    elseif (SNR >= SNR_low_thresh)
        % if isolated, can be a single or ok
        if (isnan(IsoDist) || IsoDist > iso_thresh )
            if ( (FP <= FP_single_thresh) || (ISIViolations <= ISIViolations_thresh) )
               autoCall = "single/ok";  % whether unit is good enough to be single a function of human judged isolation
               return;
            elseif (FP <= FP_ok_thresh || (ISIViolations <= ISIViolations_ok_thresh))
               autoCall = "ok"; % Ok
            else
               if firing_std < 0.5*firing_std_thresh
                    autoCall = "multi";
               elseif firing_std < firing_std_thresh
                    autoCall = "multi/None";
               end
            end
        else
            % if not isolated, call as a multi/ok if ISI is low enough
            % otherwise call as multi if uniform enough
            if ( (FP <= FP_ok_thresh) || (ISIViolations <= ISIViolations_ok_thresh))
                autoCall = "ok";
            else
                if firing_std < 0.5*firing_std_thresh
                    autoCall = "multi";
                elseif firing_std < firing_std_thresh
                    autoCall = "multi/None";
                end
            end
        end
%     elseif (SNR >= SNR_multi_thresh)
%         % just check for stable firing. If "quite stable" very likely
%         % qualifies as a analyzable MUA; otherwise up to curator
%             if firing_std < 0.5*firing_std_thresh
%                 autoCall = "multi";
%             elseif firing_std < firing_std_thresh
%                 autoCall = "multi/None";
%             end
    end

    
end