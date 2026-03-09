function [positions, labels] = extract_labeled_electrodes(chanlocs, excludedLabels)
% EXTRACT_LABELED_ELECTRODES - Extracts labeled 3D points from EEG.chanlocs
%
% Inputs:
%   chanlocs        - Table with columns: labels, X, Y, Z
%   excludedLabels  - Cell array of label strings to exclude (e.g. {'vEOG', 'X', 'Y'})
%
% Outputs:
%   positions       - Nx3 matrix of electrode coordinates
%   labels          - 1xN cell array of label strings

    if nargin < 2
        excludedLabels = {};
    end

    if isstring(chanlocs.labels)
        chanlocs.labels = cellstr(chanlocs.labels);
    end

    % Extract all valid rows
    allLabels = chanlocs.labels;
    isValid = ~cellfun(@isempty, allLabels) & ...
              ~ismember(allLabels, excludedLabels);

    % Apply mask to struct array
    filteredTable = chanlocs(isValid, :);

    % Extract positions and labels
    labels = filteredTable.labels;
    positions = [filteredTable.X, filteredTable.Y, filteredTable.Z];
end
