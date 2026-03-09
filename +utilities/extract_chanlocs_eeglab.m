function outTable = extract_chanlocs_eeglab(setFilePath, outCsvPath)
% EXTRACT_CHANLOCS_EEGLAB - Extract 3D chanlocs (labels, X, Y, Z) from an EEGLAB .set file.
%
% outTable = utils.extract_chanlocs_eeglab()
% outTable = utils.extract_chanlocs_eeglab(setFilePath)
% outTable = utils.extract_chanlocs_eeglab(setFilePath, outCsvPath)
%
% Inputs (optional)
%   setFilePath : path to an EEGLAB .set file. If omitted or empty, uses
%                 <EEGLAB_DIR>/sample_data/eeglab_data.set
%   outCsvPath  : output CSV path. If omitted or empty, uses fullfile('chanlocs.csv')
%
% Output
%   outTable    : table with variables: labels, X, Y, Z
%
% Notes
% - Requires EEGLAB on the MATLAB path.
% - Only channels with non-empty X/Y/Z coordinates are exported.

    if nargin < 1 || isempty(setFilePath)
        eeglabMPath = which('eeglab.m');
        if isempty(eeglabMPath)
            error('EEGLAB not found on the MATLAB path. Please add EEGLAB to the path first.');
        end

        eeglabDir = fileparts(eeglabMPath);
        setFilePath = fullfile(eeglabDir, 'sample_data', 'eeglab_data.set');

        if exist(setFilePath, 'file') ~= 2
            error('Default EEGLAB sample dataset not found at: %s', setFilePath);
        end
    else
        if exist(setFilePath, 'file') ~= 2
            error('SET file not found: %s', setFilePath);
        end
    end

    if nargin < 2 || isempty(outCsvPath)
        outCsvPath = fullfile('chanlocs.csv');
    end

    % Ensure output folder exists (if a folder is provided)
    outDir = fileparts(outCsvPath);
    if ~isempty(outDir) && exist(outDir, 'dir') ~= 7
        mkdir(outDir);
    end

    % Initialize EEGLAB (needed for pop_* functions and internal globals)
    % Using 'nogui' keeps it lightweight for scripts.
    try
        eeglab('nogui');
    catch ME
        error('Failed to initialize EEGLAB: %s', ME.message);
    end

    % Load dataset
    EEG = pop_loadset('filename', setFilePath);

    if ~isfield(EEG, 'chanlocs') || isempty(EEG.chanlocs)
        error('Dataset has no chanlocs: %s', setFilePath);
    end

    % Extract channels with valid X/Y/Z
    labels = {};
    X = [];
    Y = [];
    Z = [];

    for i = 1:numel(EEG.chanlocs)
        ch = EEG.chanlocs(i);

        hasX = isfield(ch, 'X') && ~isempty(ch.X) && ~isnan(ch.X);
        hasY = isfield(ch, 'Y') && ~isempty(ch.Y) && ~isnan(ch.Y);
        hasZ = isfield(ch, 'Z') && ~isempty(ch.Z) && ~isnan(ch.Z);

        if hasX && hasY && hasZ
            if isfield(ch, 'labels') && ~isempty(ch.labels)
                labels{end+1, 1} = ch.labels;
            else
                labels{end+1, 1} = sprintf('Ch%d', i);
            end

            X(end+1, 1) = ch.X;
            Y(end+1, 1) = ch.Y;
            Z(end+1, 1) = ch.Z;
        end
    end

    if isempty(labels)
        error('No channels with valid X/Y/Z coordinates were found in: %s', setFilePath);
    end

    outTable = table(labels, X, Y, Z, 'VariableNames', {'labels','X','Y','Z'});

    % Write CSV
    writetable(outTable, outCsvPath);
end
