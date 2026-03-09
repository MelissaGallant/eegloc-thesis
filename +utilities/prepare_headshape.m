function headshape = prepare_headshape(modelPath, outMatPath)
% PREPARE_HEADSHAPE - Prepare a FieldTrip headshape in the CTF coordinate system from a 3D model.
%
% Usage:
%   headshape = prepare_headshape(modelPath)
%   headshape = prepare_headshape(modelPath, outMatPath)
%
% Inputs:
%   modelPath  : path to the head model mesh (e.g., .obj, .ply, .stl)
%   outMatPath : optional output .mat path (default: fullfile('headshape.mat'))
%
% Outputs:
%   headshape         : FieldTrip mesh struct, realigned to CTF coordsys (mm)
%
% Notes:
% - Requires FieldTrip on the MATLAB path.
% - Saves variable 'headshape' into outMatPath.

    if nargin < 1 || isempty(modelPath)
        error('modelPath is required.');
    end
    if exist(modelPath, 'file') ~= 2
        error('Model file not found: %s', modelPath);
    end
    if nargin < 2 || isempty(outMatPath)
        outMatPath = fullfile('headshape.mat');
    end

    % Ensure output directory exists (if specified)
    outDir = fileparts(outMatPath);
    if ~isempty(outDir) && exist(outDir, 'dir') ~= 7
        mkdir(outDir);
    end

    % FieldTrip is required for preparing the headshape
    try
        ft_defaults;
    catch ME
        error('Failed to run ft_defaults. Make sure FieldTrip is on the MATLAB path. (%s)', ME.message);
    end

    % Load headshape
    headshape = ft_read_headshape(modelPath);
    headshape = ft_convert_units(headshape, 'mm');

    % Select fiducials (UI)
    fiducials = eegloc.ui.select_fiducials(headshape);

    % Realign to CTF coordinate system using fiducials
    cfg = [];
    cfg.method = 'fiducial';
    cfg.coordsys = 'ctf';

    % Expecting fields: nas, lhj, rhj
    if ~isfield(fiducials, 'nas') || ~isfield(fiducials, 'lhj') || ~isfield(fiducials, 'rhj')
        error('Fiducials struct must contain fields: nas, lhj, rhj.');
    end

    cfg.fiducial.nas = fiducials.nas;
    cfg.fiducial.lpa = fiducials.lhj;
    cfg.fiducial.rpa = fiducials.rhj;

    headshape = ft_meshrealign(cfg, headshape);

    % Compute rotated fiducials for visualization
    rotatedFiducials = [];
    if isfield(headshape, 'cfg') && isfield(headshape.cfg, 'transform') && ~isempty(headshape.cfg.transform)
        T = headshape.cfg.transform;

        pts = [fiducials.nas; fiducials.lhj; fiducials.rhj];
        rotatedFiducials = [pts, ones(3, 1)] * T';
        rotatedFiducials(:, end) = [];
    end

    % Plot headshape in CTF coordinate system
    try
        figure;
        hold on;
        ft_plot_headshape(headshape, 'axes', true);
        if ~isempty(rotatedFiducials)
            plot3(rotatedFiducials(:, 1), rotatedFiducials(:, 2), rotatedFiducials(:, 3), ...
                'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
        end
        axis equal;
        hold off;
    catch
    end

    save(outMatPath, 'headshape');
end
