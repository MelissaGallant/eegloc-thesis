function cfg = coregister_template(cfg)
% COREGISTER_TEMPLATE - Aligns the template electrode positions to the detected
%                       electrode positions using anchor points and a rigid
%                       transformation via the Kabsch-Umeyama algorithm.
%
% Inputs:
%   cfg - Configuration struct for electrode localization and labeling.
%
% Outputs:
%   cfg - Updated configuration struct.
%
% The function also visualizes the 3D coregistration using plot_cap_registration.

    import eegloc.algorithms.*
    import eegloc.plotting.*
    import eegloc.ui.*

    % Define anchor points for alignment
    cfg.detectedElectrodeAnchorPointsUV = label_electrodes(cfg.flattenedImage, cfg.detectionsUV, cfg.anchorLabels);
    cfg.detectedElectrodeAnchorPoints3D = project_electrodes_uv_to_3d(cfg.headshape, cfg.uv, cfg.detectedElectrodeAnchorPointsUV);

    % Extract template electrode postions
    [cfg.templateElectrodePos3D, cfg.templateElectrodeLabels] = extract_labeled_electrodes(cfg.chanlocs, cfg.chanlocsExcludedLabels);

    % Find anchor points in the template electrode positions
    [~, idx] = ismember(string(cfg.anchorLabels), cfg.templateElectrodeLabels);
    templateElectrodeAnchorPoints3D = cfg.templateElectrodePos3D(idx, :);

    % Align electrodes figure to headshape
    [cfg.coregisteredTemplateElectrodePos3D, cfg.alignmentTransformation] = kabsch_umeyama(templateElectrodeAnchorPoints3D, cfg.detectedElectrodeAnchorPoints3D, cfg.templateElectrodePos3D);

    plot_cap_registration(cfg.coregisteredTemplateElectrodePos3D, cfg.detectedElectrodePos3D, {'Registered Template Electrodes', 'Detected Electrodes'}, cfg.uvProjectionMethod);

end
