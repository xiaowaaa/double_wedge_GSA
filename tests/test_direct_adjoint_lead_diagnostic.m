function test_direct_adjoint_lead_diagnostic()
%TEST_DIRECT_ADJOINT_LEAD_DIAGNOSTIC Verify one tiny direct/adjoint wavemaker audit.

    setup_double_wedge_paths('IncludeTests', true);

    layout = get_state_layout_info('primitive5_u_v_w_T_p');
    Ny = 1;
    Nx = 1;
    assert(layout.nvar == 5, 'This regression test assumes the primitive-five layout.');

    lambda_direct = 0.15 + 0.05i;
    LNS_L = diag([lambda_direct, -0.30 + 0.10i, -0.45, -0.60, -0.75]);
    LNS_Gam = eye(5);
    q_direct = zeros(5, 1);
    q_direct(1) = 1.0;

    data = struct();
    data.Ny = Ny;
    data.Nx = Nx;
    data.X = 0.0;
    data.Y = 0.0;
    data.RHO = 1.0;

    Config = struct();
    Config.state_layout = layout.name;
    Config.Cv_nd = 0.12;

    masks = struct();
    masks.bubble = true;
    masks.bubble_core = true;
    masks.bubble_support = true;
    masks.near_wall = true;
    masks.shock = false;
    masks.shock_core = false;
    masks.outlet = false;
    masks.outlet_wall = false;
    masks.corner = false;
    masks.bad_point = false;
    masks.free_stream = false;

    audit = compute_direct_adjoint_lead_diagnostic( ...
        LNS_L, LNS_Gam, lambda_direct, q_direct, data, Config, masks);

    assert(audit.enabled, 'The direct/adjoint audit should be enabled for a valid tiny pencil.');
    assert(abs(audit.lambda_direct - lambda_direct) < 1.0e-12, ...
        'The saved direct eigenvalue should match the requested lead.');
    assert(abs(audit.lambda_adjoint - lambda_direct) < 1.0e-10, ...
        'The returned adjoint partner should map back to the same physical eigenvalue.');
    assert(audit.direct_residual < 1.0e-12, ...
        'The synthetic direct mode should have a near-zero generalized residual.');
    assert(audit.wavemaker_bubble_frac > 0.99, ...
        'The wavemaker should localize inside the only bubble-support cell.');
    assert(audit.wavemaker_shock_frac == 0.0, ...
        'The tiny synthetic problem has no shock support.');
    assert(audit.wavemaker_peak_in_bubble, ...
        'The wavemaker peak should sit inside the bubble-support cell.');

    fprintf('[test_direct_adjoint_lead_diagnostic] PASS\n');
end
