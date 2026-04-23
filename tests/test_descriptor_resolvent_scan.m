function test_descriptor_resolvent_scan()
%TEST_DESCRIPTOR_RESOLVENT_SCAN Verify one tiny descriptor resolvent scan.

    setup_double_wedge_paths('IncludeTests', true);

    layout = get_state_layout_info('primitive5_u_v_w_T_p');
    Ny = 1;
    Nx = 1;
    assert(layout.nvar == 5, 'This regression test assumes the primitive-five layout.');

    lambda1 = 0.10 + 0.20i;
    lambda2 = 0.45 + 0.15i;
    LNS_L = diag([lambda1, lambda2, 0.80, 1.00, 1.20]);
    LNS_Gam = eye(5);

    data = struct();
    data.Ny = Ny;
    data.Nx = Nx;
    data.X = 0.0;
    data.Y = 0.0;
    data.U = -1.0;
    data.RHO = 1.0;
    data.BaseflowMasks = struct( ...
        'bubble_core_mask', true, ...
        'bubble_support_mask', true, ...
        'near_wall_mask', true, ...
        'outlet_mask', false, ...
        'outlet_wall_mask', false);
    data.ShockInfo = struct('shock_mask', false, 'shock_raw', false);

    Config = struct();
    Config.state_layout = layout.name;
    Config.Cv_nd = 0.12;
    Config.mode_filter = struct( ...
        'near_wall_fraction', 1.0, ...
        'outlet_fraction', 0.12);

    sigma_list = [lambda1 + 1.0e-3, 0.70 + 0.20i];
    scan = compute_descriptor_resolvent_scan(LNS_L, LNS_Gam, data, Config, sigma_list);

    assert(height(scan.summary_table) == 2, ...
        'The resolvent summary table should contain one row per requested sigma.');
    assert(scan.entries(1).gain > scan.entries(2).gain, ...
        'The sigma nearest the lead eigenvalue should yield the larger gain.');
    assert(scan.entries(1).bubble_overlap > 0.99, ...
        'The tiny resolvent response should live entirely inside the only bubble-support cell.');
    assert(strcmp(scan.entries(1).solver, 'full_svd'), ...
        'Tiny systems should use the deterministic full-SVD path.');

    fprintf('[test_descriptor_resolvent_scan] PASS\n');
end
