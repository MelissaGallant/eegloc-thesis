function export_chanlocs(cfg, name)
% EXPORT_CHANLOCS - Export electrode and fiducial locations to file
%   cfg  - configuration structure containing chanlocs and headshape info
%   name - name of the file to be saved (e.g., 'chanlocs.txt')

    fiducials = cfg.headshape.cfg.fiducial;
    T = cfg.headshape.cfg.transform;
    rotatedFiducials = [[fiducials.nas; fiducials.lpa; fiducials.rpa], ones(3,1)] * T';
    rotatedFiducials(:,end) = []; % remove homogeneous coords

    % Export from final chanlocs table
    labels = cfg.chanlocs.labels(:);
    pos = [cfg.chanlocs.X, cfg.chanlocs.Y, cfg.chanlocs.Z];

    % Append fiducials for usage in, e.g., EEGLAB's dipfit
    labels(end+1:end+3,1) = {'nas'; 'lpa'; 'rpa'};
    pos(end+1:end+3,:) = rotatedFiducials;

    file = fopen(name, 'w');
    v = ver('Matlab');

    if str2double(v.Version) >= 9.1
        fprintf(file, '%6s %9.4f %9.4f %9.4f\n', [string(labels') ; pos(:,:)']);
    else
        for i = 1:length(labels)
            fprintf(file, '%6s %9.4f %9.4f %9.4f\n', labels{i}, pos(i,:));
        end
    end

    fclose(file);
end
