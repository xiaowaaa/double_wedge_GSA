function FigureAudit = write_baseflow_derivative_figures(fig_dir, X, Y, ~, dX)
%WRITE_BASEFLOW_DERIVATIVE_FIGURES Save the requested u_x and u_xx checks.

    if exist(fig_dir, 'dir') ~= 7
        mkdir(fig_dir);
    end

    derivative_label = localize_output_label('baseflow derivative');
    figure_name = sprintf('Fig02_%s_u_x_u_xx.png', ...
        sanitize_output_filename_token(derivative_label));
    output_file = fullfile(fig_dir, figure_name);
    legacy_output_file = fullfile(fig_dir, 'Fig02_BaseflowUxUxx.png');
    if exist(legacy_output_file, 'file') == 2
        delete(legacy_output_file);
    end

    fig = figure('Visible', 'off', 'Position', [80, 80, 1220, 480]);
    cleanup_obj = onCleanup(@() close(fig)); %#ok<NASGU>

    tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

    nexttile;
    local_draw_derivative_field(X, Y, dX.ux, 'u_x');
    hold on;
    plot(X(1, :), Y(1, :), 'k-', 'LineWidth', 1.2);
    title(sprintf('%s: u_x', derivative_label));

    nexttile;
    local_draw_derivative_field(X, Y, dX.uxx, 'u_{xx}');
    hold on;
    plot(X(1, :), Y(1, :), 'k-', 'LineWidth', 1.2);
    title(sprintf('%s: u_{xx}', derivative_label));

    saveas(fig, output_file);

    FigureAudit = struct();
    FigureAudit.output_files = {output_file};
    FigureAudit.figure_name = figure_name;
end

function local_draw_derivative_field(X, Y, field_value, label_text)
%LOCAL_DRAW_DERIVATIVE_FIELD Draw one symmetric derivative contour map.

    vmax = local_percentile(abs(field_value(:)), 99.0);
    if ~(isfinite(vmax) && vmax > 1.0e-30)
        vmax = max(abs(field_value(:)));
    end
    if ~(isfinite(vmax) && vmax > 1.0e-30)
        vmax = 1.0;
    end

    contourf(X, Y, field_value, linspace(-vmax, vmax, 48), 'LineStyle', 'none');
    colormap(gca, local_redblue_colormap(128));
    caxis([-vmax, vmax]);
    colorbar;
    axis tight;
    axis equal;
    box on;
    xlabel('x^{*}', 'Interpreter', 'tex');
    ylabel('y^{*}', 'Interpreter', 'tex');
    title(label_text, 'Interpreter', 'tex');
end

function value = local_percentile(data_value, pct)
%LOCAL_PERCENTILE Toolbox-free percentile helper.

    data_value = sort(data_value(:));
    if isempty(data_value)
        value = 0.0;
        return;
    end

    pct = min(max(pct, 0.0), 100.0);
    idx = 1 + (numel(data_value) - 1) * pct / 100.0;
    i_lo = floor(idx);
    i_hi = ceil(idx);
    if i_lo == i_hi
        value = data_value(i_lo);
    else
        w_hi = idx - i_lo;
        w_lo = 1.0 - w_hi;
        value = w_lo * data_value(i_lo) + w_hi * data_value(i_hi);
    end
end

function cmap = local_redblue_colormap(n)
%LOCAL_REDBLUE_COLORMAP Build one blue-white-red diverging colormap.

    if nargin < 1
        n = 128;
    end
    n = max(2, round(n));
    half = floor(n / 2);
    up = linspace(0.0, 1.0, half).';
    down = linspace(1.0, 0.0, n - half).';
    blue = [up, up, ones(half, 1)];
    red = [ones(n - half, 1), down, down];
    cmap = [blue; red];
end
