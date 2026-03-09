function plot_cap_registration(source, target, legends, method)
% PLOT_CAP_REGISTRATION - Visualizes 3D cap registration between two point sets
%                         with optional interactive keypress close behavior.
%
% Inputs:
%   source   - Nx3 matrix of 3D coordinates (e.g., aligned default electrodes)
%   target   - Nx3 matrix of 3D coordinates (e.g., detected electrodes)
%   legends  - (optional) 1x2 cell array of legend labels. Default: {'source', 'target'}
%   method           - (optional) Projection method: 'lambert', 'equidistant', or 'stereographic' (default: 'stereographic')

    import eegloc.algorithms.compute_uv_coordinates

    if nargin < 3 || isempty(legends)
        legends = {'source', 'target'};
    end
    if nargin < 4 || isempty(method)
        method = 'stereographic';
    end

    hFig = figure('Name', '3D Cap Registration', ...
                  'NumberTitle', 'off', ...
                  'CloseRequestFcn', @(src, event) closeAndResume(src));
    
    % Add keypress handling
    hFig.KeyPressFcn = @(src, event) onKeyPress(src, event, hFig);

    % Plot
    hold on;
    h1 = scatter3(source(:,1), source(:,2), source(:,3), 30, [0.4 0.4 0.4], 'filled');

    % Try to construct and visualize a surface mesh
    try
        sourceShifted = source;
        sourceShifted(:,3) = source(:,3) + max(source(:,3)) - min(source(:,3));
        [u, v] = compute_uv_coordinates(sourceShifted(:,1), sourceShifted(:,2), sourceShifted(:,3), method, false);
        source2D = [u, v];

        dt = delaunayTriangulation(source2D);
        faces = dt.ConnectivityList;

        patch('Vertices', source, ...
              'Faces', faces, ...
              'FaceColor', [0.8 0.8 0.8], ...
              'EdgeColor', [0.4 0.4 0.4], ...
              'FaceAlpha', 0.75, ...
              'EdgeAlpha', 0.3, ...
              'LineWidth', 0.5, ...
              'AmbientStrength', 0.3, ...
              'DiffuseStrength', 0.6, ...
              'SpecularStrength', 0.1, ...
              'SpecularExponent', 10);

        material('dull');

    catch
        warning('Could not construct mesh. Only plotting source points.');
    end

    h2 = scatter3(target(:,1), target(:,2), target(:,3), 50, 'r', 'filled');

    legend([h1, h2], legends{1}, legends{2});
    title(sprintf('3D Cap Registration'));
    axis equal;
    grid on;
    xlabel('X');
    ylabel('Y');
    zlabel('Z');

    % Pause interaction until figure is closed or a key is pressed
    uiwait(hFig);
end

%% Helper: Key press handling
function onKeyPress(~, event, fig)
    if any(strcmp(event.Key, {'return', 'escape', 'backspace'}))
        closeAndResume(fig);
    end
end

%% Helper: Safe figure close + resume
function closeAndResume(fig)
    if ishghandle(fig)
        uiresume(fig);
        delete(fig);
    end
end
