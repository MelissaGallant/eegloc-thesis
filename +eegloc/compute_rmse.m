function rmse = compute_rmse(cfg)
% COMPUTE_RMSE - Computes the RMSE between the default and detected electrode positions
%
% Inputs:
%   cfg - Configuration struct for electrode localization and labeling.
%
% Outputs:
%   rmse - Struct with fields:
%          - alignDefaultToDetected : RMSE of default aligned to detected
%          - alignDetectedToDefault : RMSE of detected aligned to default

    defaultLabels  = string(cfg.templateElectrodeLabels);
    detectedLabels = string(cfg.detectedElectrodeLabels);

    % Match labels
    idxDetectedToDefault = match_label_indices(defaultLabels, detectedLabels);

    detectedMatched = cfg.detectedElectrodePos3D(idxDetectedToDefault, :);
    correctedMatched = cfg.correctedElectrodePos3D(idxDetectedToDefault, :);

    rmse.alignDefaultToDetected = compute_rmse_pairwise(cfg.alignedDefaultElectrodePos3D, detectedMatched);
    rmse.alignDetectedToDefault = compute_rmse_pairwise(cfg.defaultElectrodePos3D, correctedMatched);

    if ~nargout
        fprintf('RMSE of default aligned to detected: %.2f\n', rmse.alignDefaultToDetected);
        fprintf('RMSE of detected aligned to default: %.2f\n', rmse.alignDetectedToDefault);
    end
end

function idxInTarget = match_label_indices(sourceLabels, targetLabels)
    [found, idxInTarget] = ismember(sourceLabels, targetLabels);
    if any(~found)
        missing = sourceLabels(~found);
        error("Missing label(s) in detectedElectrodeLabels: %s", strjoin(missing, ", "));
    end
end

function rmse = compute_rmse_pairwise(A, B)
    rmse = sqrt(mean(sum((A - B).^2, 2)));
end
