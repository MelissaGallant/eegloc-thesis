function plot_headshape_with_electrodes(headshape, elec3D, labels)
% PLOT_HEADSHAPE_WITH_ELECTRODES - Displays 3D head with electrode markers.
%
% Inputs:
%   headshape - Struct with .pos (Nx3), .tri (Mx3), and optional .color (Nx3)
%   elec3D    - Kx3 matrix of 3D electrode coordinates
%   labels    - [optional] Kx1 string array of electrode names

    import eegloc.algorithms.electrode_normals

    % Clean invalid electrodes
    valid = all(~isnan(elec3D), 2);
    elec3D = elec3D(valid, :);
    
    if nargin >= 3
        labels = labels(valid);
        if ~isstring(labels) || size(labels,1) ~= size(elec3D,1)
            error('Labels must be a Kx1 string array matching elec3D.');
        end
    else
        labels = [];
    end

    elecNormals = electrode_normals(headshape, elec3D);

    % Plot head
    hFig = figure('Name', '3D Electrode Viewer', ...
                  'NumberTitle', 'off', ...
                  'CloseRequestFcn', @(src, event) closeAndResume(src));
    
    hFig.KeyPressFcn = @(src, event) onKeyPress(src, event, hFig);

    patch('Vertices', headshape.pos, ...
          'Faces', headshape.tri, ...
          'FaceVertexCData', get_vertex_color(headshape), ...
          'FaceColor', 'interp', ...
          'EdgeColor', 'none', ...
          'FaceAlpha', 1);
    hold on;
    
    % Plot electrodes
    offsetAmount = 0.5;  % tweak as needed (in mm or mesh units)
    elec3D_offset = elec3D + offsetAmount * elecNormals;
    if isempty(labels)
        % Unlabeled: red outline markers
        plot3(elec3D_offset(:,1), elec3D_offset(:,2), elec3D_offset(:,3), 'ro', ...
              'MarkerSize', 8, 'LineWidth', 1.5);
    else
        % Labeled: white filled markers
        scatter3(elec3D_offset(:,1), elec3D_offset(:,2), elec3D_offset(:,3), ...
                 60, 'r', 'filled');
    end

    % Plot normal arrows (only if labels are not shown)
    if isempty(labels)
        arrowScale = 1;
        quiver3(elec3D(:,1), elec3D(:,2), elec3D(:,3), ...
                elecNormals(:,1), elecNormals(:,2), elecNormals(:,3), ...
                arrowScale, 'Color', 'b', 'LineWidth', 1.2);
    end

    % Plot labels if given
    if ~isempty(labels)
        offset = 2;  % offset factor in the direction of the normal
        labelPos = elec3D + offset * elecNormals;
        for i = 1:length(labels)
            text(labelPos(i,1), labelPos(i,2), labelPos(i,3), labels(i), ...
                'Color', [1 1 1], ...
                'FontSize', 10, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');
        end
    end

    % Visual settings
    axis equal off;
    lighting gouraud;
    title('EEG Electrodes Projected on 3D Headshape');
    uiwait(hFig);
end

%% Helper function for color fallback
function cdata = get_vertex_color(headshape)
    if isfield(headshape, 'color') && ~isempty(headshape.color)
        cdata = headshape.color;
    else
        cdata = repmat([0.9 0.9 0.9], size(headshape.pos,1), 1);  % default grey
    end
end

function onKeyPress(~, event, fig)
    if any(strcmp(event.Key, {'return', 'escape', 'backspace'}))
        closeAndResume(fig);
    end
end

function closeAndResume(fig)
    uiresume(fig);  % Resume if uiwait is active
    delete(fig);    % Then close the figure
end
