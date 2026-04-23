function Main_DoubleWedge_Part4_v6(varargin)
%MAIN_DOUBLEWEDGE_PART4_V6 Solve, rank, and plot the Paper-A production EVP.

    p = inputParser;
    p.FunctionName = 'Main_DoubleWedge_Part4_v6';
    addParameter(p, 'FigureDirectory', fullfile(pwd, 'figs'), @(x) ischar(x) || (isstring(x) && isscalar(x)));
    parse(p, varargin{:});

    setup_double_wedge_paths();

    if exist('Part3_Results.mat', 'file') ~= 2
        error('Main_DoubleWedge_Part4_v6:MissingPart3', ...
            'Part3_Results.mat is required before running Part4.');
    end

    data = load('Part3_Results.mat');
    Config = local_normalize_config(data.Config);
    fig_dir = char(string(p.Results.FigureDirectory));
    if exist(fig_dir, 'dir') ~= 7
        mkdir(fig_dir);
    end

    solve_result = solve_paperA_descriptor_modes(data.LNS_L, data.LNS_Gam, Config);
    masks = build_paperA_mode_masks(data, Config, data.Ny, data.Nx);
    ranking = rank_paperA_modes( ...
        solve_result.EigVals, solve_result.EigVecs, ...
        solve_result.residuals, solve_result.residuals_active, ...
        solve_result.residuals_algebraic, solve_result.residuals_scaled, ...
        data, Config, masks);
    [plot_leading_mode_position, PlotLeadAudit] = select_paperA_plot_lead_index(ranking); %#ok<NASGU>
    [plot_phase_factor_s, PhaseAudit_s] = local_phase_align_modes( ...
        ranking.EigVecs, data.Ny, data.Nx, Config.state_layout, ...
        masks.bubble, masks.near_wall, data.X, data.Y); %#ok<NASGU>
    ModeSelectionAudit = local_build_mode_selection_audit( ...
        ranking.EigVals, ranking.residuals, ranking.metrics.bubble_overlap, ...
        ranking.metrics.near_wall_energy_frac, ranking.metrics.shock_energy_frac, ...
        ranking.metrics.shock_core_energy_frac, ranking.metrics.corner_energy_frac, ...
        ranking.metrics.bad_point_energy_frac, ranking.metrics.free_stream_energy_frac, ...
        ranking.metrics.outlet_energy_frac, ranking.metrics.outlet_wall_energy_frac, ...
        ranking.metrics.checker_ratio, ranking.metrics.u_peak_in_bubble, ...
        ranking.metrics.u_peak_in_shock_core, ranking.metrics.u_peak_in_outlet_wall, ...
        ranking.metrics.u_peak_in_corner, ranking.metrics.u_peak_in_bad_point, ...
        ranking.publication_allowed, ranking.selected_for_plots, ranking.plot_candidate_mask, ...
        ranking.original_mode_index, PhaseAudit_s, ranking.legacy_rejection_tags, ...
        ranking.freq_info.freq_nd_signed(ranking.order), ranking.metrics.family_label, ...
        ranking.metrics.physical_candidate_score, ranking.metrics.bubble_shock_phase_deg, ...
        ranking.metrics.bubble_shock_sync, ranking.metrics.coupled_support_flag); %#ok<NASGU>
    ModeCouplingAudit = local_build_mode_coupling_audit(ranking); %#ok<NASGU>
    ComponentModeAudit = local_build_component_mode_audit(ranking); %#ok<NASGU>
    ModeReferenceTable = local_build_mode_reference_table(ranking); %#ok<NASGU>
    EigenReferenceTable = local_build_eigen_reference_table(ranking, Config); %#ok<NASGU>
    FigureCriteriaTable = local_build_figure_criteria_table(Config); %#ok<NASGU>

    sorted_leading_mode_position = 1;
    sorted_leading_mode_index = ranking.original_mode_index(sorted_leading_mode_position);
    sorted_leading_mode_original_index = sorted_leading_mode_index; %#ok<NASGU>
    plot_leading_mode_index = NaN;
    plot_leading_mode_original_index = NaN; %#ok<NASGU>
    publication_leading_mode_position = NaN;
    publication_leading_mode_index = NaN; %#ok<NASGU>
    publication_candidates = find(ranking.publication_allowed, 1, 'first');
    if isfinite(plot_leading_mode_position)
        plot_leading_mode_index = ranking.original_mode_index(plot_leading_mode_position);
        plot_leading_mode_original_index = plot_leading_mode_index;
    end
    if ~isempty(publication_candidates)
        publication_leading_mode_position = publication_candidates;
        publication_leading_mode_index = ranking.original_mode_index(publication_leading_mode_position);
    end
    ranking.selection_summary.leading_mode_index = sorted_leading_mode_index;
    ranking.selection_summary.leading_mode_original_index = sorted_leading_mode_original_index;
    ranking.selection_summary.leading_mode_position = sorted_leading_mode_position;
    ranking.selection_summary.plot_leading_mode_index = plot_leading_mode_index;
    ranking.selection_summary.plot_leading_mode_original_index = plot_leading_mode_original_index;
    ranking.selection_summary.plot_leading_mode_position = plot_leading_mode_position;
    ranking.selection_summary.publication_leading_mode_index = publication_leading_mode_index;
    ranking.selection_summary.publication_leading_mode_position = publication_leading_mode_position;
    ranking.selection_summary.shift_count = numel(solve_result.SolveAudit.shifts);
    ranking.selection_summary.solver_status = solve_result.SolveAudit.status;
    ranking.selection_summary.plot_lead_status = PlotLeadAudit.status;
    ranking.selection_summary.plot_lead_candidate_count = PlotLeadAudit.candidate_count;
    if isfinite(plot_leading_mode_position)
        ranking.selection_summary.degenerate_frequency_cluster_flag = ...
            ModeSelectionAudit(plot_leading_mode_position).degenerate_frequency_cluster_flag;
        ranking.selection_summary.leading_mode_family = ranking.metrics.family_label{plot_leading_mode_position};
        ranking.selection_summary.leading_physical_candidate_score = ranking.metrics.physical_candidate_score(plot_leading_mode_position);
        mode_validity_report = local_build_mode_validity_report( ...
            ranking.selection_summary, ModeSelectionAudit(plot_leading_mode_position)); %#ok<NASGU>
    else
        ranking.selection_summary.degenerate_frequency_cluster_flag = false;
        ranking.selection_summary.leading_mode_family = '';
        ranking.selection_summary.leading_physical_candidate_score = NaN;
        mode_validity_report = local_build_mode_validity_report(ranking.selection_summary, struct()); %#ok<NASGU>
    end

    EigVals_s = ranking.EigVals; %#ok<NASGU>
    EigVecs_s = ranking.EigVecs; %#ok<NASGU>
    res_s = ranking.residuals; %#ok<NASGU>
    res_active_s = ranking.residuals_active; %#ok<NASGU>
    res_algebraic_s = ranking.residuals_algebraic; %#ok<NASGU>
    res_scaled_s = ranking.residuals_scaled; %#ok<NASGU>
    freq_s = ranking.freq_info.freq_nd_abs(ranking.order); %#ok<NASGU>
    freq_signed_s = ranking.freq_info.freq_nd_signed(ranking.order); %#ok<NASGU>
    OmegaVals_s = ranking.freq_info.omega(ranking.order); %#ok<NASGU>
    ModeDiag = ranking.ModeDiag; %#ok<NASGU>
    ranking_table = ranking.ranking_table; %#ok<NASGU>
    bubble_overlap_s = ranking.metrics.bubble_overlap; %#ok<NASGU>
    wall_energy_frac_s = ranking.metrics.wall_energy_frac; %#ok<NASGU>
    near_wall_energy_frac_s = ranking.metrics.near_wall_energy_frac; %#ok<NASGU>
    free_stream_energy_frac_s = ranking.metrics.free_stream_energy_frac; %#ok<NASGU>
    sponge_energy_frac_s = ranking.metrics.sponge_energy_frac; %#ok<NASGU>
    shock_energy_frac_s = ranking.metrics.shock_energy_frac; %#ok<NASGU>
    outlet_energy_frac_s = ranking.metrics.outlet_energy_frac; %#ok<NASGU>
    outlet_wall_energy_frac_s = ranking.metrics.outlet_wall_energy_frac; %#ok<NASGU>
    checker_ratio_s = ranking.metrics.checker_ratio; %#ok<NASGU>
    p_checker_ratio_s = ranking.metrics.p_checker_ratio; %#ok<NASGU>
    p_free_stream_overlap_s = ranking.metrics.p_free_stream_overlap; %#ok<NASGU>
    p_outlet_overlap_s = ranking.metrics.p_outlet_overlap; %#ok<NASGU>
    p_outlet_wall_overlap_s = ranking.metrics.p_outlet_wall_overlap; %#ok<NASGU>
    p_shock_core_overlap_s = ranking.metrics.p_shock_core_overlap; %#ok<NASGU>
    farfield_ratio_s = ranking.farfield_ratio; %#ok<NASGU>
    highfreq_ratio_s = ranking.highfreq_ratio; %#ok<NASGU>
    corner_energy_frac_s = ranking.metrics.corner_energy_frac; %#ok<NASGU>
    bad_point_energy_frac_s = ranking.metrics.bad_point_energy_frac; %#ok<NASGU>
    ModeFamily_s = ranking.metrics.family_label; %#ok<NASGU>
    physical_candidate_score_s = ranking.metrics.physical_candidate_score; %#ok<NASGU>
    bubble_shock_phase_deg_s = ranking.metrics.bubble_shock_phase_deg; %#ok<NASGU>
    bubble_shock_sync_s = ranking.metrics.bubble_shock_sync; %#ok<NASGU>

    EigVecs_plot_s = bsxfun(@times, ranking.EigVecs, reshape(plot_phase_factor_s, 1, [])); %#ok<NASGU>
    AdjointLeadAudit = struct('enabled', false, 'reason', 'disabled_by_config'); %#ok<NASGU>
    WavemakerLeadMap = []; %#ok<NASGU>
    PlotProvenanceAudit = local_build_default_plot_provenance_audit(Config); %#ok<NASGU>
    if isfinite(plot_leading_mode_position)
        q_lead = EigVecs_plot_s(:, plot_leading_mode_position);
        u_hat = extract_state_component(q_lead, data.Ny, data.Nx, Config.state_layout, 'u'); %#ok<NASGU>
        v_hat = extract_state_component(q_lead, data.Ny, data.Nx, Config.state_layout, 'v'); %#ok<NASGU>
        w_hat = extract_state_component(q_lead, data.Ny, data.Nx, Config.state_layout, 'w'); %#ok<NASGU>
        T_hat = extract_state_component(q_lead, data.Ny, data.Nx, Config.state_layout, 'T'); %#ok<NASGU>
        p_hat = extract_state_component(q_lead, data.Ny, data.Nx, Config.state_layout, 'p'); %#ok<NASGU>
        rho_hat = p_hat ./ max((1.0 / (Config.gamma * Config.Ma_inf^2)) .* data.TT, eps) - ...
            data.RHO .* T_hat ./ max(data.TT, eps); %#ok<NASGU>
        lambda_max = EigVals_s(plot_leading_mode_position); %#ok<NASGU>
        PlotProvenanceAudit = local_build_plot_provenance_audit( ...
            q_lead, data, Config, plot_leading_mode_position, PhaseAudit_s, ranking);
        if Config.analysis.compute_adjoint_lead
            AdjointLeadAudit = compute_direct_adjoint_lead_diagnostic( ...
                data.LNS_L, data.LNS_Gam, ranking.EigVals(plot_leading_mode_position), ...
                ranking.EigVecs(:, plot_leading_mode_position), data, Config, masks);
            WavemakerLeadMap = AdjointLeadAudit.wavemaker_map;
        else
            AdjointLeadAudit = struct('enabled', false, 'reason', 'disabled_by_config');
            WavemakerLeadMap = [];
        end
    else
        u_hat = []; %#ok<NASGU>
        v_hat = []; %#ok<NASGU>
        w_hat = []; %#ok<NASGU>
        T_hat = []; %#ok<NASGU>
        p_hat = []; %#ok<NASGU>
        rho_hat = []; %#ok<NASGU>
        lambda_max = NaN; %#ok<NASGU>
        AdjointLeadAudit = struct('enabled', false, 'reason', 'no_plot_lead');
        WavemakerLeadMap = [];
        PlotProvenanceAudit = local_build_default_plot_provenance_audit(Config);
    end
    lambda_sorted_lead = EigVals_s(sorted_leading_mode_position); %#ok<NASGU>
    lambda_plotted_lead = lambda_max; %#ok<NASGU>
    St_s = freq_s; %#ok<NASGU>
    if isfinite(plot_leading_mode_position)
        St_max = St_s(plot_leading_mode_position); %#ok<NASGU>
        leading_region_energy = struct( ... %#ok<NASGU>
            'bubble', bubble_overlap_s(plot_leading_mode_position), ...
            'near_wall', near_wall_energy_frac_s(plot_leading_mode_position), ...
            'free_stream', free_stream_energy_frac_s(plot_leading_mode_position), ...
            'sponge', sponge_energy_frac_s(plot_leading_mode_position), ...
            'shock', shock_energy_frac_s(plot_leading_mode_position), ...
            'outlet', outlet_energy_frac_s(plot_leading_mode_position), ...
            'outlet_wall', outlet_wall_energy_frac_s(plot_leading_mode_position));
    else
        St_max = NaN; %#ok<NASGU>
        leading_region_energy = struct( ... %#ok<NASGU>
            'bubble', NaN, 'near_wall', NaN, 'free_stream', NaN, ...
            'sponge', NaN, 'shock', NaN, 'outlet', NaN, 'outlet_wall', NaN);
    end
    MatrixHealth = solve_result.MatrixHealth; %#ok<NASGU>
    MatrixHealth.sigma_shift = Config.sigma;
    MatrixHealth.sigma_triplet = Config.sigma_triplet;
    MatrixHealth.krylov_dimension = solve_result.SolveAudit.krylov_dimension;
    freq_label = 'f_nd'; %#ok<NASGU>
    freq_label_long = 'Signed nondimensional frequency from sigma = -i*omega'; %#ok<NASGU>

    X = data.X; %#ok<NASGU>
    Y = data.Y; %#ok<NASGU>
    U = data.U; %#ok<NASGU>
    V = data.V; %#ok<NASGU>
    W = data.W; %#ok<NASGU>
    RHO = data.RHO; %#ok<NASGU>
    PP = data.PP; %#ok<NASGU>
    TT = data.TT; %#ok<NASGU>
    Nx = data.Nx; %#ok<NASGU>
    Ny = data.Ny; %#ok<NASGU>
    BaseflowPhysicsAudit = local_optional_field(data, 'BaseflowPhysicsAudit', struct()); %#ok<NASGU>
    GeometryAudit = local_optional_field(data, 'GeometryAudit', struct()); %#ok<NASGU>
    BaseflowMasks = local_optional_field(data, 'BaseflowMasks', struct()); %#ok<NASGU>
    ShockInfo = local_optional_field(data, 'ShockInfo', struct()); %#ok<NASGU>
    OperatorHealth = local_optional_field(data, 'OperatorHealth', struct()); %#ok<NASGU>
    selection_summary = ranking.selection_summary; %#ok<NASGU>
    selection_summary.sorted_leading_mode_position = sorted_leading_mode_position;
    selection_summary.sorted_leading_mode_index = sorted_leading_mode_index;
    selection_summary.sorted_leading_mode_original_index = sorted_leading_mode_original_index;
    selection_summary.plot_leading_mode_position = plot_leading_mode_position;
    selection_summary.plot_leading_mode_index = plot_leading_mode_index;
    SolveAudit = solve_result.SolveAudit; %#ok<NASGU>
    FigureAudit = struct(); %#ok<NASGU>
    PlotContractAudit = struct(); %#ok<NASGU>

    save('Part4_Results.mat', ...
        'Config', 'EigVals_s', 'EigVecs_s', 'res_s', 'St_s', ...
        'res_active_s', 'res_algebraic_s', 'res_scaled_s', ...
        'freq_s', 'freq_signed_s', 'OmegaVals_s', ...
        'ModeDiag', 'ranking_table', 'bubble_overlap_s', 'wall_energy_frac_s', ...
        'near_wall_energy_frac_s', 'free_stream_energy_frac_s', ...
        'sponge_energy_frac_s', 'shock_energy_frac_s', 'outlet_energy_frac_s', ...
        'outlet_wall_energy_frac_s', 'corner_energy_frac_s', 'bad_point_energy_frac_s', ...
        'checker_ratio_s', 'p_checker_ratio_s', 'p_free_stream_overlap_s', ...
        'p_outlet_overlap_s', 'p_outlet_wall_overlap_s', 'p_shock_core_overlap_s', ...
        'farfield_ratio_s', 'highfreq_ratio_s', ...
        'ModeFamily_s', 'physical_candidate_score_s', ...
        'bubble_shock_phase_deg_s', 'bubble_shock_sync_s', ...
        'lambda_max', 'lambda_sorted_lead', 'lambda_plotted_lead', ...
        'St_max', 'leading_region_energy', ...
        'MatrixHealth', 'u_hat', 'v_hat', 'w_hat', 'T_hat', 'p_hat', ...
        'rho_hat', 'X', 'Y', 'U', 'V', 'W', 'RHO', 'PP', 'TT', 'Nx', 'Ny', ...
        'freq_label', 'freq_label_long', 'selection_summary', ...
        'mode_validity_report', 'ModeSelectionAudit', 'ModeCouplingAudit', 'plot_phase_factor_s', ...
        'PhaseAudit_s', 'SolveAudit', 'BaseflowPhysicsAudit', 'GeometryAudit', ...
        'BaseflowMasks', 'ShockInfo', 'OperatorHealth', ...
        'AdjointLeadAudit', 'WavemakerLeadMap', ...
        'ModeReferenceTable', 'EigenReferenceTable', 'FigureCriteriaTable', ...
        'ComponentModeAudit', 'PlotProvenanceAudit', ...
        'plot_leading_mode_index', 'plot_leading_mode_original_index', ...
        'plot_leading_mode_position', ...
        'publication_leading_mode_index', 'publication_leading_mode_position', ...
        'FigureAudit', 'PlotContractAudit', '-v7.3');

    FigureAudit = write_paperA_reference_figures(fig_dir, ranking, data, Config, plot_phase_factor_s, PhaseAudit_s); %#ok<NASGU>
    PlotContractAudit = local_build_plot_contract_audit( ...
        Config, FigureAudit, ranking.selection_summary, PlotProvenanceAudit, GeometryAudit); %#ok<NASGU>
    save('Part4_Results.mat', 'FigureAudit', 'PlotContractAudit', '-append');
end

function [phase_factors, phase_audit] = local_phase_align_modes(EigVecs, Ny, Nx, state_layout, bubble_mask, near_wall_mask, X, Y)
%LOCAL_PHASE_ALIGN_MODES Phase-align each sorted mode for plotting.

    num_modes = size(EigVecs, 2);
    phase_factors = ones(num_modes, 1);
    phase_audit = repmat(struct('type', 'none', 'row', NaN, 'col', NaN, 'x', NaN, 'y', NaN), num_modes, 1);
    for k = 1:num_modes
        [phase_factors(k), phase_audit(k)] = choose_mode_phase_factor(EigVecs(:, k), Ny, Nx, state_layout, ...
            'BubbleMask', bubble_mask, 'NearWallMask', near_wall_mask, 'X', X, 'Y', Y);
    end
end

function audit = local_build_mode_selection_audit(EigVals, residuals, bubble_overlap, near_wall, ...
        shock_frac, shock_core_frac, corner_frac, bad_point_frac, ...
        free_stream_frac, outlet_frac, outlet_wall_frac, checker_ratio, ...
        u_peak_in_bubble, u_peak_in_shock_core, u_peak_in_outlet_wall, ...
        u_peak_in_corner, u_peak_in_bad_point, publication_allowed, selected_for_plots, ...
        plot_candidate_mask, original_mode_index, phase_audit, legacy_rejection_tags, freq_signed, ...
        mode_family, physical_candidate_score, bubble_shock_phase_deg, bubble_shock_sync, ...
        coupled_support_flag)
%LOCAL_BUILD_MODE_SELECTION_AUDIT Build the per-mode audit struct saved in Part4.

    num_modes = numel(EigVals);
    audit = repmat(struct( ...
        'original_mode_index', 0, ...
        'sigma_r', 0.0, ...
        'sigma_i', 0.0, ...
        'residual', 0.0, ...
        'selected_for_plots', false, ...
        'selected_for_publication', false, ...
        'plot_candidate', false, ...
        'bubble_overlap', 0.0, ...
        'near_wall_energy_frac', 0.0, ...
        'shock_energy_frac', 0.0, ...
        'shock_core_energy_frac', 0.0, ...
        'corner_energy_frac', 0.0, ...
        'bad_point_energy_frac', 0.0, ...
        'free_stream_energy_frac', 0.0, ...
        'outlet_energy_frac', 0.0, ...
        'outlet_wall_energy_frac', 0.0, ...
        'checker_ratio', 0.0, ...
        'u_peak_in_bubble', false, ...
        'u_peak_in_shock_core', false, ...
        'u_peak_in_outlet_wall', false, ...
        'u_peak_in_corner', false, ...
        'u_peak_in_bad_point', false, ...
        'phase_anchor_type', 'none', ...
        'phase_anchor_x', NaN, ...
        'phase_anchor_y', NaN, ...
        'mode_family', '', ...
        'physical_candidate_score', NaN, ...
        'bubble_shock_phase_deg', NaN, ...
        'bubble_shock_sync', NaN, ...
        'coupled_support_flag', false, ...
        'degenerate_frequency_cluster_flag', false, ...
        'legacy_rejection_tags', {{}}, ...
        'freq_signed', 0.0), num_modes, 1);

    for k = 1:num_modes
        audit(k).original_mode_index = original_mode_index(k);
        audit(k).sigma_r = real(EigVals(k));
        audit(k).sigma_i = imag(EigVals(k));
        audit(k).residual = residuals(k);
        audit(k).selected_for_plots = logical(selected_for_plots(k));
        audit(k).selected_for_publication = logical(publication_allowed(k));
        audit(k).plot_candidate = logical(plot_candidate_mask(k));
        audit(k).bubble_overlap = bubble_overlap(k);
        audit(k).near_wall_energy_frac = near_wall(k);
        audit(k).shock_energy_frac = shock_frac(k);
        audit(k).shock_core_energy_frac = shock_core_frac(k);
        audit(k).corner_energy_frac = corner_frac(k);
        audit(k).bad_point_energy_frac = bad_point_frac(k);
        audit(k).free_stream_energy_frac = free_stream_frac(k);
        audit(k).outlet_energy_frac = outlet_frac(k);
        audit(k).outlet_wall_energy_frac = outlet_wall_frac(k);
        audit(k).checker_ratio = checker_ratio(k);
        audit(k).u_peak_in_bubble = logical(u_peak_in_bubble(k));
        audit(k).u_peak_in_shock_core = logical(u_peak_in_shock_core(k));
        audit(k).u_peak_in_outlet_wall = logical(u_peak_in_outlet_wall(k));
        audit(k).u_peak_in_corner = logical(u_peak_in_corner(k));
        audit(k).u_peak_in_bad_point = logical(u_peak_in_bad_point(k));
        audit(k).phase_anchor_type = phase_audit(k).type;
        audit(k).phase_anchor_x = phase_audit(k).x;
        audit(k).phase_anchor_y = phase_audit(k).y;
        audit(k).mode_family = local_value_or_default(mode_family, k, '');
        audit(k).physical_candidate_score = local_value_or_default(physical_candidate_score, k, NaN);
        audit(k).bubble_shock_phase_deg = local_value_or_default(bubble_shock_phase_deg, k, NaN);
        audit(k).bubble_shock_sync = local_value_or_default(bubble_shock_sync, k, NaN);
        audit(k).coupled_support_flag = logical(local_value_or_default(coupled_support_flag, k, false));
        audit(k).degenerate_frequency_cluster_flag = any(abs(freq_signed(k) - freq_signed) < 1.0e-8) && num_modes > 1;
        audit(k).legacy_rejection_tags = legacy_rejection_tags{k};
        audit(k).freq_signed = freq_signed(k);
    end
end

function audit = local_build_mode_coupling_audit(ranking)
%LOCAL_BUILD_MODE_COUPLING_AUDIT Save one compact per-mode coupling audit.

    num_modes = numel(ranking.EigVals);
    audit = repmat(struct( ...
        'original_mode_index', 0, ...
        'sigma_r', 0.0, ...
        'sigma_i', 0.0, ...
        'mode_family', '', ...
        'reference_component', '', ...
        'physical_candidate_score', NaN, ...
        'bubble_overlap', NaN, ...
        'bubble_support_overlap', NaN, ...
        'near_wall_energy_frac', NaN, ...
        'shock_energy_frac', NaN, ...
        'shock_core_energy_frac', NaN, ...
        'outlet_wall_energy_frac', NaN, ...
        'free_stream_energy_frac', NaN, ...
        'bubble_shock_phase_deg', NaN, ...
        'bubble_shock_sync', NaN, ...
        'coupled_support_flag', false, ...
        'shock_dominated_flag', false, ...
        'boundary_supported_flag', false, ...
        'compact_interior_flag', false), num_modes, 1);

    for k = 1:num_modes
        audit(k).original_mode_index = ranking.original_mode_index(k);
        audit(k).sigma_r = real(ranking.EigVals(k));
        audit(k).sigma_i = imag(ranking.EigVals(k));
        audit(k).mode_family = local_value_or_default(ranking.metrics.family_label, k, '');
        audit(k).reference_component = local_value_or_default(ranking.metrics.reference_component, k, '');
        audit(k).physical_candidate_score = local_value_or_default(ranking.metrics.physical_candidate_score, k, NaN);
        audit(k).bubble_overlap = local_value_or_default(ranking.metrics.bubble_overlap, k, NaN);
        audit(k).bubble_support_overlap = local_value_or_default(ranking.metrics.bubble_support_overlap, k, NaN);
        audit(k).near_wall_energy_frac = local_value_or_default(ranking.metrics.near_wall_energy_frac, k, NaN);
        audit(k).shock_energy_frac = local_value_or_default(ranking.metrics.shock_energy_frac, k, NaN);
        audit(k).shock_core_energy_frac = local_value_or_default(ranking.metrics.shock_core_energy_frac, k, NaN);
        audit(k).outlet_wall_energy_frac = local_value_or_default(ranking.metrics.outlet_wall_energy_frac, k, NaN);
        audit(k).free_stream_energy_frac = local_value_or_default(ranking.metrics.free_stream_energy_frac, k, NaN);
        audit(k).bubble_shock_phase_deg = local_value_or_default(ranking.metrics.bubble_shock_phase_deg, k, NaN);
        audit(k).bubble_shock_sync = local_value_or_default(ranking.metrics.bubble_shock_sync, k, NaN);
        audit(k).coupled_support_flag = logical(local_value_or_default(ranking.metrics.coupled_support_flag, k, false));
        audit(k).shock_dominated_flag = logical(local_value_or_default(ranking.metrics.shock_dominated_flag, k, false));
        audit(k).boundary_supported_flag = logical(local_value_or_default(ranking.metrics.boundary_supported_flag, k, false));
        audit(k).compact_interior_flag = logical(local_value_or_default(ranking.metrics.compact_interior_flag, k, false));
    end
end

function audit = local_build_component_mode_audit(ranking)
%LOCAL_BUILD_COMPONENT_MODE_AUDIT Save component-level support and peak diagnostics per mode.

    num_modes = numel(ranking.EigVals);
    component_names = {'u', 'v', 'w', 'T', 'p'};
    audit = repmat(struct( ...
        'original_mode_index', 0, ...
        'mode_family', '', ...
        'reference_component', '', ...
        'components', struct()), num_modes, 1);

    for k = 1:num_modes
        audit(k).original_mode_index = ranking.original_mode_index(k);
        audit(k).mode_family = local_value_or_default(ranking.metrics.family_label, k, '');
        audit(k).reference_component = local_value_or_default(ranking.metrics.reference_component, k, '');
        component_struct = struct();
        for c = 1:numel(component_names)
            name = component_names{c};
            component_struct.(name) = struct( ...
                'checker_ratio', local_component_metric_value(ranking.metrics, name, 'checker_ratio', k, NaN), ...
                'bubble_core_overlap', local_component_metric_value(ranking.metrics, name, 'bubble_core_overlap', k, NaN), ...
                'bubble_support_overlap', local_component_metric_value(ranking.metrics, name, 'bubble_support_overlap', k, NaN), ...
                'shock_overlap', local_component_metric_value(ranking.metrics, name, 'shock_overlap', k, NaN), ...
                'shock_core_overlap', local_component_metric_value(ranking.metrics, name, 'shock_core_overlap', k, NaN), ...
                'outlet_overlap', local_component_metric_value(ranking.metrics, name, 'outlet_overlap', k, NaN), ...
                'outlet_wall_overlap', local_component_metric_value(ranking.metrics, name, 'outlet_wall_overlap', k, NaN), ...
                'free_stream_overlap', local_component_metric_value(ranking.metrics, name, 'free_stream_overlap', k, NaN), ...
                'near_wall_overlap', local_component_metric_value(ranking.metrics, name, 'near_wall_overlap', k, NaN), ...
                'peak_row', local_component_metric_value(ranking.metrics, name, 'peak_row', k, NaN), ...
                'peak_col', local_component_metric_value(ranking.metrics, name, 'peak_col', k, NaN), ...
                'peak_in_bubble', logical(local_component_metric_value(ranking.metrics, name, 'peak_in_bubble', k, false)), ...
                'peak_in_bubble_support', logical(local_component_metric_value(ranking.metrics, name, 'peak_in_bubble_support', k, false)), ...
                'peak_in_shock_core', logical(local_component_metric_value(ranking.metrics, name, 'peak_in_shock_core', k, false)), ...
                'peak_in_outlet_wall', logical(local_component_metric_value(ranking.metrics, name, 'peak_in_outlet_wall', k, false)), ...
                'peak_in_free_stream', logical(local_component_metric_value(ranking.metrics, name, 'peak_in_free_stream', k, false)));
        end
        audit(k).components = component_struct;
    end
end

function tbl = local_build_mode_reference_table(ranking)
%LOCAL_BUILD_MODE_REFERENCE_TABLE Build one literature-facing mode-property table.

    num_modes = numel(ranking.EigVals);
    stationary_flag = abs(ranking.freq_info.freq_nd_signed(ranking.order)) <= 1.0e-2;
    stationary_label = repmat("oscillatory", num_modes, 1);
    stationary_label(stationary_flag) = "stationary";
    tbl = table( ...
        (1:num_modes).', ...
        ranking.original_mode_index(:), ...
        string(local_value_or_default(ranking.metrics.family_label, 1:num_modes, repmat({''}, num_modes, 1))), ...
        stationary_label, ...
        string(local_value_or_default(ranking.metrics.reference_component, 1:num_modes, repmat({''}, num_modes, 1))), ...
        ranking.metrics.bubble_support_overlap(:), ...
        ranking.metrics.shock_energy_frac(:), ...
        ranking.metrics.near_wall_energy_frac(:), ...
        ranking.plot_candidate_mask(:), ...
        ranking.selected_for_plots(:), ...
        'VariableNames', {'mode_position', 'original_mode_index', 'mode_family', ...
        'stationary_or_oscillatory', 'reference_component', 'bubble_support', ...
        'shock_support', 'near_wall_support', 'plot_candidate', 'selected_for_plots'});
end

function tbl = local_build_eigen_reference_table(ranking, Config)
%LOCAL_BUILD_EIGEN_REFERENCE_TABLE Build one compact eigenvalue/frequency table.

    num_modes = numel(ranking.EigVals);
    tbl = table( ...
        (1:num_modes).', ...
        ranking.original_mode_index(:), ...
        real(ranking.EigVals(:)), ...
        imag(ranking.EigVals(:)), ...
        ranking.freq_info.freq_nd_signed(ranking.order), ...
        repmat(Config.beta, num_modes, 1), ...
        string(local_value_or_default(ranking.metrics.family_label, 1:num_modes, repmat({''}, num_modes, 1))), ...
        repmat("code_correction_stage", num_modes, 1), ...
        'VariableNames', {'mode_position', 'original_mode_index', 'sigma_r', 'sigma_i', ...
        'freq_signed', 'beta', 'mode_family', 'exactness'});
end

function tbl = local_build_figure_criteria_table(Config)
%LOCAL_BUILD_FIGURE_CRITERIA_TABLE Build one figure acceptance/rejection table.

    target = local_get_target_benchmark(Config);
    if strcmpi(target, 'Sidharth2018')
        pass_signal_mode = 'bubble-centred mode with visible w'' support in the separation bubble';
        reject_signal_mode = 'compact upper-layer packet or shock-only packet';
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

function audit = local_build_default_plot_provenance_audit(Config)
%LOCAL_BUILD_DEFAULT_PLOT_PROVENANCE_AUDIT Build the no-plot default provenance payload.

    audit = struct();
    audit.has_plot_lead = false;
    audit.normalization = 'energy_total_l2';
    audit.normalization_scale = NaN;
    audit.phase_anchor_type = 'none';
    audit.phase_anchor_x = NaN;
    audit.phase_anchor_y = NaN;
    audit.plot_mode_position = NaN;
    audit.reference_component = '';
    audit.target_benchmark = local_get_target_benchmark(Config);
end

function audit = local_build_plot_provenance_audit(q_lead, data, Config, plot_position, PhaseAudit_s, ranking)
%LOCAL_BUILD_PLOT_PROVENANCE_AUDIT Save the exact lead-mode plotting provenance.

    audit = local_build_default_plot_provenance_audit(Config);
    audit.has_plot_lead = true;
    audit.plot_mode_position = plot_position;
    audit.reference_component = local_value_or_default(ranking.metrics.reference_component, plot_position, '');
    audit.normalization_scale = local_component_energy_scale( ...
        q_lead, data.Ny, data.Nx, data.RHO, Config.Cv_nd, Config.state_layout);
    audit.phase_anchor_type = PhaseAudit_s(plot_position).type;
    audit.phase_anchor_x = PhaseAudit_s(plot_position).x;
    audit.phase_anchor_y = PhaseAudit_s(plot_position).y;
end

function audit = local_build_plot_contract_audit(Config, FigureAudit, selection_summary, PlotProvenanceAudit, GeometryAudit)
%LOCAL_BUILD_PLOT_CONTRACT_AUDIT Save the active plotting contract and generated outputs.

    audit = struct();
    audit.primary_plot_contract = local_optional_field(Config, 'plot_contract', '');
    audit.secondary_plot_contract = local_optional_field(Config, 'secondary_plot_contract', '');
    audit.target_benchmark = local_get_target_benchmark(Config);
    audit.selection_status = selection_summary.status;
    audit.plot_status = local_optional_field(selection_summary, 'plot_status', '');
    audit.has_plot_lead = PlotProvenanceAudit.has_plot_lead;
    audit.reference_component = PlotProvenanceAudit.reference_component;
    audit.normalization = PlotProvenanceAudit.normalization;
    audit.normalization_scale = PlotProvenanceAudit.normalization_scale;
    audit.phase_anchor_type = PlotProvenanceAudit.phase_anchor_type;
    audit.phase_anchor_x = PlotProvenanceAudit.phase_anchor_x;
    audit.phase_anchor_y = PlotProvenanceAudit.phase_anchor_y;
    audit.generated_files = local_optional_field(FigureAudit, 'output_files', {});
    audit.sidharth_generated_files = local_optional_field(FigureAudit, 'sidharth_output_files', {});
    audit.figure_status = local_optional_field(FigureAudit, 'status', '');
    audit.bubble_window = local_optional_field(GeometryAudit, 'bubble_window', [NaN, NaN, NaN, NaN]);
end

function validity = local_build_mode_validity_report(selection_summary, leading_audit)
%LOCAL_BUILD_MODE_VALIDITY_REPORT Report whether the leading plotted mode is publication-ready.

    validity = struct();
    validity.selection_status = selection_summary.status;
    validity.mode_family = '';
    validity.physical_candidate_score = NaN;
    validity.bubble_shock_phase_deg = NaN;
    validity.bubble_shock_sync = NaN;
    validity.coupled_support_flag = false;
    if nargin < 2 || ~isstruct(leading_audit) || isempty(fieldnames(leading_audit))
        validity.publication_allowed = false;
        validity.debug_only = true;
        validity.primary_reason = 'no_physical_plot_candidate';
        validity.title_prefix = 'No physical plot candidate';
        validity.legacy_rejection_tags = {};
        return;
    end

    if isfield(leading_audit, 'mode_family')
        validity.mode_family = leading_audit.mode_family;
    end
    if isfield(leading_audit, 'physical_candidate_score')
        validity.physical_candidate_score = leading_audit.physical_candidate_score;
    end
    if isfield(leading_audit, 'bubble_shock_phase_deg')
        validity.bubble_shock_phase_deg = leading_audit.bubble_shock_phase_deg;
    end
    if isfield(leading_audit, 'bubble_shock_sync')
        validity.bubble_shock_sync = leading_audit.bubble_shock_sync;
    end
    if isfield(leading_audit, 'coupled_support_flag')
        validity.coupled_support_flag = logical(leading_audit.coupled_support_flag);
    end

    validity.publication_allowed = leading_audit.selected_for_publication;
    validity.debug_only = ~validity.publication_allowed;
    if validity.publication_allowed
        if validity.coupled_support_flag
            validity.primary_reason = 'paperA_coupled_physical_mode';
            validity.title_prefix = 'Paper-A coupled leading mode';
        else
            validity.primary_reason = 'paperA_physical_mode';
            validity.title_prefix = 'Paper-A physical leading mode';
        end
    else
        if ~leading_audit.plot_candidate
            validity.primary_reason = 'not_even_plot_candidate';
        elseif leading_audit.checker_ratio >= 5.0
            validity.primary_reason = 'checker_ratio_too_large';
        elseif leading_audit.bubble_overlap <= 0.05
            validity.primary_reason = 'bubble_support_too_low';
        elseif leading_audit.near_wall_energy_frac <= 0.10
            validity.primary_reason = 'near_wall_support_too_low';
        elseif leading_audit.shock_energy_frac >= 0.35
            validity.primary_reason = 'shock_energy_too_high';
        elseif leading_audit.outlet_wall_energy_frac >= 0.20 || leading_audit.u_peak_in_outlet_wall
            validity.primary_reason = 'outlet_wall_energy_too_high';
        elseif leading_audit.free_stream_energy_frac >= 0.20
            validity.primary_reason = 'free_stream_energy_too_high';
        elseif isfield(leading_audit, 'mode_family') && strcmp(leading_audit.mode_family, 'boundary_supported')
            validity.primary_reason = 'boundary_supported_mode';
        elseif isfield(leading_audit, 'mode_family') && strcmp(leading_audit.mode_family, 'shock_dominated')
            validity.primary_reason = 'shock_dominated_mode';
        else
            validity.primary_reason = 'residual_or_quality_gate_failed';
        end
        validity.title_prefix = sprintf('Debug-leading mode (%s)', validity.primary_reason);
    end
    validity.legacy_rejection_tags = leading_audit.legacy_rejection_tags;
end

function value = local_value_or_default(values, index, default_value)
%LOCAL_VALUE_OR_DEFAULT Read one vector/cell/string entry with fallback.

    if nargin < 3
        default_value = [];
    end
    value = default_value;
    if isempty(values)
        return;
    end
    if isnumeric(index) && numel(index) > 1
        if iscell(values)
            value = values(index);
        elseif isstring(values)
            value = values(index);
        elseif isnumeric(values) || islogical(values)
            value = values(index);
        end
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

function value = local_component_metric_value(metrics, component_name, field_name, index, default_value)
%LOCAL_COMPONENT_METRIC_VALUE Read one nested component metric with fallback.

    value = default_value;
    if ~isstruct(metrics) || ~isfield(metrics, 'component_support') || ...
            ~isstruct(metrics.component_support) || ~isfield(metrics.component_support, component_name)
        return;
    end
    component_metrics = metrics.component_support.(component_name);
    if ~isstruct(component_metrics) || ~isfield(component_metrics, field_name)
        return;
    end
    value = local_value_or_default(component_metrics.(field_name), index, default_value);
end

function value = local_optional_field(S, name, default_value)
%LOCAL_OPTIONAL_FIELD Return one optional field from a loaded MAT struct.

    if isstruct(S) && isfield(S, name)
        value = S.(name);
    else
        value = default_value;
    end
end

function Config = local_normalize_config(Config)
%LOCAL_NORMALIZE_CONFIG Force the v6 Paper-A defaults.

    Config.state_layout = 'primitive5_u_v_w_T_p';
    Config.operator_model = 'paperA_primitive5_direct_v6';
    if ~isfield(Config, 'n_eigs') || isempty(Config.n_eigs)
        Config.n_eigs = 80;
    end
    if ~isfield(Config, 'sigma') || isempty(Config.sigma)
        Config.sigma = 0.05 + 0.02i;
    end
    if ~isfield(Config, 'sigma_triplet') || isempty(Config.sigma_triplet)
        Config.sigma_triplet = [0.00 + 0.005i, 0.00 + 0.010i, 0.00 + 0.020i, 0.02 + 0.020i, 0.05 + 0.020i];
    end
    if ~isfield(Config, 'krylov_dimension_floor')
        Config.krylov_dimension_floor = 120;
    end
    if ~isfield(Config, 'krylov_dimension_cap')
        Config.krylov_dimension_cap = 180;
    end
    if ~isfield(Config, 'mode_filter') || isempty(Config.mode_filter)
        Config.mode_filter = struct();
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
    if ~isfield(Config.mode_filter, 'near_wall_fraction')
        Config.mode_filter.near_wall_fraction = 0.15;
    end
    if ~isfield(Config.mode_filter, 'bubble_fraction_threshold')
        Config.mode_filter.bubble_fraction_threshold = 0.05;
    end
    if ~isfield(Config.mode_filter, 'shock_fraction_threshold')
        Config.mode_filter.shock_fraction_threshold = 0.35;
    end
    if ~isfield(Config.mode_filter, 'free_stream_fraction_threshold')
        Config.mode_filter.free_stream_fraction_threshold = 0.20;
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
    if ~isfield(Config.mode_filter, 'coupled_mode_shock_min_threshold')
        Config.mode_filter.coupled_mode_shock_min_threshold = 0.08;
    end
    if ~isfield(Config.mode_filter, 'coupled_mode_shock_max_threshold')
        Config.mode_filter.coupled_mode_shock_max_threshold = 0.65;
    end
    if ~isfield(Config.mode_filter, 'coupled_mode_phase_sync_threshold')
        Config.mode_filter.coupled_mode_phase_sync_threshold = -0.10;
    end
    if ~isfield(Config.mode_filter, 'stationary_frequency_threshold')
        Config.mode_filter.stationary_frequency_threshold = 1.0e-2;
    end
    if ~isfield(Config, 'analysis') || ~isstruct(Config.analysis)
        Config.analysis = struct();
    end
    if ~isfield(Config.analysis, 'compute_adjoint_lead')
        Config.analysis.compute_adjoint_lead = false;
    end
    if ~isfield(Config, 'plot_debug_fields')
        Config.plot_debug_fields = false;
    end
    if ~isfield(Config, 'plot_debug_mode_diagnosis')
        Config.plot_debug_mode_diagnosis = false;
    end
    if ~isfield(Config, 'target_benchmark')
        Config.target_benchmark = '';
    end
    if ~isfield(Config, 'secondary_plot_contract')
        Config.secondary_plot_contract = '';
    end
end

function target = local_get_target_benchmark(Config)
%LOCAL_GET_TARGET_BENCHMARK Read the benchmark target with backward compatibility.

    target = '';
    if isstruct(Config) && isfield(Config, 'target_benchmark')
        target = char(string(Config.target_benchmark));
    elseif isstruct(Config) && isfield(Config, 'benchmark') && isstruct(Config.benchmark) && ...
            isfield(Config.benchmark, 'target_benchmark')
        target = char(string(Config.benchmark.target_benchmark));
    end
end

function scale = local_component_energy_scale(q_mode, Ny, Nx, RHO, Cv_nd, state_layout)
%LOCAL_COMPONENT_ENERGY_SCALE Match the plotting normalization used for field figures.

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
