function plot_headshape(headshape)
% PLOT_HEADSHAPE - Plot a FieldTrip headshape.
%
% If headshape.cfg.fiducials exists (and contains nas/lhj/rhj), this will:
%   - plot the headshape with axes using ft_plot_headshape(..., 'axes', true)
%   - overlay the fiducials as red points
%
% Otherwise:
%   - plot the headshape without axes using ft_plot_headshape(headshape)
%
% Input:
%   headshape : FieldTrip mesh struct (e.g., from ft_read_headshape / ft_meshrealign)
%
% Notes:
% - Requires FieldTrip on the MATLAB path.

    if nargin < 1 || isempty(headshape)
        error('headshape is required.');
    end

    % FieldTrip plotting
    try
        ft_defaults;
    catch ME
        error('Failed to run ft_defaults. Make sure FieldTrip is on the MATLAB path. (%s)', ME.message);
    end

    hasCfg = isfield(headshape, 'cfg') && ~isempty(headshape.cfg);
    hasFids = hasCfg && isfield(headshape.cfg, 'fiducial') && ~isempty(headshape.cfg.fiducial);

    % Determine if we have the fiducials we expect
    canPlotFids = false;
    fiducials = [];
    if hasFids
        fiducials = headshape.cfg.fiducial;
        canPlotFids = isfield(fiducials, 'nas') && isfield(fiducials, 'lpa') && isfield(fiducials, 'rpa') && ...
                      ~isempty(fiducials.nas) && ~isempty(fiducials.lpa) && ~isempty(fiducials.rpa);
    end

    figure;
    hold on;

    if canPlotFids
        % Plot with axes
        ft_plot_headshape(headshape, 'axes', true);

        % Compute fiducials to overlay. If a transform exists, apply it.
        pts = [fiducials.nas; fiducials.lpa; fiducials.rpa];

        if isfield(headshape.cfg, 'transform') && ~isempty(headshape.cfg.transform)
            T = headshape.cfg.transform;
            rotatedFiducials = [pts, ones(3, 1)] * T';
            rotatedFiducials(:, end) = [];
        else
            rotatedFiducials = pts;
        end

        % Overlay fiducials
        plot3(rotatedFiducials(:, 1), rotatedFiducials(:, 2), rotatedFiducials(:, 3), ...
              'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');

    else
        % Plot without axes
        ft_plot_headshape(headshape);
    end

    axis equal;
    view(3);
    hold off;
end
