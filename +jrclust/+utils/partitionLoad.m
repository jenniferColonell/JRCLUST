function [nLoads, nSamplesLoad, nSamplesFinal] = partitionLoad(nSamples, nSamplesMax)
    %PARTITIONLOAD Compute the number of samples to load from a file
    nLoads = min(max(ceil(nSamples / nSamplesMax), 1), inf);

    nSamplesLoad = min(nSamples, nSamplesMax);

    if nLoads == 1 % first load is last load, use nSamplesFinal
        nSamplesLoad = nSamples;
        nSamplesFinal = nSamples;
    else % multiple loads, all will be the same except the last one
        nSamplesFinal = mod(nSamples, nSamplesLoad);
        if nSamplesFinal == 0
            nSamplesFinal = nSamplesLoad;
        elseif nSamplesFinal < nSamplesLoad/2
            % if last part is too small increase the size
            nLoads = nLoads - 1;
            nSamplesFinal = nSamplesFinal + nSamplesLoad;
        end
    end
    %JIC hack to ensure last load has even number of samples
%     if mod(nSamplesFinal,2) == 1
%         nSamplesFinal = nSamplesFinal - 1;
%     end
end
