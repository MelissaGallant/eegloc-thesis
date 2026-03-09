function assignedLabels = assign_labels_hungarian(centroids, labels, queryPoints, visualize)
% ASSIGN_LABELS_HUNGARIAN - Assigns labels to query points using affine + Hungarian assignment.
%
% Inputs:
%   centroids   - Nx2 or Nx3 matrix of labeled reference points.
%   labels      - Nx1 or 1xN string array of labels for the reference points.
%   queryPoints - Mx2 or Mx3 matrix of unlabeled query points to assign.
%   visualize   - (optional) logical flag to enable visualization of results.
%
% Output:
%   assignedLabels - Mx1 string array with labels assigned to each query point,
%                    or '?' for unassigned rows (if any).

    import eegloc.algorithms.munkres
    import eegloc.algorithms.pdist2

    if nargin < 4, visualize = false; end

    if size(centroids, 2) ~= size(queryPoints, 2)
        error('centroids and queryPoints must have the same number of columns (2D or 3D)');
    end

    if ~(isstring(labels) || iscellstr(labels))
        error('labels must be a string array or cell array of character vectors.');
    end
    labels = string(labels(:));  % ensure column vector

    % Hungarian assignment
    costMatrix = pdist2(queryPoints, centroids);
    [assignment, ~] = munkres(costMatrix);

    % Build assignedLabels
    assignedLabels = repmat("?", size(queryPoints, 1), 1);  % Default to unknown
    for i = 1:length(assignment)
        if assignment(i) > 0
            assignedLabels(i) = labels(assignment(i));
        end
    end

    %% Optional visualization
    if visualize
        figure('Color','w'); hold on; axis equal; grid on;
        title('Label Assignment via Affine + Hungarian');

        plot(centroids(:,1), centroids(:,2), 'ko', 'MarkerFaceColor', [0.6 0.6 0.6]);
        plot(queryPoints(:,1), queryPoints(:,2), 'rx');

        for i = 1:length(assignment)
            if assignment(i) > 0
                label = labels(assignment(i));
                text(queryPoints(i,1), queryPoints(i,2)+0.008, label, ...
                    'Color','r', 'FontSize', 8, 'HorizontalAlignment','center');
                line([centroids(assignment(i),1), queryPoints(i,1)], ...
                     [centroids(assignment(i),2), queryPoints(i,2)], ...
                     'Color', [0.2 0.6 1], 'LineStyle', '--');
            else
                text(queryPoints(i,1), queryPoints(i,2)+0.008, '?', ...
                    'Color','b', 'FontSize', 8, 'HorizontalAlignment','center');
            end
        end

        legend({'Reference (Labeled)', 'Query (Unlabeled)'});
        hold off;
    end
end
