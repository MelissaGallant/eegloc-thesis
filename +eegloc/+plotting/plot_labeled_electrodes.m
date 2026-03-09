function plot_labeled_electrodes(img, uvPoints, labels)
% PLOT_LABELED_ELECTRODES - Plots labeled UV points on an image or blank canvas.
%
% Inputs:
%   img        - Grayscale or RGB image (MxNx1 or MxNx3). Can be empty.
%   uvPoints   - Nx2 matrix of [u, v] coordinates (normalized, origin bottom-left)
%   labels     - Nx1 cell array or string array of label strings

    % Determine image dimensions and gridSize
    if ~isempty(img)
        [H, W, ~] = size(img);
        gridSize = max(H, W);
        uvPoints(:,2) = 1 - uvPoints(:,2);  % Flip v ONLY for image display
    else
        H = 512; W = 512;
        gridSize = max(H, W);
    end

    % Convert UVs to pixel coordinates
    x = uvPoints(:,1) * gridSize;
    y = uvPoints(:,2) * gridSize;

    % Display image or blank canvas
    figure;
    if ~isempty(img)
        if size(img,3) == 3
            img = rgb2gray(img);
        end
        imshow(img); hold on;
    else
        % Dummy scatter to initialize axes
        scatter(x, y, 1, 'w'); 
        padding = 0.05 * gridSize;
        xrange = [min(x)-padding, max(x)+padding];
        yrange = [min(y)-padding, max(y)+padding];
        axis([xrange, yrange]);
        axis equal; hold on;
    end

    % Plot small filled black dots
    scatter(x, y, 10, 'k', 'filled');

    % Plot red labels
    for i = 1:length(labels)
        text(x(i), y(i), labels{i}, ...
            'Color', 'r', ...
            'FontSize', 10, ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom');
    end

    title('Labeled Electrode Positions');
end
