function test_mode_coupling_audit()
%TEST_MODE_COUPLING_AUDIT Classify bubble, coupled, and boundary-supported modes.

    setup_double_wedge_paths('IncludeTests', true);

    Ny = 20;
    Nx = 24;
    [X, Y] = meshgrid(linspace(0.0, 1.0, Nx), linspace(0.0, 1.0, Ny));
    layout = get_state_layout_info('primitive5_u_v_w_T_p');

    bubble_field = exp(-((X - 0.32).^2 / 0.010 + (Y - 0.10).^2 / 0.004));
    shock_field = exp(-((X - 0.68).^2 / 0.008 + (Y - 0.34).^2 / 0.006));
    outlet_wall_field = double((X > 0.88) & (Y < 0.18));

    masks = struct();
    masks.bubble = bubble_field > 0.20;
    masks.bubble_core = bubble_field > 0.35;
    masks.bubble_support = bubble_field > 0.12;
    masks.near_wall = false(Ny, Nx);
    masks.near_wall(1:4, :) = true;
    masks.shock = shock_field > 0.20;
    masks.shock_core = shock_field > 0.35;
    masks.outlet = X > 0.88;
    masks.outlet_wall = masks.outlet & masks.near_wall;
    masks.free_stream = Y > 0.60;
    masks.corner = false(Ny, Nx);
    masks.bad_point = false(Ny, Nx);

    q_modes = zeros(layout.nvar * Ny * Nx, 3);
    q_modes(3:layout.nvar:end, 1) = bubble_field(:);
    q_modes(1:layout.nvar:end, 1) = 0.20 * bubble_field(:);
    q_modes(3:layout.nvar:end, 2) = bubble_field(:) + 0.85 * shock_field(:);
    q_modes(1:layout.nvar:end, 2) = 0.15 * bubble_field(:);
    q_modes(1:layout.nvar:end, 3) = outlet_wall_field(:);

    data = struct();
    data.RHO = ones(Ny, Nx);

    Config = struct();
    Config.state_layout = layout.name;
    Config.Cv_nd = 0.12;
    Config.mode_filter = struct( ...
        'bubble_support_fraction_threshold', 0.05, ...
        'shock_fraction_threshold', 0.35, ...
        'shock_core_fraction_threshold', 0.15, ...
        'free_stream_fraction_threshold', 0.20, ...
        'outlet_fraction_threshold', 0.35, ...
        'outlet_wall_fraction_threshold', 0.20, ...
        'coupled_mode_shock_min_threshold', 0.08, ...
        'coupled_mode_shock_max_threshold', 0.65, ...
        'coupled_mode_phase_sync_threshold', -0.10);

    mode_metrics = struct();
    mode_metrics.bubble_support_overlap = [0.34; 0.28; 0.01];
    mode_metrics.near_wall_energy_frac = [0.24; 0.22; 0.38];
    mode_metrics.shock_energy_frac = [0.04; 0.20; 0.05];
    mode_metrics.shock_core_energy_frac = [0.01; 0.05; 0.02];
    mode_metrics.outlet_energy_frac = [0.02; 0.03; 0.62];
    mode_metrics.outlet_wall_energy_frac = [0.01; 0.02; 0.36];
    mode_metrics.free_stream_energy_frac = [0.05; 0.07; 0.08];
    mode_metrics.checker_ratio = [0.20; 0.25; 0.10];
    mode_metrics.u_peak_in_outlet_wall = [false; false; true];
    mode_metrics.u_peak_in_outlet = [false; false; true];
    mode_metrics.u_peak_in_shock_core = [false; false; false];

    coupling = build_mode_coupling_audit(q_modes, Ny, Nx, data, Config, masks, mode_metrics);

    assert(strcmp(coupling.family_label{1}, 'bubble_centred'), ...
        'Bubble-supported mode should be classified as bubble_centred.');
    assert(strcmp(coupling.family_label{2}, 'shock_bubble_coupled'), ...
        'Bubble-plus-shock mode should be classified as shock_bubble_coupled.');
    assert(strcmp(coupling.family_label{3}, 'boundary_supported'), ...
        'Outlet-wall mode should be classified as boundary_supported.');
    assert(strcmp(coupling.reference_component{1}, 'w') && strcmp(coupling.reference_component{2}, 'w'), ...
        'Three-dimensional synthetic modes should prefer w as the reference component.');
    assert(coupling.bubble_shock_sync(2) > 0.9, ...
        'The coupled mode should register strong bubble-shock phase synchronisation.');
    assert(coupling.physical_candidate_score(2) > coupling.physical_candidate_score(3), ...
        'Physical-candidate scoring should prefer the coupled mode over the boundary-supported mode.');

    fprintf('[test_mode_coupling_audit] PASS\n');
end
