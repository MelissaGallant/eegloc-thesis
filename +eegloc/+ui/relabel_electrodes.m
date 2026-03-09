function [updatedLabels, reviewOption] = relabel_electrodes(img, pointsUV, currentLabels, allLabels)
% RELABEL_ELECTRODES - Interactively modify electrode labels on an image.
%
% Inputs:
%   img           - RGB or grayscale image
%   pointsUV      - Nx2 matrix of [u,v] coordinates (normalized, origin bottom-left)
%   currentLabels - Nx1 string array of existing labels (may include '?')
%   allLabels     - Mx1 string array of all possible labels (final desired order)
%
% Output:
%   updatedLabelsUV - Mx2 matrix of labeled point coordinates in UV space

    if size(img, 3) == 3
        img = rgb2gray(img);
    end

    [H, W] = size(img);
    gridSize = max(H, W);

    % Normalize coordinates for display (flip v to image origin top-left)
    pointsXY = pointsUV;
    pointsXY(:,2) = 1 - pointsXY(:,2);
    pointsXY = pointsXY * gridSize;

    % Initialize state
    updatedLabelsUV = nan(length(allLabels), 2);
    labelToIndexMap = containers.Map(allLabels, 1:length(allLabels));
    assignedLabels = currentLabels(:);
    selectedIdx = [];
    highlightHandle = [];

    % Compute initial unassigned labels
    used = setdiff(assignedLabels, "?");
    availableLabels = setdiff(allLabels, used, 'stable');

    % Setup UI
    hFig = figure('Name', 'Relabel Electrodes', 'NumberTitle', 'off', ...
                  'KeyPressFcn', @onKeyPress, ...
                  'WindowButtonDownFcn', @onClick, ...
                  'Units', 'normalized', ...
                  'Position', [0.1, 0.1, 0.8, 0.8]);

    ax = axes('Parent', hFig, 'Units', 'normalized', 'Position', [0.1, 0.25, 0.6, 0.7]);
    imshow(img, 'Parent', ax); hold(ax, 'on');

    % Plot all points with color based on current label
    markerColors = get_marker_colors(assignedLabels);
    scatterHandle = scatter(ax, pointsXY(:,1), pointsXY(:,2), 80, markerColors, 'filled');

    % Set axis limits with 10% margin around points
    xMin = min(pointsXY(:,1));
    xMax = max(pointsXY(:,1));
    yMin = min(pointsXY(:,2));
    yMax = max(pointsXY(:,2));

    xRange = xMax - xMin;
    yRange = yMax - yMin;

    xMargin = 0.05 * xRange;
    yMargin = 0.05 * yRange;

    xlim(ax, [xMin - xMargin, xMax + xMargin]);
    ylim(ax, [yMin - yMargin, yMax + yMargin]);

    % Label texts
    labelHandles = gobjects(length(assignedLabels),1);
    for i = 1:length(assignedLabels)
        labelHandles(i) = text(pointsXY(i,1), pointsXY(i,2)-10, assignedLabels(i), ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'Color', get_label_color(assignedLabels(i)));
    end

    title({'Click a point to (re)label it', 'Enter = assign, Backspace = remove'}, ...
          'FontWeight', 'bold', 'FontSize', 12, 'Parent', ax);

    labelBox = uicontrol('Style', 'listbox', ...
                         'String', availableLabels, ...
                         'Units', 'normalized', ...
                         'Position', [0.75, 0.25, 0.2, 0.7], ...
                         'FontSize', 12);

    counterText = uicontrol('Style', 'text', ...
                            'Units', 'normalized', ...
                            'Position', [0.75, 0.1, 0.2, 0.05], ...
                            'String', sprintf('Labeled: %d / %d', sum(assignedLabels ~= "?"), length(allLabels)), ...
                            'FontSize', 12, ...
                            'HorizontalAlignment', 'left');

    uiwait(hFig);
    if ishandle(hFig), close(hFig); end

    % Return updated labels as Nx1 string array (same order as pointsUV)
    updatedLabels = assignedLabels;
    
    % Summary of changes
    n_initial = sum(currentLabels ~= "?");
    n_final = sum(updatedLabels ~= "?");
    n_changes = sum(currentLabels ~= updatedLabels);
    
    fprintf('\nElectrode labeling summary:\n');
    fprintf(' - Detected electrode positions on headshape.\n');
    fprintf(' - Originally labeled electrodes: %d\n', n_initial);
    fprintf(' - User modifications: %d labels changed\n', n_changes);
    fprintf(' - Final number of labeled electrodes: %d\n\n', n_final);
    
    % Prompt for 3D headshape review
    while true
        userInput = lower(input('Would you like to review the 3D labeled electrode positions? [Y/n]: ', 's'));
        if isempty(userInput) || any(strcmp(userInput, {'y', 'n'}))
            break;
        else
            disp('Please enter Y or N.');
        end
    end
    
    % Only proceed if explicitly 'y'
    reviewOption = strcmp(userInput, 'y');

    %% Callback: Mouse click
    function onClick(~, ~)
        cp = get(ax, 'CurrentPoint');
        clickX = cp(1,1);
        clickY = cp(1,2);

        distances = sqrt((pointsXY(:,1) - clickX).^2 + (pointsXY(:,2) - clickY).^2);
        [minDist, idx] = min(distances);
        if minDist < 10
            selectedIdx = idx;
            highlight_point(pointsXY(idx, :));
        end
    end

    %% Callback: Key press
    function onKeyPress(~, event)
        switch event.Key
            case 'escape'
                uiresume(hFig);
                return;
        end

        if isempty(selectedIdx), return; end

        switch event.Key
            case 'return'
                if isempty(availableLabels), return; end
                selectedValue = labelBox.Value;
                newLabel = availableLabels(selectedValue);

                assignedLabels(selectedIdx) = newLabel;

                % Update marker + text
                scatterHandle.CData(selectedIdx,:) = get_color(newLabel);
                set(labelHandles(selectedIdx), 'String', newLabel, 'Color', get_label_color(newLabel));

            case 'backspace'
                assignedLabels(selectedIdx) = "?";

                scatterHandle.CData(selectedIdx,:) = get_color("?");
                set(labelHandles(selectedIdx), 'String', "?", 'Color', get_label_color("?"));
        end

        % Update available label list based on current state
        availableLabels = setdiff(allLabels, assignedLabels, 'stable');

        set(labelBox, 'String', availableLabels);
        labelBox.Value = min(labelBox.Value, max(1, numel(availableLabels)));

        selectedIdx = [];
        remove_highlight();

        numAssigned = sum(assignedLabels ~= "?");
        set(counterText, 'String', sprintf('Labeled: %d / %d', numAssigned, length(allLabels)));
    end


    %% Highlight selected point
    function highlight_point(pt)
        remove_highlight();
        highlightHandle = scatter(ax, pt(1), pt(2), 100, 'go', 'LineWidth', 2);
        drawnow;
    end

    %% Remove highlight
    function remove_highlight()
        if ~isempty(highlightHandle) && isvalid(highlightHandle)
            delete(highlightHandle);
            highlightHandle = [];
        end
    end

    %% Get marker colors
    function colors = get_marker_colors(lbls)
        colors = zeros(length(lbls), 3);
        for i = 1:length(lbls)
            colors(i,:) = get_color(lbls(i));
        end
    end

    %% Assign color by label
    function c = get_color(lbl)
        if lbl == "?"
            c = [0, 0, 1];  % blue for ambiguous
        else
            c = [0, 0.7, 0];  % green for labeled
        end
    end

    function c = get_label_color(lbl)
        if lbl == "?"
            c = [0.8 0.8 0.8];  % gray text for ambiguous
        else
            c = [1 1 1];  % white text for labeled
        end
    end

end
