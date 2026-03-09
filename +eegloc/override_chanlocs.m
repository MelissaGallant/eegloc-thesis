function cfg = override_chanlocs(cfg)
% OVERRIDE_CHANLOCS - Update the chanlocs with newly detected positions
%
% Inputs:
%   cfg - Configuration struct for electrode localization and labeling.
%
% Output:
%   cfg - Updated configuration struct.

    import eegloc.algorithms.*
    import eegloc.plotting.*

    % Use the detected (raw) electrode positions directly
    updatedPos = cfg.pushedInDetectedElectrodePos3D;

    % Convert all labels to char for matching.
    % Use cfg.chanlocs as original labels as they preserve all omitted labels
    origLabels = cellfun(@char, cfg.chanlocs.labels(:), 'UniformOutput', false);
    detectedLabels = cellfun(@char, cfg.detectedElectrodeLabels(:), 'UniformOutput', false);

    for j = 1:length(detectedLabels)
        label = detectedLabels{j};
        idx = find(strcmp(origLabels, label), 1);
    
        if ~isempty(idx)
            cfg.chanlocs.X(idx) = updatedPos(j,1);
            cfg.chanlocs.Y(idx) = updatedPos(j,2);
            cfg.chanlocs.Z(idx) = updatedPos(j,3);
        else
            warning('Label "%s" not found in chanlocs. Skipping.', label);
        end
    end

    plot_cap_registration(updatedPos, cfg.coregisteredTemplateElectrodePos3D, {'Detected Electrodes', 'Registered Template Electrodes'})

end
