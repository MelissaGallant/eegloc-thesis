function cropped = crop_headshape(headshape, xlim, ylim, zlim)
% CROP_HEADSHAPE Crops a headshape mesh to the specified X, Y, Z ranges.
%
% Usage:
%   cropped = crop_headshape(headshape, xlim, ylim, zlim)
%
% Inputs:
%   headshape - struct with fields:
%       .pos   : Nx3 vertex coordinates
%       .tri   : Mx3 face indices
%       .color : Nx3 RGB values (optional)
%       .unit, .coordsys, .cfg (optional)
%   xlim, ylim, zlim - [min max] ranges for each axis, or [] to skip cropping
%
% Output:
%   cropped   - clone of headshape with updated .pos/.tri/.color

    % Validate input
    if ~isfield(headshape, 'pos') || ~isfield(headshape, 'tri')
        error('headshape must contain fields "pos" and "tri"');
    end

    pos = double(headshape.pos);  % Nx3
    tri = headshape.tri;

    % Default: keep everything
    in_bounds = true(size(pos, 1), 1);

    % Apply bounds where specified
    if ~isempty(xlim)
        in_bounds = in_bounds & (pos(:,1) >= xlim(1) & pos(:,1) <= xlim(2));
    end
    if ~isempty(ylim)
        in_bounds = in_bounds & (pos(:,2) >= ylim(1) & pos(:,2) <= ylim(2));
    end
    if ~isempty(zlim)
        in_bounds = in_bounds & (pos(:,3) >= zlim(1) & pos(:,3) <= zlim(2));
    end

    kept_idx = find(in_bounds);
    if isempty(kept_idx)
        error('Cropping removed all vertices. Please check xlim/ylim/zlim.');
    end

    old_to_new = zeros(size(pos, 1), 1);
    old_to_new(kept_idx) = 1:numel(kept_idx);

    % Filter faces: all 3 vertices must be kept
    tri_mask = all(ismember(tri, kept_idx), 2);
    new_tri = tri(tri_mask, :);

    if isempty(new_tri)
        error('Cropping removed all faces. Please check xlim/ylim/zlim.');
    end

    % Remap triangle indices
    new_tri = old_to_new(new_tri);

    % Clone original struct and overwrite geometry fields
    cropped = headshape;
    cropped.pos = pos(kept_idx, :);
    cropped.tri = new_tri;

    % Update or remove color depending on compatibility
    if isfield(headshape, 'color') && size(headshape.color, 1) == size(pos, 1)
        cropped.color = headshape.color(kept_idx, :);
    elseif isfield(cropped, 'color')
        cropped = rmfield(cropped, 'color');
    end
    
end
