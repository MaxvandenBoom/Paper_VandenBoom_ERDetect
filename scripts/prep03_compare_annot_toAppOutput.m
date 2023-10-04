%
%   Validate the detection methods by comparing the visual-manual annotations to the App detection output
%

addpath('../functions');
addpath('../external');


%%
% Configuration

stimpair_min_trials = 5;            % the minimum number of trials required to be included
electrode_excludeDist = 12;         % the distance in mm at which electrodes are excluded, [] or 0 = not excluding
stim_channels_include = {'ECOG'};   % only include ECOG stim-pairs. Also SEEG = {'ECOG', 'SEEG'}
rec_channels_include = {'ECOG'};    % only include ECOG channels. Also SEEG = {'ECOG', 'SEEG'}

% 
bids_projectPath   = 'D:\BIDS_erdetect';
%bids_projectPath   = '~/Documents/ERDetect';

derivatives_app_outputPath = 'app_detect_output';


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

allSubjects_results = [];               % <annot dataset> x [acc, retKappa.k, spec, sens, prec, retKrip]
for iSet = 1:size(bids_sets, 1)
    
    %
    bids_manual_annotPath       = fullfile(bids_projectPath, 'derivatives', bids_sets{iSet, 7}, ...
                                    ['sub-' bids_sets{iSet, 2} '_ses-' bids_sets{iSet, 4} '_task-' bids_sets{iSet, 5} '_run-' bids_sets{iSet, 6} '_', bids_sets{iSet, 8}, '.mat']);

    bids_appDetect_annotPath    = fullfile(bids_projectPath, 'derivatives', derivatives_app_outputPath, ...
                                    ['sub-' bids_sets{iSet, 2} '_ses-' bids_sets{iSet, 4} '_task-' bids_sets{iSet, 5} '_run-' bids_sets{iSet, 6}], 'erdetect_data.mat');    
                        
    bids_channelsPath           = fullfile(bids_projectPath, ['sub-' bids_sets{iSet, 2}], ['ses-' bids_sets{iSet, 4}], 'ieeg',...
                                    ['sub-' bids_sets{iSet, 2} '_ses-' bids_sets{iSet, 4} '_task-' bids_sets{iSet, 5} '_run-' bids_sets{iSet, 6}, '_channels.tsv']);

    bids_electrodesPath         = fullfile(bids_projectPath, ['sub-' bids_sets{iSet, 2}], ['ses-' bids_sets{iSet, 4}], 'ieeg',...
                                    ['sub-' bids_sets{iSet, 2} '_ses-' bids_sets{iSet, 4} '_electrodes.tsv']);

    bids_eventsPath             = fullfile(bids_projectPath, ['sub-' bids_sets{iSet, 2}], ['ses-' bids_sets{iSet, 4}], 'ieeg',...
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
    appStruct = ccep_annot_filterByType(appStruct, bids_channelsPath, stim_channels_include, rec_channels_include);
    
    % filter the annotations to only include stimulus-pair and recoding channels that are marked as good
    % Note: manual detection should already have excluded bad_channels, but just in case
    manualStruct = ccep_annot_filterByStatus(manualStruct, bids_channelsPath);
    appStruct = ccep_annot_filterByStatus(appStruct, bids_channelsPath);
    
    % nan out channels that are too close to the stim-pair
    manualStruct = ccep_annot_nanByElectrodeDistance(manualStruct, bids_electrodesPath, electrode_excludeDist, 0);
    appStruct = ccep_annot_nanByElectrodeDistance(appStruct, bids_electrodesPath, electrode_excludeDist, 0);

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
    
    % compare the ER matrices
    [acc, spec, sens, prec, retKappa, agreeMats, retKrip] = ccep_compareN1Matrices(manualStruct.annotations, appStruct.annotations);
    disp(['Visual - ERDetect: ', num2str(acc), '%     - kappa: ', num2str(retKappa.k), '%     - krip: ', num2str(retKrip), '%     - spec: ', num2str(spec), '%     - sens: ', num2str(sens), '%     - prec: ', num2str(prec)]);

    % concatenate
    allSubjects_results(end + 1, :) = [acc, retKappa.k, spec, sens, prec, retKrip];
    
    clear acc spec sens prec retKappa agreeMats retKrip
end
clear iSet manualStruct appStruct
clear bids_manual_annotPath bids_appDetect_annotPath bids_channelsPath bids_electrodesPath

% transfer to a table for easy reading
allSubjects_results_table = array2table(allSubjects_results, 'VariableNames', {'agr perc', 'kappa', 'spec', 'sens', 'prec', 'krip'});
allSubjects_results_table.sub =  bids_sets(:, 1);


%%
%  Calculate averages over subjects

allSubjects_results_average = mean(allSubjects_results, 1);   %[acc, retKappa.k, spec, sens, prec, retKrip]

clear bids_projectPath
return;

save('D:\BIDS_erdetect\derivatives\compares\compare_manualVSapp_output.mat');
