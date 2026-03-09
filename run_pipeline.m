function [chanlocs, cfg] = run_pipeline(headshapePath, templateChanlocsPath, outChanlocsPath, opts)
% RUN_PIPELINE - Run the electrode localization pipeline (automatic electrode detection + labeling).
%
% Usage:
%   chanlocs = run_pipeline(headshapePath, templateChanlocsPath)
%   chanlocs = run_pipeline(headshapePath, templateChanlocsPath, outChanlocsPath)
%   chanlocs = run_pipeline(headshapePath, templateChanlocsPath, outChanlocsPath, opts)
%   [chanlocs, cfg] = run_pipeline(...)
%
% Inputs:
%   headshapePath         : path to headshape.mat containing variable 'headshape'
%   templateChanlocsPath  : path to template_chanlocs.csv (readtable-compatible)
%   outChanlocsPath       : optional output file path (default: fullfile('new_chanlocs.txt'))
%   opts                  : optional opts struct passed to eegloc.initialize_config
%                           (default: moveinwards=7, capSegmentationMethod='')
%
% Outputs:
%   chanlocs : cfg.chanlocs (struct array, suitable for EEG.chanlocs in EEGLAB)
%   cfg      : full pipeline cfg struct

    if nargin < 1 || isempty(headshapePath)
        error('headshapePath is required.');
    end
    if nargin < 2 || isempty(templateChanlocsPath)
        error('templateChanlocsPath is required.');
    end
    if exist(headshapePath, 'file') ~= 2
        error('Headshape file not found: %s', headshapePath);
    end
    if exist(templateChanlocsPath, 'file') ~= 2
        error('Template chanlocs file not found: %s', templateChanlocsPath);
    end

    if nargin < 3 || isempty(outChanlocsPath)
        outChanlocsPath = fullfile('new_chanlocs.txt');
    end

    if nargin < 4 || isempty(opts)
        opts = struct();
        opts.moveinwards = 7;
        opts.capSegmentationMethod = '';
        % opts.uvProjectionMethod = 'lambert';
        % opts.labelDetectionMethod = 'voronoi';
    else
        % Ensure defaults exist if user passes partial opts
        if ~isfield(opts, 'moveinwards'), opts.moveinwards = 7; end
        if ~isfield(opts, 'capSegmentationMethod'), opts.capSegmentationMethod = ''; end
    end

    % Ensure output directory exists (if a folder is provided)
    outDir = fileparts(outChanlocsPath);
    if ~isempty(outDir) && exist(outDir, 'dir') ~= 7
        mkdir(outDir);
    end

    % Load headshape (expects variable named 'headshape')
    S = load(headshapePath);
    if ~isfield(S, 'headshape')
        error('Expected variable ''headshape'' in MAT file: %s', headshapePath);
    end
    headshape = S.headshape;

    % Load template chanlocs table
    templateChanlocs = readtable(templateChanlocsPath);

    % Run pipeline
    cfg = eegloc.initialize_config(headshape, templateChanlocs, opts);
    cfg = eegloc.detect_electrode_positions(cfg);
    cfg = eegloc.coregister_template(cfg);
    cfg = eegloc.detect_labels(cfg);
    cfg = eegloc.shift_electrodes_inwards(cfg);
    cfg = eegloc.override_chanlocs(cfg);

    % Export chanlocs
    eegloc.export_chanlocs(cfg, outChanlocsPath);

    % Return chanlocs for direct EEGLAB override
    if ~isfield(cfg, 'chanlocs') || isempty(cfg.chanlocs)
        error('Pipeline completed but cfg.chanlocs is missing or empty.');
    end
    chanlocs = cfg.chanlocs;
end