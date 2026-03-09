function [u, v] = compute_uv_coordinates(x, y, z, method, clamp)
% COMPUTE_UV_COORDINATES - Maps 3D coordinates to 2D UV space.
%
% Inputs:
%   x, y, z - Nx1 vectors of 3D coordinates
%   method  - Projection method: 'lambert', 'equidistant', or 'stereographic'
%   clamp   - (optional) Clamp UV to [0, 1] (default: true)
%
% Outputs:
%   u, v    - Nx1 UV coordinates in 2D space

    if nargin < 4 || isempty(method)
        method = 'stereographic';
    end
    if nargin < 5 || isempty(clamp)
        clamp = true;
    end

    % Convert to spherical coordinates
    [azimuth, elevation, radius] = cart2sph(x, y, z);

    % Convert to spherical geographic coords
    phi = elevation;  % latitude (from XY plane)
    lambda = azimuth - pi/2; % longitude (from +X axis), rotate projection frame so +X faces down
    theta = pi/2 - phi; % polar angle from +Z

    switch lower(method)
        case 'lambert'
            % Lambert Azimuthal Equal-Area (centered on Z+)
            k = sqrt(2 ./ (1 + cos(theta)));
            x_proj = k .* sin(theta) .* cos(lambda);
            y_proj = k .* sin(theta) .* sin(lambda);
            scale = 2 * sqrt(2); % max diameter of projected disk

        case 'equidistant'
            % Azimuthal Equidistant (centered on Z+)
            % theta = pi/2 - elevation; % angular distance from top
            x_proj = theta .* sin(azimuth);
            y_proj = -theta .* cos(azimuth);  % Flip to center top of head
            scale = pi;

        case 'stereographic'
            % Stereographic projection (centered on Z+)
            k = 2 ./ (1 + cos(theta));
            x_proj = k .* sin(theta) .* cos(lambda);
            y_proj = k .* sin(theta) .* sin(lambda);
            scale = 4; % approximate range

        otherwise
            error('Unknown projection method: %s', method);
    end

    % Normalize to UV space [0, 1]
    u = (x_proj / scale) + 0.5;
    v = (y_proj / scale) + 0.5;

    if clamp
        u = max(0, min(1, u));
        v = max(0, min(1, v));
    end
end
