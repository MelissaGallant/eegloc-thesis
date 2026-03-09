function cfg = detect_labels(cfg)
% DETECT_LABELS - Assigns labels to detected electrodes and provides an interactive UI
%                 for manual correction and review.
%
% This function automatically assigns labels to detected 3D electrode positions
% by matching them to an aligned default electrode template. It then launches
% an interactive interface for visual review and optional relabeling.
%
% Inputs:
%   cfg - Configuration struct for electrode localization and labeling.
%
% Outputs:
%   cfg - Updated configuration struct.

    import eegloc.algorithms.*
    import eegloc.plotting.*
    import eegloc.ui.*

    if strcmp(cfg.labelDetectionMethod, 'munkres')
        use_munkres = true;
    else
        use_munkres = false;
    end

    % Perform automatic labeling
    if use_munkres
        cfg.originalDetectedElectrodeLabels = assign_labels_hungarian(cfg.coregisteredTemplateElectrodePos3D, cfg.templateElectrodeLabels, cfg.detectedElectrodePos3D);
    else
        cfg.originalDetectedElectrodeLabels = assign_labels_voronoi(cfg.coregisteredTemplateElectrodePos3D, cfg.templateElectrodeLabels, cfg.detectedElectrodePos3D);
    end
    cfg.detectedElectrodeLabels = cfg.originalDetectedElectrodeLabels;
   
    % Display interactive UI
    while true
        [cfg.detectedElectrodeLabels, reviewLabels] = relabel_electrodes(cfg.flattenedImage, cfg.detectionsUV, cfg.detectedElectrodeLabels, cfg.templateElectrodeLabels);
        if reviewLabels
            plot_headshape_with_electrodes(cfg.headshape, cfg.detectedElectrodePos3D, cfg.detectedElectrodeLabels);
        else
            break; % if review option is false do not reopen UI
        end
    end
end
