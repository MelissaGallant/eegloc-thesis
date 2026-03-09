function [alignedPoints, transformMatrix] = kabsch_umeyama(labelAnchors, unlabelAnchors, labeledPoints)
% KABSCH_UMEYAMA - Align a labelled 3D point cloud to an unlabeled one using Umeyama algorithm.
%
% Inputs:
%   labelAnchors   - 5x3 matrix of anchor points from the labeled set
%   unlabelAnchors - 5x3 matrix of corresponding anchor points from the unlabeled set
%   labeledPoints - Nx3 matrix of all points in the labelled set
%
% Outputs:
%   alignedPoints    - Nx3 aligned labelled points
%   transformMatrix  - 4x4 homogeneous transformation matrix

    n = size(labelAnchors, 1);

    % Compute centroids
    centroidLabel   = mean(labelAnchors, 1);
    centroidUnlabel = mean(unlabelAnchors, 1);

    % Center anchor sets
    labelCentered   = labelAnchors - centroidLabel;
    unlabelCentered = unlabelAnchors - centroidUnlabel;

    % Cross-covariance matrix
    covariance = (unlabelCentered' * labelCentered) / n;

    % Singular value decomposition
    [U, S, V] = svd(covariance);

    % Handle reflection if needed
    d = sign(det(U) * det(V'));
    reflectionFix = diag([1 1 d]);
    rotation = U * reflectionFix * V';

    % Scale estimation
    varUnlabel = mean(sum(unlabelCentered.^2, 2));
    singularVals = diag(S);
    traceAdjusted = sum(singularVals .* diag(reflectionFix));
    scale = varUnlabel / traceAdjusted;

    % Translation
    translation = centroidUnlabel - scale * (rotation * centroidLabel')';

    % Apply transformation
    alignedPoints = (labeledPoints - centroidLabel) * (scale * rotation)' + centroidUnlabel;

    % Construct homogeneous transformation matrix
    transformMatrix = eye(4);
    transformMatrix(1:3, 1:3) = scale * rotation;
    transformMatrix(1:3, 4)   = translation';
end
