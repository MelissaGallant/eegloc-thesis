function correctedPoints3D = inverse_alignment(detectedPoints3D, alignmentTransformation)
% INVERSE_ALIGNMENT - Applies inverse of a 4x4 transformation matrix to detected
% 3D points to map them back to source space.
%
% Inputs:
%   detectedPoints3D        - Nx3 matrix of 3D points in target/aligned space
%   alignmentTransformation - 4x4 homogeneous transformation matrix (source -> target)
%
% Output:
%   correctedPoints3D       - Nx3 matrix of points mapped back into source space

    if size(detectedPoints3D,2) ~= 3
        error('Input detectedPoints3D must be Nx3');
    end
    if ~isequal(size(alignmentTransformation), [4, 4])
        error('alignmentTransformation must be a 4x4 matrix');
    end

    % Convert to homogeneous coordinates
    homDetected = [detectedPoints3D, ones(size(detectedPoints3D,1), 1)];

    % Apply inverse transformation (using matrix division instead of inv)
    homCorrected = (alignmentTransformation \ homDetected')';

    % Extract corrected XYZ coordinates
    correctedPoints3D = homCorrected(:, 1:3);
end
