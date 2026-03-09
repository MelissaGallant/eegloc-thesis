function assignedLabels = assign_labels_voronoi(centroids, labels, queryPoints, visualize)
% ASSIGN_LABELS_VORONOI - Assigns labels to query points using Voronoi cells from labeled reference points.
%
% Each query point is assigned the label of the reference point whose Voronoi cell it lies in.
% Ambiguities [Case A, B] are handled by marking with '?'.
%
% Inputs:
%   centroids   - Nx2 matrix of labeled reference points.
%   labels      - Nx1 or 1xN string array of labels for the reference points.
%   queryPoints - Mx2 matrix of unlabeled query points to assign.
%   visualize   - (optional) logical flag to enable visualization of results.
%
% Output:
%   assignedLabels - Mx1 string array with labels assigned to each query point,
%                     or '?' for ambiguous cases.

    if nargin < 4, visualize = false; end
    [~, dim] = size(centroids);
    if size(queryPoints,2) ~= dim
        error('centroids and queryPoints must have the same dimensionality.');
    end
    if ~(isstring(labels) || iscellstr(labels))
        error('labels must be a string array or cell array of character vectors.');
    end
    labels = string(labels(:));  % ensure column vector

    numRef = size(centroids,1);
    numQuery = size(queryPoints,1);

    % Add tiny perturbation to avoid Qhull precision errors on co-spherical data
    pert = 1e-6;
    centroids = centroids + pert * randn(size(centroids));

    %% Case A – Multiple query points in one reference Voronoi cell
    queryToRef = dsearchn(centroids, queryPoints);
    refCellCounts = accumarray(queryToRef, 1, [numRef, 1]);
    isAmbigA = refCellCounts(queryToRef) > 1;

    % trace ray backward from centroid to most distant query point
    % to find neighbors that were potentially pushed out of an overfilled cell
    extendedAmbigA = false(numQuery, 1);
    raySegments = [];

    [~, refCells] = voronoin(centroids);
    maxSteps = 80;
    stepSize = 0.01;

    overfilledRefs = find(refCellCounts > 1);
    for rid = overfilledRefs(:)'
        % Find all query points that fell into this overfilled reference cell
        qidx = find(queryToRef == rid);
        if numel(qidx) < 2, continue; end

        % Compute centroid of the reference cell
        verts = refCells{rid};
        if any(verts == 1), continue; end  % skip unbounded cell
        refCenter = centroids(rid, :);

        % Find the query point furthest away from the Voronoi centroid
        distances = vecnorm(queryPoints(qidx,:) - refCenter, 2, 2);
        [~, farIdx] = max(distances);
        farPt = queryPoints(qidx(farIdx), :);

        dir = farPt - refCenter;
        if norm(dir) < 1e-12, continue; end
        dir = dir / norm(dir);

        % Store ray for visualization
        rayEnd = refCenter + maxSteps * stepSize * dir;
        raySegments(end+1, :) = [refCenter, rayEnd];

        lastCell = -1;
        for s = 1:maxSteps
            pt = refCenter + s * stepSize * dir;
            cell = dsearchn(centroids, pt);
            if cell == lastCell || ismember(cell, overfilledRefs), continue; end
            lastCell = cell;
            if any(refCells{cell} == 1), break; end  % stop at unbounded region
            extendedAmbigA(queryToRef == cell) = true;
        end
    end

    %% Case B – Empty reference cells traced using reciprocal Voronoi
    emptyRefCells = find(refCellCounts == 0);

    [queryVerts, queryCells] = voronoin(queryPoints);
    refToQuery = dsearchn(queryPoints, centroids);
    queryCellCounts = accumarray(refToQuery, 1, [numQuery, 1]);
    reciprocalSharedCells = find(queryCellCounts >= 2);

    isAmbigB = false(numQuery, 1);

    for qi = reciprocalSharedCells'
        refIDs = find(refToQuery == qi);
        refEmpty = intersect(refIDs, emptyRefCells);
        refValid = setdiff(refIDs, emptyRefCells);
        if isempty(refEmpty) || isempty(refValid), continue; end

        verts = queryCells{qi};
        if any(verts == 1), continue; end  % skip unbounded cell
        center = queryPoints(qi, :);

        for rid = refEmpty(:)'  % iterate over empty reference points in this query cell
            target = centroids(rid,:);
            start = centroids(refValid(1),:);
            dir = center - start;
            if norm(dir) < 1e-12, continue; end
            dir = dir / norm(dir);

            % Store ray for visualization
            rayEnd = target + maxSteps * stepSize * dir;
            raySegments(end+1, :) = [target, rayEnd];

            lastCell = -1;
            for s = 1:maxSteps
                pt = target + s * stepSize * dir;
                cell = dsearchn(centroids, pt);
                if cell == lastCell || ismember(cell, emptyRefCells), continue; end
                lastCell = cell;
                if any(refCells{cell} == 1), break; end  % stop at unbounded region
                isAmbigB(queryToRef == cell) = true;
            end
        end
    end

    %% Final label assignment
    isAmbiguous = isAmbigA | isAmbigB | extendedAmbigA;
    assignedLabels = labels(queryToRef);
    assignedLabels(isAmbiguous) = "?";

    %% Visualization (optional)
    if visualize
        figure('Color','w'); hold on; axis equal; grid on;
        title('Voronoi Labeling with Ambiguities');

        [vx, vy] = voronoi(centroids(:,1), centroids(:,2));
        plot(vx, vy, 'k-');
        plot(centroids(:,1), centroids(:,2), 'ko', 'MarkerFaceColor', [0.6 0.6 0.6]);

        for i = 1:numQuery
            pt = queryPoints(i,:);
            if assignedLabels(i) == "?"
                plot(pt(1), pt(2), 'bx', 'LineWidth', 1.5, 'MarkerSize', 8);
                text(pt(1), pt(2)+0.008, '?', 'Color','b', 'FontSize', 8, ...
                     'FontWeight','bold', 'HorizontalAlignment','center');
            else
                plot(pt(1), pt(2), 'rx', 'LineWidth', 1.5, 'MarkerSize', 8);
                text(pt(1), pt(2)+0.008, assignedLabels(i), 'Color','r', 'FontSize', 8, ...
                     'HorizontalAlignment','center');
            end
        end

        for i = 1:size(raySegments,1)
            line(raySegments(i,[1 3]), raySegments(i,[2 4]), ...
                'Color', [0.2 0.6 1], 'LineStyle', '--', 'LineWidth', 1.2);
        end

        allPts = [centroids; queryPoints];
        minXY = min(allPts, [], 1);
        maxXY = max(allPts, [], 1);
        padding = 0.03;

        xlim([minXY(1)-padding, maxXY(1)+padding]);
        ylim([minXY(2)-padding, maxXY(2)+padding]);

        set(gca, 'LooseInset', [0 0 0 0]);
        hold off;       
    end
end
