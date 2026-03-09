function modifiedImg = correct_cap_color(img, capColor)
% CORRECT_CAP_COLOR - Improve contrast for yellow/pink EEG caps by
% normalizing cap fabric and internal gray strip to a uniform dark gray.
%
% This function adjusts the appearance of yellow and pink EEG caps to improve
% downstream segmentation by correcting for their low contrast.
% Blue caps are left unmodified.
%
% Inputs:
%   img      - RGB image of the flattened head projection
%   capColor - String: 'blue', 'yellow', or 'pink'. Determines correction strategy
%
% Output:
%   modifiedImg - RGB image with cap regions corrected to a uniform dark gray

    if nargin < 2 || isempty(capColor)
        error('You must provide capColor (''blue'', ''yellow'', or ''pink'').');
    end
    
    hsvImg = rgb2hsv(img);
    H = hsvImg(:,:,1);
    S = hsvImg(:,:,2);
    V = hsvImg(:,:,3);

    % Define cap color masks
    colorMask = false(size(H));
    switch lower(capColor)
        case 'yellow'
            colorMask = (H >= 0.10 & H <= 0.17) & ...
                        (S > 0.4) & ...
                        (V > 0.2);
        case 'pink'
            % colorMask = ((H >= 0.9 | H <= 0.03) & (S > 0.2));
            colorMask = ((H >= 0.9 | H <= 0.03) & ...
                         (S > 0.4) & ...
                         (V > 0.3));
        case 'blue'
            % Do not apply any colorMask for blue
            modifiedImg = img;
            return;
        otherwise
            error('Unsupported capColor.');
    end
    
    % Detect low-saturation, low-brightness gray areas
    rawGrayStripMask = (S < 0.25) & (V < 0.5);
    
    % Fill all internal holes in colorMask, including edge-connected ones
    se = strel('disk', 10);
    closedColorMask = imclose(colorMask, se);
    filledColorMask = imfill(closedColorMask, 'holes');

    % Detect area of gray strip that does not intersect with the rest
    grayStripMask = rawGrayStripMask & ~filledColorMask;

    % Combine both into a unified cap mask
    capMask = colorMask | grayStripMask;

    % Paint both regions as uniform dark gray
    modifiedImg = img;
    darkGray = [0.1, 0.1, 0.1];

    for c = 1:3
        channel = modifiedImg(:,:,c);
        channel(capMask) = darkGray(c);
        modifiedImg(:,:,c) = channel;
    end
end
