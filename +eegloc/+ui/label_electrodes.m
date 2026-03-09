function labeledPointsUV = label_electrodes(img, pointsUV, labels)
% LABEL_ELECTRODES - Interactively assign predefined labels to clicked points
%
% Inputs:
%   img      - RGB or grayscale image
%   pointsUV - Nx2 matrix of [u,v] coordinates (normalized, origin bottom-left)
%   labels   - Mx1 cell or string array of predefined labels
%
% Output:
%   labeledPointsUV - Mx2 matrix of labeled point coordinates in UV space

    if size(img, 3) == 3
        img = rgb2gray(img);
    end

    [H, W] = size(img);
    gridSize = max(H, W);

    % Flip v-coordinates to match image origin (top-left)
    pointsXY = pointsUV;
    pointsXY(:,2) = 1 - pointsXY(:,2);
    pointsXY = pointsXY * gridSize;

    % Initialize state
    labeledPointsUV = nan(length(labels), 2);
    availableLabels = labels;
    labelToIndexMap = containers.Map(labels, 1:length(labels));
    selectedIdx = [];
    highlightHandle = [];

    % Setup UI
    hFig = figure('Name', 'Label Electrodes', 'NumberTitle', 'off', ...
                  'KeyPressFcn', @onKeyPress, ...
                  'WindowButtonDownFcn', @onClick, ...
                  'Units', 'normalized', ...
                  'Position', [0.1, 0.1, 0.8, 0.8]);

    ax = axes('Parent', hFig, 'Units', 'normalized', 'Position', [0.1, 0.25, 0.6, 0.7]);
    imshow(img, 'Parent', ax); hold(ax, 'on');
    scatterHandle = scatter(ax, pointsXY(:,1), pointsXY(:,2), 80, 'ro', 'filled');

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

    title({'Click a point to label it', 'Press Enter to assign selected label'}, ...
          'FontWeight', 'bold', 'FontSize', 12, 'Parent', ax);

    labelBox = uicontrol('Style', 'listbox', ...
                         'String', availableLabels, ...
                         'Units', 'normalized', ...
                         'Position', [0.75, 0.25, 0.2, 0.7], ...
                         'FontSize', 12);

    counterText = uicontrol('Style', 'text', ...
                            'Units', 'normalized', ...
                            'Position', [0.75, 0.1, 0.2, 0.05], ...
                            'String', 'Labeled: 0', ...
                            'FontSize', 12, ...
                            'HorizontalAlignment', 'left');

    uiwait(hFig);

    if ishandle(hFig)
        close(hFig);
    end

    % Mouse click callback
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

    % --- Key press handler ---
    function onKeyPress(~, event)
        if strcmp(event.Key, 'escape')
            uiresume(hFig);
            return;
        end

        if strcmp(event.Key, 'return') && ...
           ~isempty(selectedIdx) && ...
           ~isempty(availableLabels)

            selectedValue = labelBox.Value;
            label = availableLabels{selectedValue};
            labelIdx = labelToIndexMap(label);

            uv = pointsXY(selectedIdx, :) / gridSize;
            uv(:,2) = 1 - uv(:,2);  % Flip v back to bottom-left origin
            labeledPointsUV(labelIdx, :) = min(max(uv, 0), 1);

            % Visually confirm
            scatter(pointsXY(selectedIdx,1), pointsXY(selectedIdx,2), 80, 'go', 'filled');
            selectedIdx = [];
            remove_highlight();

            % Remove label from list
            availableLabels(selectedValue) = [];

            if isempty(availableLabels)
                uiresume(hFig);
                return;
            else
                set(labelBox, 'String', availableLabels);
                labelBox.Value = min(selectedValue, numel(availableLabels));
            end

            % Update counter
            numAssigned = sum(~isnan(labeledPointsUV(:,1)));
            set(counterText, 'String', sprintf('Labeled: %d / %d', numAssigned, length(labels)));
        end
    end

    % Highlight selected poin
    function highlight_point(pt)
        remove_highlight();
        highlightHandle = scatter(ax, pt(1), pt(2), 100, 'go', 'LineWidth', 2);
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
