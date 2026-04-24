function refresh_result = refresh_saved_paperA_outputs(case_dir, varargin)
%REFRESH_SAVED_PAPERA_OUTPUTS Redraw one saved Paper-A case without re-solving eigs.

    p = inputParser;
    p.FunctionName = 'refresh_saved_paperA_outputs';
    addParameter(p, 'FigureDirectory', '', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'AppendAudit', true, @(x) islogical(x) || isnumeric(x));
    addParameter(p, 'PreserveSavedOrder', true, @(x) islogical(x) || isnumeric(x));
    parse(p, varargin{:});

    case_dir = char(string(case_dir));
    part3_file = fullfile(case_dir, 'Part3_Results.mat');
    part4_file = fullfile(case_dir, 'Part4_Results.mat');
    if exist(part3_file, 'file') ~= 2 || exist(part4_file, 'file') ~= 2
        error('refresh_saved_paperA_outputs:MissingCaseFiles', ...
            'Expected Part3_Results.mat and Part4_Results.mat in %s.', case_dir);
    end

    if strlength(string(p.Results.FigureDirectory)) > 0
        fig_dir = char(string(p.Results.FigureDirectory));
    else
        fig_dir = fullfile(case_dir, 'figs');
    end

    data = load(part3_file);
    part4 = load(part4_file);
    data.Config = local_upgrade_config(data.Config);
    data = local_upgrade_baseflow_masks(data);
    masks = build_paperA_mode_masks(data, data.Config, data.Ny, data.Nx);

    preserve_saved_order = logical(p.Results.PreserveSavedOrder);
    if preserve_saved_order
        ranking = local_build_saved_order_ranking(part4);
    else
        ranking = rank_paperA_modes( ...
            part4.EigVals_s, part4.EigVecs_s, ...
            part4.res_s, part4.res_active_s, part4.res_algebraic_s, part4.res_scaled_s, ...
            data, data.Config, masks);
    end
    [plot_phase_factor_s, PhaseAudit_s] = local_phase_align_modes( ...
        ranking.EigVecs, data.Ny, data.Nx, data.Config.state_layout, ...
        masks.bubble, masks.near_wall, data.X, data.Y, ranking.metrics.reference_component);
    FigureAudit = write_paperA_reference_figures(fig_dir, ranking, data, data.Config, plot_phase_factor_s, PhaseAudit_s);
    PlotContractAudit = local_build_refresh_plot_contract_audit(data.Config, FigureAudit, ranking, part4, data); %#ok<NASGU>
    FigureCriteriaTable = local_build_refresh_figure_criteria_table(data.Config); %#ok<NASGU>

    refresh_result = struct();
    refresh_result.case_dir = case_dir;
    refresh_result.figure_directory = fig_dir;
    refresh_result.ranking = ranking;
    refresh_result.plot_phase_factor_s = plot_phase_factor_s;
    refresh_result.PhaseAudit_s = PhaseAudit_s;
    refresh_result.FigureAudit = FigureAudit;
    refresh_result.preserve_saved_order = preserve_saved_order;

    if logical(p.Results.AppendAudit)
        RefreshAudit = struct(); %#ok<NASGU>
        RefreshAudit.timestamp = datetime('now');
        RefreshAudit.figure_directory = fig_dir;
        RefreshAudit.preserve_saved_order = preserve_saved_order;
        RefreshAudit.selection_summary = ranking.selection_summary;
        RefreshAudit.lead_plot_index = FigureAudit.lead_plot_index;
        RefreshAudit.output_files = FigureAudit.output_files;
        RefreshAudit.figure_audit = FigureAudit;
        if preserve_saved_order
            save(part4_file, 'RefreshAudit', 'FigureAudit', 'PlotContractAudit', 'FigureCriteriaTable', '-append');
        else
            save(part4_file, 'RefreshAudit', 'FigureCriteriaTable', '-append');
        end
    end
end

function tbl = local_build_refresh_figure_criteria_table(Config)
%LOCAL_BUILD_REFRESH_FIGURE_CRITERIA_TABLE Build refreshed figure criteria.

    target = local_optional_field(Config, 'target_benchmark', '');
    if strcmpi(target, 'Sidharth2018')
        pass_signal_mode = 'bubble-centred mode with a literature-style component layout in the separation bubble';
        reject_signal_mode = 'mismatched component windows, compact upper-layer packet, or shock-only packet';
    else
        pass_signal_mode = 'physically supported mode with consistent bubble localization';
        reject_signal_mode = 'debug-only or boundary/shock-dominated packet';
    end

    tbl = table( ...
        string({'eigenspectrum'; 'mode_image'; 'beta_or_wavelength_scan'}), ...
        string({'least-stable branch topology'; 'support region and component structure'; 'peak wavelength / branch continuity'}), ...
        string({'expected stationary branch remains plot-eligible'; pass_signal_mode; 'peak stays stable under consistent numerics'}), ...
        string({'isolated debug branch dominates'; reject_signal_mode; 'peak shifts violently under minor numerics changes'}), ...
        'VariableNames', {'figure', 'what_to_compare', 'pass_signal', 'reject_signal'});
end

function ranking = local_build_saved_order_ranking(part4)
%LOCAL_BUILD_SAVED_ORDER_RANKING Build plotting metadata in saved Part4 order.

    n_modes = numel(part4.EigVals_s);
    ranking = struct();
    ranking.EigVals = part4.EigVals_s;
    ranking.EigVecs = part4.EigVecs_s;
    ranking.residuals = local_vector_field(part4, 'res_s', n_modes, Inf);
    ranking.residuals_active = local_vector_field(part4, 'res_active_s', n_modes, Inf);
    ranking.residuals_algebraic = local_vector_field(part4, 'res_algebraic_s', n_modes, Inf);
    ranking.residuals_scaled = local_vector_field(part4, 'res_scaled_s', n_modes, Inf);
    ranking.order = (1:n_modes).';
    ranking.freq_info = struct();
    ranking.freq_info.freq_nd_signed = local_vector_field(part4, 'freq_signed_s', n_modes, NaN);
    if all(isnan(ranking.freq_info.freq_nd_signed))
        ranking.freq_info.freq_nd_signed = local_vector_field(part4, 'St_s', n_modes, NaN);
    end

    selected_for_plots = false(n_modes, 1);
    publication_allowed = false(n_modes, 1);
    original_mode_index = (1:n_modes).';
    if isfield(part4, 'ranking_table') && istable(part4.ranking_table)
        if ismember('selected_for_plots', part4.ranking_table.Properties.VariableNames)
            selected_for_plots = logical(part4.ranking_table.selected_for_plots);
        end
        if ismember('selected_for_publication', part4.ranking_table.Properties.VariableNames)
            publication_allowed = logical(part4.ranking_table.selected_for_publication);
        end
        if ismember('mode_index', part4.ranking_table.Properties.VariableNames)
            original_mode_index = part4.ranking_table.mode_index;
        end
    end
    ranking.selected_for_plots = selected_for_plots(:);
    ranking.publication_allowed = publication_allowed(:);
    ranking.original_mode_index = original_mode_index(:);
    ranking.plot_lead_candidate_mask = false(n_modes, 1);
    saved_plot_position = local_saved_plot_position(part4, n_modes);
    if isfinite(saved_plot_position)
        ranking.plot_lead_candidate_mask(saved_plot_position) = true;
    else
        ranking.plot_lead_candidate_mask = ranking.selected_for_plots;
    end

    audit = local_selection_audit(part4, n_modes);
    ranking.metrics = local_saved_metrics(part4, audit, n_modes);
    ranking.ModeDiag = local_optional_field(part4, 'ModeDiag', struct([]));
    ranking.ranking_table = local_optional_field(part4, 'ranking_table', table());
    ranking.selection_summary = local_optional_field(part4, 'selection_summary', struct());
    if ~isfield(ranking.selection_summary, 'status')
        ranking.selection_summary.status = 'saved_order_refresh';
    end
    if ~isfield(ranking.selection_summary, 'plot_status')
        if any(ranking.plot_lead_candidate_mask)
            ranking.selection_summary.plot_status = 'physical_plot_candidates_available';
        else
            ranking.selection_summary.plot_status = 'no_physical_plot_candidates';
        end
    end
end

function metrics = local_saved_metrics(part4, audit, n_modes)
%LOCAL_SAVED_METRICS Reconstruct the metrics used by the figure lead selector.

    metrics = struct();
    metrics.family_priority = zeros(n_modes, 1);
    metrics.physical_candidate_score = local_vector_field(part4, 'physical_candidate_score_s', n_modes, 0.0);
    metrics.bubble_core_overlap = local_audit_vector(audit, 'bubble_core_overlap', ...
        local_vector_field(part4, 'bubble_overlap_s', n_modes, 0.0));
    metrics.bubble_support_overlap = local_audit_vector(audit, 'bubble_support_overlap', ...
        local_vector_field(part4, 'bubble_overlap_s', n_modes, 0.0));
    metrics.near_wall_energy_frac = local_vector_field(part4, 'near_wall_energy_frac_s', n_modes, 0.0);
    metrics.shock_energy_frac = local_vector_field(part4, 'shock_energy_frac_s', n_modes, 0.0);
    metrics.shock_core_energy_frac = local_audit_vector(audit, 'shock_core_energy_frac', ...
        metrics.shock_energy_frac);
    metrics.outlet_energy_frac = local_vector_field(part4, 'outlet_energy_frac_s', n_modes, 0.0);
    metrics.outlet_wall_energy_frac = local_vector_field(part4, 'outlet_wall_energy_frac_s', n_modes, 0.0);
    metrics.free_stream_energy_frac = local_vector_field(part4, 'free_stream_energy_frac_s', n_modes, 0.0);
    metrics.checker_ratio = local_vector_field(part4, 'checker_ratio_s', n_modes, 0.0);
    metrics.u_peak_in_bubble = local_audit_vector(audit, 'u_peak_in_bubble', false(n_modes, 1));
    metrics.u_peak_in_shock_core = local_audit_vector(audit, 'u_peak_in_shock_core', false(n_modes, 1));
    metrics.u_peak_in_outlet_wall = local_audit_vector(audit, 'u_peak_in_outlet_wall', false(n_modes, 1));
    metrics.p_checker_ratio = local_vector_field(part4, 'p_checker_ratio_s', n_modes, 0.0);
    metrics.p_free_stream_overlap = local_vector_field(part4, 'p_free_stream_overlap_s', n_modes, 0.0);
    metrics.p_outlet_overlap = local_vector_field(part4, 'p_outlet_overlap_s', n_modes, 0.0);
    metrics.p_outlet_wall_overlap = local_vector_field(part4, 'p_outlet_wall_overlap_s', n_modes, 0.0);
    metrics.p_shock_core_overlap = local_vector_field(part4, 'p_shock_core_overlap_s', n_modes, 0.0);
    metrics.reference_component = local_audit_cell(audit, 'reference_component', n_modes, 'u');
    metrics.component_support = struct();
    metrics.component_support.w = local_component_metrics(part4, 'w', n_modes);
    metrics.component_support.p = local_component_metrics(part4, 'p', n_modes);
end

function component_metrics = local_component_metrics(part4, component_name, n_modes)
%LOCAL_COMPONENT_METRICS Extract saved component-level support vectors.

    component_metrics = struct();
    component_metrics.bubble_support_overlap = zeros(n_modes, 1);
    component_metrics.bubble_core_overlap = zeros(n_modes, 1);
    component_metrics.shock_core_overlap = zeros(n_modes, 1);
    component_metrics.checker_ratio = zeros(n_modes, 1);
    component_metrics.free_stream_overlap = zeros(n_modes, 1);
    component_metrics.outlet_overlap = zeros(n_modes, 1);
    component_metrics.outlet_wall_overlap = zeros(n_modes, 1);
    component_metrics.peak_in_bubble_support = false(n_modes, 1);
    component_metrics.peak_in_shock_core = false(n_modes, 1);
    component_metrics.peak_in_free_stream = false(n_modes, 1);
    component_metrics.peak_in_outlet_wall = false(n_modes, 1);
    if ~isfield(part4, 'ComponentModeAudit') || ~isstruct(part4.ComponentModeAudit)
        return;
    end

    for k = 1:min(n_modes, numel(part4.ComponentModeAudit))
        entry = part4.ComponentModeAudit(k);
        if ~isfield(entry, 'components') || ~isstruct(entry.components) || ...
                ~isfield(entry.components, component_name)
            continue;
        end
        c = entry.components.(component_name);
        component_metrics.bubble_support_overlap(k) = local_optional_field(c, 'bubble_support_overlap', 0.0);
        component_metrics.bubble_core_overlap(k) = local_optional_field(c, 'bubble_core_overlap', 0.0);
        component_metrics.shock_core_overlap(k) = local_optional_field(c, 'shock_core_overlap', 0.0);
        component_metrics.checker_ratio(k) = local_optional_field(c, 'checker_ratio', 0.0);
        component_metrics.free_stream_overlap(k) = local_optional_field(c, 'free_stream_overlap', 0.0);
        component_metrics.outlet_overlap(k) = local_optional_field(c, 'outlet_overlap', 0.0);
        component_metrics.outlet_wall_overlap(k) = local_optional_field(c, 'outlet_wall_overlap', 0.0);
        component_metrics.peak_in_bubble_support(k) = local_optional_field(c, 'peak_in_bubble_support', false);
        component_metrics.peak_in_shock_core(k) = local_optional_field(c, 'peak_in_shock_core', false);
        component_metrics.peak_in_free_stream(k) = local_optional_field(c, 'peak_in_free_stream', false);
        component_metrics.peak_in_outlet_wall(k) = local_optional_field(c, 'peak_in_outlet_wall', false);
    end
end

function value = local_vector_field(S, field_name, n_modes, default_value)
%LOCAL_VECTOR_FIELD Read or backfill one column vector.

    if isstruct(S) && isfield(S, field_name) && numel(S.(field_name)) >= n_modes
        value = S.(field_name)(1:n_modes);
        value = value(:);
    else
        value = repmat(default_value, n_modes, 1);
    end
end

function audit = local_selection_audit(part4, n_modes)
%LOCAL_SELECTION_AUDIT Return a saved ModeSelectionAudit array or an empty fallback.

    if isfield(part4, 'ModeSelectionAudit') && isstruct(part4.ModeSelectionAudit) && ...
            numel(part4.ModeSelectionAudit) >= n_modes
        audit = part4.ModeSelectionAudit;
    else
        audit = struct([]);
    end
end

function value = local_audit_vector(audit, field_name, default_value)
%LOCAL_AUDIT_VECTOR Read one field from ModeSelectionAudit.

    value = default_value(:);
    n_modes = numel(value);
    if ~isstruct(audit) || isempty(audit)
        return;
    end
    for k = 1:min(n_modes, numel(audit))
        if isfield(audit(k), field_name)
            value(k) = audit(k).(field_name);
        end
    end
end

function value = local_audit_cell(audit, field_name, n_modes, default_value)
%LOCAL_AUDIT_CELL Read one character field from ModeSelectionAudit.

    value = repmat({default_value}, n_modes, 1);
    if ~isstruct(audit) || isempty(audit)
        return;
    end
    for k = 1:min(n_modes, numel(audit))
        if isfield(audit(k), field_name)
            candidate = audit(k).(field_name);
            if isstring(candidate)
                value{k} = char(candidate);
            elseif ischar(candidate)
                value{k} = candidate;
            end
        end
    end
end

function position = local_saved_plot_position(part4, n_modes)
%LOCAL_SAVED_PLOT_POSITION Resolve the saved plotted-lead sorted position.

    position = NaN;
    if isfield(part4, 'plot_leading_mode_position') && ...
            isnumeric(part4.plot_leading_mode_position) && isscalar(part4.plot_leading_mode_position) && ...
            isfinite(part4.plot_leading_mode_position)
        position = min(max(round(part4.plot_leading_mode_position), 1), n_modes);
        return;
    end
    if isfield(part4, 'selection_summary') && isstruct(part4.selection_summary) && ...
            isfield(part4.selection_summary, 'plot_leading_mode_position') && ...
            isnumeric(part4.selection_summary.plot_leading_mode_position) && ...
            isscalar(part4.selection_summary.plot_leading_mode_position) && ...
            isfinite(part4.selection_summary.plot_leading_mode_position)
        position = min(max(round(part4.selection_summary.plot_leading_mode_position), 1), n_modes);
    end
end

function audit = local_build_refresh_plot_contract_audit(Config, FigureAudit, ranking, part4, data)
%LOCAL_BUILD_REFRESH_PLOT_CONTRACT_AUDIT Refresh plot metadata without re-solving Part4.

    audit = struct();
    if isfield(part4, 'PlotContractAudit') && isstruct(part4.PlotContractAudit)
        audit = part4.PlotContractAudit;
    end
    plot_provenance = struct();
    if isfield(part4, 'PlotProvenanceAudit') && isstruct(part4.PlotProvenanceAudit)
        plot_provenance = part4.PlotProvenanceAudit;
    end
    audit.primary_plot_contract = local_optional_field(Config, 'plot_contract', '');
    audit.secondary_plot_contract = local_optional_field(Config, 'secondary_plot_contract', '');
    audit.target_benchmark = local_optional_field(Config, 'target_benchmark', '');
    audit.selection_status = local_optional_field(ranking.selection_summary, 'status', '');
    audit.plot_status = local_optional_field(ranking.selection_summary, 'plot_status', '');
    audit.has_plot_lead = local_has_valid_mode_index(FigureAudit.lead_plot_index, numel(ranking.EigVals));
    audit.reference_component = local_optional_field(plot_provenance, 'reference_component', '');
    audit.normalization = local_optional_field(plot_provenance, 'normalization', 'energy_total_l2');
    audit.normalization_scale = local_optional_field(plot_provenance, 'normalization_scale', NaN);
    audit.phase_anchor_type = local_optional_field(plot_provenance, 'phase_anchor_type', '');
    audit.phase_anchor_component = local_optional_field(plot_provenance, 'phase_anchor_component', '');
    audit.phase_anchor_requested_component = local_optional_field(plot_provenance, 'phase_anchor_requested_component', '');
    audit.phase_anchor_x = local_optional_field(plot_provenance, 'phase_anchor_x', NaN);
    audit.phase_anchor_y = local_optional_field(plot_provenance, 'phase_anchor_y', NaN);
    audit.generated_files = local_optional_field(FigureAudit, 'output_files', {});
    audit.sidharth_generated_files = local_optional_field(FigureAudit, 'sidharth_output_files', {});
    audit.sidharth_component_contract = local_optional_field(FigureAudit, 'sidharth_component_contract', '');
    audit.sidharth_displayed_components = local_optional_field(FigureAudit, 'sidharth_displayed_components', {});
    audit.sidharth_common_plot_window = local_optional_field(FigureAudit, 'sidharth_common_plot_window', [NaN, NaN, NaN, NaN]);
    audit.sidharth_gallery_component = local_optional_field(FigureAudit, 'sidharth_gallery_component', '');
    audit.figure_status = local_optional_field(FigureAudit, 'status', '');
    geometry = local_optional_field(data, 'GeometryAudit', struct());
    audit.bubble_window = local_optional_field(geometry, 'bubble_window', [NaN, NaN, NaN, NaN]);
end

function tf = local_has_valid_mode_index(idx, num_modes)
%LOCAL_HAS_VALID_MODE_INDEX True when one index is finite and in range.

    tf = isscalar(idx) && isfinite(idx) && idx >= 1 && idx <= num_modes;
end

function value = local_optional_field(S, name, default_value)
%LOCAL_OPTIONAL_FIELD Return one optional struct field.

    if isstruct(S) && isfield(S, name)
        value = S.(name);
    else
        value = default_value;
    end
end

function data = local_upgrade_baseflow_masks(data)
%LOCAL_UPGRADE_BASEFLOW_MASKS Fill in bubble-support and shock-outer masks for older saved cases.

    if ~isfield(data, 'BaseflowMasks') || ~isstruct(data.BaseflowMasks)
        data.BaseflowMasks = struct();
    end
    if ~isfield(data.BaseflowMasks, 'bubble_core_mask')
        if isfield(data.BaseflowMasks, 'bubble_mask')
            data.BaseflowMasks.bubble_core_mask = logical(data.BaseflowMasks.bubble_mask);
        else
            data.BaseflowMasks.bubble_core_mask = data.U < 0;
        end
    end

    if ~isfield(data.BaseflowMasks, 'bubble_support_mask')
        bubble_core = logical(data.BaseflowMasks.bubble_core_mask);
        data.BaseflowMasks.bubble_support_mask = local_build_bubble_support(data.X, data.Y, bubble_core);
    end

    if ~isfield(data.BaseflowMasks, 'near_wall_mask')
        near_rows = min(data.Ny, max(3, round(data.Ny * data.Config.mode_filter.near_wall_fraction)));
        near_mask = false(data.Ny, data.Nx);
        near_mask(1:near_rows, :) = true;
        data.BaseflowMasks.near_wall_mask = near_mask;
    end

    if ~isfield(data.BaseflowMasks, 'shock_core_mask')
        if isfield(data.BaseflowMasks, 'shock_mask')
            data.BaseflowMasks.shock_core_mask = logical(data.BaseflowMasks.shock_mask);
        elseif isfield(data, 'ShockInfo') && isstruct(data.ShockInfo) && isfield(data.ShockInfo, 'shock_raw')
            data.BaseflowMasks.shock_core_mask = logical(data.ShockInfo.shock_raw);
        else
            data.BaseflowMasks.shock_core_mask = false(data.Ny, data.Nx);
        end
    end

    if ~isfield(data.BaseflowMasks, 'shock_outer_mask')
        data.BaseflowMasks.shock_outer_mask = logical(data.BaseflowMasks.shock_core_mask) & ...
            ~logical(data.BaseflowMasks.near_wall_mask);
    end
    if ~isfield(data.BaseflowMasks, 'outlet_mask')
        x_min = min(data.X(:));
        x_max = max(data.X(:));
        outlet_fraction = 0.12;
        if isfield(data.Config, 'mode_filter') && isfield(data.Config.mode_filter, 'outlet_fraction')
            outlet_fraction = data.Config.mode_filter.outlet_fraction;
        end
        data.BaseflowMasks.outlet_mask = data.X >= (x_max - outlet_fraction * max(x_max - x_min, eps));
    end
    if ~isfield(data.BaseflowMasks, 'outlet_wall_mask')
        data.BaseflowMasks.outlet_wall_mask = logical(data.BaseflowMasks.outlet_mask) & ...
            logical(data.BaseflowMasks.near_wall_mask);
    end
    data.BaseflowMasks.shock_mask = logical(data.BaseflowMasks.shock_outer_mask);
end

function bubble_support = local_build_bubble_support(X, Y, bubble_core)
%LOCAL_BUILD_BUBBLE_SUPPORT Reconstruct the default bubble-support mask.

    bubble_support = bubble_core;
    if ~any(bubble_core(:))
        return;
    end
    x_vals = X(bubble_core);
    y_vals = Y(bubble_core);
    dx = max(max(x_vals) - min(x_vals), eps);
    dy = max(max(y_vals) - min(y_vals), eps);
    Ly = max(Y(:)) - min(Y(:));
    x_min = min(x_vals) - 0.05 * dx;
    x_max = max(x_vals) + 0.55 * dx;
    y_cap = max(y_vals) + max(0.75 * dy, 0.04 * Ly);
    wall_y = Y(1, :);
    for ii = 1:size(X, 2)
        bubble_support(:, ii) = bubble_support(:, ii) | ...
            (X(:, ii) >= x_min & X(:, ii) <= x_max & ...
             Y(:, ii) >= wall_y(ii) & Y(:, ii) <= y_cap);
    end
end

function [phase_factors, phase_audit] = local_phase_align_modes(EigVecs, Ny, Nx, state_layout, ...
        bubble_mask, near_wall_mask, X, Y, reference_components)
%LOCAL_PHASE_ALIGN_MODES Phase-align each sorted mode for plotting.

    num_modes = size(EigVecs, 2);
    phase_factors = ones(num_modes, 1);
    phase_audit = repmat(struct( ...
        'type', 'none', ...
        'row', NaN, ...
        'col', NaN, ...
        'x', NaN, ...
        'y', NaN, ...
        'component', '', ...
        'requested_component', ''), num_modes, 1);
    for k = 1:num_modes
        reference_component = local_value_or_default(reference_components, k, 'u');
        [phase_factors(k), phase_audit(k)] = choose_mode_phase_factor(EigVecs(:, k), Ny, Nx, state_layout, ...
            'BubbleMask', bubble_mask, 'NearWallMask', near_wall_mask, ...
            'X', X, 'Y', Y, 'ReferenceComponent', reference_component);
    end
end

function value = local_value_or_default(values, index, default_value)
%LOCAL_VALUE_OR_DEFAULT Read one vector/cell/string entry with fallback.

    value = default_value;
    if isempty(values)
        return;
    end
    if iscell(values)
        if numel(values) >= index
            value = values{index};
        end
    elseif isstring(values)
        if numel(values) >= index
            value = char(values(index));
        end
    elseif isnumeric(values) || islogical(values)
        if numel(values) >= index
            value = values(index);
        end
    end
end

function Config = local_upgrade_config(Config)
%LOCAL_UPGRADE_CONFIG Backfill newer mode-filter fields for older saved cases.

    if ~isfield(Config, 'mode_filter') || ~isstruct(Config.mode_filter)
        Config.mode_filter = struct();
    end
    if ~isfield(Config.mode_filter, 'near_wall_fraction')
        Config.mode_filter.near_wall_fraction = 0.15;
    end
    if ~isfield(Config.mode_filter, 'support_weighting')
        Config.mode_filter.support_weighting = 'component_energy';
    end
    if ~isfield(Config.mode_filter, 'free_stream_eta_threshold')
        Config.mode_filter.free_stream_eta_threshold = 0.50;
    end
    if ~isfield(Config.mode_filter, 'near_wall_support_threshold')
        Config.mode_filter.near_wall_support_threshold = 0.10;
    end
    if ~isfield(Config.mode_filter, 'bubble_fraction_threshold')
        Config.mode_filter.bubble_fraction_threshold = 0.05;
    end
    if ~isfield(Config.mode_filter, 'bubble_core_fraction_threshold')
        Config.mode_filter.bubble_core_fraction_threshold = 0.03;
    end
    if ~isfield(Config.mode_filter, 'bubble_support_fraction_threshold')
        Config.mode_filter.bubble_support_fraction_threshold = 0.05;
    end
    if ~isfield(Config.mode_filter, 'shock_fraction_threshold')
        Config.mode_filter.shock_fraction_threshold = 0.35;
    end
    if ~isfield(Config.mode_filter, 'shock_core_fraction_threshold')
        Config.mode_filter.shock_core_fraction_threshold = 0.15;
    end
    if ~isfield(Config.mode_filter, 'free_stream_fraction_threshold')
        Config.mode_filter.free_stream_fraction_threshold = 0.20;
    end
    if ~isfield(Config.mode_filter, 'residual_threshold')
        Config.mode_filter.residual_threshold = 1.0e-4;
    end
    if ~isfield(Config.mode_filter, 'checker_threshold')
        Config.mode_filter.checker_threshold = 5.0;
    end
    if ~isfield(Config.mode_filter, 'checker_threshold_structural')
        Config.mode_filter.checker_threshold_structural = 20.0;
    end
    if ~isfield(Config.mode_filter, 'pressure_checker_threshold')
        Config.mode_filter.pressure_checker_threshold = 1.5;
    end
    if ~isfield(Config.mode_filter, 'pressure_checker_threshold_structural')
        Config.mode_filter.pressure_checker_threshold_structural = 1.5;
    end
    if ~isfield(Config.mode_filter, 'outlet_fraction')
        Config.mode_filter.outlet_fraction = 0.12;
    end
    if ~isfield(Config.mode_filter, 'outlet_fraction_threshold')
        Config.mode_filter.outlet_fraction_threshold = 0.35;
    end
    if ~isfield(Config.mode_filter, 'outlet_wall_fraction_threshold')
        Config.mode_filter.outlet_wall_fraction_threshold = 0.20;
    end
    if ~isfield(Config.mode_filter, 'plot_free_stream_fraction_threshold')
        Config.mode_filter.plot_free_stream_fraction_threshold = 0.50;
    end
    if ~isfield(Config.mode_filter, 'plot_outlet_wall_fraction_threshold')
        Config.mode_filter.plot_outlet_wall_fraction_threshold = 0.35;
    end
    if ~isfield(Config.mode_filter, 'plot_gallery_limit')
        Config.mode_filter.plot_gallery_limit = 4;
    end
    if ~isfield(Config.mode_filter, 'pressure_free_stream_fraction_threshold')
        Config.mode_filter.pressure_free_stream_fraction_threshold = 0.35;
    end
    if ~isfield(Config.mode_filter, 'pressure_outlet_fraction_threshold')
        Config.mode_filter.pressure_outlet_fraction_threshold = 0.40;
    end
    if ~isfield(Config.mode_filter, 'pressure_outlet_wall_fraction_threshold')
        Config.mode_filter.pressure_outlet_wall_fraction_threshold = 0.20;
    end
    if ~isfield(Config.mode_filter, 'pressure_shock_core_fraction_threshold')
        Config.mode_filter.pressure_shock_core_fraction_threshold = 0.20;
    end
end
