function uvCentroids = detect_electrodes(imgCap, visualize)
% DETECT_ELECTRODES - Detects hole-like regions in the EEG cap image and returns UV-normalized centroids
%
% Inputs:
%   imgCap       - RGB image of segmented cap
%   visualize    - (optional) Logical flag to enable visualization of results.
%
% Outputs:
%   uvCentroids  - N×2 matrix of (u, v) coordinates (normalized to [0,1])

    if nargin < 2 || isempty(visualize)
        visualize = false;
    end

    % Convert to grayscale
    grayImg = rgb2gray(imgCap);

    % Enhance contrast by removing background shading
    se = strel('disk', 20);  % tweak depending on cap scale
    background = imopen(grayImg, se);
    I = imadjust(grayImg - background);  % increase local contrast

    % Edge detection
    edges = edge(I, 'Canny', [0.05, 0.1]);  % thresholds are tweakable

    % Fill enclosed regions
    filled = imfill(edges, 'holes');
    
    % Remove very small noise
    filled = bwareaopen(filled, 20);  % tweak minimum blob size

    % Break weak connections & reconstruct
    eroded = imerode(filled, strel('disk', 2));
    cleaned = imreconstruct(eroded, filled);

    % Label & filter blobs by shape (circularity)
    CC = bwconncomp(cleaned);
    stats = regionprops(CC, 'Area', 'Perimeter', 'Centroid');

    circularity = @(s) 4 * pi * s.Area / (s.Perimeter^2 + eps);
    circScores = arrayfun(circularity, stats);
    keepIdx = find(circScores > 0.8);  % tweak threshold

    % Keep only selected blobs
    holeMask = ismember(labelmatrix(CC), keepIdx);

    % Post-process to smooth blobs
    holeMask = imopen(holeMask, strel('disk', 1));

    % Extract pixel-space centroids
    validStats = stats(keepIdx);
    pixelCentroids = reshape([validStats.Centroid], 2, []).';  % N×2 matrix

    % Convert to UV space (normalized coordinates)
    [H, W, ~] = size(imgCap);
    gridSize = max(H, W);
    uvCentroids = pixelCentroids / gridSize;
    uvCentroids(:,2) = 1 - uvCentroids(:,2); % Flip vertically to match image space

    % Optional: clamp just in case
    uvCentroids = min(max(uvCentroids, 0), 1);

    % Visualization
    if visualize
        figure;
        imshowpair(imgCap, holeMask, 'montage');
        title('Original Cap Image and Detected Holes');
    end
end
