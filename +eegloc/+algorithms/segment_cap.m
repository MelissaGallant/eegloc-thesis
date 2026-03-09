function imgCap = segment_cap(img, visualize, useVariance, capColor)
% SEGMENT_CAP - Adaptive EEG cap segmentation using active contour
%
% Inputs:
%   img         - RGB image (flattened head projection)
%   visualize   - (optional) Logical flag to enable visualization of results.
%   useVariance - (optional) Boolean: use high variance. default: true.
%   capColor    - (optional) 'blue', 'yellow', or 'pink'. If empty, auto-detect
%
% Output:
%   imgCap      - Image of the EEG cap

    import eegloc.algorithms.detect_cap_color
    import eegloc.algorithms.correct_cap_color

    if nargin < 2 || isempty(visualize)
        visualize = false;
    end
    if nargin < 3 || isempty(useVariance)
        useVariance = true;
    end
    if nargin < 4 || isempty(capColor)
        capColor = detect_cap_color(img);
    end

    % Correct cap color such that light fabrics become dark gray
    img = correct_cap_color(img, capColor);

    % Convert to grayscale
    grayImg = rgb2gray(img);
    [h, w, ~] = size(img);

    % Determine cap mask depending on cap color
    hsvImg = rgb2hsv(img);
    H = hsvImg(:,:,1);
    S = hsvImg(:,:,2);
    V = hsvImg(:,:,3);
    
    switch lower(capColor)
        case 'blue' % large cap size
            % Use original HSV-based color detection
            colorMask = (H >= 0.55 & H <= 0.7) & (S > 0.4) & (V > 0.2);
            grayElectrodeMask = (S < 0.25) & (V < 0.45);
            capMask = colorMask | grayElectrodeMask;
        case {'yellow', 'pink'} % for small and medium cap sizes
            % Use dark-gray mask to detect regularized cap (color + electrodes)
            tol = 0.05;
            grayTarget = 0.1;
            colorMask = all(abs(img - grayTarget) < tol, 3);
            capMask = colorMask;
        otherwise
            error('Unsupported capColor: %s', capColor);
    end

    % Optional: enhance mask using texture variance
    if useVariance
        localVar = stdfilt(grayImg, true(17));
        localVar = mat2gray(localVar);

        combinedMask = localVar .* double(capMask);
        combinedMask = mat2gray(combinedMask);
        highResponse = imbinarize(combinedMask, graythresh(combinedMask));
        highResponse = bwareaopen(highResponse, 200);
    else
        highResponse = capMask;
    end

    % Keep only largest circular-ish region
    cc = bwconncomp(highResponse);
    stats = regionprops(cc, 'Area', 'Eccentricity');
    circularIdx = find([stats.Eccentricity] < 0.85);
    areas = [stats(circularIdx).Area];

    if ~isempty(areas)
        [~, bestIdx] = max(areas);
        highResponse = false(size(highResponse));
        highResponse(cc.PixelIdxList{circularIdx(bestIdx)}) = true;
    end

    % Estimate cap center
    [yCoords, xCoords] = find(highResponse);
    if ~isempty(xCoords)
        cx = mean(xCoords);
        cy = mean(yCoords);
    else
        cx = w / 2;
        cy = h / 2;
        warning('No strong response for cap center; falling back to image center.');
    end

    % Initial ellipse mask
    [X, Y] = meshgrid(1:w, 1:h);
    stats = regionprops(highResponse, 'BoundingBox');
    ellipseScale = 1;

    if ~isempty(stats)
        allBoxes = cat(1, stats.BoundingBox);
        xMin = min(allBoxes(:,1));
        xMax = max(allBoxes(:,1) + allBoxes(:,3));
        yMin = min(allBoxes(:,2));
        yMax = max(allBoxes(:,2) + allBoxes(:,4));

        rx = (xMax - xMin) / 2 * ellipseScale;
        ry = (yMax - yMin) / 2 * ellipseScale;
    else
        rx = w / 2.5;
        ry = h / 2.5;
    end

    initMask = ((X - cx).^2 / rx^2 + (Y - cy).^2 / ry^2) <= 1;

    % Active contour segmentation
    bwCap = activecontour(grayImg, initMask, 100, 'edge');

    % Post-processing
    bwCap = imfill(bwCap, 'holes');
    bwCap = bwareaopen(bwCap, 1000);

    % Apply mask to RGB image
    imgCap = img;
    for c = 1:3
        channel = img(:,:,c);
        channel(~bwCap) = 0;
        imgCap(:,:,c) = channel;
    end

    % Visualization
    if visualize
        figure;

        subplot(1, 2, 1);
        imshow(highResponse);
        title('High Response Area');

        subplot(1, 2, 2);
        imshow(img);
        hold on;
        visboundaries(bwCap, 'Color', 'g', 'LineWidth', 2);
        plot(cx, cy, 'rx', 'MarkerSize', 10, 'LineWidth', 2);
        title(sprintf('Cap Segmentation (Detected Cap Color: %s)', capColor));
    end
end
