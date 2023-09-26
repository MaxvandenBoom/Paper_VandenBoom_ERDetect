%
%   Extract the annotation results for different baseline thresholds from data coming out of the
%   'test_thresholdsAndMetrics.py' test script, by matching them against the stim-pairs and channels in a manual/visual struct. 
%   The different baseline threshold results are evaluated against the manual/visual annotations.
%
%   [thresholds, threshold_results, cutoff_YoudenJ, cutoff_DVal] = ccep_annot_matchBaseStdThresholds(manualStruct, testStruct)
%
%       manualStruct            = The manual/visual-struct that the test-struct stim-pairs and channels will be
%                                 matched to and the annotations will be compared against
%       testStruct              = A data struct, derived from the test script results, that contains the
%                                 annotation results for different baseline thresholds
%
%
%   Returns: 
%       thresholds              = The different baseline thresholds that were found in the test-struct
%       threshold_results       = The results of the comparison between the manual/visual annotations and the test
%                                 annotations (at different threshold values), format: [score, kappa, spec, sns] x thresholds
%       cutoff_YoudenJ          = The Youden-index for each of the threshold values
%       cutoff_DVal             = The D-value for each of the threshold values
%
%

%   Max van den Boom (Multimodal Neuroimaging Lab, Mayo Clinic, Rochester MN), 2023
%
function [thresholds, threshold_results, threshold_YoudenJ, threshold_DVal] = ccep_annot_matchBaseStdThresholds(manualStruct, testStruct)
    if ~exist('verbose', 'var'), verbose = 1;   end
    threshold_results = [];
    threshold_YoudenJ = [];
    threshold_DVal = [];
    
    % 
    testStruct.channels_measured = strtrim(num2cell(testStruct.channels_measured, 2));
    testStruct.stimpairs = strtrim(num2cell(testStruct.stimpairs, 2));
    
    
    %
    % match the channel and stim-pair names and map their indices
    %
    test_struct_map_channel = [];
    test_struct_map_stimpair = [];
    test_struct_map_stimmed = [];

    % loop through the manual/visual stim-pairs
    for iManualStimpair = 1:length(manualStruct.stimpairs)
        manual_stimpair = manualStruct.stimpairs{iManualStimpair};
        manual_stimpair_split = split(manual_stimpair, '-');

        % try to find the manual/visual stim-pair in the metric stim-pairs
        metric_stimpair_idx = find(strcmpi(testStruct.stimpairs, manual_stimpair));
        if isempty(metric_stimpair_idx)
            error(['The manual/visual stim-pair ''', manual_stimpair, ''' could not be found in the test-struct stim-pairs']);
        end
		
        % loop through the manual/visual annotation recorded channels
        for iManualChan = 1:length(manualStruct.channels)
            manual_channel = manualStruct.channels{iManualChan};

            % try to find the manual/visual channel in the metric channels
            metric_channel_idx = find(strcmp(testStruct.channels_measured, manual_channel));
            if isempty(metric_channel_idx)
                error(['The manual/visual channel ''', manual_channel, ''' could not be found in the test-struct channels']);
            end
            
            
            %
            % map the indices
            %

            % check if the current channel is a stimulated channel on this stim-pair
            if any(strcmpi(manual_stimpair_split, manual_channel))
                % stimulated channel

                % set value to nan, don't include stimulated channels in the comparison
                test_struct_map_stimmed(iManualChan, iManualStimpair) = 1;

            else
                % not a stimulated channel

                test_struct_map_channel(iManualChan) = metric_channel_idx;
                test_struct_map_stimpair(iManualStimpair) = metric_stimpair_idx;
                test_struct_map_stimmed(iManualChan, iManualStimpair) = 0;
                
            end
            
        end     % end of channel loop
    end     % end of stim-pair loop

    % determine the thresholds in the given struct
    thresholds = testStruct.range;
    
    % variables to store the Youden index and D-Val for this metric
    threshold_YoudenJ      = nan(1, length(thresholds));
    threshold_DVal         = nan(1, length(thresholds));

    % variable to store the comparison results for the different metric cutoffs (<class/kappa/spec/sens> x <cutoffs>)
    threshold_results = nan(4, length(thresholds));

    %    
    for iThresh = 1:length(thresholds)
        
        % retrieve the annotation results matching this threshold from the test struct
        inMatrix = testStruct.(['neg_lat_fact_', num2str(thresholds(iThresh) * 100)]);
        matched_annotations = inMatrix(test_struct_map_channel, test_struct_map_stimpair);
        
        % convert the detected ERs to 1s (and non-ERs to 0s)
        matched_annotations(~isnan(matched_annotations)) = 1;
        matched_annotations(isnan(matched_annotations)) = 0;
        
        % clear the measured electrodes at the stimulated-pairs
        matched_annotations(test_struct_map_stimmed == 1) = nan;
        
        % store annotation comparison for this threshold
        % Note: the function will exclude values that are nans (un-annotated) from both inputs
        [score, spec, sens, retKappa, agreeMats] = ccep_compareN1Matrices(manualStruct.annotations, matched_annotations);
        threshold_results(1, iThresh) = score;
        threshold_results(2, iThresh) = retKappa.k;
        threshold_results(3, iThresh) = spec;
        threshold_results(4, iThresh) = sens;

        % store younden-index of this cutoff
        threshold_YoudenJ(iThresh) = spec + sens - 1;
        threshold_DVal(iThresh) = sqrt((100 - sens) ^ 2 + (100 - spec) ^ 2);

    end
    
end