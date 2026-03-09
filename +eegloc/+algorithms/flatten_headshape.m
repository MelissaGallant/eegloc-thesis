function [uv, imgRaster] = flatten_headshape(headshape, visualize, headRotationDeg, centerPoint, method, gridSize)
% FLATTEN_HEADSHAPE - Projects a 3D head mesh to a 2D UV raster image
%
% Syntax:
%   [uv, imgRaster] = headshape_to_uv_raster(headshape)
%   [uv, imgRaster] = headshape_to_uv_raster(headshape, headRotationDeg, gridSize)
%
% Inputs:
%   headshape        - Struct with fields: pos (Nx3), tri (Mx3), color (Nx3)
%   visualize        - (optional) Logical flag to enable visualization of results.
%   headRotationDeg  - (optional) Degrees to rotate around Y-axis (default: 0)
%   centerPoint      - (optional) Degrees to rotate around Y-axis (default: mean(headshape.pos)))
%   gridSize         - (optional) Output image resolution (default: 512)
%   method           - (optional) Projection method: 'lambert', 'equidistant', or 'stereographic' (default: 'stereographic')
%
% Outputs:
%   uv               - Nx2 matrix of normalized UV texture coordinates
%   imgRaster        - Rasterized UV image (gridSize x gridSize x 3)

    import eegloc.algorithms.compute_uv_coordinates

    if nargin < 2 || isempty(visualize)
        visualize = false;
    end
    if nargin < 3 || isempty(headRotationDeg)
        headRotationDeg = 0;
    end
    if nargin < 4 || isempty(centerPoint)
        centerPoint = mean(headshape.pos);
    end
    if nargin < 5 || isempty(method)
        method = 'stereographic';
    end
    if nargin < 6 || isempty(gridSize)
        gridSize = 512;
    end

    % Extract 3D coordinates
    x = headshape.pos(:,1);
    y = headshape.pos(:,2);
    z = headshape.pos(:,3);
    colors = headshape.color;

    % Center the head
    x = x - centerPoint(1);
    y = y - centerPoint(2);
    % z = z - center(3);

    % Rotate head around Y-axis
    theta = deg2rad(headRotationDeg);
    R = [cos(theta), 0, sin(theta);
         0, 1, 0;
        -sin(theta), 0, cos(theta)];

    rotated = (R * [x'; y'; z'])';
    x = rotated(:,1);
    y = rotated(:,2);
    z = rotated(:,3);
    z = z + 0.1*max(z); % include 10% more of headshape below fiducials
    
    % Compute UV coordinates using azimuthal projection
    [u, v] = compute_uv_coordinates(x, y, z, method);
    v = 1 - v; % Flip vertically to match image space
    uv = [u, v];

    % Define grid
    [uq, vq] = meshgrid(linspace(0, 1, gridSize), linspace(0, 1, gridSize));

    % Interpolate colors
    F_r = scatteredInterpolant(u, v, colors(:,1), 'linear', 'nearest');
    F_g = scatteredInterpolant(u, v, colors(:,2), 'linear', 'nearest');
    F_b = scatteredInterpolant(u, v, colors(:,3), 'linear', 'nearest');

    Rimg = F_r(uq, vq);
    Gimg = F_g(uq, vq);
    Bimg = F_b(uq, vq);

    imgRaster = cat(3, Rimg, Gimg, Bimg);
    % imgRaster = flipud(imgRaster); % Flip vertically for correct display

    if visualize
        figure;
        imshow(imgRaster);
        title('Rasterized UV Projection');
    end
end
