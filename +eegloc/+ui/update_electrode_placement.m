function [editedUVPoints, reviewOption] = update_electrode_placement(img, initialUVPoints)
% UPDATE_ELECTRODE_PLACEMENT - Interactively edit (add/remove) 2D points on an image.
%
% Inputs:
%   img             	- RGB or grayscale image
%   initialUVPoints     - Nx2 matrix of [u, v] coordinates in normalized [0,1] space
%
% Output:
%   editedUVPoints      - Updated Nx2 matrix of [u, v] coordinates (normalized)
%   reviewOption        - Boolean, indicating whether to review changes

    % Convert image to grayscale if needed
    if size(img, 3) == 3
        img = rgb2gray(img);
    end

    [H, W] = size(img);
    gridSize = max(H, W);

    % Convert UV to pixel coordinates for display
    pixelPoints = initialUVPoints;
    pixelPoints(:,2) = 1 - pixelPoints(:,2);
    pixelPoints = pixelPoints * gridSize;

    % Setup figure
    hFig = figure('Name', 'Interactive Point Editor', 'NumberTitle', 'off');
    imshow(img);
    hold on;

    axis on;

    ax = gca;
    ax.Units = 'normalized';
    ax.Position = [0.1, 0.15, 0.8, 0.75];  % leave room at top for title

    scatterHandle = scatter(pixelPoints(:,1), pixelPoints(:,2), 100, 'ro', 'LineWidth', 2);

    titleHandle = title({'Click to ADD points', 'Click existing points + press DELETE to remove'}, ...
                        'FontWeight', 'bold', 'FontSize', 12);

    counterHandle = text(1, -0.08, ...
        sprintf('Total electrodes: %d', size(pixelPoints,1)), ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'right', ...
        'VerticalAlignment', 'top', ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'Color', 'k');

    % State
    points = pixelPoints;
    selectedIdx = [];
    highlightHandle = [];

    % Set up callbacks
    set(hFig, 'WindowButtonDownFcn', @onClick);
    set(hFig, 'KeyPressFcn', @onKeyPress);

    uiwait(hFig); % Wait until the figure is closed

   if ishandle(hFig)
        close(hFig);
    end

    % Flip back Y and convert to UV
    editedUVPoints = points / gridSize;
    editedUVPoints(:,2) = 1 - editedUVPoints(:,2);
    editedUVPoints = min(max(editedUVPoints, 0), 1);

    % Summary of changes
    n_initial = size(initialUVPoints, 1);
    n_final = size(editedUVPoints, 1);
    n_changes = abs(n_final - n_initial);

    fprintf('\nElectrode placement summary:\n');
    fprintf(' - Detected initial electrode positions on headshape.\n');
    fprintf(' - Currently detected: %d electrodes\n', n_initial);
    fprintf(' - User modifications: %d changes \n', n_changes);
    fprintf(' - Final number of electrodes detected: %d electrodes\n\n', n_final);

    % Prompt for 3D headshape review
    while true
        userInput = lower(input('Would you like to review the 3D electrode positions? [Y/n]: ', 's'));
        if isempty(userInput) || any(strcmp(userInput, {'y', 'n'}))
            break;
        else
            disp('Please enter Y or N.');
        end
    end
    
    % Only proceed if explicitly 'y'
    reviewOption = strcmp(userInput, 'y');

    % Mouse click handler
    function onClick(~, ~)
        cp = get(gca, 'CurrentPoint');
        clickX = cp(1,1);
        clickY = cp(1,2);

        xLimits = xlim(gca);
        yLimits = ylim(gca);
    
        if clickX < xLimits(1) || clickX > xLimits(2) || ...
           clickY < yLimits(1) || clickY > yLimits(2)
            return;
        end

        distances = sqrt((points(:,1) - clickX).^2 + (points(:,2) - clickY).^2);
        [minDist, idx] = min(distances);

        threshold = 5;
        if minDist < threshold
            selectedIdx = idx;
            highlight_point(points(idx, :));
        else
            points = [points; clickX, clickY];
            selectedIdx = [];
            remove_highlight();
            update_plot();
        end
    end

    % Key press handler
    function onKeyPress(~, event)
        if (strcmp(event.Key, 'delete') || strcmp(event.Key, 'backspace')) && ~isempty(selectedIdx)
            points(selectedIdx, :) = [];
            selectedIdx = [];
            remove_highlight();
            update_plot();
        elseif strcmp(event.Key, 'return') || strcmp(event.Key, 'escape')
            uiresume(hFig);
        end
    end

    % Update scatter plot and counter
    function update_plot()
        if isvalid(scatterHandle)
            scatterHandle.XData = points(:,1);
            scatterHandle.YData = points(:,2);
        end
        if isvalid(counterHandle)
            counterHandle.String = sprintf('Total electrodes: %d', size(points,1));
        end
    end

    % Highlight selected point
    function highlight_point(pt)
        remove_highlight();
        highlightHandle = scatter(pt(1), pt(2), 120, 'go', 'LineWidth', 2);
        drawnow;
    end

    % Remove highlight
    function remove_highlight()
        if ~isempty(highlightHandle) && isvalid(highlightHandle)
            delete(highlightHandle);
            highlightHandle = [];
        end
    end
end
