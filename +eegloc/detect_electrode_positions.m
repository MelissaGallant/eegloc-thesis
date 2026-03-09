function cfg = detect_electrode_positions(cfg)
% DETECT_ELECTRODE_POSITIONS - Detects electrode positions from a flattened head image
%                              and provides an interactive UI for manual refinement.
%
% This function performs automatic detection of electrode positions from a segmented
% projection of the head surface. It also provides an interactive interface for
% manual correction and review of the detected electrode locations.
%
% Inputs:
%   cfg - Configuration struct for electrode localization.
%
% Outputs:
%   cfg - Updated configuration struct with additional fields.

    import eegloc.algorithms.*
    import eegloc.ui.*
    import eegloc.plotting.*
    
    % Estimate angle needed to rotate headshape to center around Cz
    [cz, ang] = eegloc.algorithms.estimate_cz(cfg.headshape);

    % Obtain a 2D flattened headshape from a 3D model
    [cfg.uv, cfg.flattenedImage] = flatten_headshape(cfg.headshape, false, -ang, cz, cfg.uvProjectionMethod);

    % Identify the cap segment
    cfg.detectedCapColor = detect_cap_color(cfg.flattenedImage); % !for bookkeeping only!
    if strcmp(cfg.capSegmentationMethod, 'highVariance')
        cfg.imgCap = segment_cap(cfg.flattenedImage, false, true);
    else
        cfg.imgCap = segment_cap(cfg.flattenedImage, false, false);
    end

    % Perform electrode detection
    cfg.originalDetectionsUV = detect_electrodes(cfg.imgCap);
    cfg.originalDetectedElectrodePos3D = project_electrodes_uv_to_3d(cfg.headshape, cfg.uv, cfg.originalDetectionsUV);
    cfg.detectionsUV = cfg.originalDetectionsUV;

    % Display interactive UI
    while true
        [cfg.detectionsUV, reviewElectrodes] = update_electrode_placement(cfg.flattenedImage, cfg.detectionsUV);
        cfg.detectedElectrodePos3D = project_electrodes_uv_to_3d(cfg.headshape, cfg.uv, cfg.detectionsUV);
        if reviewElectrodes
            plot_headshape_with_electrodes(cfg.headshape, cfg.detectedElectrodePos3D);
        else
            break; % if review option is false do not reopen UI
        end
    end
end
