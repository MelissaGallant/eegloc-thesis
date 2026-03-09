function cfg = shift_electrodes_inwards(cfg)
% SHIFT_ELECTRODES_INWARDS - Moves detected 3D electrode positions inward along the scalp surface normals.
% Inputs:
%   cfg - Configuration struct for electrode localization and labeling.
%
% Outputs:
%   cfg - Updated configuration struct.

    import eegloc.algorithms.*

    % Validate input fields
    if ~isfield(cfg, 'detectedElectrodePos3D') || isempty(cfg.detectedElectrodePos3D)
        error('cfg.detectedElectrodePos3D is missing or empty.');
    end
    if ~isfield(cfg, 'moveinwards')
        error('cfg.moveinwards is missing.');
    end
    if ~isfield(cfg, 'headshape') || ~isfield(cfg.headshape, 'cfg') || ...
       ~isfield(cfg.headshape, 'pos') || ~isfield(cfg.headshape, 'tri')
        error('cfg.headshape.pos and cfg.headshape.tri are required.');
    end

    % Compute normals at electrode locations
    elecNormals = electrode_normals(cfg.headshape, cfg.detectedElectrodePos3D);

    % Shift electrodes inward
    cfg.pushedInDetectedElectrodePos3D = cfg.detectedElectrodePos3D - cfg.moveinwards * elecNormals;
end
