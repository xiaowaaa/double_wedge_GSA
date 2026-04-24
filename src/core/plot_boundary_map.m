function output_file = plot_boundary_map(X, Y, config, varargin)
%PLOT_BOUNDARY_MAP Render a simple boundary-label diagnostic figure.

    p = inputParser;
    p.FunctionName = 'plot_boundary_map';
    addParameter(p, 'OutputFile', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'Visible', 'off', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'Verbose', true, @(x) islogical(x) && isscalar(x));
    parse(p, varargin{:});

    audit_label = localize_output_label('boundary audit');
    output_file = char(string(p.Results.OutputFile));
    if isempty(output_file)
        output_file = fullfile(pwd, sprintf('%s.png', ...
            sanitize_output_filename_token(audit_label)));
    end
    legacy_output_file = fullfile(fileparts(output_file), 'boundary_audit.png');
    if exist(legacy_output_file, 'file') == 2
        delete(legacy_output_file);
    end

    [mask, ~] = build_boundary_masks(X, Y, config, 'Verbose', false);
    labels = zeros(size(X));
    labels(mask.symmetry) = 1;
    labels(mask.wall) = 2;
    labels(mask.inlet) = 3;
    labels(mask.outlet) = 4;
    labels(mask.farfield) = 5;

    out_dir = fileparts(output_file);
    if ~isempty(out_dir) && exist(out_dir, 'dir') ~= 7
        mkdir(out_dir);
    end

    fig = figure('Visible', char(string(p.Results.Visible)));
    cleanup_fig = onCleanup(@() close(fig)); %#ok<NASGU>
    imagesc(labels);
    axis image tight;
    title(audit_label);
    xlabel('i');
    ylabel('j');
    colorbar;
    saveas(fig, output_file);

    if p.Results.Verbose
        fprintf('[plot_boundary_map] wrote %s\n', output_file);
    end
end
