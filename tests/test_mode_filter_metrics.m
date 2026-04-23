function test_mode_filter_metrics()
%TEST_MODE_FILTER_METRICS Validate wall-energy and checker filters.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    Ny = 40;
    Nx = 50;
    layout = get_state_layout_info('primitive5_u_v_w_T_p');

    [X, Y] = meshgrid(linspace(0.0, 1.0, Nx), linspace(0.0, 1.0, Ny));
    RHO = 1.0 + 0 * X;
    Cv_nd = 0.12;

    bubble = exp(-((X - 0.35).^2 / 0.015 + (Y - 0.08).^2 / 0.004));
    checker_amp = repmat(mod((1:Ny).', 2), 1, Nx) + repmat(mod(1:Nx, 2), Ny, 1);
    checker_amp = double(mod(checker_amp, 2) == 0);

    q_bubble = zeros(layout.nvar * Ny * Nx, 1);
    q_checker = zeros(layout.nvar * Ny * Nx, 1);
    q_pressure_checker = zeros(layout.nvar * Ny * Nx, 1);
    q_mixed_reference = zeros(layout.nvar * Ny * Nx, 1);
    q_bubble(1:layout.nvar:end) = bubble(:);
    q_bubble(2:layout.nvar:end) = 0.4 * bubble(:);
    q_bubble(3:layout.nvar:end) = 0.6 * bubble(:);
    q_bubble(4:layout.nvar:end) = 0.2 * bubble(:);
    q_checker(1:layout.nvar:end) = checker_amp(:);
    q_pressure_checker(1:layout.nvar:end) = bubble(:);
    q_pressure_checker(5:layout.nvar:end) = checker_amp(:);
    q_mixed_reference(1:layout.nvar:end) = 0.8 * double(Y > 0.65);
    q_mixed_reference(3:layout.nvar:end) = 8.0 * bubble(:);

    metrics = compute_mode_filter_metrics([q_bubble, q_checker, q_pressure_checker, q_mixed_reference], Ny, Nx, RHO, Cv_nd, ...
        'StateLayout', layout.name, ...
        'NearWallFraction', 0.15, ...
        'BubbleMask', bubble > 0.2);

    assert(metrics.wall_energy_frac(1) > 0.20, ...
        'Bubble mode should carry significant near-wall energy.');
    assert(metrics.bubble_overlap(1) > 0.20, ...
        'Bubble mode should overlap the supplied separation bubble mask.');
    assert(metrics.wall_energy_frac(2) < metrics.wall_energy_frac(1), ...
        'Checker mode should not look more wall-dominant than the bubble mode.');
    assert(metrics.bubble_overlap(2) < metrics.bubble_overlap(1), ...
        'Checker mode should not look more bubble-supported than the bubble mode.');
    assert(metrics.checker_ratio(2) > metrics.checker_ratio(1), ...
        'Checker mode should have the larger checker ratio.');
    assert(isfield(metrics, 'component_support') && isfield(metrics.component_support, 'w'), ...
        'Mode-filter metrics should save component-level support diagnostics.');
    assert(metrics.component_support.w.bubble_support_overlap(1) > 0.20, ...
        'The w'' component should remain bubble-supported for the bubble mode.');
    assert(metrics.component_support.w.bubble_support_overlap(2) < metrics.component_support.w.bubble_support_overlap(1), ...
        'Checker modes should not outrank the bubble mode in w'' bubble support.');
    assert(isfield(metrics.component_support.p, 'checker_ratio'), ...
        'Component-level diagnostics should include p'' checker ratio.');
    assert(metrics.p_checker_ratio(3) > metrics.p_checker_ratio(1), ...
        'A p''-only checker tail should be visible in pressure-specific diagnostics.');
    assert(metrics.checker_ratio(3) >= metrics.p_checker_ratio(3), ...
        'The total checker ratio should include p'' checker contamination.');
    assert(strcmp(metrics.support_basis, 'component_energy'), ...
        'Production support fractions should default to component_energy, not u_dominant.');
    assert(metrics.bubble_overlap(4) > 0.30, ...
        'A w'' bubble mode with unrelated u'' support should still score as bubble-supported.');

    fprintf('[test_mode_filter_metrics] PASS\n');
end
