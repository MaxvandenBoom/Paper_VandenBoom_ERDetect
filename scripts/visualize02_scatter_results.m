%
%   Visualize the results of comparing manual annotation against automatic detection
%   as scatterplots using a specific theshold (std dev base methods) and cutoffs (metrics)
%

load('D:\BIDS_erdetect\derivatives\compares\compare_manualVSappTest_thresholdsAndCutoffs.mat'); % output of script prep02_
load('D:\BIDS_erdetect\derivatives\compares\compare_annot_interRater.mat');                     % output of script prep01_


%%
%  Pick the acc/sens/spec/kappa based on specific thresholds (set below)
%

plot_stdB_threshold = 3.4;
%plot_stdB_threshold = 1.7;
plot_w15_cutoff = 1100;
plot_cpt_cutoff = 4;

plot_stdB_index = find(stdB_thresholds == plot_stdB_threshold);
plot_w15_index = find(w15_cutoffs == plot_w15_cutoff);
plot_cpt_index = find(cpt_cutoffs == plot_cpt_cutoff);

% [base std, 10-30Hz, cross prof] x <subjects>
allAcc = nan(3, length(allSubjects_threshAndMetr));
allSens = nan(3, length(allSubjects_threshAndMetr));
allSpec = nan(3, length(allSubjects_threshAndMetr));
allKappa = nan(3, length(allSubjects_threshAndMetr));


for iSet = 1:length(allSubjects_threshAndMetr)
    for iMeth = 1:3
        if iMeth == 1, strMetric = 'stdB'; optimal_index = plot_stdB_index;  end
        if iMeth == 2, strMetric = 'w15';  optimal_index = plot_w15_index;   end
        if iMeth == 3, strMetric = 'cpt';  optimal_index = plot_cpt_index;   end

        % retrieve the values for that specific threshold/cutoff
        mValues = allSubjects_threshAndMetr{iSet}.(['mutual_', strMetric, '_comp']);
        mValues = mValues([1, 4, 3, 2], optimal_index);
        
        % fill the 
        allAcc(iMeth, iSet) = mValues(1);
        allSens(iMeth, iSet) = mValues(2);
        allSpec(iMeth, iSet) = mValues(3);
        allKappa(iMeth, iSet) = mValues(4);
        
    end
end

return


%%
%   Pick the acc/sens/spec/kappa based on the highest youden per subject per method
%

%{

% [base std, 10-30Hz, cross prof] x <subjects>
allAcc = nan(3, length(allSubjects_threshAndMetr));
allSens = nan(3, length(allSubjects_threshAndMetr));
allSpec = nan(3, length(allSubjects_threshAndMetr));
allKappa = nan(3, length(allSubjects_threshAndMetr));

% loop over the sets and methods
for iSet = 1:length(allSubjects_threshAndMetr)
    for iMeth = 1:3
        
        if iMeth == 1, strMetric = 'stdB'; strTestType = 'threshold';   end
        if iMeth == 2, strMetric = 'w15'; strTestType = 'cutoff';   end
        if iMeth == 3, strMetric = 'cpt'; strTestType = 'cutoff';   end

        %
        mCutOffYouden = allSubjects_threshAndMetr{iSet}.([strMetric, '_', strTestType, '_YoudenJ']);
        mCutOffDVal = allSubjects_threshAndMetr{iSet}.([strMetric, '_', strTestType, '_DVal']);

        % find the optimal threshold/cutoff for this subject annotation/method
        [~, optimal_index] = max(mCutOffYouden);

        % retrieve the values for that specific threshold/cutoff
        mValues = allSubjects_threshAndMetr{iSet}.(['mutual_', strMetric, '_comp']);
        mValues = mValues([1, 4, 3, 2], optimal_index);
        
        % fill the 
        allAcc(iMeth, iSet) = mValues(1);
        allSens(iMeth, iSet) = mValues(2);
        allSpec(iMeth, iSet) = mValues(3);
        allKappa(iMeth, iSet) = mValues(4);
        
    end
end

return
%}



%%
% Scatterplot of the accuracies

figure
title('Accuracies');
hold on;
subj_labels = categorical(bids_sets(:,1));
subj_labels = reordercats(subj_labels, bids_sets(:, 1));
for iMeth = 0:3
    
    switch iMeth
        case 0, strMetricDisplay = 'Inter-rater'; ...
                strTestType = ''; metricColor = [0.6353, 0.0784, 0.1843];
        case 1, strMetric = 'stdB';  strMetricDisplay = 'Dev. from baseline'; ...
                strTestType = 'threshold'; metricColor = [0.4667, 0.6745, 0.1882];
        case 2, strMetric = 'w15';  strMetricDisplay = 'Wavelet'; ...
                strTestType = 'cutoff'; metricColor = [0    0.4471    0.7412];
        case 3, strMetric = 'cpt';  strMetricDisplay = 'Inter-trial similarity'; ...
                strTestType = 'cutoff'; metricColor = [0.9294    0.6941    0.1255];
    end
    
    if iMeth == 0
        
        values = interRater_results(:, 1);  % acc
        %values = interRater_results(:, 4);  % sens
        %values = interRater_results(:, 3);  % spec
        plot(ones(1, numel(values)) * iMeth + 1, values, 'x', 'DisplayName', strMetricDisplay, 'LineWidth', 2, 'Color', metricColor);
    else
    
        values = allAcc(iMeth, :);
        %values = allSens(iMeth, :);
        %values = allSpec(iMeth, :);
        plot(ones(1, numel(values)) * iMeth + 1, values, 'x', 'DisplayName', strMetricDisplay, 'LineWidth', 2, 'Color', metricColor);
    end
    
    % plot average
    plot(iMeth + 1, mean(values), 'o', 'Color', [0 0 0], 'LineWidth', 2);
    
    disp([strMetricDisplay, ': ', num2str(mean(values))]);
end
hold off;

ylim([0 100]);
xlim([.5 4.5]);
legend
set(gcf,'color', 'w');




%%
%  Scatterplot of the Kappa's with inter-rater

figure
title('Cohen''s Kappa');
hold on;
subj_labels = categorical(bids_sets(:, 1));
subj_labels = reordercats(subj_labels, bids_sets(:, 1));

for iMeth = 0:3

    switch iMeth
        case 0, strMetricDisplay = 'Inter-rater'; ...
                strTestType = ''; metricColor = [0.6353, 0.0784, 0.1843];
        case 1, strMetric = 'stdB';  strMetricDisplay = 'Dev. from baseline'; ...
                strTestType = 'threshold'; metricColor = [0.4667, 0.6745, 0.1882];
        case 2, strMetric = 'w15';  strMetricDisplay = 'Wavelet'; ...
                strTestType = 'cutoff'; metricColor = [0    0.4471    0.7412];
        case 3, strMetric = 'cpt';  strMetricDisplay = 'Inter-trial similarity'; ...
                strTestType = 'cutoff'; metricColor = [0.9294    0.6941    0.1255];
    end
    
    
    if iMeth == 0
        values = interRater_results(:, 2);
        %plot(ones(1, numel(values)) * iMeth + 1, values, 'x', 'DisplayName', strMetricDisplay, 'LineWidth', 2);
        plot(ones(1, numel(values)) * iMeth + 1, values, 'x', 'DisplayName', strMetricDisplay, 'LineWidth', 2, 'Color', metricColor);
    else
        values = allKappa(iMeth, :);
        %plot(ones(1, numel(values)) * iMeth + 1, values, 'x', 'DisplayName', strMetricDisplay, 'LineWidth', 2);
        plot(ones(1, numel(values)) * iMeth + 1, values, 'x', 'DisplayName', strMetricDisplay, 'LineWidth', 2, 'Color', metricColor);
    end
    
    
    plot(iMeth + 1, mean(values), 'o', 'Color', [0 0 0], 'MarkerFaceColor', [0 0 0], 'MarkerSize', 10, 'LineWidth', 1);
    disp([strMetricDisplay, ' kappa: ', num2str(mean(values))]);
end
yline(.20, 'k--', '.21 - .4 = Fair', 'FontSize', 14);
yline(.40, 'k--', '.41 - .6 = moderate', 'FontSize', 14)
yline(.60, 'k--', '.61 - .8 = good', 'FontSize', 14);
yline(.80, 'k--', '.> .8 = very good', 'FontSize', 14);

hold off
ylim([0 1]);
set(gcf,'color', 'w');
xticks([1, 2, 3, 4]);
set(gca,'XTickLabel', {'Inter-rater', 'Dev. from baseline', 'Wavelet', 'Inter-trial similarity'}, 'fontsize', 16)
xtickangle(45)

yticks([0, .2, .4 .6 .8 1]);
ylim([0 1]);
xlim([.5 6]);
set(gcf,'color', 'w');

%{
set(gcf, 'renderer', 'painters');
saveas(gcf, 'D:\erdetect_output\fig_scatter.eps', 'epsc');
%}
