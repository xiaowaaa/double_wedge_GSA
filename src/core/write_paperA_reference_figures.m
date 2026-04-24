function FigureAudit = write_paperA_reference_figures(fig_dir, ranking, data, Config, plot_phase_factor_s, PhaseAudit_s)
%WRITE_PAPERA_REFERENCE_FIGURES Write the retained Paper-A figures plus Sidharth figures.

    if exist(fig_dir, 'dir') ~= 7
        mkdir(fig_dir);
    end

    local_cleanup_legacy_outputs(fig_dir);

    EigVals_s = ranking.EigVals;
    EigVecs_plot_s = bsxfun(@times, ranking.EigVecs, reshape(plot_phase_factor_s, 1, []));
    res_s = ranking.residuals;
    freq_signed_s = ranking.freq_info.freq_nd_signed(ranking.order);
    bubble_mask = local_get_mask(data, 'bubble_core_mask', 'bubble_mask');
    bubble_window = local_get_bubble_window(data.GeometryAudit, data.X, data.Y);
    bubble_focus_window = local_get_bubble_focus_window(data, bubble_mask, bubble_window);
    [lead_plot_idx, lead_plot_audit] = select_paperA_plot_lead_index(ranking);
    plot_mode_indices = find(ranking.selected_for_plots);

    spectrum_file = local_figure_output_file(fig_dir, 'spectrum');
    raw_file = local_figure_output_file(fig_dir, 'raw_uvpt');
    bubble_file = local_figure_output_file(fig_dir, 'bubble_uvpt');
    local_write_eigenspectrum_figure(spectrum_file, EigVals_s, lead_plot_idx, plot_mode_indices);
    output_files = {spectrum_file};
    num_gallery_pages = 0;
    sidharth_output_files = {};
    sidharth_audit = local_default_sidharth_audit();
    sidharth_gallery_pages = 0;
    if local_has_valid_mode_index(lead_plot_idx, numel(EigVals_s))
        q_lead_plot = EigVecs_plot_s(:, lead_plot_idx);
        local_write_raw_normalized_cloud_figure( ...
            raw_file, q_lead_plot, EigVals_s(lead_plot_idx), ...
            freq_signed_s(lead_plot_idx), res_s(lead_plot_idx), data.X, data.Y, ...
            data.RHO, Config.Cv_nd, Config.state_layout, bubble_mask);
        local_write_uvpt_bubble_figure( ...
            bubble_file, q_lead_plot, EigVals_s(lead_plot_idx), ...
            freq_signed_s(lead_plot_idx), res_s(lead_plot_idx), data.X, data.Y, ...
            data.U, data.V, data.RHO, Config.Cv_nd, Config.state_layout, ...
            bubble_mask, bubble_focus_window, data.GeometryAudit);
        num_gallery_pages = local_write_all_modes_u_gallery( ...
            fig_dir, EigVecs_plot_s, EigVals_s, freq_signed_s, res_s, data.X, data.Y, ...
            data.RHO, Config.Cv_nd, Config.state_layout, bubble_mask);
        output_files = {spectrum_file, raw_file, bubble_file};
        for page = 1:num_gallery_pages
            output_files{end + 1} = local_figure_output_file(fig_dir, 'u_gallery_page', page); %#ok<AGROW>
        end

        if local_write_sidharth_contract(Config)
            [sidharth_output_files, sidharth_gallery_pages, sidharth_audit] = local_write_sidharth_figures( ...
                fig_dir, lead_plot_idx, plot_mode_indices, EigVecs_plot_s, EigVals_s, ...
                freq_signed_s, res_s, data, Config, bubble_mask, bubble_focus_window);
        end
    end

    FigureAudit = struct();
    FigureAudit.lead_plot_index = lead_plot_idx;
    FigureAudit.status = lead_plot_audit.status;
    FigureAudit.output_files = output_files;
    FigureAudit.num_gallery_pages = num_gallery_pages;
    FigureAudit.sidharth_output_files = sidharth_output_files;
    FigureAudit.sidharth_gallery_pages = sidharth_gallery_pages;
    FigureAudit.sidharth_component_contract = sidharth_audit.component_contract;
    FigureAudit.sidharth_displayed_components = sidharth_audit.displayed_components;
    FigureAudit.sidharth_common_plot_window = sidharth_audit.common_plot_window;
    FigureAudit.sidharth_gallery_component = sidharth_audit.gallery_component;
    FigureAudit.primary_plot_contract = local_get_string_field(Config, 'plot_contract', '');
    FigureAudit.secondary_plot_contract = local_get_string_field(Config, 'secondary_plot_contract', '');

    if isfield(Config, 'plot_debug_mode_diagnosis') && Config.plot_debug_mode_diagnosis
        save(fullfile(fig_dir, 'PhaseAudit_debug.mat'), 'PhaseAudit_s');
    end
end

function local_cleanup_legacy_outputs(fig_dir)
%LOCAL_CLEANUP_LEGACY_OUTPUTS Remove old retained outputs before writing new ones.

    patterns = { ...
        'Fig13_*.png', ...
        'Fig18_*.png', ...
        'Fig19_*.png', ...
        'Fig20_*.png', ...
        'Fig21_*.png', ...
        'Fig22_*.png', ...
        'Sidharth_Fig*.png'};
    for k = 1:numel(patterns)
        files = dir(fullfile(fig_dir, patterns{k}));
        for f = 1:numel(files)
            delete(fullfile(fig_dir, files(f).name));
        end
    end
end

function local_write_eigenspectrum_figure(output_file, EigVals_s, lead_plot_idx, plot_mode_indices)
%LOCAL_WRITE_EIGENSPECTRUM_FIGURE Save the full spectrum and one zoom panel.

    fig = figure('Visible', 'off', 'Position', [80, 80, 1100, 430]);
    cleanup_obj = onCleanup(@() close(fig)); %#ok<NASGU>
    local_configure_figure_font(fig);
    sigma_r = real(EigVals_s);
    sigma_i = imag(EigVals_s);

    subplot(1, 2, 1);
    scatter(sigma_r, sigma_i, 24, [0.25, 0.25, 0.25], 'filled');
    hold on;
    if ~isempty(plot_mode_indices)
        scatter(sigma_r(plot_mode_indices), sigma_i(plot_mode_indices), 48, [0.10, 0.35, 0.80], 'filled');
    end
    if local_has_valid_mode_index(lead_plot_idx, numel(EigVals_s))
        scatter(sigma_r(lead_plot_idx), sigma_i(lead_plot_idx), 80, [0.85, 0.20, 0.15], 'filled');
    end
    yline(0.0, 'k--', 'LineWidth', 0.8);
    local_annotate_modes(sigma_r, sigma_i, plot_mode_indices);
    if local_has_valid_mode_index(lead_plot_idx, numel(EigVals_s))
        text(sigma_r(lead_plot_idx), sigma_i(lead_plot_idx), '  主模态', ...
            'Color', [0.75, 0.10, 0.05], 'FontWeight', 'bold', 'Interpreter', 'none');
        title('特征值谱', 'Interpreter', 'none');
    else
        title('特征值谱（无可绘制物理模态）', 'Interpreter', 'none');
    end
    xlabel('sigma_r', 'Interpreter', 'none');
    ylabel('sigma_i', 'Interpreter', 'none');
    grid on;
    box on;

    subplot(1, 2, 2);
    scatter(sigma_r, sigma_i, 20, [0.60, 0.60, 0.60], 'filled');
    hold on;
    if ~isempty(plot_mode_indices)
        scatter(sigma_r(plot_mode_indices), sigma_i(plot_mode_indices), 54, [0.10, 0.35, 0.80], 'filled');
    end
    if local_has_valid_mode_index(lead_plot_idx, numel(EigVals_s))
        scatter(sigma_r(lead_plot_idx), sigma_i(lead_plot_idx), 90, [0.85, 0.20, 0.15], 'filled');
    end
    yline(0.0, 'k--', 'LineWidth', 0.8);
    local_annotate_modes(sigma_r, sigma_i, plot_mode_indices);
    if local_has_valid_mode_index(lead_plot_idx, numel(EigVals_s))
        text(sigma_r(lead_plot_idx), sigma_i(lead_plot_idx), '  主模态', ...
            'Color', [0.75, 0.10, 0.05], 'FontWeight', 'bold', 'Interpreter', 'none');
    end
    [xlim_zoom, ylim_zoom] = local_zoom_limits(sigma_r, sigma_i, plot_mode_indices, lead_plot_idx);
    xlim(xlim_zoom);
    ylim(ylim_zoom);
    xlabel('sigma_r', 'Interpreter', 'none');
    ylabel('sigma_i', 'Interpreter', 'none');
    if local_has_valid_mode_index(lead_plot_idx, numel(EigVals_s))
        title('候选模态局部放大', 'Interpreter', 'none');
    else
        title('局部放大（无可绘制物理模态）', 'Interpreter', 'none');
    end
    grid on;
    box on;

    saveas(fig, output_file);
end

function local_annotate_modes(sigma_r, sigma_i, plot_mode_indices)
%LOCAL_ANNOTATE_MODES Label highlighted plot candidates.

    for k = 1:numel(plot_mode_indices)
        idx = plot_mode_indices(k);
        text(sigma_r(idx), sigma_i(idx), sprintf('  #%d', k), ...
            'Color', [0.05, 0.20, 0.55], 'FontWeight', 'bold', 'Interpreter', 'none');
    end
end

function tf = local_has_valid_mode_index(idx, num_modes)
%LOCAL_HAS_VALID_MODE_INDEX True when one index is finite and in range.

    tf = isscalar(idx) && isfinite(idx) && idx >= 1 && idx <= num_modes;
end

function local_write_raw_normalized_cloud_figure(output_file, q_mode, sigma_value, freq_value, residual_value, ...
        X, Y, RHO, Cv_nd, state_layout, bubble_mask)
%LOCAL_WRITE_RAW_NORMALIZED_CLOUD_FIGURE Save the retained full-field uvpT figure.

    Ny = size(X, 1);
    Nx = size(X, 2);
    energy_scale = local_energy_scale(q_mode, Ny, Nx, RHO, Cv_nd, state_layout);
    u_norm = real(extract_state_component(q_mode, Ny, Nx, state_layout, 'u')) / energy_scale;
    v_norm = real(extract_state_component(q_mode, Ny, Nx, state_layout, 'v')) / energy_scale;
    p_norm = real(extract_state_component(q_mode, Ny, Nx, state_layout, 'p')) / energy_scale;
    T_norm = real(extract_state_component(q_mode, Ny, Nx, state_layout, 'T')) / energy_scale;

    title_prefix = sprintf('主模态全场归一化 | sigma_r=%+.3e sigma_i=%+.3e f=%.4f res=%.2e', ...
        real(sigma_value), imag(sigma_value), freq_value, residual_value);

    fig = figure('Visible', 'off', 'Position', [60, 60, 1280, 900]);
    cleanup_obj = onCleanup(@() close(fig)); %#ok<NASGU>
    local_configure_figure_font(fig);

    subplot(2, 2, 1);
    local_draw_field(X, Y, u_norm, sprintf('%s\nu'' 扰动全场', title_prefix), []);
    local_overlay_geometry(X, Y, bubble_mask);

    subplot(2, 2, 2);
    local_draw_field(X, Y, v_norm, 'v'' 扰动全场', []);
    local_overlay_geometry(X, Y, bubble_mask);

    subplot(2, 2, 3);
    local_draw_field(X, Y, p_norm, 'p'' 扰动全场', []);
    local_overlay_geometry(X, Y, bubble_mask);

    subplot(2, 2, 4);
    local_draw_field(X, Y, T_norm, 'T'' 扰动全场', []);
    local_overlay_geometry(X, Y, bubble_mask);

    saveas(fig, output_file);
end

function local_write_uvpt_bubble_figure(output_file, q_mode, sigma_value, freq_value, residual_value, ...
        X, Y, U, V, RHO, Cv_nd, state_layout, bubble_mask, bubble_window, GeometryAudit)
%LOCAL_WRITE_UVPT_BUBBLE_FIGURE Save the retained bubble-window uvpT figure.

    Ny = size(X, 1);
    Nx = size(X, 2);
    energy_scale = local_energy_scale(q_mode, Ny, Nx, RHO, Cv_nd, state_layout);
    u_norm = real(extract_state_component(q_mode, Ny, Nx, state_layout, 'u')) / energy_scale;
    v_norm = real(extract_state_component(q_mode, Ny, Nx, state_layout, 'v')) / energy_scale;
    p_norm = real(extract_state_component(q_mode, Ny, Nx, state_layout, 'p')) / energy_scale;
    T_norm = real(extract_state_component(q_mode, Ny, Nx, state_layout, 'T')) / energy_scale;

    support_field = max(abs(u_norm), abs(v_norm));
    plot_window = local_choose_plot_window(support_field, X, Y, bubble_window);
    title_prefix = sprintf('主模态分离泡局部结构 | sigma_r=%+.3e sigma_i=%+.3e f=%.4f res=%.2e', ...
        real(sigma_value), imag(sigma_value), freq_value, residual_value);

    fig = figure('Visible', 'off', 'Position', [60, 60, 1280, 900]);
    cleanup_obj = onCleanup(@() close(fig)); %#ok<NASGU>
    local_configure_figure_font(fig);

    subplot(2, 2, 1);
    local_draw_field(X, Y, u_norm, sprintf('%s\nu'' 扰动', title_prefix), plot_window);
    local_overlay_geometry(X, Y, bubble_mask);
    local_overlay_streamlines(X, Y, U, V, GeometryAudit, plot_window);

    subplot(2, 2, 2);
    local_draw_field(X, Y, v_norm, 'v'' 扰动', plot_window);
    local_overlay_geometry(X, Y, bubble_mask);
    local_overlay_streamlines(X, Y, U, V, GeometryAudit, plot_window);

    subplot(2, 2, 3);
    local_draw_field(X, Y, p_norm, 'p'' 扰动', plot_window);
    local_overlay_geometry(X, Y, bubble_mask);
    local_overlay_streamlines(X, Y, U, V, GeometryAudit, plot_window);

    subplot(2, 2, 4);
    local_draw_field(X, Y, T_norm, 'T'' 扰动', plot_window);
    local_overlay_geometry(X, Y, bubble_mask);
    local_overlay_streamlines(X, Y, U, V, GeometryAudit, plot_window);

    saveas(fig, output_file);
end

function num_pages = local_write_all_modes_u_gallery(fig_dir, EigVecs_plot_s, EigVals_s, freq_signed_s, res_s, ...
        X, Y, RHO, Cv_nd, state_layout, bubble_mask)
%LOCAL_WRITE_ALL_MODES_U_GALLERY Save the retained sorted u' gallery.

    num_modes = size(EigVecs_plot_s, 2);
    modes_per_page = 4;
    num_pages = ceil(num_modes / modes_per_page);
    Ny = size(X, 1);
    Nx = size(X, 2);

    for page = 1:num_pages
        first_idx = (page - 1) * modes_per_page + 1;
        last_idx = min(page * modes_per_page, num_modes);
        fig = figure('Visible', 'off', 'Position', [60, 60, 1220, 920]);
        cleanup_obj = onCleanup(@() close(fig)); %#ok<NASGU>
        local_configure_figure_font(fig);
        tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

        for k = first_idx:last_idx
            nexttile;
            q_mode = EigVecs_plot_s(:, k);
            energy_scale = local_energy_scale(q_mode, Ny, Nx, RHO, Cv_nd, state_layout);
            u_norm = real(extract_state_component(q_mode, Ny, Nx, state_layout, 'u')) / energy_scale;
            local_draw_field(X, Y, u_norm, local_mode_title('u', k, EigVals_s(k), freq_signed_s(k), res_s(k)), []);
            local_overlay_geometry(X, Y, bubble_mask);
        end

        output_file = local_figure_output_file(fig_dir, 'u_gallery_page', page);
        saveas(fig, output_file);
    end
end

function [output_files, num_pages, audit] = local_write_sidharth_figures(fig_dir, lead_plot_idx, plot_mode_indices, ...
        EigVecs_plot_s, EigVals_s, freq_signed_s, res_s, data, Config, bubble_mask, bubble_window)
%LOCAL_WRITE_SIDHARTH_FIGURES Write the added Sidharth-oriented figures.

    output_files = {};
    num_pages = 0;
    audit = local_default_sidharth_audit();
    if ~local_has_valid_mode_index(lead_plot_idx, size(EigVecs_plot_s, 2))
        return;
    end

    q_lead = EigVecs_plot_s(:, lead_plot_idx);
    component_file = local_figure_output_file(fig_dir, 'sidharth_component');
    audit = local_write_sidharth_component_figure( ...
        component_file, EigVecs_plot_s(:, lead_plot_idx), EigVals_s(lead_plot_idx), ...
        freq_signed_s(lead_plot_idx), res_s(lead_plot_idx), data, Config, bubble_mask, bubble_window);
    output_files{end + 1} = component_file; %#ok<AGROW>

    gallery_indices = plot_mode_indices(:).';
    if isempty(gallery_indices)
        gallery_indices = lead_plot_idx;
    end
    gallery_component = local_pick_literature_gallery_component(q_lead, data.Ny, data.Nx, Config.state_layout);
    audit.gallery_component = gallery_component;
    num_pages = local_write_sidharth_component_gallery( ...
        fig_dir, gallery_indices, gallery_component, EigVecs_plot_s, EigVals_s, freq_signed_s, res_s, data, Config, bubble_mask, bubble_window);
    for page = 1:num_pages
        output_files{end + 1} = local_figure_output_file(fig_dir, 'sidharth_gallery_page', page); %#ok<AGROW>
    end
end

function audit = local_write_sidharth_component_figure(output_file, q_mode, sigma_value, freq_value, residual_value, ...
        data, Config, bubble_mask, bubble_window)
%LOCAL_WRITE_SIDHARTH_COMPONENT_FIGURE Save the Sidharth-style bubble-window component figure.

    Ny = data.Ny;
    Nx = data.Nx;
    energy_scale = local_energy_scale(q_mode, Ny, Nx, data.RHO, Config.Cv_nd, Config.state_layout);
    component_names = local_pick_literature_component_names(q_mode, Ny, Nx, Config.state_layout);
    component_titles = local_component_titles(component_names, 'window');
    component_contract = 'literature_style_bubble_components';
    plot_window = local_component_common_window(data, q_mode, Config, bubble_window);
    figure_title = sprintf('文献风格主模态分量图 | sigma_r=%+.3e sigma_i=%+.3e f=%+.4f res=%.2e', ...
        real(sigma_value), imag(sigma_value), freq_value, residual_value);
    fig = figure('Visible', 'off', 'Position', [60, 60, 1380, 860]);
    cleanup_obj = onCleanup(@() close(fig)); %#ok<NASGU>
    local_configure_figure_font(fig);
    tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    local_add_figure_title(figure_title);

    for k = 1:numel(component_names)
        nexttile;
        field_value = real(extract_state_component(q_mode, Ny, Nx, Config.state_layout, component_names{k})) / energy_scale;
        title_text = component_titles{k};
        local_draw_field(data.X, data.Y, field_value, title_text, plot_window);
        local_overlay_geometry(data.X, data.Y, bubble_mask);
        local_overlay_streamlines(data.X, data.Y, data.U, data.V, data.GeometryAudit, plot_window);
    end

    nexttile;
    local_write_component_support_text(data, Config, q_mode, bubble_window, component_names, component_contract);
    saveas(fig, output_file);
    audit = local_default_sidharth_audit();
    audit.component_contract = component_contract;
    audit.displayed_components = component_names;
    audit.common_plot_window = plot_window;
end

function local_write_component_support_text(data, Config, q_mode, bubble_window, component_names, component_contract)
%LOCAL_WRITE_COMPONENT_SUPPORT_TEXT Add a small component-support summary panel.

    Ny = data.Ny;
    Nx = data.Nx;
    axis off;
    text(0.0, 1.0, '模态分量概览', 'FontWeight', 'bold', 'Interpreter', 'none');
    text(0.0, 0.92, local_contract_label(component_contract), 'Interpreter', 'none');
    y0 = 0.82;
    for k = 1:numel(component_names)
        field_value = extract_state_component(q_mode, Ny, Nx, Config.state_layout, component_names{k});
        if all(isnan(field_value(:)))
            bubble_frac = NaN;
            shock_frac = NaN;
        else
            support = abs(field_value).^2;
            total_support = sum(support(:));
            if total_support <= 1.0e-60
                total_support = 1.0;
            end
            bubble_mask = local_get_mask(data, 'bubble_support_mask', 'bubble_mask');
            shock_mask = local_get_mask(data, 'shock_mask', 'shock_core_mask');
            bubble_frac = sum(support(bubble_mask), 'all') / total_support;
            shock_frac = sum(support(shock_mask), 'all') / total_support;
        end
        text(0.0, y0 - 0.14 * (k - 1), sprintf('%s: 分离泡=%.3f 激波=%.3f', ...
            local_component_label(component_names{k}), bubble_frac, shock_frac), 'Interpreter', 'none');
    end
    text(0.0, 0.10, sprintf('窗口范围 = [%.3g, %.3g] x [%.3g, %.3g]', ...
        bubble_window(1), bubble_window(2), bubble_window(3), bubble_window(4)), ...
        'Interpreter', 'none');
end

function num_pages = local_write_sidharth_component_gallery(fig_dir, gallery_indices, component_name, EigVecs_plot_s, EigVals_s, ...
        freq_signed_s, res_s, data, Config, bubble_mask, bubble_window)
%LOCAL_WRITE_SIDHARTH_COMPONENT_GALLERY Save the literature-style component gallery.

    gallery_indices = gallery_indices(:).';
    num_modes = numel(gallery_indices);
    modes_per_page = 4;
    num_pages = ceil(num_modes / modes_per_page);
    Ny = data.Ny;
    Nx = data.Nx;

    for page = 1:num_pages
        first_idx = (page - 1) * modes_per_page + 1;
        last_idx = min(page * modes_per_page, num_modes);
        fig = figure('Visible', 'off', 'Position', [60, 60, 1220, 920]);
        cleanup_obj = onCleanup(@() close(fig)); %#ok<NASGU>
        local_configure_figure_font(fig);
        tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

        for kk = first_idx:last_idx
            mode_idx = gallery_indices(kk);
            nexttile;
            q_mode = EigVecs_plot_s(:, mode_idx);
            energy_scale = local_energy_scale(q_mode, Ny, Nx, data.RHO, Config.Cv_nd, Config.state_layout);
            component_field = real(extract_state_component(q_mode, Ny, Nx, Config.state_layout, component_name)) / energy_scale;
            plot_window = local_component_common_window(data, q_mode, Config, bubble_window);
            local_draw_field(data.X, data.Y, component_field, ...
                local_mode_title(component_name, mode_idx, EigVals_s(mode_idx), freq_signed_s(mode_idx), res_s(mode_idx)), plot_window);
            local_overlay_geometry(data.X, data.Y, bubble_mask);
            local_overlay_streamlines(data.X, data.Y, data.U, data.V, data.GeometryAudit, plot_window);
        end

        output_file = local_figure_output_file(fig_dir, 'sidharth_gallery_page', page);
        saveas(fig, output_file);
    end
end

function output_file = local_figure_output_file(fig_dir, key, page)
%LOCAL_FIGURE_OUTPUT_FILE Build one Chinese-friendly figure output filename.

    if nargin < 3
        page = [];
    end

    switch char(string(key))
        case 'spectrum'
            file_name = 'Fig13_特征值谱.png';
        case 'raw_uvpt'
            file_name = 'Fig18_主模态全场归一化_uvpT.png';
        case 'bubble_uvpt'
            file_name = 'Fig19_主模态分离泡局部结构_uvpT.png';
        case 'u_gallery_page'
            file_name = sprintf('Fig22_候选模态_u_实部分布_第%02d页.png', page);
        case 'sidharth_component'
            file_name = 'Sidharth_Fig14_主模态分离泡分量图.png';
        case 'sidharth_gallery_page'
            file_name = sprintf('Sidharth_Fig15_候选模态分量图_第%02d页.png', page);
        otherwise
            error('write_paperA_reference_figures:UnknownOutputKey', ...
                'Unknown figure output key: %s', char(string(key)));
    end

    output_file = fullfile(fig_dir, file_name);
end

function title_text = local_mode_title(component_name, k, eigval, freq_value, residual_value)
%LOCAL_MODE_TITLE Build a short mode title used by gallery pages.

    title_text = sprintf('%s 模态 %d | sigma_r=%+.2e sigma_i=%+.2e\nf=%+.4f res=%.1e', ...
        local_component_label(component_name), k, real(eigval), imag(eigval), freq_value, residual_value);
end

function local_draw_field(X, Y, field_value, title_text, window)
%LOCAL_DRAW_FIELD Draw one symmetric filled contour field.

    vmax = local_window_percentile(field_value, window, X, Y, 99.0);
    if ~(isfinite(vmax) && vmax > 1.0e-20)
        vmax = max(abs(field_value(:)));
    end
    if ~(isfinite(vmax) && vmax > 1.0e-20)
        vmax = 1.0;
    end

    contourf(X, Y, field_value, linspace(-vmax, vmax, 48), 'LineStyle', 'none');
    caxis([-vmax, vmax]);
    colormap(gca, local_redblue_colormap(128));
    colorbar;
    axis tight;
    axis equal;
    xlabel('x^{*}', 'Interpreter', 'tex');
    ylabel('y^{*}', 'Interpreter', 'tex');
    title(title_text, 'Interpreter', 'none');
    box on;
    if ~isempty(window)
        xlim(window(1:2));
        ylim(window(3:4));
    end
end

function local_add_figure_title(title_text)
%LOCAL_ADD_FIGURE_TITLE Add a figure-level title with a safe fallback.

    try
        sgtitle(title_text, 'Interpreter', 'none', 'FontName', local_preferred_font_name());
    catch
        annotation(gcf, 'textbox', [0.02, 0.95, 0.96, 0.04], ...
            'String', title_text, 'EdgeColor', 'none', ...
            'HorizontalAlignment', 'center', 'Interpreter', 'none', ...
            'FontName', local_preferred_font_name());
    end
end

function local_configure_figure_font(fig)
%LOCAL_CONFIGURE_FIGURE_FONT Configure a CJK-friendly figure default font.

    font_name = local_preferred_font_name();
    set(fig, 'DefaultAxesFontName', font_name);
    set(fig, 'DefaultTextFontName', font_name);
    set(fig, 'DefaultUicontrolFontName', font_name);
end

function font_name = local_preferred_font_name()
%LOCAL_PREFERRED_FONT_NAME Return one Windows-friendly font for Chinese figure text.

    font_name = 'Microsoft YaHei';
end

function local_overlay_geometry(X, Y, bubble_mask)
%LOCAL_OVERLAY_GEOMETRY Overlay wall line and bubble boundary.

    hold on;
    plot(X(1, :), Y(1, :), 'k-', 'LineWidth', 1.5);
    if any(bubble_mask(:))
        contour(X, Y, double(bubble_mask), [0.5, 0.5], 'k--', 'LineWidth', 1.1);
    end
end

function local_overlay_streamlines(X, Y, U, V, GeometryAudit, window)
%LOCAL_OVERLAY_STREAMLINES Overlay baseflow streamlines when seeds are available.

    if isempty(GeometryAudit) || ~isstruct(GeometryAudit) || ~isfield(GeometryAudit, 'streamline_seed_set')
        return;
    end
    seeds = GeometryAudit.streamline_seed_set;
    if ~isfield(seeds, 'x') || ~isfield(seeds, 'y') || isempty(seeds.x)
        return;
    end

    try
        streams = stream2(X, Y, U, V, seeds.x(:), seeds.y(:));
        for k = 1:numel(streams)
            xy = streams{k};
            if isempty(xy)
                continue;
            end
            if ~isempty(window)
                inside = xy(:, 1) >= window(1) & xy(:, 1) <= window(2) & ...
                    xy(:, 2) >= window(3) & xy(:, 2) <= window(4);
                xy = xy(inside, :);
                if size(xy, 1) < 2
                    continue;
                end
            end
            plot(xy(:, 1), xy(:, 2), 'Color', [0.10, 0.35, 0.80], 'LineWidth', 0.9);
        end
    catch
        % Streamlines are diagnostic-only; ignore failures.
    end
end

function scale = local_energy_scale(q_mode, Ny, Nx, RHO, Cv_nd, state_layout)
%LOCAL_ENERGY_SCALE Compute the retained mode normalization scale.

    u = extract_state_component(q_mode, Ny, Nx, state_layout, 'u');
    v = extract_state_component(q_mode, Ny, Nx, state_layout, 'v');
    w = extract_state_component(q_mode, Ny, Nx, state_layout, 'w');
    T = extract_state_component(q_mode, Ny, Nx, state_layout, 'T');

    energy = RHO .* (abs(u).^2 + abs(v).^2);
    if ~all(isnan(w(:)))
        energy = energy + RHO .* abs(w).^2;
    end
    energy = energy + (RHO .* Cv_nd) .* abs(T).^2;
    scale = sqrt(sum(energy(:)));
    if scale <= 1.0e-60
        scale = 1.0;
    end
end

function plot_window = local_component_common_window(data, q_mode, Config, fallback_window)
%LOCAL_COMPONENT_COMMON_WINDOW Use one bubble window for all component panels.

    plot_window = local_sanitize_window(fallback_window, data.X, data.Y);
    if ~isempty(plot_window)
        return;
    end

    Ny = data.Ny;
    Nx = data.Nx;
    u = extract_state_component(q_mode, Ny, Nx, Config.state_layout, 'u');
    v = extract_state_component(q_mode, Ny, Nx, Config.state_layout, 'v');
    support = max(abs(u), abs(v));
    plot_window = local_choose_plot_window(support, data.X, data.Y, []);
    plot_window = local_sanitize_window(plot_window, data.X, data.Y);
    if isempty(plot_window)
        plot_window = [min(data.X(:)), max(data.X(:)), min(data.Y(:)), max(data.Y(:))];
    end
end

function window = local_sanitize_window(window, X, Y)
%LOCAL_SANITIZE_WINDOW Clamp one [xmin xmax ymin ymax] window to the grid.

    if isempty(window) || ~isnumeric(window) || numel(window) ~= 4 || any(~isfinite(window(:)))
        window = [];
        return;
    end
    window = double(window(:)).';
    if window(2) <= window(1) || window(4) <= window(3)
        window = [];
        return;
    end
    window(1) = max(min(X(:)), window(1));
    window(2) = min(max(X(:)), window(2));
    window(3) = max(min(Y(:)), window(3));
    window(4) = min(max(Y(:)), window(4));
    if window(2) <= window(1) || window(4) <= window(3)
        window = [];
    end
end

function audit = local_default_sidharth_audit()
%LOCAL_DEFAULT_SIDHARTH_AUDIT Build default Sidharth figure metadata.

    audit = struct();
    audit.component_contract = 'not_written';
    audit.displayed_components = {};
    audit.common_plot_window = [NaN, NaN, NaN, NaN];
    audit.gallery_component = '';
end

function component_names = local_pick_literature_component_names(q_mode, Ny, Nx, state_layout)
%LOCAL_PICK_LITERATURE_COMPONENT_NAMES Choose a literature-style displayed component set.

    if local_component_is_active(q_mode, Ny, Nx, state_layout, 'w')
        component_names = {'w', 'u', 'v', 'T', 'p'};
    else
        component_names = {'u', 'v', 'T', 'p'};
    end
end

function component_name = local_pick_literature_gallery_component(q_mode, Ny, Nx, state_layout)
%LOCAL_PICK_LITERATURE_GALLERY_COMPONENT Choose the most informative gallery component.

    if local_component_is_active(q_mode, Ny, Nx, state_layout, 'w')
        component_name = 'w';
    else
        component_name = 'u';
    end
end

function titles = local_component_titles(component_names, window_label)
%LOCAL_COMPONENT_TITLES Build displayed subplot titles for one component list.

    if nargin < 2 || isempty(window_label)
        window_label = '';
    end
    titles = cell(size(component_names));
    for k = 1:numel(component_names)
        if isempty(window_label)
            titles{k} = sprintf('%s 扰动', local_component_label(component_names{k}));
        else
            titles{k} = sprintf('%s %s', local_component_label(component_names{k}), local_window_label_text(window_label));
        end
    end
end

function label_text = local_component_label(component_name)
%LOCAL_COMPONENT_LABEL Convert one component key into a display label.

    switch char(string(component_name))
        case 'u'
            label_text = 'u''';
        case 'v'
            label_text = 'v''';
        case 'w'
            label_text = 'w''';
        case 'T'
            label_text = 'T''';
        case 'p'
            label_text = 'p''';
        otherwise
            label_text = char(string(component_name));
    end
end

function text_value = local_window_label_text(window_label)
%LOCAL_WINDOW_LABEL_TEXT Convert one internal window token to displayed text.

    switch char(string(window_label))
        case 'window'
            text_value = '分离泡窗口';
        otherwise
            text_value = char(string(window_label));
    end
end

function label_text = local_contract_label(contract_name)
%LOCAL_CONTRACT_LABEL Convert one internal contract id into displayed Chinese text.

    switch char(string(contract_name))
        case 'literature_style_bubble_components'
            label_text = '统一文献风格分量布局';
        otherwise
            label_text = char(string(contract_name));
    end
end

function tf = local_component_is_active(q_mode, Ny, Nx, state_layout, component_name)
%LOCAL_COMPONENT_IS_ACTIVE True when one component carries non-negligible amplitude.

    field_value = extract_state_component(q_mode, Ny, Nx, state_layout, component_name);
    if all(isnan(field_value(:)))
        tf = false;
        return;
    end

    other_components = {'u', 'v', 'w', 'T', 'p'};
    ref = eps;
    for k = 1:numel(other_components)
        field_k = extract_state_component(q_mode, Ny, Nx, state_layout, other_components{k});
        if any(~isnan(field_k(:)))
            ref = max(ref, max(abs(field_k(:))));
        end
    end
    tf = max(abs(field_value(:))) > 1.0e-8 * ref;
end

function [xlim_zoom, ylim_zoom] = local_zoom_limits(sigma_r, sigma_i, plot_mode_indices, lead_plot_idx)
%LOCAL_ZOOM_LIMITS Build the zoom window around highlighted modes.

    idx = plot_mode_indices(:);
    if local_has_valid_mode_index(lead_plot_idx, numel(sigma_r))
        idx = [idx; lead_plot_idx]; %#ok<AGROW>
    end
    idx = unique(idx);
    if isempty(idx)
        idx = (1:numel(sigma_r)).';
    end
    x_vals = sigma_r(idx);
    y_vals = sigma_i(idx);
    dx = max(max(x_vals) - min(x_vals), 5.0e-3);
    dy = max(max(y_vals) - min(y_vals), 5.0e-3);
    xlim_zoom = [min(x_vals) - 0.35 * dx, max(x_vals) + 0.35 * dx];
    ylim_zoom = [min(y_vals) - 0.35 * dy, max(y_vals) + 0.35 * dy];
end

function plot_window = local_choose_plot_window(support_field, X, Y, fallback_window)
%LOCAL_CHOOSE_PLOT_WINDOW Choose one compact view window around the support field.

    if any(isfinite(support_field(:)) & abs(support_field(:)) > 1.0e-12)
        mask = abs(support_field) >= 0.15 * max(abs(support_field(:)));
        if any(mask(:))
            extent = [min(X(mask)), max(X(mask)), min(Y(mask)), max(Y(mask))];
            Lx = max(X(:)) - min(X(:));
            Ly = max(Y(:)) - min(Y(:));
            plot_window = [ ...
                max(min(X(:)), extent(1) - 0.08 * max(Lx, eps)), ...
                min(max(X(:)), extent(2) + 0.08 * max(Lx, eps)), ...
                max(min(Y(:)), extent(3) - 0.05 * max(Ly, eps)), ...
                min(max(Y(:)), extent(4) + 0.08 * max(Ly, eps))];
            return;
        end
    end
    plot_window = fallback_window;
end

function bubble_window = local_get_bubble_window(GeometryAudit, X, Y)
%LOCAL_GET_BUBBLE_WINDOW Read the saved bubble window with fallback.

    if isstruct(GeometryAudit) && isfield(GeometryAudit, 'bubble_window')
        bubble_window = GeometryAudit.bubble_window;
    else
        bubble_window = [min(X(:)), max(X(:)), min(Y(:)), max(Y(:))];
    end
end

function bubble_focus_window = local_get_bubble_focus_window(data, bubble_mask, bubble_window)
%LOCAL_GET_BUBBLE_FOCUS_WINDOW Build one compact bubble-focused window.

    bubble_focus_window = bubble_window;
    if any(bubble_mask(:))
        x_vals = data.X(bubble_mask);
        y_vals = data.Y(bubble_mask);
        Lx = max(data.X(:)) - min(data.X(:));
        Ly = max(data.Y(:)) - min(data.Y(:));
        bubble_focus_window = [ ...
            max(min(data.X(:)), min(x_vals) - 0.04 * max(Lx, eps)), ...
            min(max(data.X(:)), max(x_vals) + 0.15 * max(Lx, eps)), ...
            max(min(data.Y(:)), min(y_vals) - 0.02 * max(Ly, eps)), ...
            min(max(data.Y(:)), max(y_vals) + 0.12 * max(Ly, eps))];
    end
end

function mask = local_get_mask(data, primary_name, fallback_name)
%LOCAL_GET_MASK Read one saved mask with a fallback name.

    mask = false(size(data.X));
    if isfield(data, 'BaseflowMasks') && isstruct(data.BaseflowMasks)
        if isfield(data.BaseflowMasks, primary_name)
            mask = logical(data.BaseflowMasks.(primary_name));
            return;
        end
        if isfield(data.BaseflowMasks, fallback_name)
            mask = logical(data.BaseflowMasks.(fallback_name));
            return;
        end
    end
end

function tf = local_write_sidharth_contract(Config)
%LOCAL_WRITE_SIDHARTH_CONTRACT True when Sidharth-specific figures should be emitted.

    tf = strcmpi(local_get_string_field(Config, 'target_benchmark', ''), 'Sidharth2018') || ...
        strcmpi(local_get_string_field(Config, 'secondary_plot_contract', ''), 'sidharth2018_reproduction_v1');
end

function text = local_get_string_field(S, name, default_value)
%LOCAL_GET_STRING_FIELD Read one string-like field with fallback.

    text = default_value;
    if isstruct(S) && isfield(S, name)
        text = char(string(S.(name)));
    end
end

function value = local_window_percentile(field_value, window, X, Y, pct)
%LOCAL_WINDOW_PERCENTILE Percentile of |field| inside an optional window.

    data_value = abs(field_value(:));
    if ~isempty(window)
        in_window = X >= window(1) & X <= window(2) & Y >= window(3) & Y <= window(4);
        data_value = abs(field_value(in_window));
    end
    data_value = data_value(isfinite(data_value));
    if isempty(data_value)
        value = 0.0;
        return;
    end
    value = local_percentile(data_value, pct);
end

function value = local_percentile(data_value, pct)
%LOCAL_PERCENTILE Toolbox-free percentile helper.

    data_value = sort(data_value(:));
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
%LOCAL_REDBLUE_COLORMAP Small red-blue diverging map.

    if nargin < 1
        n = 64;
    end
    m = ceil(n / 2);
    blue = [linspace(0.10, 1.00, m).', linspace(0.20, 1.00, m).', ones(m, 1)];
    red = [ones(n - m, 1), linspace(1.00, 0.20, n - m).', linspace(1.00, 0.10, n - m).'];
    cmap = [blue; flipud(red)];
    cmap = cmap(1:n, :);
end
