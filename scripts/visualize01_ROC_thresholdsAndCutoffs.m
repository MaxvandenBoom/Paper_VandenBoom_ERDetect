%
%   Visualize the results of comparing manual annotation against automatic
%   detection using different thresholds (factor of std dev base) and cutoffs (metrics)
%

load('D:\BIDS_erdetect\derivatives\compares\compare_manualVSappTest_thresholdsAndCutoffs.mat'); % output of script prep02_
load('D:\BIDS_erdetect\derivatives\compares\compare_annot_interRater.mat');                     % output of script prep01_
load('D:\BIDS_erdetect\derivatives\compares\compare_manualVSapp_output.mat');                   % output of script prep03_


%%
%  Average ROC curve per metric (y=sensitivity vs x=100-specificity)
    
% loop through the required metrics
stdSensMetrics = {};
for iMeth = 1:3

    % 
    strMetric = '';
    metricColor = [0 0 0];
    strMetricDisplay = '';
    switch iMeth
        case 1, strMetric = 'stdB';  strMetricDisplay = 'Std. dev.'; ...
                strTestType = 'threshold'; metricColor = [1 0 0];
        case 2, strMetric = 'w15';  strMetricDisplay = '10-30Hz'; ...
                strTestType = 'cutoff'; metricColor = [0    0.4471    0.7412];
        case 3, strMetric = 'cpt';  strMetricDisplay = 'Cross proj. t'; ...
                strTestType = 'cutoff'; metricColor = [0.9294    0.6941    0.1255];
    end

    % open a plot
    f = figure('Position', [0, 0, 1400, 900]);
    hold on;
    
    

    
    %
    % Plot subject lines
    %
    mAllSensValues = [];
    for iSubj = 1:length(allSubjects_threshAndMetr)

        % 

        mValues = allSubjects_threshAndMetr{iSubj}.(['mutual_', strMetric, '_comp']);
        mCutOffs = allSubjects_threshAndMetr{iSubj}.([strMetric, '_', strTestType, 's']);
        mCutOffYouden = allSubjects_threshAndMetr{iSubj}.([strMetric, '_', strTestType, '_YoudenJ']);
        mCutOffDVal = allSubjects_threshAndMetr{iSubj}.([strMetric, '_', strTestType, '_DVal']);

        % order first by sensitivity (first column) and then by specificity (second column)
        %[mROCValues, reIndex] = sortrows(flip(mValues(3:4, :), 1)', 'ascend');
        %[mROCValues, reIndex] = sortrows(flip(mValues(3:4, :), 1)', [2 1]);
        % (reorder the cutoffs accordingly)
        %mROCCutOffs = mCutOffs(reIndex);

        % plot the ROC points
        plot(100 - mValues(3, :), mValues(4, :), '-', 'LineWidth', 1.5, 'DisplayName', strMetricDisplay, 'Color', metricColor);

        %a = [100 - mValues(3, :)', mValues(4, :)'];
        %b = unique(a, 'rows', 'stable');
        %plot(b(:, 1), b(:, 2), '-', 'LineWidth', 1.5, 'DisplayName', strMetricDisplay, 'Color', metricColor);
        mAllSensValues(end + 1, :) = mValues(4, :);

        %
        % Mark optimum cutoffs
        %

        %
        %a = interp1(100 - mValues(3, :), mValues(4, :), linspace(0, 1, 100));
        %tprs(iSubj, :) = a;
        %%tprs.append(interp(, fpr, tpr))


        % find the optimal index
        [~, opt_cutoff_idx] = max(mCutOffYouden);
        %[~, opt_cutoff_idx] = min(mCutOffDVal);

        strMetricOptimumDisplay = [strMetricDisplay, ' (Youden Idx _m_a_x)'];

        % plot the optimum
        plot(100 - mValues(3, opt_cutoff_idx), mValues(4, opt_cutoff_idx), '^', 'LineWidth', 1.5, 'DisplayName', strMetricOptimumDisplay, 'Color', metricColor, 'MarkerSize', 9, 'MarkerFaceColor', metricColor);            
        text(100 - mValues(3, opt_cutoff_idx), mValues(4, opt_cutoff_idx), num2str(mCutOffs(opt_cutoff_idx)));

        
        
        %
        %
        %
        title(strMetricDisplay);

    end

    
    %
    % Plot averages
    %
    
    % averages (pre-calculated)
    mValues = allSubjects_threshAndMetr_averages.(['mutual_', strMetric, '_comp']);
    mCutOffs = allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, 's']);
    mCutOffYouden = allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_YoudenJ']);
    mCutOffDVal = allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_DVal']);
    
    % order first by sensitivity (first column) and then by specificity (second column)
    %[mROCValues, reIndex] = sortrows(flip(mValues(3:4, :), 1)', 'ascend');
    %[mROCValues, reIndex] = sortrows(flip(mValues(3:4, :), 1)', [2 1]);
    % (reorder the cutoffs accordingly)
    %mROCCutOffs = mCutOffs(reIndex);

    % calculate std, and a upper and lower of 2 * std
    sensStd = std(mAllSensValues, 1);
    stdSensMetrics{iMeth} = sensStd;
    
    %tprs_upper = min(mValues(4, :) + sensStd, 100);
    %tprs_lower = max(mValues(4, :) - sensStd, 0);
    %x2 = [100 - mValues(3, :), fliplr(100 - mValues(3, :))];
    %inBetween = [tprs_upper, fliplr(tprs_lower)];
    %fill(x2, inBetween, 'g');
    %plot(100 - mValues(3, :), tprs_upper, '-', 'LineWidth', .5, 'DisplayName', strMetricDisplay, 'Color', [1 0 0]);
    %plot(100 - mValues(3, :), tprs_lower, '-', 'LineWidth', .5, 'DisplayName', strMetricDisplay, 'Color', [1 0 0]);
    
    % plot the ROC points
    plot(100 - mValues(3, :), mValues(4, :), '-', 'LineWidth', 1.5, 'DisplayName', strMetricDisplay, 'Color', [0 0 0]);

    
    % Mark optimum cutoffs
    if iMeth == 1 || iMeth == 2

        % find the optimal index
        [~, opt_cutoff_idx] = max(mCutOffYouden);
        %[~, opt_cutoff_idx] = min(mCutOffDVal);

        strMetricOptimumDisplay = [strMetricDisplay, ' (Youden Idx _m_a_x)'];
        
        % plot the optimum
        plot(100 - mValues(3, opt_cutoff_idx), mValues(4, opt_cutoff_idx), '^', 'LineWidth', 1.5, 'DisplayName', strMetricOptimumDisplay, 'Color', [0 0 0], 'MarkerSize', 11, 'MarkerFaceColor', [0 0 0]);
        text(100 - mValues(3, opt_cutoff_idx) + 2, mValues(4, opt_cutoff_idx) + 1, num2str(mCutOffs(opt_cutoff_idx)), 'FontSize', 14);
        
    end


    % plot diagonal
    line([0 100], [0 100], 'Color', [.2 .2 .2], 'LineStyle','--', 'LineWidth', 1.0);

    % stop drawing
    hold off;

    xlabel('100 - specificity (false positive rate)')
    ylabel('sensitivity (true positive rate)')
    set(gca,'Xtick', 0:50:100);
    set(gca,'Ytick', 0:50:100);
    %xlim([0 100]);
    %ylim([0 100]);

    pbaspect([1 1 1]);
    set(gcf,'color', 'w');
    
    %{
    set(gcf, 'renderer', 'painters');
    saveas(gcf, ['D:\erdetect_output\fig_ROC_M', num2str(iMetric), '.eps'], 'epsc');
    %}
    
end




%%
%  Average ROC curve (y=sensitivity vs x=100-specificity) for each metric


% open a plot
f = figure('Position', [0, 0, 1400, 900]);
hold on;

% loop through the detection metrics
for iMeth = 1:4

    % 
    strMetric = '';
    metricColor = [0 0 0];
    strMetricDisplay = '';
    switch iMeth
        case 1, strMetric = 'stdB';  strMetricDisplay = 'Std. Dev.'; ...
                strTestType = 'threshold'; metricColor = [0.4667, 0.6745, 0.1882];
        case 2, strMetric = 'w15';  strMetricDisplay = 'Waveform'; ...
                strTestType = 'cutoff'; metricColor = [0    0.4471    0.7412];
        case 3, strMetric = 'cpt';  strMetricDisplay = 'Cross projection'; ...
                strTestType = 'cutoff'; metricColor = [0.9294    0.6941    0.1255];
        case 4, strMetric = 'cp';   strMetricDisplay = 'Cross projection (p_b_o_n_f < .05)'; ...
                metricColor = [0.9294    0.6941    0.1255];
    end

    %
    if iMeth == 4
        % 
        
        mValues = allSubjects_threshAndMetr_averages.(['mutual_', strMetric, '_comp']);
        plot(100 - mValues(3), mValues(4), 'diamond', 'LineWidth', 1.5, 'DisplayName', strMetricDisplay, 'Color', metricColor, 'MarkerSize', 9, 'MarkerFaceColor', metricColor);

    else
        % 
        
        mValues = allSubjects_threshAndMetr_averages.(['mutual_', strMetric, '_comp']);
        mCutOffs = allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, 's']);
        mCutOffYouden = allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_YoudenJ']);
        mCutOffDVal = allSubjects_threshAndMetr_averages.([strMetric, '_', strTestType, '_DVal']);
        
        % order first by sensitivity (first column) and then by specificity (second column)
        %[mROCValues, reIndex] = sortrows(flip(mValues(3:4, :), 1)', 'ascend');
        [mROCValues, reIndex] = sortrows(flip(mValues(3:4, :), 1)', [2 1]);
        % (reorder the cutoffs accordingly)
        mROCCutOffs = mCutOffs(reIndex);
        
        if iMeth == 2 || iMeth == 3
            % plot std. dev as area
            sensStd = stdSensMetrics{iMeth};
            tprs_upper = min(mValues(4, :) + sensStd, 100);
            tprs_lower = max(mValues(4, :) - sensStd, 0);
            x2 = [100 - mValues(3, :), fliplr(100 - mValues(3, :))];
            inBetween = [tprs_upper, fliplr(tprs_lower)];
            a = fill(x2, inBetween, metricColor, 'LineStyle', 'none');
            a.FaceAlpha = 0.1;
            %plot(100 - mValues(3, :), tprs_upper, '-', 'LineWidth', .5, 'DisplayName', strMetricDisplay, 'Color', [1 0 0]);
            %plot(100 - mValues(3, :), tprs_lower, '-', 'LineWidth', .5, 'DisplayName', strMetricDisplay, 'Color', [1 0 0]);
        end
        
        %
        mValues(3, 1) = 0;
        mValues(3, end) = 100;
        mValues(4, 1) = 100;
        mValues(4, end) = 0;
        
        % plot the ROC points
        plot(100 - mValues(3, :), mValues(4, :), '-', 'LineWidth', 1.5, 'DisplayName', strMetricDisplay, 'Color', metricColor);

        
        %
        % Mark optimum cutoffs
        %

        % find the optimal index
        [~, opt_cutoff_idx] = max(mCutOffYouden);
        %[~, opt_cutoff_idx] = min(mCutOffDVal);

        % print 
        disp([strMetricDisplay, ' optimum = ', num2str(mCutOffs(opt_cutoff_idx))]);

        strMetricOptimumDisplay = [strMetricDisplay, ' - Youden optimum'];
        if iMeth == 4
            metricColor = [0.9294    0.5941    0.2755];
        end

        % plot the optimum
        plot(100 - mValues(3, opt_cutoff_idx), mValues(4, opt_cutoff_idx), 'square', 'LineWidth', 1.5, 'DisplayName', strMetricOptimumDisplay, 'Color', metricColor, 'MarkerSize', 12, 'MarkerFaceColor', metricColor);

    end

end


% draw the sens & spec of the current appp output results (baseline 3.4)
plot(100 - allSubjects_results_average(3), allSubjects_results_average(4), 'o', ...
     'LineWidth', 1.5, 'DisplayName', 'Current default (base 3.4)', 'Color', [0 .6 0], 'MarkerSize', 10, 'MarkerFaceColor', [0 .6 0]);

% draw the average sens & spec of the inter-rater
plot(100 - interRater_results_averages(3), interRater_results_averages(4), 'o', ...
     'LineWidth', 1.5, 'DisplayName', 'Inter-rater average', 'Color', [0.6353, 0.0784, 0.1843], 'MarkerSize', 10, 'MarkerFaceColor', [0.6353, 0.0784, 0.1843]);


% plot diagonal
line([0 100], [0 100], 'Color', [.2 .2 .2], 'LineStyle','--', 'LineWidth', 1.0);

% stop drawing
hold off;


ax = gca;
ax.FontSize = 16; 


xlabel('100 - specificity (false positive rate)', 'FontSize', 24)
ylabel('sensitivity (true positive rate)', 'FontSize', 24)
set(gca,'Xtick', 0:25:100);
set(gca,'Ytick', 0:25:100);
%xlim([0 100]);
%ylim([0 100]);

pbaspect([1 1 1]);
legend('Location', 'southeast');
set(gcf,'color', 'w');

%{
set(gcf, 'renderer', 'painters');
saveas(gcf, 'D:\erdetect_output\fig_ROCS.eps', 'epsc');
%}

