function cfg = initialize_config(headshape, chanlocs, options)
% INITIALIZE_CONFIG - Initializes a struct to store localization data.
%
% Inputs:
%   headshape         - Struct or object representing the 3D head surface
%   chanlocs          - EEGlab template chanlocs table [Label, X, Y, Z]
%   options           - (Optional) Struct of optional parameters to override defaults:
%                         .chanlocsExcludedLabels
%                         .moveinwards
%                         .anchorLabels
%                         .uvProjectionMethod
%
% Output:
%   cfg               - Configuration struct for electrode localization and labeling.

    if nargin < 3
        options = struct();
    end

    cfg = struct();
    cfg.headshape = headshape;
    cfg.chanlocs = chanlocs;

    % Assign default or user-specified values
    cfg.chanlocsExcludedLabels = get_option(options, 'chanlocsExcludedLabels', ...
        {'vEOG', 'hEOG', 'X', 'Y', 'Z', 'synchTrigger', 'synchBeep', 'Saw'});
    cfg.moveinwards = get_option(options, 'moveinwards', 7);
    cfg.anchorLabels = get_option(options, 'anchorLabels', ...
        {'Iz', 'Fpz', 'Cz', 'T7', 'T8'});
    cfg.uvProjectionMethod = get_option(options, 'uvProjectionMethod', 'stereographic');
    cfg.labelDetectionMethod = get_option(options, 'labelDetectionMethod', 'munkres');
    cfg.capSegmentationMethod = get_option(options, 'capSegmentationMethod', 'highVariance');

    % Initialize remaining fields
    cfg.uv = [];
    cfg.flattenedImage = [];
    cfg.imgCap = [];
    cfg.detectionsUV = [];
    cfg.detectedElectrodeAnchorPointsUV = [];
    cfg.detectedElectrodeAnchorPoints3D = [];
    cfg.detectedElectrodeLabels = [];
    cfg.detectedElectrodePos3D = [];
    cfg.pushedInDetectedElectrodePos3D = [];
    cfg.templateElectrodeLabels = {};
    cfg.templateElectrodePos3D = [];
    cfg.alignmentTransformation = [];
    cfg.coregisteredTemplateElectrodePos3D = [];
    
    % For bookkeeping
    cfg.originalDetectionsUV = [];
    cfg.originalDetectedElectrodePos3D = [];
    cfg.originalDetectedElectrodeLabels = [];
    cfg.detectedCapColor = '';
    
end

function val = get_option(opts, fieldname, default)
    if isfield(opts, fieldname)
        val = opts.(fieldname);
    else
        val = default;
    end
end
