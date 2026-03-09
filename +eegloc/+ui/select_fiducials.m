function fiducials = select_fiducials(headshape, initialFiducials, fiducialNames)
% SELECT_FIDUCIALS - Interactive UI for placing fiducials on a FieldTrip headshape
%
% Input:
%   headshape - Struct with fields:
%       .pos         - Nx3 vertex coordinates
%       .tri         - Mx3 face indices
%       .color       - Nx1 color data
%   fiducialNames - (optional) cell array of fiducial names to place
%
% Output:
%   fiducials     - Struct with fields for each placed fiducial

    if nargin < 2
        initialFiducials = struct();
    end
    if nargin < 3 || isempty(fiducialNames)
        fiducialNames = {'nas', 'lhj', 'rhj'};
    end
    
    placedFiducials = struct();
    remaining = fiducialNames(:);
    selectedFiducial = '';
    highlightedFid = '';
    camLightHandle = [];

    hFig = figure('Name','Label Fiducials','NumberTitle','off',...
        'WindowKeyPressFcn',@onKeyPress,...
        'WindowButtonDownFcn',@onClick,...
        'CloseRequestFcn',@onClose,...
        'Units','normalized','Position',[0.1,0.1,0.8,0.8]);

    ax = axes('Parent', hFig, 'Position', [0.05, 0.15, 0.65, 0.8]);
    hold(ax, 'on'); rotate3d(ax, 'on');

    trisurf(headshape.tri, ...
        headshape.pos(:,1), headshape.pos(:,2), headshape.pos(:,3), ...
        'FaceVertexCData', headshape.color, ...
        'FaceColor', 'interp', ...
        'EdgeColor', 'none', ...
        'FaceAlpha', 1.0, ...
        'Parent', ax);
    lighting(ax, 'none');  % Default: lighting off
    axis(ax, 'equal'); axis(ax, 'off');
    title(ax, 'Toggle Edit Mode to place/delete fiducials, or View Mode to rotate', 'FontSize', 11);

    listBox = uicontrol('Style','listbox',...
        'String', remaining,...
        'Units','normalized','Position',[0.75 0.3 0.2 0.6],...
        'FontSize',12,...
        'Enable','off',...
        'Callback',@onSelectFiducial);

    toggleBox = uicontrol('Style','togglebutton',...
        'String','Edit Mode Off',...
        'Units','normalized',...
        'Position',[0.75 0.2 0.2 0.05],...
        'FontSize',12,...
        'Value',0,...
        'Callback',@onToggleMode);

    lightToggle = uicontrol('Style','togglebutton', ...
        'String','Lighting Off', ...
        'Units','normalized', ...
        'Position',[0.75 0.13 0.2 0.05], ...
        'FontSize',12, ...
        'Value',0, ...
        'Callback',@onToggleLighting);

    markers = containers.Map();
    highlightHandle = [];
    

    initialNames = fieldnames(initialFiducials);
    for k = 1:numel(initialNames)
        fname = initialNames{k};
        if ismember(fname, fiducialNames)
            p = initialFiducials.(fname);
            h = plot3(ax, p(1), p(2), p(3), ...
                'ro', 'MarkerSize', 10, 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
            markers(fname) = h;
            placedFiducials.(fname) = p;
            remaining(strcmp(remaining, fname)) = [];  % remove from remaining
        end
    end
    
    if ~isempty(remaining)
        set(listBox, 'String', remaining, 'Value', 1);
        selectedFiducial = remaining{1};
    else
        set(listBox, 'String', {}, 'Value', []);
        selectedFiducial = '';
    end


    function onToggleMode(src, ~)
        if src.Value == 1
            rotate3d(ax, 'off');
            set(listBox, 'Enable', 'on');
            set(hFig, 'Pointer', 'crosshair');
            set(src, 'String', 'Edit Mode On');

            listItems = listBox.String;
            selectedIdx = listBox.Value;
            if ~isempty(listItems) && ~isempty(selectedIdx) && selectedIdx <= numel(listItems)
                selectedFiducial = listItems{selectedIdx};
            else
                selectedFiducial = '';
            end
        else
            rotate3d(ax, 'on');
            set(listBox, 'Enable', 'off');
            set(hFig, 'Pointer', 'arrow');
            set(src, 'String', 'Edit Mode Off');
            selectedFiducial = '';
            remove_highlight();
        end
    end

    function onToggleLighting(src, ~)
        if src.Value == 1
            lighting(ax, 'gouraud');
            if isempty(camLightHandle) || ~isvalid(camLightHandle)
                camLightHandle = camlight(ax, 'headlight');
            end
            set(src, 'String', 'Lighting On');
        else
            if isvalid(camLightHandle)
                delete(camLightHandle);
                camLightHandle = [];
            end
            lighting(ax, 'none');
            set(src, 'String', 'Lighting Off');
        end
    end

    function onSelectFiducial(src, ~)
        items = src.String;
        idx = src.Value;
        if isempty(items) || isempty(idx) || idx > numel(items)
            selectedFiducial = '';
        else
            selectedFiducial = items{idx};
        end
    end

    function onClick(~, ~)
        if ~toggleBox.Value, return; end

        [pIntersect, hit] = getClickedSurfacePoint(ax, headshape.pos, headshape.tri);

        if ~hit
            return;
        end

        [clickedMarker, dist] = findNearestMarker(pIntersect);
        if dist < 10
            highlight_point(clickedMarker);
            return;
        end

        if isempty(selectedFiducial)
            warndlg('Please select a fiducial label from the list first.', 'No Fiducial Selected');
            return;
        end

        h = plot3(ax, pIntersect(1), pIntersect(2), pIntersect(3), ...
                  'ro', 'MarkerSize', 10, 'LineWidth', 1.5, ...
                  'MarkerFaceColor', 'r');
        markers(selectedFiducial) = h;
        placedFiducials.(selectedFiducial) = pIntersect;

        idx = find(strcmp(remaining, selectedFiducial));
        remaining(idx) = [];
        set(listBox, 'String', remaining);

        if ~isempty(remaining)
            set(listBox, 'Value', 1);
            selectedFiducial = remaining{1};
        else
            set(listBox, 'Value', []);
            selectedFiducial = '';
        end
        remove_highlight();
    end

    function onKeyPress(~, event)
        if strcmp(event.Key, 'return')
            uiresume(hFig);

        elseif strcmp(event.Key, 'delete') || strcmp(event.Key, 'backspace')
            if isempty(highlightedFid), return; end
            if isKey(markers, highlightedFid)
                delete(markers(highlightedFid));
                markers.remove(highlightedFid);
            end
            if isfield(placedFiducials, highlightedFid)
                placedFiducials = rmfield(placedFiducials, highlightedFid);
            end

            remaining{end+1} = highlightedFid;
            remaining = sort(remaining);
            set(listBox, 'String', remaining);

            idx = find(strcmp(remaining, highlightedFid));
            if ~isempty(idx)
                set(listBox, 'Value', idx);
                selectedFiducial = highlightedFid;
            else
                set(listBox, 'Value', []);
                selectedFiducial = '';
            end
            remove_highlight();
        end
    end

    function onClose(~, ~)
        uiresume(hFig);
        if isvalid(hFig)
            delete(hFig);
        end
    end

    function [closestName, minDist] = findNearestMarker(pt)
        closestName = '';
        minDist = inf;
        for k = keys(markers)
            name = k{1};
            p = placedFiducials.(name);
            dist = norm(p - pt);
            if dist < minDist
                minDist = dist;
                closestName = name;
            end
        end
    end

    function highlight_point(name)
        remove_highlight();
        p = placedFiducials.(name);
        highlightHandle = plot3(ax, p(1), p(2), p(3), ...
            'go', 'MarkerSize', 14, 'LineWidth', 2, 'MarkerFaceColor', 'none');
        highlightedFid = name;
    end

    function remove_highlight()
        if ~isempty(highlightHandle) && isvalid(highlightHandle)
            delete(highlightHandle);
        end
        highlightHandle = [];
        highlightedFid = '';
    end

    onToggleMode(toggleBox);  % Apply initial view mode settings (Edit Mode Off)
    uiwait(hFig);
    if ishandle(hFig)
        close(hFig);
    end
    fiducials = placedFiducials;
end


function [closestPoint, success] = getClickedSurfacePoint(ax, vertices, faces)
    cp = get(ax, 'CurrentPoint');
    rayOrigin = cp(1, :);
    rayDirection = cp(2,:) - cp(1,:);
    rayDirection = rayDirection / norm(rayDirection);

    v0 = vertices(faces(:,1), :);
    v1 = vertices(faces(:,2), :);
    v2 = vertices(faces(:,3), :);

    eps = 1e-5;
    edge1 = v1 - v0;
    edge2 = v2 - v0;
    h = cross(repmat(rayDirection, size(edge2,1), 1), edge2, 2);
    a = dot(edge1, h, 2);

    mask = abs(a) > eps;
    if ~any(mask)
        closestPoint = [NaN NaN NaN];
        success = false;
        return;
    end

    f = 1 ./ a(mask);
    s = rayOrigin - v0(mask,:);
    u = f .* dot(s, h(mask,:), 2);

    q = cross(s, edge1(mask,:), 2);
    v = f .* dot(repmat(rayDirection, sum(mask), 1), q, 2);
    t = f .* dot(edge2(mask,:), q, 2);

    valid = u >= 0 & v >= 0 & (u + v) <= 1 & t > 0;
    if ~any(valid)
        closestPoint = [NaN NaN NaN];
        success = false;
        return;
    end

    t = t(valid);
    u = u(valid);
    v = v(valid);
    validMaskIdx = find(mask);
    triIdx = validMaskIdx(valid);

    [~, i] = min(t);
    tri = faces(triIdx(i), :);
    bary = [1 - u(i) - v(i), u(i), v(i)];
    closestPoint = bary(1) * vertices(tri(1), :) + ...
                   bary(2) * vertices(tri(2), :) + ...
                   bary(3) * vertices(tri(3), :);
    success = true;
end
