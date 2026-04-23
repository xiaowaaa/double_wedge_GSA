function test_descriptor_solver_low_memory()
%TEST_DESCRIPTOR_SOLVER_LOW_MEMORY Verify the descriptor solver trims large runs.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    config = local_base_config();
    [config, ~] = validate_config(config, 'Verbose', false);
    config.n_eigs = 20;
    config.sigma = 0.05 + 0.02i;
    config.sigma_triplet = [0.00 + 0.010i, 0.03 + 0.020i, 0.05 + 0.020i];
    config.descriptor_solver.large_system_threshold = 1;
    config.descriptor_solver.huge_system_threshold = 1;
    config.descriptor_solver.max_total_modes_huge = 4;
    config.descriptor_solver.max_shifts_huge = 1;
    config.descriptor_solver.max_modes_per_shift_huge = 2;
    config.descriptor_solver.min_modes_per_shift = 2;
    config.descriptor_solver.krylov_floor_huge = 8;
    config.descriptor_solver.krylov_cap_huge = 14;

    n = 399;
    main_diag = complex(linspace(-0.18, 0.08, n).', linspace(0.0, 0.06, n).');
    A = spdiags(main_diag, 0, n, n);
    B = speye(n);

    result = solve_paperA_descriptor_modes(A, B, config);

    assert(~isempty(result.EigVals), 'Low-memory descriptor solve returned no eigenpairs.');
    assert(strcmp(result.SolveAudit.memory_policy, 'huge_system_low_memory'), ...
        'The forced large-system solve should enter huge-system low-memory mode.');
    assert(numel(result.SolveAudit.shifts) == 1, ...
        'Huge-system low-memory mode should trim the shift family to one primary shift.');
    assert(result.SolveAudit.target_n_eigs <= 4, ...
        'Huge-system low-memory mode should cap the total mode budget.');
    assert(all(result.SolveAudit.k_local_candidates <= 2), ...
        'Huge-system low-memory mode should reduce modes per shift aggressively.');
    assert(all(result.SolveAudit.krylov_candidates >= result.SolveAudit.k_local_candidates(1) + 2), ...
        'Every Krylov candidate must remain larger than k.');

    fprintf('[test_descriptor_solver_low_memory] PASS\n');
end

function config = local_base_config()
%LOCAL_BASE_CONFIG Return a minimal Config for descriptor-solver testing.

    config = struct();
    config.Ma_inf = 7.0;
    config.Re_inf = 1.0e5;
    config.T_inf = 191.0;
    config.gamma = 1.4;
    config.Pr = 0.71;
    config.x_hinge = 0.0;
    config.n_eigs = 10;
    config.datafile = 'double_wedge_baseflow.dat';
end
