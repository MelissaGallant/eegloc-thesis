function D = pdist2(A, B)
% PDIST2 - Compute Euclidean distance matrix between two point sets
%
%    Inputs:
%       A - NxD matrix
%       B - MxD matrix
%
%   Outputs:
%       D - NxM matrix where D(i,j) = distance between A(i,:) and B(j,:)

    diff = permute(A, [1 3 2]) - permute(B, [3 1 2]);
    D = sqrt(sum(diff.^2, 3));
end
