%
%   Validate the different thresholds and cuttoffs of the detection methods by comparing the visual-manual
%   annotations to the output of the App-test (test specifically designed to try different thresholds)
%

addpath('./functions');


%%
% Configuration

stimpair_min_trials = 5;            % the minimum number of trials required to be included
electrode_excludeDist = 12;         % the distance in mm at which electrodes are excluded, [] or 0 = not excluding
stim_channels_include = {'ECOG'};   % only include ECOG stim-pairs. Also SEEG = {'ECOG', 'SEEG'}
rec_channels_include = {'ECOG'};    % only include ECOG channels. Also SEEG = {'ECOG', 'SEEG'}


% specify the cutoffs to try on the different metrics
w15_cutoffs = [0:50:60000];
cpt_cutoffs = [-30:.5:30];

% 
bids_projectPath   = 'D:\BIDS_erdetect';
%bids_projectPath   = '~/Documents/ERDetect';

derivatives_app_outputPath = 'app_detect_output';
derivatives_app_thresholdsAndMetrics_path = 'app_thresholdsAndMetrics';


% data-sets (unique_ID, sub, hemi, ses, task, run)
bids_sets           = { 'UMCU20_DvB',  'UMCU20', {'LH'}, '1',       'SPESclin', '011757', 'annots', 'annot_DvB'; ...    % UMCU - DvB
                        'UMCU21_DvB',  'UMCU21', {'RH'}, '1',       'SPESclin', '021525', 'annots', 'annot_DvB'; ...
                        'UMCU22_DvB',  'UMCU22', {'LH'}, '1',       'SPESclin', '011714', 'annots', 'annot_DvB'; ...
                        'UMCU23_DvB',  'UMCU23', {'RH'}, '1',       'SPESclin', '021706', 'annots', 'annot_DvB'; ...
                        'UMCU25_DvB',  'UMCU25', {'RH'}, '1',       'SPESclin', '031729', 'annots', 'annot_DvB'; ...
                        'UMCU26_DvB',  'UMCU26', {'RH'}, '1',       'SPESclin', '011555', 'annots', 'annot_DvB'; ...
                        'UMCU59_JvdA', 'UMCU59', {'RH'}, '1',       'SPESclin', '041501', 'annots', 'annot_JvdA'; ...   % UMCU - JvdA
                        'UMCU62_JvdA', 'UMCU62', {'LH'}, '1b',      'SPESclin', '050941', 'annots', 'annot_JvdA'; ...
                        'UMCU67_JvdA', 'UMCU67', {'RH'}, '1',       'SPESclin', '021704', 'annots', 'annot_JvdA'; ...
                        'UMCU20_MvdB', 'UMCU20', {'LH'}, '1',       'SPESclin', '011757', 'annots', 'annot_MvdB'; ...   % UMCU - MvdB
                        'UMCU21_MvdB', 'UMCU21', {'RH'}, '1',       'SPESclin', '021525', 'annots', 'annot_MvdB'; ...
                        'UMCU22_MvdB', 'UMCU22', {'LH'}, '1',       'SPESclin', '011714', 'annots', 'annot_MvdB'; ...
                        'UMCU23_MvdB', 'UMCU23', {'RH'}, '1',       'SPESclin', '021706', 'annots', 'annot_MvdB'; ...
                        'UMCU25_MvdB', 'UMCU25', {'RH'}, '1',       'SPESclin', '031729', 'annots', 'annot_MvdB'; ...
                        'UMCU26_MvdB', 'UMCU26', {'RH'}, '1',       'SPESclin', '011555', 'annots', 'annot_MvdB'; ...
                        'UMCU59_MvdB', 'UMCU59', {'RH'}, '1',       'SPESclin', '041501', 'annots', 'annot_MvdB'; ...
                        'UMCU62_MvdB', 'UMCU62', {'LH'}, '1b',      'SPESclin', '050941', 'annots', 'annot_MvdB'; ...
                        'UMCU67_MvdB', 'UMCU67', {'RH'}, '1',       'SPESclin', '021704', 'annots', 'annot_MvdB'; ...
                        'MAYO01_MvdB', 'MAYO01', {'LH'}, 'ieeg01',  'ccep', '01', 'annots', 'annot_MvdB_clin'; ...      % Mayo - MvdB
                        'MAYO02_MvdB', 'MAYO02', {'LH'}, 'ieeg01',  'ccep', '01', 'annots', 'annot_MvdB_clin'; ...
                        'MAYO03_MvdB', 'MAYO03', {'RH'}, 'ieeg01',  'ccep', '01', 'annots', 'annot_MvdB_clin'; ...
                        'MAYO04_MvdB', 'MAYO04', {'LH'}, 'ieeg01',  'ccep', '01', 'annots', 'annot_MvdB_clin'; ...
                        'MAYO05_MvdB', 'MAYO05', {'LH'}, 'ieeg01',  'ccep', '01', 'annots', 'annot_MvdB_clin'; ...
                        'MAYO04_SB',   'MAYO04', {'LH'}, 'ieeg01',  'ccep', '01', 'annots', 'annot_SB'; ...             % Mayo - SB
                        'MAYO05_SB',   'MAYO05', {'LH'}, 'ieeg01',  'ccep', '01', 'annots', 'annot_SB'     };


                        
%%
%

allSubjects_threshAndMetr = {};
for iSet = 1:size(bids_sets, 1)
    
    % build BIDS paths
    bids_manual_annotPath         = fullfile(bids_projectPath, 'derivatives', bids_sets{iSet, 7}, ...
                                      ['sub-' bids_sets{iSet, 2} '_ses-' bids_sets{iSet, 4} '_task-' bids_sets{iSet, 5} '_run-' bids_sets{iSet, 6} '_', bids_sets{iSet, 8}, '.mat']);

    bids_appDetect_annotPath      = fullfile(bids_projectPath, 'derivatives', derivatives_app_outputPath, ...
                                      ['sub-' bids_sets{iSet, 2} '_ses-' bids_sets{iSet, 4} '_task-' bids_sets{iSet, 5} '_run-' bids_sets{iSet, 6}], 'erdetect_data.mat');    
    
    bids_thresholdsAndMetricsPath = fullfile(bids_projectPath, 'derivatives', derivatives_app_thresholdsAndMetrics_path, ...
                                      ['sub-' bids_sets{iSet, 2} '_ROC.mat']);
                        
    bids_channelsPath             = fullfile(bids_projectPath, ['sub-' bids_sets{iSet, 2}], ['ses-' bids_sets{iSet, 4}], 'ieeg',...
                                      ['sub-' bids_sets{iSet, 2} '_ses-' bids_sets{iSet, 4} '_task-' bids_sets{iSet, 5} '_run-' bids_sets{iSet, 6}, '_channels.tsv']);

    bids_electrodesPath           = fullfile(bids_projectPath, ['sub-' bids_sets{iSet, 2}], ['ses-' bids_sets{iSet, 4}], 'ieeg',...
                                      ['sub-' bids_sets{iSet, 2} '_ses-' bids_sets{iSet, 4} '_electrodes.tsv']);
                        
    bids_eventsPath               = fullfile(bids_projectPath, ['sub-' bids_sets{iSet, 2}], ['ses-' bids_sets{iSet, 4}], 'ieeg',...
                                      ['sub-' bids_sets{iSet, 2} '_ses-' bids_sets{iSet, 4} '_task-' bids_sets{iSet, 5} '_run-' bids_sets{iSet, 6}, '_events.tsv']);


    %%
    %
    %
    
    % Load and match the CCEP stim-pairs and channels from manual/visual and automatic detection annotation files
    [manualStruct, appStruct] = ccep_annot_matchManualAndAuto(bids_manual_annotPath, bids_appDetect_annotPath);
    
    % check whether the channels and stim-pairs match
    chan_mismatch = cellfun(@strcmp, appStruct.channels, manualStruct.channels) == 0;
    if any(chan_mismatch)
        error('mismatch in channels between the two files');
    end
    stimpair_mismatch = cellfun(@strcmp, appStruct.stimpairs, manualStruct.stimpairs) == 0;
    if any(stimpair_mismatch)
        error('mismatch in stim-pairs between the two files');
    end
    clear chan_mismatch stimpair_mismatch
    
    % filter the annotation to only include stimulus-pair and recoding channels types we want
    manualStruct = ccep_annot_filterByType(manualStruct, bids_channelsPath, stim_channels_include, rec_channels_include);
    appStruct    = ccep_annot_filterByType(appStruct, bids_channelsPath, stim_channels_include, rec_channels_include);
    
    % filter the annotations to only include stimulus-pair and recoding channels that are marked as good
    % Note: manual detection should already have excluded bad_channels, but just in case
    manualStruct = ccep_annot_filterByStatus(manualStruct, bids_channelsPath);
    appStruct    = ccep_annot_filterByStatus(appStruct, bids_channelsPath);
    
    % nan out channels that are too close to the stim-pair
    manualStruct = ccep_annot_nanByElectrodeDistance(manualStruct, bids_electrodesPath, electrode_excludeDist, 0);
    appStruct    = ccep_annot_nanByElectrodeDistance(appStruct, bids_electrodesPath, electrode_excludeDist, 0);
    
    % filter out the stim-pairs that have less than the minimum required number of trials
    manualStruct = ccep_annot_filterByNumTrials(manualStruct, bids_eventsPath, 1, stimpair_min_trials, 1);
    appStruct    = ccep_annot_filterByNumTrials(appStruct, bids_eventsPath, 1, stimpair_min_trials, 0);
    
    % check again whether the channels and stim-pairs match
    chan_mismatch = cellfun(@strcmp, appStruct.channels, manualStruct.channels) == 0;
    if any(chan_mismatch)
        error('mismatch in channels between the two files after filterig');
    end
    stimpair_mismatch = cellfun(@strcmp, appStruct.stimpairs, manualStruct.stimpairs) == 0;
    if any(stimpair_mismatch)
        error('mismatch in stim-pairs between the two files after filterig');
    end
    clear chan_mismatch stimpair_mismatch
    
    
    %%
    %
    %
    
    % load the metric file
    threshAndMetrics = load(bids_thresholdsAndMetricsPath);

    % evaluate the different baseline thresholds
    [stdB_thresholds, ...
     stdB_threshold_results, ...
     stdB_threshold_YoudenJ, stdB_threshold_DVal] = ccep_annot_matchBaseStdThresholds(manualStruct, threshAndMetrics);
    
    % extract the metric values and match them against the manual/visual annotation 
    [~, w15_cutoff_results, ...
        w15_cutoff_YoudenJ, w15_cutoff_DVal] = ccep_annot_matchMetric(manualStruct, ...
                                                                      struct('channels', {strtrim(num2cell(threshAndMetrics.channels_measured, 2))}, ...
                                                                             'stimpairs', {strtrim(num2cell(threshAndMetrics.stimpairs, 2))}, ...
                                                                             'metric_values', {threshAndMetrics.metrics.waveform}), ...
                                                                      w15_cutoffs);

    [~, cpt_cutoff_results, ...
        cpt_cutoff_YoudenJ, cpt_cutoff_DVal] = ccep_annot_matchMetric(manualStruct, ...
                                                                      struct('channels', {strtrim(num2cell(threshAndMetrics.channels_measured, 2))}, ...
                                                                             'stimpairs', {strtrim(num2cell(threshAndMetrics.stimpairs, 2))}, ...
                                                                             'metric_values', {threshAndMetrics.metrics.cross_proj_t}), ...
                                                                      cpt_cutoffs);

    [~, cp_cutoff_results, ~, ~] = ccep_annot_matchMetric(manualStruct, ...
                                                          struct('channels', {strtrim(num2cell(threshAndMetrics.channels_measured, 2))}, ...
                                                                 'stimpairs', {strtrim(num2cell(threshAndMetrics.stimpairs, 2))}, ...
                                                                 'metric_values', {threshAndMetrics.metrics.cross_proj_p}), ...
                                                          'pbonfsign');
    
    % 
    subject_threshAndMetr                         = [];
    
    subject_threshAndMetr.stdB_thresholds         = stdB_thresholds;
    subject_threshAndMetr.w15_cutoffs             = w15_cutoffs;
    subject_threshAndMetr.cpt_cutoffs             = cpt_cutoffs;

    subject_threshAndMetr.stdB_threshold_YoudenJ  = stdB_threshold_YoudenJ;
    subject_threshAndMetr.stdB_threshold_DVal     = stdB_threshold_DVal;
    subject_threshAndMetr.w15_cutoff_YoudenJ      = w15_cutoff_YoudenJ;
    subject_threshAndMetr.w15_cutoff_DVal         = w15_cutoff_DVal;
    subject_threshAndMetr.cpt_cutoff_YoudenJ      = cpt_cutoff_YoudenJ;
    subject_threshAndMetr.cpt_cutoff_DVal         = cpt_cutoff_DVal;
    
    subject_threshAndMetr.mutual_stdB_comp        = stdB_threshold_results;
    subject_threshAndMetr.mutual_w15_comp         = w15_cutoff_results;
    subject_threshAndMetr.mutual_cpt_comp         = cpt_cutoff_results;
    subject_threshAndMetr.mutual_cp_comp          = cp_cutoff_results;
    
    allSubjects_threshAndMetr{iSet} = subject_threshAndMetr;
    
    clear stdB_threshold_YoudenJ stdB_threshold_DVal w15_cutoff_YoudenJ w15_cutoff_DVal cpt_cutoff_YoudenJ cpt_cutoff_DVal
    clear w15_cutoff_results cpt_cutoff_results cp_cutoff_results
    clear subject_threshAndMetr
end
clear manualStruct appStruct threshAndMetrics
clear bids_manual_annotPath bids_autoDetect_annotPath bids_thresholdsAndMetricsPath bids_channelsPath bids_electrodesPath




%%
%  Calculate averages over subjects


% transfer the thresholds/cutoff values
allSubjects_threshAndMetr_averages = struct;

allSubjects_threshAndMetr_averages.stdB_thresholds = allSubjects_threshAndMetr{1}.stdB_thresholds;
allSubjects_threshAndMetr_averages.w15_cutoffs     = allSubjects_threshAndMetr{1}.w15_cutoffs;
allSubjects_threshAndMetr_averages.cpt_cutoffs     = allSubjects_threshAndMetr{1}.cpt_cutoffs;


% loop/average over the sets and methods
for iSet = 1:length(allSubjects_threshAndMetr)
    for iMetric = 1:4

        % 
        strMetric = '';
        switch iMetric
            case 1, strMetric = 'stdB'; strTestType = 'threshold';
            case 2, strMetric = 'w15'; strTestType = 'cutoff';
            case 3, strMetric = 'cpt'; strTestType = 'cutoff';
            case 4, strMetric = 'cp'; strTestType = 'cutoff';
                
        end

        % transfer the threshold/metric values
        if ~isfield(allSubjects_threshAndMetr_averages, ['mutual_', strMetric, '_comp'])
            allSubjects_threshAndMetr_averages.(['mutual_', strMetric, '_comp']) = zeros(size(allSubjects_threshAndMetr{iSet}.(['mutual_', strMetric, '_comp'])));
        end
        allSubjects_threshAndMetr_averages.(['mutual_', strMetric, '_comp']) = allSubjects_threshAndMetr_averages.(['mutual_', strMetric, '_comp']) + allSubjects_threshAndMetr{iSet}.(['mutual_', strMetric, '_comp']);

        % transfer the youden en dvals
        if iMetric == 1 || iMetric == 2 ||  iMetric == 3
            
            if ~isfield(allSubjects_threshAndMetr_averages, [strMetric, '_', strTestType, '_YoudenJ'])
                allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_YoudenJ']) = zeros(size(allSubjects_threshAndMetr{iSet}.([strMetric, '_', strTestType, '_YoudenJ'])));
            end
            allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_YoudenJ']) = allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_YoudenJ']) + allSubjects_threshAndMetr{iSet}.([strMetric, '_', strTestType, '_YoudenJ']);

            if ~isfield(allSubjects_threshAndMetr_averages, [strMetric, '_', strTestType, '_DVal'])
                allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_DVal']) = zeros(size(allSubjects_threshAndMetr{iSet}.([strMetric, '_', strTestType, '_DVal'])));
            end
            allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_DVal']) = allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_DVal']) + allSubjects_threshAndMetr{iSet}.([strMetric, '_', strTestType, '_DVal']);
            
        end
        
        % at the last subject, divide the totals for the average
        if iSet == length(allSubjects_threshAndMetr)
            allSubjects_threshAndMetr_averages.(['mutual_', strMetric, '_comp']) = allSubjects_threshAndMetr_averages.(['mutual_', strMetric, '_comp']) / length(allSubjects_threshAndMetr);
            
            if iMetric == 1 || iMetric == 2 || iMetric == 3
               allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_YoudenJ']) = allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_YoudenJ']) / length(allSubjects_threshAndMetr);
               allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_DVal']) = allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_DVal']) / length(allSubjects_threshAndMetr);
            end
            
        end
        
    end
    
end
clear iSet iMetric strMetric

%% 
%  Print for each method the threshold/cutoff that results from the highest average youden index

for iMeth = 1:3
    if iMeth == 1, strMetric = 'stdB'; strTestType = 'threshold';   end
    if iMeth == 2, strMetric = 'w15'; strTestType = 'cutoff';   end
    if iMeth == 3, strMetric = 'cpt'; strTestType = 'cutoff';   end

    % find the highest average Youden per method
    mCutOffYouden = allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_YoudenJ']);
    [~, optimal_index] = max(mCutOffYouden);
    
    % retrieve the threshold/cutoff based on Youden for this method
    mCutOffs = allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, 's']);
    optimal_value = mCutOffs(optimal_index);
    
    % print
    disp([strMetric, ' optimal ', strTestType, ': ' num2str(optimal_value)]);

end
clear iMeth strMetric strTestType optimal_index optimal_value 
clear mCutOffYouden mCutOffs

clear bids_projectPath
clear derivatives_app_outputPath derivatives_app_thresholdsAndMetrics_path
return;


%%
%
save('D:\BIDS_erdetect\derivatives\compares\compare_manualVSappTest_thresholdsAndCutoffs.mat');
