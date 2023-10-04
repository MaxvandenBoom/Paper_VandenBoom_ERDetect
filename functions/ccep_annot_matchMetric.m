%
%   Extract metric-values from a metrics-struct (with stim-pairs, channels and metric values matrix), for
%   example from the results of the '<name here>' test script; or out of a '*_metric.mat' file from the 
%   annotation tool or bids app) by matching them against the stim-pairs and channels in a manual/visual
%   struct. Optionally, one or more cutoff values can be supplied to threshold the metric values
%   with different cutoffs and evaluate the resulting annotations against to the manual/visual annotations.
%
%   [outMatrix, metric_cutoff_results, cutoff_YoudenJ, cutoff_DVal] = ccep_annot_matchMetric(manualStruct, metricStruct, cutoffs)
%
%       manualStruct            = The manual/visual-struct that the metric-struct stim-pairs and channels will be matched
%                                 to and the annotations will be compared against
%       metricStruct            = The metric-struct to extract the values from, expecting the fields 'channels', 'stimpairs' and 'metric_values'
%       cutoffs                 = The cutoffs applied to convert the extracted metric values to annotations for
%                                 comparison against the manual/visual annotations
%
%
%   Returns: 
%       outMatrix               = The metric-values <channels x stimpairs>
%       metric_cutoff_results   = The results of the comparison between the manual/visual annotations and the
%                                 metric annotations (by different cutoff values), format: [acc, kappa, spec, sens] x cuttoffs
%       cutoff_YoudenJ          = The Youden-index for each of the cutoff values
%       cutoff_DVal             = The D-value for each of the cutoff values
%
%

%   Max van den Boom (Multimodal Neuroimaging Lab, Mayo Clinic, Rochester MN), 2023
%
function [outMatrix, metric_cutoff_results, cutoff_YoudenJ, cutoff_DVal] = ccep_annot_matchMetric(manualStruct, metricStruct, cutoffs)
    if ~exist('verbose', 'var'), verbose = 1;   end
     metric_cutoff_results = [];
     cutoff_YoudenJ = [];
     cutoff_DVal = [];
    
    % initialize metrics output
    outMatrix = nan(length(manualStruct.channels), length(manualStruct.stimpairs));
    
    % variable to count the number of measurements (recorded electrodes while excluding the pairs that were stimulated on)
    numMeasurements = 0;

    % loop through the manual/visual stim-pairs
    for iManualStimpair = 1:length(manualStruct.stimpairs)
        manual_stimpair = manualStruct.stimpairs{iManualStimpair};
        manual_stimpair_split = split(manual_stimpair, '-');

        % try to find the manual/visual stim-pair in the metric stim-pairs
        metric_stimpair_idx = find(strcmpi(metricStruct.stimpairs, manual_stimpair));
        if isempty(metric_stimpair_idx)
            error(['The manual/visual stim-pair ''', manual_stimpair, ''' could not be found in the metric stim-pairs']);
        end
		
        % loop through the manual/visual annotation recorded channels
        channelCounter = 0;
        for iManualChan = 1:length(manualStruct.channels)
            manual_channel = manualStruct.channels{iManualChan};

            % try to find the manual/visual channel in the metric channels
            metric_channel_idx = find(strcmp(metricStruct.channels, manual_channel));
            if isempty(metric_channel_idx)
                error(['The manual/visual channel ''', manual_channel, ''' could not be found in the metric channels']);
            end
            
            
            %
            % metric value
            %

            % check if the current channel is a stimulated channel on this stim-pair
            if any(strcmpi(manual_stimpair_split, manual_channel))
                % stimulated channel

                % set value to nan, don't include stimulated channels in the comparison
                outMatrix(iManualChan, iManualStimpair) = nan;

            else
                % not a stimulated channel

                outMatrix(iManualChan, iManualStimpair) = metricStruct.metric_values(metric_channel_idx, metric_stimpair_idx);
                
                % count as measurement
                numMeasurements = numMeasurements + 1;

            end
            
        end     % end of channel loop

    end     % end of stim-pair loop
    
    if ~isempty(cutoffs)
        if ischar('cutoffs') && strcmpi(cutoffs, 'pbonfsign')    
            % assume the metric values are p-values, use bonferonni significance threshold

            % cross projections (single)
            metric_cutoff_results = nan(5, 1);     % <acc/kappa/spec/sens/prec>

            % annotate by threshold 
            metric_annotations = double(outMatrix < (.05 / numel(outMatrix)));
            %metric_annotations = double(outMatrix < (.05 / numMeasurements));
            
            % clear the measured electrodes at the stimulated-pairs
            metric_annotations(isnan(outMatrix)) = nan;

            % store matching results of this cutoff
            % Note: the function will exclude values that are nans (un-annotated) from both inputs
            [acc, spec, sens, prec, retKappa, agreeMats] = ccep_compareN1Matrices(manualStruct.annotations, metric_annotations);
            metric_cutoff_results(1, 1) = acc;
            metric_cutoff_results(2, 1) = retKappa.k;
            metric_cutoff_results(3, 1) = spec;
            metric_cutoff_results(4, 1) = sens;
			metric_cutoff_results(5, 1) = prec;

        else    

            % variables to store the Youden index and D-Val for this metric
            cutoff_YoudenJ      = nan(1, length(cutoffs));
            cutoff_DVal         = nan(1, length(cutoffs));

            % variable to store the comparison results for the different metric cutoffs (<acc/kappa/spec/sens/prec> x <cutoffs>)
            metric_cutoff_results = nan(5, length(cutoffs));

            % loop over the different cutoffs
            for iCuttoff = 1:length(cutoffs)
                
                % convert (threshold using cutoff) metric-values to annotation values (0, 1 or nan)
                metric_annotations = double(outMatrix > cutoffs(iCuttoff));
                metric_annotations(isnan(outMatrix)) = nan;

                % store annotation comparison results for this cutoff
                [acc, spec, sens, prec, retKappa, agreeMats] = ccep_compareN1Matrices(manualStruct.annotations, metric_annotations);
                metric_cutoff_results(1, iCuttoff) = acc;
                metric_cutoff_results(2, iCuttoff) = retKappa.k;
                metric_cutoff_results(3, iCuttoff) = spec;
                metric_cutoff_results(4, iCuttoff) = sens;
				metric_cutoff_results(5, iCuttoff) = prec;

                % store younden-index of this cutoff
                cutoff_YoudenJ(iCuttoff) = spec + sens - 1;
                cutoff_DVal(iCuttoff) = sqrt((100 - sens) ^ 2 + (100 - spec) ^ 2);

            end

        end
    end
    
end