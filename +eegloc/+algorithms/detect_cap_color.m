function capColor = detect_cap_color(img)
% DETECT_CAP_COLOR - Automatically detects EEG cap color in HSV space

    hsvImg = rgb2hsv(img);
    H = hsvImg(:,:,1);
    S = hsvImg(:,:,2);
    V = hsvImg(:,:,3);

    % Basic HSV masks
    maskBlue   = (H >= 0.55 & H <= 0.7)  & S > 0.3;
    maskYellow = (H >= 0.10 & H <= 0.18) & S > 0.3;
    maskPink   = ((H >= 0.9 | H <= 0.03) & S > 0.2);

    % Apply center weighting to suppress corners
    [h, w] = size(H);
    centerPrior = fspecial('gaussian', [h, w], 0.3 * h);
    centerPrior = mat2gray(centerPrior);

    % Weighted color score
    scoreBlue   = sum(centerPrior(maskBlue));
    scoreYellow = sum(centerPrior(maskYellow));
    scorePink   = sum(centerPrior(maskPink));

    % Pick the color with the highest score
    [~, idx] = max([scoreBlue, scoreYellow, scorePink]);
    capOptions = {'blue', 'yellow', 'pink'};
    capColor = capOptions{idx};
end
