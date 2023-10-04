%
% function that compares two ER matrices and returns several metrics
%

function [acc, spec, sens, prec, retKappa, agreeMats, retKrip, swapSpec, swapSens, swapPrec] = ccep_compareN1Matrices(mat1, mat2)
    agreeY = double(mat1==1 & mat2==1);     % true positives
    agreeN = double(mat1==0 & mat2==0);     % true negatives
    agree = double(agreeY | agreeN);
    Y1N2 = double(mat1==1 & mat2==0);       % false negatives (considering mat1 as truth)
    Y2N1 = double(mat1==0 & mat2==1);       % false positives (considering mat1 as truth)

    % nan the values in both of the matrices if a value is missing in either
    stimmat = (isnan(mat1) | isnan(mat2));
    agreeY(stimmat) = nan;
    agreeN(stimmat) = nan;
    agree(stimmat) = nan;
    Y1N2(stimmat) = nan;
    Y2N1(stimmat) = nan;
    
    % transfer to return variable
    agreeMats.agree = agree;
    agreeMats.agreeY = agreeY;              % true positives
    agreeMats.agreeN = agreeN;              % true negatives
    agreeMats.Y1N2 = Y1N2;                  % false negatives (considering mat1 as truth)
    agreeMats.Y2N1 = Y2N1;                  % false positives (considering mat1 as truth)
    
    % 
    acc = nansum(agree(:)) / sum(~isnan(agree(:))) * 100;                       % accuracy    = (TP + TN) / total
    sens = nansum(agreeY(:)) / (nansum(agreeY(:)) + nansum(Y1N2(:))) * 100;     % sensitivity = TP / (TP + FN)
    spec = nansum(agreeN(:)) / (nansum(agreeN(:)) + nansum(Y2N1(:))) * 100;     % specificity = TN / (TN + FP)
    prec = nansum(agreeY(:)) / (nansum(agreeY(:)) + nansum(Y2N1(:))) * 100;     % precision   = TP / (TP + FP)
    
    % check if the reverse are requested
    if nargout > 7
        [~, swapSpec, swapSens, swapPrec, ~, ~, ~] = ccep_compareN1Matrices(mat2, mat1);
    end
    
    % prepare to calculate kappa
    TagreeY = nansum(agreeY(:));
    TagreeN = nansum(agreeN(:));
    TY1N2 = nansum(Y1N2(:));
    TY2N1 = nansum(Y2N1(:));

    x(1,1) = TagreeY;
    x(1,2) = TY1N2;
    x(2,1) = TY2N1;
    x(2,2) = TagreeN;

    % compute kappa
    confLevel= 0.95;
    retKappa = kappa(x, 0, 1 - confLevel, 0);
    
    % compute Krippendorff alpha
    mat1(stimmat) = nan;
    mat2(stimmat) = nan;
    retKrip = kriAlpha([mat1(:), mat2(:)]', 'nominal');
    
end
