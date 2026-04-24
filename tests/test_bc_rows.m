function test_bc_rows()
%TEST_BC_ROWS Validate Paper-A primitive-five BC row patterns.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    Ny = 6;
    Nx = 7;
    Ndof = 5 * Ny * Nx;
    idx = @(j, i, var) (i - 1) * Ny * 5 + (j - 1) * 5 + var;

    X = repmat([-2, -1, -0.5, 0.0, 0.5, 1.0, 1.5], Ny, 1);
    LNS_L = speye(Ndof);
    LNS_Gam = speye(Ndof);

    mask = struct();
    mask.inlet = false(Ny, Nx);
    mask.outlet = false(Ny, Nx);
    mask.farfield = false(Ny, Nx);
    mask.wall = false(Ny, Nx);
    mask.symmetry = false(Ny, Nx);
    mask.outer = false(Ny, Nx);

    mask.inlet(Ny, 2:Nx-1) = true;
    mask.inlet(2:Ny-1, 1) = true;
    mask.outlet(2:Ny-1, Nx) = true;
    mask.symmetry(1, 1:3) = true;
    mask.wall(1, 4:Nx) = true;
    mask.outer = mask.inlet | mask.outlet | mask.farfield | mask.wall | mask.symmetry;

    [LNS_L, LNS_Gam, report] = apply_structured_bc_rows( ...
        LNS_L, LNS_Gam, mask, X, ...
        'Verbose', false, ...
        'StateLayout', 'primitive5_u_v_w_T_p', ...
        'WallModel', 'adiabatic');

    cN = [-25, 48, -36, 16, -3] / 12.0;
    cE = [1, -4, 6, -4, 1];

    row_in = idx(Ny, 3, 4);
    assert(nnz(LNS_L(row_in, :)) == 1 && full(LNS_L(row_in, row_in)) == 1, ...
        'Inlet row must be Dirichlet.');
    assert(nnz(LNS_Gam(row_in, :)) == 0, ...
        'Inlet Gamma row must be zero for an algebraic BC constraint.');

    row_out = idx(4, Nx, 1);
    cols_out = find(LNS_L(row_out, :));
    vals_out = full(LNS_L(row_out, cols_out));
    exp_cols = [idx(4, Nx-4, 1), idx(4, Nx-3, 1), idx(4, Nx-2, 1), idx(4, Nx-1, 1), idx(4, Nx, 1)];
    exp_vals = [cE(5), cE(4), cE(3), cE(2), cE(1)];
    assert(isequal(cols_out, exp_cols), 'Outlet row columns are incorrect.');
    assert(norm(vals_out - exp_vals, inf) < 1e-12, 'Outlet row coefficients are incorrect.');
    assert(nnz(LNS_Gam(row_out, :)) == 0, ...
        'Outlet Gamma row must be zero for an algebraic BC constraint.');

    row_wall_u = idx(1, 5, 1);
    assert(nnz(LNS_L(row_wall_u, :)) == 1 && full(LNS_L(row_wall_u, row_wall_u)) == 1, ...
        'Primitive-5 wall u row must be Dirichlet.');
    assert(nnz(LNS_Gam(row_wall_u, :)) == 0, ...
        'Primitive-5 wall u Gamma row must be zero.');

    row_wall_p = idx(1, 5, 5);
    cols_wall_p = find(LNS_L(row_wall_p, :));
    vals_wall_p = full(LNS_L(row_wall_p, cols_wall_p));
    exp_cols_wall_p = arrayfun(@(j) idx(j, 5, 5), 1:5);
    assert(isequal(cols_wall_p, exp_cols_wall_p), ...
        'Primitive-5 wall p row columns are incorrect.');
    assert(norm(vals_wall_p - cN, inf) < 1e-12, ...
        'Primitive-5 wall p row coefficients are incorrect.');

    row_wall_T_adiabatic = idx(1, 5, 4);
    cols_wall_T_adiabatic = find(LNS_L(row_wall_T_adiabatic, :));
    vals_wall_T_adiabatic = full(LNS_L(row_wall_T_adiabatic, cols_wall_T_adiabatic));
    exp_cols_wall_T_adiabatic = arrayfun(@(j) idx(j, 5, 4), 1:5);
    assert(isequal(cols_wall_T_adiabatic, exp_cols_wall_T_adiabatic), ...
        'Adiabatic wall temperature row should be one-sided Neumann.');
    assert(norm(vals_wall_T_adiabatic - cN, inf) < 1e-12, ...
        'Adiabatic wall temperature row coefficients are incorrect.');

    row_sym_v = idx(1, 2, 2);
    assert(nnz(LNS_L(row_sym_v, :)) == 1 && full(LNS_L(row_sym_v, row_sym_v)) == 1, ...
        'Primitive-5 symmetry v row must be Dirichlet.');
    assert(nnz(LNS_Gam(row_sym_v, :)) == 0, ...
        'Primitive-5 symmetry v Gamma row must be zero.');

    row_sym_p = idx(1, 2, 5);
    cols_sym_p = find(LNS_L(row_sym_p, :));
    vals_sym_p = full(LNS_L(row_sym_p, cols_sym_p));
    exp_cols_sym_p = arrayfun(@(j) idx(j, 2, 5), 1:5);
    assert(isequal(cols_sym_p, exp_cols_sym_p), ...
        'Primitive-5 symmetry p row columns are incorrect.');
    assert(norm(vals_sym_p - cN, inf) < 1e-12, ...
        'Primitive-5 symmetry p row coefficients are incorrect.');

    row_sym_w = idx(1, 2, 3);
    cols_sym_w = find(LNS_L(row_sym_w, :));
    vals_sym_w = full(LNS_L(row_sym_w, cols_sym_w));
    exp_cols_sym_w = arrayfun(@(j) idx(j, 2, 3), 1:5);
    assert(isequal(cols_sym_w, exp_cols_sym_w), ...
        'Primitive-5 symmetry w row columns are incorrect.');
    assert(norm(vals_sym_w - cN, inf) < 1e-12, ...
        'Primitive-5 symmetry w row coefficients are incorrect.');

    assert(strcmp(report.state_layout, 'primitive5_u_v_w_T_p'), ...
        'Unexpected primitive-5 state layout tag.');
    assert(isfield(report, 'boundary_row_mask') && islogical(report.boundary_row_mask), ...
        'BC enforcement should save the overwritten-row mask.');
    assert(nnz(report.boundary_row_mask) == report.num_overwritten_rows, ...
        'The overwrite-count summary should match the boundary-row mask.');
    assert(isequal(find(report.boundary_row_mask), report.overwritten_rows(:)), ...
        'The explicit overwritten row list should match the saved mask.');
    assert(strcmp(report.wall_model, 'adiabatic'), ...
        'BC report should record the active adiabatic wall model.');
    assert(strcmp(report.wall_thermal_constraint, 'dT_dn=0'), ...
        'BC report should record the adiabatic thermal constraint.');

    LNS_L_iso = speye(Ndof);
    LNS_Gam_iso = speye(Ndof);
    [LNS_L_iso, LNS_Gam_iso, report_iso] = apply_structured_bc_rows( ...
        LNS_L_iso, LNS_Gam_iso, mask, X, ...
        'Verbose', false, ...
        'StateLayout', 'primitive5_u_v_w_T_p', ...
        'WallModel', 'isothermal');
    row_wall_T_iso = idx(1, 5, 4);
    assert(nnz(LNS_L_iso(row_wall_T_iso, :)) == 1 && ...
        full(LNS_L_iso(row_wall_T_iso, row_wall_T_iso)) == 1, ...
        'Isothermal wall temperature row must be Dirichlet.');
    assert(nnz(LNS_Gam_iso(row_wall_T_iso, :)) == 0, ...
        'Isothermal wall temperature Gamma row must be zero.');
    assert(strcmp(report_iso.wall_model, 'isothermal'), ...
        'BC report should record the active isothermal wall model.');
    assert(strcmp(report_iso.wall_thermal_constraint, 'T_prime=0'), ...
        'BC report should record the isothermal thermal constraint.');
    fprintf('[test_bc_rows] PASS\n');
end
