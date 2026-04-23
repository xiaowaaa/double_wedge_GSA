function thresholds = build_paperA_mode_filter_thresholds(Config, structural_only)
%BUILD_PAPERA_MODE_FILTER_THRESHOLDS Resolve the active Part4 ranking gates.

    if nargin < 2 || isempty(structural_only)
        structural_only = false;
    end

    thresholds = struct();
    thresholds.support_weighting = local_get_mode_filter(Config, 'support_weighting', 'component_energy');
    thresholds.free_stream_eta_threshold = local_get_mode_filter(Config, 'free_stream_eta_threshold', 0.50);
    thresholds.residual_threshold = local_get_mode_filter(Config, 'residual_threshold', 1.0e-4);
    thresholds.checker_threshold = local_get_mode_filter(Config, 'checker_threshold', 5.0);
    thresholds.checker_threshold_structural = local_get_mode_filter(Config, 'checker_threshold_structural', 20.0);
    thresholds.checker_threshold_used = thresholds.checker_threshold;
    if structural_only
        thresholds.checker_threshold_used = thresholds.checker_threshold_structural;
    end

    thresholds.bubble_fraction_threshold = local_get_mode_filter(Config, 'bubble_fraction_threshold', 0.05);
    thresholds.bubble_core_fraction_threshold = local_get_mode_filter( ...
        Config, 'bubble_core_fraction_threshold', max(0.02, 0.50 * thresholds.bubble_fraction_threshold));
    thresholds.bubble_support_fraction_threshold = local_get_mode_filter( ...
        Config, 'bubble_support_fraction_threshold', thresholds.bubble_fraction_threshold);
    thresholds.near_wall_support_threshold = local_get_mode_filter(Config, 'near_wall_support_threshold', 0.10);
    thresholds.shock_fraction_threshold = local_get_mode_filter(Config, 'shock_fraction_threshold', 0.35);
    thresholds.shock_core_fraction_threshold = local_get_mode_filter(Config, 'shock_core_fraction_threshold', 0.15);
    thresholds.free_stream_fraction_threshold = local_get_mode_filter(Config, 'free_stream_fraction_threshold', 0.20);
    thresholds.outlet_fraction_threshold = local_get_mode_filter(Config, 'outlet_fraction_threshold', 0.35);
    thresholds.outlet_wall_fraction_threshold = local_get_mode_filter(Config, 'outlet_wall_fraction_threshold', 0.20);

    thresholds.pressure_checker_threshold = local_get_mode_filter(Config, 'pressure_checker_threshold', 1.5);
    thresholds.pressure_checker_threshold_structural = local_get_mode_filter( ...
        Config, 'pressure_checker_threshold_structural', 1.5);
    thresholds.pressure_checker_threshold_used = thresholds.pressure_checker_threshold;
    if structural_only
        thresholds.pressure_checker_threshold_used = thresholds.pressure_checker_threshold_structural;
    end
    thresholds.pressure_free_stream_fraction_threshold = local_get_mode_filter( ...
        Config, 'pressure_free_stream_fraction_threshold', 0.35);
    thresholds.pressure_outlet_fraction_threshold = local_get_mode_filter( ...
        Config, 'pressure_outlet_fraction_threshold', 0.40);
    thresholds.pressure_outlet_wall_fraction_threshold = local_get_mode_filter( ...
        Config, 'pressure_outlet_wall_fraction_threshold', thresholds.outlet_wall_fraction_threshold);
    thresholds.pressure_shock_core_fraction_threshold = local_get_mode_filter( ...
        Config, 'pressure_shock_core_fraction_threshold', max(0.20, thresholds.shock_core_fraction_threshold + 0.05));

    thresholds.coupled_mode_shock_min_threshold = local_get_mode_filter(Config, 'coupled_mode_shock_min_threshold', 0.08);
    thresholds.coupled_mode_shock_max_threshold = local_get_mode_filter(Config, 'coupled_mode_shock_max_threshold', 0.65);
    thresholds.coupled_mode_phase_sync_threshold = local_get_mode_filter(Config, 'coupled_mode_phase_sync_threshold', -0.10);
    thresholds.stationary_frequency_threshold = local_get_mode_filter(Config, 'stationary_frequency_threshold', 1.0e-2);

    thresholds.plot_free_stream_fraction_threshold = local_get_mode_filter(Config, 'plot_free_stream_fraction_threshold', 0.50);
    thresholds.plot_outlet_wall_fraction_threshold = local_get_mode_filter( ...
        Config, 'plot_outlet_wall_fraction_threshold', max(0.35, thresholds.outlet_wall_fraction_threshold + 0.10));
    thresholds.plot_gallery_limit = max(1, round(local_get_mode_filter(Config, 'plot_gallery_limit', 4)));
end

function value = local_get_mode_filter(Config, field_name, default_value)
%LOCAL_GET_MODE_FILTER Return one mode-filter field with fallback.

    value = default_value;
    if isstruct(Config) && isfield(Config, 'mode_filter') && isstruct(Config.mode_filter) && ...
            isfield(Config.mode_filter, field_name)
        value = Config.mode_filter.(field_name);
    end
    if isstring(value) && isscalar(value)
        value = char(value);
    end
end
