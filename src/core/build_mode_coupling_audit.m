function coupling = build_mode_coupling_audit(EigVecs, Ny, Nx, data, Config, masks, mode_metrics)
%BUILD_MODE_COUPLING_AUDIT Classify bubble/shock support and phase coupling.

    num_modes = size(EigVecs, 2);
    if nargin < 7
        mode_metrics = struct();
    end

    coupling = struct();
    coupling.reference_component = repmat({''}, num_modes, 1);
    coupling.family_label = repmat({'mixed_uncertain'}, num_modes, 1);
    coupling.family_priority = 3 * ones(num_modes, 1);
    coupling.physical_candidate_score = -inf(num_modes, 1);
    coupling.bubble_shock_phase_deg = nan(num_modes, 1);
    coupling.bubble_shock_sync = nan(num_modes, 1);
    coupling.bubble_complex_amp = complex(nan(num_modes, 1));
    coupling.shock_complex_amp = complex(nan(num_modes, 1));
    coupling.bubble_support_flag = false(num_modes, 1);
    coupling.coupled_support_flag = false(num_modes, 1);
    coupling.shock_dominated_flag = false(num_modes, 1);
    coupling.boundary_supported_flag = false(num_modes, 1);
    coupling.compact_interior_flag = false(num_modes, 1);

    bubble_support_threshold = local_get_mode_filter(Config, 'bubble_support_fraction_threshold', 0.05);
    shock_fraction_threshold = local_get_mode_filter(Config, 'shock_fraction_threshold', 0.35);
    shock_core_fraction_threshold = local_get_mode_filter(Config, 'shock_core_fraction_threshold', 0.15);
    free_stream_threshold = local_get_mode_filter(Config, 'free_stream_fraction_threshold', 0.20);
    outlet_threshold = local_get_mode_filter(Config, 'outlet_fraction_threshold', 0.35);
    outlet_wall_threshold = local_get_mode_filter(Config, 'outlet_wall_fraction_threshold', 0.20);
    coupled_shock_min = local_get_mode_filter(Config, 'coupled_mode_shock_min_threshold', 0.08);
    coupled_shock_max = local_get_mode_filter(Config, 'coupled_mode_shock_max_threshold', 0.65);
    coupled_sync_threshold = local_get_mode_filter(Config, 'coupled_mode_phase_sync_threshold', -0.10);

    if isfield(data, 'RHO') && ~isempty(data.RHO)
        rho_ref = data.RHO;
    else
        rho_ref = ones(Ny, Nx);
    end
    if isfield(Config, 'Cv_nd') && ~isempty(Config.Cv_nd)
        Cv_nd = Config.Cv_nd;
    else
        Cv_nd = 0.0;
    end

    has_outlet_wall_peak = local_get_metric_field(mode_metrics, 'u_peak_in_outlet_wall', false(num_modes, 1));
    has_outlet_peak = local_get_metric_field(mode_metrics, 'u_peak_in_outlet', false(num_modes, 1));
    has_shock_peak = local_get_metric_field(mode_metrics, 'u_peak_in_shock_core', false(num_modes, 1));
    bubble_support = local_get_metric_field(mode_metrics, 'bubble_support_overlap', zeros(num_modes, 1));
    near_wall = local_get_metric_field(mode_metrics, 'near_wall_energy_frac', zeros(num_modes, 1));
    shock_frac = local_get_metric_field(mode_metrics, 'shock_energy_frac', zeros(num_modes, 1));
    shock_core_frac = local_get_metric_field(mode_metrics, 'shock_core_energy_frac', zeros(num_modes, 1));
    outlet_frac = local_get_metric_field(mode_metrics, 'outlet_energy_frac', zeros(num_modes, 1));
    outlet_wall_frac = local_get_metric_field(mode_metrics, 'outlet_wall_energy_frac', zeros(num_modes, 1));
    free_stream_frac = local_get_metric_field(mode_metrics, 'free_stream_energy_frac', zeros(num_modes, 1));
    checker_ratio = local_get_metric_field(mode_metrics, 'checker_ratio', zeros(num_modes, 1));

    for k = 1:num_modes
        q_mode = EigVecs(:, k);
        coupling.reference_component{k} = local_choose_reference_component(q_mode, Ny, Nx, Config.state_layout, masks);
        field_ref = extract_state_component(q_mode, Ny, Nx, Config.state_layout, coupling.reference_component{k});
        [bubble_amp, shock_amp, bubble_phase, sync_value] = local_region_phase_signature( ...
            field_ref, masks.bubble_support, masks.shock);
        coupling.bubble_complex_amp(k) = bubble_amp;
        coupling.shock_complex_amp(k) = shock_amp;
        coupling.bubble_shock_phase_deg(k) = bubble_phase;
        coupling.bubble_shock_sync(k) = sync_value;

        bubble_like = bubble_support(k) > bubble_support_threshold;
        coupled_like = bubble_like && ...
            shock_frac(k) >= coupled_shock_min && ...
            shock_frac(k) <= coupled_shock_max && ...
            shock_core_frac(k) < max(0.25, shock_core_fraction_threshold + 0.08) && ...
            isfinite(sync_value) && sync_value >= coupled_sync_threshold;
        boundary_like = ...
            (free_stream_frac(k) > free_stream_threshold) || ...
            (outlet_frac(k) > outlet_threshold) || ...
            (outlet_wall_frac(k) > outlet_wall_threshold) || ...
            has_outlet_wall_peak(k) || has_outlet_peak(k);
        shock_dominated = ...
            (shock_frac(k) > shock_fraction_threshold) && ...
            (bubble_support(k) < 0.75 * bubble_support_threshold || has_shock_peak(k));
        compact_interior = ...
            ~bubble_like && ~boundary_like && ...
            shock_frac(k) < max(0.50, shock_fraction_threshold + 0.10) && ...
            checker_ratio(k) < 0.50;

        coupling.bubble_support_flag(k) = bubble_like;
        coupling.coupled_support_flag(k) = coupled_like;
        coupling.boundary_supported_flag(k) = boundary_like;
        coupling.shock_dominated_flag(k) = shock_dominated;
        coupling.compact_interior_flag(k) = compact_interior;

        if boundary_like
            coupling.family_label{k} = 'boundary_supported';
            coupling.family_priority(k) = 4;
        elseif shock_dominated
            coupling.family_label{k} = 'shock_dominated';
            coupling.family_priority(k) = 3;
        elseif coupled_like
            coupling.family_label{k} = 'shock_bubble_coupled';
            coupling.family_priority(k) = 1;
        elseif bubble_like
            coupling.family_label{k} = 'bubble_centred';
            coupling.family_priority(k) = 0;
        elseif compact_interior
            coupling.family_label{k} = 'compact_interior_candidate';
            coupling.family_priority(k) = 2;
        else
            coupling.family_label{k} = 'mixed_uncertain';
            coupling.family_priority(k) = 2;
        end

        support_field = compute_mode_support_field(q_mode, Ny, Nx, Config.state_layout, rho_ref, Cv_nd, ...
            'Weighting', 'component_energy');
        total_support = sum(support_field(:));
        if total_support <= 0
            total_support = 1.0;
        end

        score = 0.0;
        score = score + 10.0 * bubble_support(k);
        score = score + 3.5 * near_wall(k);
        score = score - 3.0 * free_stream_frac(k);
        score = score - 2.5 * outlet_frac(k);
        score = score - 4.0 * outlet_wall_frac(k);
        score = score - 5.0 * shock_core_frac(k);
        score = score - 0.5 * checker_ratio(k);
        if coupled_like
            score = score + 2.0 + 2.0 * max(sync_value, 0.0);
        elseif bubble_like
            score = score + 2.5;
        elseif shock_dominated
            score = score - 2.5;
        elseif boundary_like
            score = score - 4.0;
        end
        coupling.physical_candidate_score(k) = score;
    end
end

function value = local_get_metric_field(mode_metrics, name, default_value)
%LOCAL_GET_METRIC_FIELD Read one optional metric vector.

    if isstruct(mode_metrics) && isfield(mode_metrics, name)
        value = mode_metrics.(name);
    else
        value = default_value;
    end
end

function value = local_get_mode_filter(Config, field_name, default_value)
%LOCAL_GET_MODE_FILTER One backward-compatible threshold getter.

    value = default_value;
    if isfield(Config, 'mode_filter') && isstruct(Config.mode_filter) && ...
            isfield(Config.mode_filter, field_name)
        value = Config.mode_filter.(field_name);
    end
end

function component_name = local_choose_reference_component(q_mode, Ny, Nx, layout_name, masks)
%LOCAL_CHOOSE_REFERENCE_COMPONENT Prefer w when the mode is truly three-dimensional.

    w_field = extract_state_component(q_mode, Ny, Nx, layout_name, 'w');
    if ~all(isnan(w_field(:)))
        bubble_w = sum(abs(w_field(masks.bubble_support)));
        shock_w = sum(abs(w_field(masks.shock)));
        if bubble_w + shock_w > 1.0e-12
            component_name = 'w';
            return;
        end
    end

    u_field = extract_state_component(q_mode, Ny, Nx, layout_name, 'u');
    if ~all(isnan(u_field(:))) && sum(abs(u_field(:))) > 0
        component_name = 'u';
        return;
    end

    v_field = extract_state_component(q_mode, Ny, Nx, layout_name, 'v');
    if ~all(isnan(v_field(:))) && sum(abs(v_field(:))) > 0
        component_name = 'v';
        return;
    end

    component_name = 'p';
end

function [bubble_amp, shock_amp, phase_deg, sync_value] = local_region_phase_signature(field_ref, bubble_mask, shock_mask)
%LOCAL_REGION_PHASE_SIGNATURE Average one complex field over bubble and shock support.

    bubble_amp = complex(NaN);
    shock_amp = complex(NaN);
    phase_deg = NaN;
    sync_value = NaN;
    if all(isnan(field_ref(:))) || ~any(bubble_mask(:)) || ~any(shock_mask(:))
        return;
    end

    bubble_values = field_ref(bubble_mask);
    shock_values = field_ref(shock_mask);
    bubble_weights = abs(bubble_values);
    shock_weights = abs(shock_values);
    if sum(bubble_weights) <= 1.0e-14 || sum(shock_weights) <= 1.0e-14
        return;
    end

    bubble_amp = sum(bubble_values .* bubble_weights) / sum(bubble_weights);
    shock_amp = sum(shock_values .* shock_weights) / sum(shock_weights);
    phase_deg = rad2deg(angle(bubble_amp * conj(shock_amp)));
    sync_value = cosd(phase_deg);
end
