function uvCoords = flatten_electrode_locations(electrode3D, method)
% FLATTEN_ELECTRODE_LOCATIONS - Projects 3D electrodes into 2D UV space
% and returns an Nx2 matrix with UV coordinates.
%
% Inputs:
%   electrode3D   - Nx3 matrix of 3D electrode positions
%   method  - Projection method: 'lambert', 'equidistant', or 'stereographic'
%
% Output:
%   uvCoords      - Nx2 matrix with columns: U, V

    import eegloc.algorithms.compute_uv_coordinates

    if nargin < 2 || isempty(method)
        method = 'stereographic';
    end

    % Apply head rotation (Ry(90) Rz(180))
    theta = deg2rad(90);
    R = [cos(theta), 0, sin(theta);
         0, 1, 0;
        -sin(theta), 0, cos(theta)];
    
    rotated = (R * electrode3D')';
    x = rotated(:,1);
    y = rotated(:,2);
    z = rotated(:,3);

    % Project to UV space using azimuthal projection
    [u, v] = compute_uv_coordinates(x, y, z, method);
    
    uvCoords = [u, v];
end
