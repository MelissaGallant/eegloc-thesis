function elecNormals = electrode_normals(headshape, elec3D)
% ELECTRODE_NORMALS - returns the surface normals at electrode positions
%
% Inputs:
%   headshape - struct with fields:
%       .tri : Mx3 triangulation matrix
%       .pos : Px3 matrix of vertex positions
%   elec3D - Nx3 matrix of electrode coordinates
%
% Output:
%   elecNormals - Nx3 matrix of normals at electrode locations

    import eegloc.algorithms.pdist2

    % Compute normals
    TR = triangulation(headshape.tri, headshape.pos);
    headshape.normals = vertexNormal(TR);

    % Find the closest vertex on the mesh for each electrode
    D = pdist2(headshape.pos, elec3D);
    [~, closestIdx] = min(D, [], 1);

    % Extract the normals from the closest vertices
    elecNormals = headshape.normals(closestIdx, :);
end
