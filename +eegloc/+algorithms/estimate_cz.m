function [cz, angle_deg] = estimate_cz(headshape, origin_mode)
% ESTIMATE_CZ - Estimate Cz as the highest scalp point at (x, y) = (mid_ears_x, 0)
%
% Inputs:
%   headshape - struct with .pos, .tri, .cfg.fiducial, .cfg.transform
%   origin_mode - 'fiducial' (default) or 'centerxy'
%
% Outputs:
%   cz - estimated Cz coordinate
%   angle_deg - angle between Cz normal and reference Z-axis

    if nargin < 2 || isempty(origin_mode), origin_mode = 'fiducial'; end

    % Parameters
    xy_tol = 2;  % mm tolerance in X and Y

    % Step 1: Validate and transform fiducials to CTF coordinates
    if ~isfield(headshape, 'cfg') || ~isfield(headshape.cfg, 'fiducial') || ...
       ~isfield(headshape.cfg, 'transform')
        error('headshape.cfg.fiducial and cfg.transform are required.');
    end

    pos = headshape.pos;
    tri = headshape.tri;
    fid = headshape.cfg.fiducial;
    T   = headshape.cfg.transform;

    fids = [fid.nas; fid.lpa; fid.rpa];
    fids_ctf = [fids, ones(3,1)] * T';
    fids_ctf(:,end) = [];
    nas = fids_ctf(1,:); lpa = fids_ctf(2,:); rpa = fids_ctf(3,:);

    % Step 2: Midpoint of LPA–RPA defines Cz X coordinate
    cz_x = mean([lpa(1), rpa(1)]);

    % Step 3: Find mesh vertices near (cz_x, 0)
    dx = abs(pos(:,1) - cz_x);
    dy = abs(pos(:,2));
    near_idx = dx < xy_tol & dy < xy_tol;

    if ~any(near_idx)
        error('No mesh vertices near Cz (x, y) = (%g, 0). Try increasing xy_tol.', cz_x);
    end

    candidates = pos(near_idx, :);
    [~, max_z_i] = max(candidates(:,3));
    cz = candidates(max_z_i, :);

    % Step 4: Surface normal at Cz
    TR = triangulation(tri, pos);
    normals = vertexNormal(TR);
    [~, cz_idx] = min(vecnorm(pos - cz, 2, 2));  % find nearest vertex
    normal_cz = normals(cz_idx,:) ./ norm(normals(cz_idx,:));

    % Step 5: Reference Z axis
    switch lower(origin_mode)
        case 'fiducial'
            x_ctf = ((lpa + rpa)/2 - nas); x_ctf = x_ctf / norm(x_ctf);
            y_ctf = (rpa - lpa);          y_ctf = y_ctf / norm(y_ctf);
            z_axis = cross(x_ctf, y_ctf); z_axis = z_axis / norm(z_axis);
        case 'centerxy'
            z_axis = [0 0 1];
        otherwise
            error('origin_mode must be ''centerxy'' or ''fiducial''.');
    end

    % Step 6: Angle between Cz normal and reference Z axis
    cos_t = abs(dot(normal_cz, z_axis));
    angle_deg = rad2deg(acos(max(min(cos_t, 1), -1)));
    
end
