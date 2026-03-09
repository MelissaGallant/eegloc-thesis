function electrodes3D = project_electrodes_uv_to_3d(headshape, uv, electrodesUV)
% PROJECT_ELECTRODES_UV_TO_3D - Maps UV-space electrode coordinates to 3D positions.
%
% Inputs:
%   headshape      - Struct with .pos (Nx3)
%   uv             - Nx2 UV coordinates per vertex, normalized [0,1]
%   electrodesUV   - Kx2 matrix of electrode positions in UV space
%
% Output:
%   electrodes3D   - Kx3 matrix of 3D electrode positions (NaN if out of bounds)

    u = uv(:,1);
    v = uv(:,2);

    u_elec = electrodesUV(:,1);
    v_elec = 1 - electrodesUV(:,2);  % Flip v to match texture origin (top-left image space)

    % Interpolants from UV to 3D coordinates
    Fx = scatteredInterpolant(u, v, headshape.pos(:,1), 'linear', 'none');
    Fy = scatteredInterpolant(u, v, headshape.pos(:,2), 'linear', 'none');
    Fz = scatteredInterpolant(u, v, headshape.pos(:,3), 'linear', 'none');

    % Interpolate positions
    x = Fx(u_elec, v_elec);
    y = Fy(u_elec, v_elec);
    z = Fz(u_elec, v_elec);

    electrodes3D = [x, y, z];
end
