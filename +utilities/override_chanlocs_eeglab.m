function EEG = override_chanlocs_eeglab(EEG, chanlocs_input)
% OVERRIDE_CHANLOCS_EEGLAB Override EEG.chanlocs coordinates from a table or text file.
%
%   EEG = override_chanlocs(EEG, chanlocs_input)
%
% Inputs
%   EEG            EEGLAB EEG struct with existing EEG.chanlocs
%
%   chanlocs_input Either:
%                  1) a table with variables: labels, X, Y, Z
%                  2) a path to a .txt file readable by readlocs using:
%                     'filetype','custom','format',{'labels','X','Y','Z'}
%
% Behavior
%   - Updates only channels whose labels exist in both EEG.chanlocs and the
%     provided chanlocs source
%   - Ignores fiducials named: nas, lpa, rpa
%   - Leaves unmatched EEG channels unchanged (e.g. EOG1/EOG2 if missing
%     from the input source)
%   - Matches labels case-insensitively
%
% Example
%   EEG = override_chanlocs(EEG, 'new_chanlocs.txt');
%
%   T = readtable('chanlocs.csv');
%   EEG = override_chanlocs(EEG, T);

    if ~isstruct(EEG) || ~isfield(EEG, 'chanlocs')
        error('First input must be an EEG struct containing EEG.chanlocs.');
    end

    newlocs = parse_chanlocs_input(chanlocs_input);
    newlocs = validate_and_clean_newlocs(newlocs);

    if isempty(newlocs)
        warning('No valid channel locations found after filtering.');
        return;
    end

    eeg_labels = {EEG.chanlocs.labels};
    new_labels = {newlocs.labels};

    [is_match, idx_new] = ismember(lower(strtrim(eeg_labels)), lower(strtrim(new_labels)));

    for k = find(is_match)
        EEG.chanlocs(k).X = newlocs(idx_new(k)).X;
        EEG.chanlocs(k).Y = newlocs(idx_new(k)).Y;
        EEG.chanlocs(k).Z = newlocs(idx_new(k)).Z;
    end

    % Recompute other location representations if available
    try
        EEG.chanlocs = convertlocs(EEG.chanlocs, 'cart2all');
    catch
    end

    try
        EEG = eeg_checkset(EEG);
    catch
    end
end


function newlocs = parse_chanlocs_input(chanlocs_input)
    if istable(chanlocs_input)
        newlocs = table_to_struct(chanlocs_input);

    elseif ischar(chanlocs_input) || (isstring(chanlocs_input) && isscalar(chanlocs_input))
        chanlocs_path = char(chanlocs_input);

        if ~exist(chanlocs_path, 'file')
            error('File not found: %s', chanlocs_path);
        end

        newlocs = readlocs(chanlocs_path, ...
            'filetype', 'custom', ...
            'format', {'labels','X','Y','Z'});

    else
        error(['chanlocs_input must be either a table or a file path ' ...
               'to a chanlocs text file.']);
    end
end


function newlocs = table_to_struct(T)
    required_vars = {'labels','X','Y','Z'};
    missing = required_vars(~ismember(required_vars, T.Properties.VariableNames));

    if ~isempty(missing)
        error('Input table is missing required columns: %s', strjoin(missing, ', '));
    end

    n = height(T);
    newlocs = repmat(struct('labels', '', 'X', [], 'Y', [], 'Z', []), n, 1);

    for i = 1:n
        lbl = T.labels(i);

        if iscell(lbl)
            lbl = lbl{1};
        end
        if isstring(lbl)
            lbl = char(lbl);
        end

        newlocs(i).labels = strtrim(lbl);
        newlocs(i).X = T.X(i);
        newlocs(i).Y = T.Y(i);
        newlocs(i).Z = T.Z(i);
    end
end


function newlocs = validate_and_clean_newlocs(newlocs)
    if ~isstruct(newlocs)
        error('Parsed channel locations must be a struct array.');
    end

    required_fields = {'labels','X','Y','Z'};
    for f = 1:numel(required_fields)
        if ~isfield(newlocs, required_fields{f})
            error('Channel location struct is missing field "%s".', required_fields{f});
        end
    end

    % Remove fiducials from newchanlocs if present
    remove_mask = ismember(lower(strtrim({newlocs.labels})), {'nas','lpa','rpa'});
    newlocs = newlocs(~remove_mask);

    % Remove empty labels
    empty_mask = cellfun(@isempty, strtrim({newlocs.labels}));
    newlocs = newlocs(~empty_mask);

    % Remove rows with invalid coordinates
    valid_mask = true(1, numel(newlocs));
    for i = 1:numel(newlocs)
        valid_mask(i) = isnumeric(newlocs(i).X) && isscalar(newlocs(i).X) && ~isnan(newlocs(i).X) && ...
                        isnumeric(newlocs(i).Y) && isscalar(newlocs(i).Y) && ~isnan(newlocs(i).Y) && ...
                        isnumeric(newlocs(i).Z) && isscalar(newlocs(i).Z) && ~isnan(newlocs(i).Z);
    end
    newlocs = newlocs(valid_mask);

    % Keep the first occurrence if duplicate labels are present
    labels_lower = lower(strtrim({newlocs.labels}));
    [~, first_idx] = unique(labels_lower, 'stable');
    newlocs = newlocs(sort(first_idx));
end
