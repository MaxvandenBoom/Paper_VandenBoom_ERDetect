%
% Calculate the inter-rater reliability metrics and annotation descriptives
%

addpath('./functions');
addpath('./external');


%%
% Configuration

checkWithAppOutput = 1;             % 1 = check to make sure all inter-rater compare stim-pairs and recorded electrodes are in the app output. 0 = all present between inter-raters

electrode_excludeDist = 12;         % the distance in mm at which electrodes are excluded, [] or 0 = not excluding
stimpair_min_trials = 5;            % the minimum number of trials required to be included
stim_channels_include = {'ECOG'};   % only include ECOG stim-pairs. Also SEEG = {'ECOG', 'SEEG'}
rec_channels_include = {'ECOG'};    % only include ECOG channels. Also SEEG = {'ECOG', 'SEEG'}


bids_projectPath   = 'D:\BIDS_erdetect';
%bids_projectPath   = '~/Documents/ERDetect';

derivatives_app_outputPath = 'app_detect_output';


compareSets           = { ... % DvB/MvdB vs SB
                          'UMCU21', {'RH'}, '1',      'SPESclin', '021525', {'DvB', 'SB'},    {'annots/sub-UMCU21_ses-1_task-SPESclin_run-021525_annot_DvB.mat',     'annots/sub-UMCU21_ses-1_task-SPESclin_run-021525_annot_SB.mat'}; ... 
                          'UMCU21', {'RH'}, '1',      'SPESclin', '021525', {'MvdB', 'SB'},   {'annots/sub-UMCU21_ses-1_task-SPESclin_run-021525_annot_MvdB.mat',    'annots/sub-UMCU21_ses-1_task-SPESclin_run-021525_annot_SB.mat'}; ...
                          'MAYO04', {'LH'}, 'ieeg01', 'ccep',     '01',     {'MvdB', 'SB'},   {'annots/sub-MAYO04_ses-ieeg01_task-ccep_run-01_annot_MvdB_clin.mat',  'annots/sub-MAYO04_ses-ieeg01_task-ccep_run-01_annot_SB.mat'}; ...
                          'MAYO05', {'LH'}, 'ieeg01', 'ccep',     '01',     {'MvdB', 'SB'},   {'annots/sub-MAYO05_ses-ieeg01_task-ccep_run-01_annot_MvdB_clin.mat',  'annots/sub-MAYO05_ses-ieeg01_task-ccep_run-01_annot_SB.mat'}; ...
                          ...   % DvB/JvdA vs MvdB
                          'UMCU20', {'LH'}, '1',      'SPESclin', '011757', {'DvB', 'MvdB'},  {'annots/sub-UMCU20_ses-1_task-SPESclin_run-011757_annot_DvB.mat',     'annots/sub-UMCU20_ses-1_task-SPESclin_run-011757_annot_MvdB.mat'}; ...
                          'UMCU21', {'RH'}, '1',      'SPESclin', '021525', {'DvB', 'MvdB'},  {'annots/sub-UMCU21_ses-1_task-SPESclin_run-021525_annot_DvB.mat',     'annots/sub-UMCU21_ses-1_task-SPESclin_run-021525_annot_MvdB.mat'}; ...
                          'UMCU22', {'LH'}, '1',      'SPESclin', '011714', {'DvB', 'MvdB'},  {'annots/sub-UMCU22_ses-1_task-SPESclin_run-011714_annot_DvB.mat',     'annots/sub-UMCU22_ses-1_task-SPESclin_run-011714_annot_MvdB.mat'}; ...
                          'UMCU23', {'RH'}, '1',      'SPESclin', '021706', {'DvB', 'MvdB'},  {'annots/sub-UMCU23_ses-1_task-SPESclin_run-021706_annot_DvB.mat',     'annots/sub-UMCU23_ses-1_task-SPESclin_run-021706_annot_MvdB.mat'}; ...
                          'UMCU25', {'RH'}, '1',      'SPESclin', '031729', {'DvB', 'MvdB'},  {'annots/sub-UMCU25_ses-1_task-SPESclin_run-031729_annot_DvB.mat',     'annots/sub-UMCU25_ses-1_task-SPESclin_run-031729_annot_MvdB.mat'}; ...
                          'UMCU26', {'RH'}, '1',      'SPESclin', '011555', {'DvB', 'MvdB'},  {'annots/sub-UMCU26_ses-1_task-SPESclin_run-011555_annot_DvB.mat',     'annots/sub-UMCU26_ses-1_task-SPESclin_run-011555_annot_MvdB.mat'}; ...
                          'UMCU59', {'RH'}, '1',      'SPESclin', '041501', {'JvdA', 'MvdB'}, {'annots/sub-UMCU59_ses-1_task-SPESclin_run-041501_annot_JvdA.mat',    'annots/sub-UMCU59_ses-1_task-SPESclin_run-041501_annot_MvdB.mat'}; ...
                          'UMCU62', {'LH'}, '1b',     'SPESclin', '050941', {'JvdA', 'MvdB'}, {'annots/sub-UMCU62_ses-1b_task-SPESclin_run-050941_annot_JvdA.mat',   'annots/sub-UMCU62_ses-1b_task-SPESclin_run-050941_annot_MvdB.mat'}; ...
                          'UMCU67', {'RH'}, '1',      'SPESclin', '021704', {'JvdA', 'MvdB'}, {'annots/sub-UMCU67_ses-1_task-SPESclin_run-021704_annot_JvdA',        'annots/sub-UMCU67_ses-1_task-SPESclin_run-021704_annot_MvdB.mat'} ...
                        };


%%
% create a unique ID based on the subject and two annotators
uniqueIDs = {};
for iSet = 1:size(compareSets, 1)
    uniqueIDs{iSet} = [compareSets{iSet, 1}, '__', compareSets{iSet, 6}{1}, '_', compareSets{iSet, 6}{2}];
end
compareSets = [uniqueIDs', compareSets];
clear uniqueIDs


%%
%

interRater_results = [];               % <inter-rater dataset> x [score, retKappa.k, spec, sens, retKrip]
interRater_annotDescr_IDs = {};
interRater_annotDescr = [];            % <inter-rater dataset> x [total, ER, NonER, ER_perc, NonER_perc]

% loop over the sets
for iSet = 1:size(compareSets, 1)
    disp(['Set: ', num2str(iSet), ' ', compareSets{iSet, 1}]);
    
    %%
    %
    %
    
    % load the annotation files           
    annot1 = load(fullfile(bids_projectPath, 'derivatives', compareSets{iSet, 8}{1}));
    annot1 = annot1.annot;

    annot2 = load(fullfile(bids_projectPath, 'derivatives', compareSets{iSet, 8}{2}));
    annot2 = annot2.annot;

    % build BIDS paths
    bids_channelsPath         = fullfile(bids_projectPath, ['sub-' compareSets{iSet, 2}], ['ses-' compareSets{iSet, 4}], 'ieeg',...
                                  ['sub-' compareSets{iSet, 2} '_ses-' compareSets{iSet, 4} '_task-' compareSets{iSet, 5} '_run-' compareSets{iSet, 6}, '_channels.tsv']);
                              
    bids_electrodesPath       = fullfile(bids_projectPath, ['sub-' compareSets{iSet, 2}], ['ses-' compareSets{iSet, 4}], 'ieeg',...
                                  ['sub-' compareSets{iSet, 2} '_ses-' compareSets{iSet, 4} '_electrodes.tsv']);
                              
    bids_eventsPath           = fullfile(bids_projectPath, ['sub-' compareSets{iSet, 2}], ['ses-' compareSets{iSet, 4}], 'ieeg',...
                                  ['sub-' compareSets{iSet, 2} '_ses-' compareSets{iSet, 4} '_task-' compareSets{iSet, 5} '_run-' compareSets{iSet, 6}, '_events.tsv']);

    if checkWithAppOutput
        bids_appDetect_annotPath = fullfile(bids_projectPath, 'derivatives', derivatives_app_outputPath, ...
                                      ['sub-' compareSets{iSet, 2} '_ses-' compareSets{iSet, 4} '_task-' compareSets{iSet, 5} '_run-' compareSets{iSet, 6}], 'erdetect_data.mat');    
    end
    
    % make sure all are rows
    if ~isrow(annot1.channels)
       annot1.channels = annot1.channels'; 
    end
    if ~isrow(annot2.channels)
       annot2.channels = annot2.channels'; 
    end
    if ~isrow(annot1.stimpairs)
       annot1.stimpairs = annot1.stimpairs'; 
    end
    if ~isrow(annot2.stimpairs)
       annot2.stimpairs = annot2.stimpairs'; 
    end
                        
    % check if the measured channels differ and adjust
    if length(annot1.channels) ~= length(annot2.channels)
        [mis_channelNames, mis_annot1, mis_annot2] = setxor(annot1.channels, annot2.channels);
        
        % check if there are channels that only exist in annot1 (in comparison to annot2)
        if length(mis_annot1) > 0
            
           % remove from annot2
           annot1.channels(mis_annot1) = [];
           annot1.annotations(mis_annot1, :) = [];         
        end
        
        % check if there are channels that only exist in annot2 (in comparison to annot1)
        if length(mis_annot2) > 0
            
           % remove from annot2
           annot2.channels(mis_annot2) = [];
           annot2.annotations(mis_annot2, :) = [];
        end

    end
    
    % check if the stim-pairs differ and adjust
    if length(annot1.stimpairs) ~= length(annot2.stimpairs)
        [mis_stimpairNames, mis_annot1, mis_annot2] = setxor(annot1.stimpairs, annot2.stimpairs);
        
        % check if there are stim-pair that only exist in annot1 (in comparison to annot2)
        if length(mis_annot1) > 0
            
           % remove from annot1
           annot1.stimpairs(mis_annot1) = [];
           annot1.annotations(:, mis_annot1) = [];
        end
        
        % check if there are stim-pair that only exist in annot2 (in comparison to annot1)
        if length(mis_annot2) > 0
            
           % remove from annot2
           annot2.stimpairs(mis_annot2) = [];
           annot2.annotations(:, mis_annot2) = [];
        end

    end                 
    
    % check whether the channels and stim-pairs match
    chan_mismatch = cellfun(@strcmp, annot2.channels, annot1.channels) == 0;
    if any(chan_mismatch)
        error('mismatch in channels between the two files');
    end
    stimpair_mismatch = cellfun(@strcmp, annot2.stimpairs, annot1.stimpairs) == 0;
    if any(stimpair_mismatch)
        error('mismatch in stim-pairs between the two files');
    end

    
    %%
    %
    %

    % filter the annotations to only include stimulus-pair and recoding channels types we want
    annot1 = ccep_annot_filterByType(annot1, bids_channelsPath, stim_channels_include, rec_channels_include);
    annot2 = ccep_annot_filterByType(annot2, bids_channelsPath, stim_channels_include, rec_channels_include);
    
    % filter the annotations to only include stimulus-pair and recoding channels that are marked as good
    annot1 = ccep_annot_filterByStatus(annot1, bids_channelsPath);
    annot2 = ccep_annot_filterByStatus(annot2, bids_channelsPath);

    % filter out the stim-pairs that have less than the minimum required
    % number of trials
    annot1 = ccep_annot_filterByNumTrials(annot1, bids_eventsPath, 1, stimpair_min_trials, 1);
    annot2 = ccep_annot_filterByNumTrials(annot2, bids_eventsPath, 1, stimpair_min_trials, 0);
    
    % nan out channels that are too close to the stim-pair
    annot1 = ccep_annot_nanByElectrodeDistance(annot1, bids_electrodesPath, electrode_excludeDist, 0);
    annot2 = ccep_annot_nanByElectrodeDistance(annot2, bids_electrodesPath, electrode_excludeDist, 0);

    % optionally, check if there are stim-pair and channels that are between inter-rates but not in the app output struct
    if checkWithAppOutput
        annot_app       = load(bids_appDetect_annotPath);
        
        % loop over the inter-rater annotation stim-pairs and find the ones that do not exist in the app output
        for iStim = 1:length(annot1.stimpairs)
            
            % check if pair does not exist in app output
            if isempty(find(strcmpi(annot_app.stimpair_labels, annot1.stimpairs{iStim}), 1))
                error(['Stim-pair ', annot1.stimpairs{iStim}, ' was annotated but not present in the app detection output']);
            end
        end
        clear iStim

        % loop over the inter-rater annotation channels and find the ones that do not exist in the app output
        for iChan = 1:length(annot1.channels)
            
            % check if pair does not exist in app output
            if isempty(find(strcmpi(annot_app.channel_labels, annot1.channels{iChan}), 1))
                error(['Recorded channel ', annot1.channels{iStim}, ' was annotated but not present in the app detection output']);
            end
        end
        clear iChan
        
    end
    
    
    % check again whether the channels and stim-pairs match
    chan_mismatch = cellfun(@strcmp, annot2.channels, annot1.channels) == 0;
    if any(chan_mismatch)
        error('mismatch in channels between the two files after filtering');
    end
    stimpair_mismatch = cellfun(@strcmp, annot2.stimpairs, annot1.stimpairs) == 0;
    if any(stimpair_mismatch)
        error('mismatch in stim-pairs between the two files after filtering');
    end
    
    % print included stim-pairs and recording channels
    disp(['   Mutual stim-pairs between raters: ', strjoin(annot1.stimpairs, '   ')]);
    disp(['   Mutual recorded channels between raters: ', strjoin(annot1.channels, '   ')]);
    
    
    %%
    %
    %
    
    % combine and make linear
    annot_l = [annot1.annotations(:), annot2.annotations(:)];

    % remove the stimulated channels
    annot_l(any(annot_l == -1, 2), :) = [];

    % convert P1s to No-ERs
    annot_l(annot_l == 2) = 0;
    
    % remove the nans for both annotaters (if there is a nan for either of the annotaters)
    annot_l_nonans = annot_l;
    annot_l_nonans(any(isnan(annot_l_nonans), 2), :) = [];

    % report on descriptives (total annotations made, num of ER and non-ER for each rater)
    annot_1_total = sum(~isnan(annot_l(:, 1)));
    annot_1_ER    = sum(annot_l(:, 1) == 1);
    annot_1_NonER = sum(annot_l(:, 1) == 0);
    annot_1_ER_perc    = round(annot_1_ER    / annot_1_total * 100);
    annot_1_NonER_perc = round(annot_1_NonER / annot_1_total * 100);
    disp(['    - ', compareSets{iSet, 8}{1}]);
    disp(['       - total annotations: ', num2str(annot_1_total)]);
    disp(['       - ER annotations: ', num2str(annot_1_ER), ' (', num2str(annot_1_ER_perc), '%)']);
    disp(['       - non-ER annotations: ', num2str(annot_1_NonER), ' (', num2str(annot_1_NonER_perc), '%)']);
    
    annot_2_total = sum(~isnan(annot_l(:, 2)));
    annot_2_ER    = sum(annot_l(:, 2) == 1);
    annot_2_NonER = sum(annot_l(:, 2) == 0);
    annot_2_ER_perc    = round(annot_2_ER    / annot_2_total * 100);
    annot_2_NonER_perc = round(annot_2_NonER / annot_2_total * 100);
    disp(['    - ', compareSets{iSet, 8}{2}]);
    disp(['       - total annotations: ', num2str(annot_2_total)]);
    disp(['       - ER annotations: ', num2str(annot_2_ER), ' (', num2str(annot_2_ER_perc), '%)']);
    disp(['       - non-ER annotations: ', num2str(annot_2_NonER), ' (', num2str(annot_2_NonER_perc), '%)']);
    %annot_l = flip(annot_l,2);
    %annot_l_nonans = flip(annot_l_nonans,2);
    
    % store the descriptives of each annotator as one entry
    if ~any(contains(interRater_annotDescr_IDs, [compareSets{iSet, 2}, '_', compareSets{iSet, 7}{1}]))
        interRater_annotDescr_IDs{end + 1} = [compareSets{iSet, 2}, '_', compareSets{iSet, 7}{1}];
        interRater_annotDescr(end + 1, :) = [annot_1_total, annot_1_ER, annot_1_NonER, annot_1_ER_perc, annot_1_NonER_perc];
    end
    if ~any(contains(interRater_annotDescr_IDs, [compareSets{iSet, 2}, '_', compareSets{iSet, 7}{2}]))
        interRater_annotDescr_IDs{end + 1} = [compareSets{iSet, 2}, '_', compareSets{iSet, 7}{2}];
        interRater_annotDescr(end + 1, :) = [annot_2_total, annot_2_ER, annot_2_NonER, annot_2_ER_perc, annot_2_NonER_perc]; 
    end
    clear annot_1_total annot_1_ER annot_1_NonER annot_1_ER_perc annot_1_NonER_perc
    clear annot_2_total annot_2_ER annot_2_NonER annot_2_ER_perc annot_2_NonER_perc
    
    
    %%
    %  Percentages and cohen's kappa

    [score, spec, sens, retKappa, agreeMats, retKrip, swapSpec, swapSens] = ccep_compareN1Matrices(annot_l(:,1), annot_l(:,2));
    disp(['- Perc agreement match: ', num2str(round(score))]);
    disp(['- Perc agreement sens (true pos): ', num2str(round(sens))]);
    disp(['- Perc agreement sens (true pos), swapped mat: ', num2str(round(swapSens))]);
    disp(['- Perc agreement spec (true neg): ', num2str(round(spec))]);
    disp(['- Perc agreement spec (true neg): swap matrices: ', num2str(round(swapSpec))]);
    disp(['- Cohens kappa: ', num2str(round(retKappa.k, 2)), '      (', num2str(retKappa.k), ')']);
    disp(['- Krippendorff (kriAlpha function) alpha:   ', num2str(round(retKrip, 2)), '      (', num2str(retKappa.k), ')']);
    
    % store
    interRater_results(end + 1, :) = [score, retKappa.k, spec, sens, retKrip];
    
    
    %{
    %%
    %  Krippendorff alpha

    k_alpha = kriAlpha(annot_l', 'nominal');
    %disp(['- Krippendorff (matlab-central) alpha: ', num2str(k_alpha)]);

    % from paper: Computing Krippendorff's Alpha-Reliability
    data = annot_l_nonans';
    n = numel(data);
    o = [sum(data(1, :) == 0 & data(2, :) == 0) + sum(data(1, :) == 0 & data(2, :) == 0), sum(data(1, :) == 0 & data(2, :) == 1) + sum(data(1, :) == 1 & data(2, :) == 0); ...
         sum(data(1, :) == 1 & data(2, :) == 0) + sum(data(1, :) == 0 & data(2, :) == 1), sum(data(1, :) == 1 & data(2, :) == 1) + sum(data(1, :) == 1 & data(2, :) == 1)];
    n01 = sum(o, 1);
    a = 1 - (n - 1) * o(1,2) / (n01(1) * n01(2));
    disp(['- Krippendorff (paper) alpha:               ', num2str(round(a, 2)), '      (', num2str(retKappa.k), ')']);
    %}

    %%
    %  Cronbach's alpha
    
    % TODO: check value on exactly matching matrices?


    % calculate the number of items
    k = size(annot_l_nonans, 1);

    % calculate the variance of the items' sum
    varTotal = var(sum(annot_l_nonans'));

    % calculate the item variance
    sumVarAnnot = sum(var(annot_l_nonans));

    % calculate the Cronbach's alpha
    c_alpha = k / (k - 1) * (varTotal - sumVarAnnot) / varTotal;
    disp(['- Cronbach alpha: ', num2str(c_alpha)]);
    
    clear annot_l annot1 annot2 annot_l_nonans annot_app
    clear mis_annot1 mis_annot2 mis_channelNames mis_stimpairNames chan_mismatch stimpair_mismatch
    clear k varTotal sumVarAnnot c_alpha
    clear score spec sens retKappa agreeMats retKrip swapSpec swapSens
end
clear iSet
clear bids_channelsPath bids_electrodesPath bids_eventsPath bids_appDetect_annotPath

% calculate totals and averages 
interRater_results_averages = mean(interRater_results, 1);          %[score, retKappa.k, spec, sens, retKrip]
interRater_annotDescr_averages = mean(interRater_annotDescr, 1);    %[total, ER, NonER, ER_perc, NonER_perc]
interRater_annotDescr_totals   = sum(interRater_annotDescr, 1);     %[total, ER, NonER, ER_perc, NonER_perc]

clear bids_projectPath
return


%%
%
save('D:\BIDS_erdetect\derivatives\compares\compare_annot_interRater.mat');