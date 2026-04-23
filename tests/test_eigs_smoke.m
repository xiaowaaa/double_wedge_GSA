function test_eigs_smoke()
%TEST_EIGS_SMOKE Build and solve a small primitive-5 generalized EVP.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    Ny = 6;
    Nx = 7;
    beta = 0.35;

    x_line = linspace(-1.0, 1.0, Nx);
    y_line = linspace(0.0, 1.0, Ny).';
    X = repmat(x_line, Ny, 1);
    Y = repmat(y_line, 1, Nx);

    config = local_base_config();
    config.boundary_map = struct( ...
        'south', 'wall', ...
        'north', 'farfield', ...
        'west', 'inlet', ...
        'east', 'outlet');

    [mask, ~] = build_boundary_masks(X, Y, config, 'Verbose', false);
    [A_full, B_full] = local_build_smoke_operator(X, Y, beta);

    [sigma_sp, sponge_info] = build_sponge_profile(X, Y, mask, ...
        'SigmaMax', 3.0, ...
        'Power', 2.0, ...
        'ApplyOutlet', true, ...
        'ApplyTop', true, ...
        'ApplyInlet', false);

    pressure_proxy = 1.0 + 0.5 * tanh(14.0 * (X - 0.1));
    sav_info = build_semi_artificial_viscosity(pressure_proxy, ...
        'Epsilon', 1.0e-2, ...
        'Power', 2.0, ...
        'Threshold', 0.02);

    A_full = local_apply_smoke_damping(A_full, sigma_sp, sav_info.coefficient, Ny, Nx);
    [A_full, B_full] = apply_structured_bc_rows( ...
        A_full, B_full, mask, X, ...
        'Verbose', false, ...
        'StateLayout', 'primitive5_u_v_w_T_p');

    gamma_diag = full(diag(B_full));
    active = gamma_diag > 0;
    assert(any(~active), 'BC-constrained rows should zero out entries in the mass matrix.');

    A = A_full(active, active);
    B = B_full(active, active);

    opts = struct();
    opts.tol = 1.0e-10;
    opts.maxit = 300;
    opts.disp = 0;
    eigs(A, B, 4, 'largestreal', opts);

    [V_full, D_full] = eig(full(A), full(B), 'vector');
    finite_mask = isfinite(D_full);
    assert(any(finite_mask), 'Smoke eigensolve produced no finite eigenvalues.');
    lambdas = D_full(finite_mask);
    V_full = V_full(:, finite_mask);
    [~, order] = sort(real(lambdas), 'descend');
    lambdas = lambdas(order);
    V_full = V_full(:, order);

    q_full = zeros(5 * Ny * Nx, 1);
    q_full(active) = V_full(:, 1);
    lambda = lambdas(1);
    residual_vec = A_full * q_full - lambda * (B_full * q_full);
    residual = norm(residual_vec(active)) / max(norm((A_full(active, :) * q_full)), eps);
    assert(isfinite(residual) && residual < 1.0e-8, ...
        'Smoke eigensolve residual is too large.');

    output_dir = fullfile(project_root, 'outputs', 'mat');
    if exist(output_dir, 'dir') ~= 7
        mkdir(output_dir);
    end
    save(fullfile(output_dir, 'test_eigs_smoke.mat'), ...
        'lambda', 'lambdas', 'residual', 'beta', 'sigma_sp', 'sponge_info', 'sav_info');

    fprintf('[test_eigs_smoke] PASS\n');
end

function [A, B] = local_build_smoke_operator(X, Y, beta)
%LOCAL_BUILD_SMOKE_OPERATOR Assemble a small primitive-5 toy operator.

    [Ny, Nx] = size(X);
    nvar = 5;
    Ndof = nvar * Ny * Nx;
    idx = @(j, i, var) (i - 1) * Ny * nvar + (j - 1) * nvar + var;

    A = spalloc(Ndof, Ndof, 20 * Ndof);
    B = speye(Ndof);

    base_shift = [-0.10, -0.16, -0.18, -0.12, -0.08];

    for i = 1:Nx
        for j = 1:Ny
            for var = 1:nvar
                row = idx(j, i, var);
                A(row, row) = A(row, row) + base_shift(var) - beta^2;

                if i > 1
                    A(row, idx(j, i-1, var)) = A(row, idx(j, i-1, var)) + 0.20;
                    A(row, row) = A(row, row) - 0.20;
                end
                if i < Nx
                    A(row, idx(j, i+1, var)) = A(row, idx(j, i+1, var)) + 0.20;
                    A(row, row) = A(row, row) - 0.20;
                end
                if j > 1
                    A(row, idx(j-1, i, var)) = A(row, idx(j-1, i, var)) + 0.25;
                    A(row, row) = A(row, row) - 0.25;
                end
                if j < Ny
                    A(row, idx(j+1, i, var)) = A(row, idx(j+1, i, var)) + 0.25;
                    A(row, row) = A(row, row) - 0.25;
                end
            end

            ru = idx(j, i, 1);
            rv = idx(j, i, 2);
            rw = idx(j, i, 3);
            rT = idx(j, i, 4);
            rp = idx(j, i, 5);

            A(ru, rp) = A(ru, rp) - 0.12;
            A(rv, rp) = A(rv, rp) - 0.08;
            A(rw, rp) = A(rw, rp) + 0.10i * beta;
            A(rT, rp) = A(rT, rp) - 0.04;

            A(rp, ru) = A(rp, ru) - 0.05;
            A(rp, rv) = A(rp, rv) - 0.05;
            A(rp, rw) = A(rp, rw) - 0.10i * beta;
            A(rp, rT) = A(rp, rT) - 0.03;
        end
    end
end

function A = local_apply_smoke_damping(A, sigma_sp, sav_coeff, Ny, Nx)
%LOCAL_APPLY_SMOKE_DAMPING Add sponge and weak stabilization to the toy A matrix.

    nvar = 5;
    idx = @(j, i, var) (i - 1) * Ny * nvar + (j - 1) * nvar + var;

    for i = 1:Nx
        for j = 1:Ny
            sigma_loc = sigma_sp(j, i);
            sav_loc = sav_coeff(j, i);
            for var = 1:nvar
                row = idx(j, i, var);
                A(row, row) = A(row, row) - sigma_loc - 0.5 * sav_loc;
            end
        end
    end
end

function config = local_base_config()
%LOCAL_BASE_CONFIG Return a minimal valid Config for unit tests.

    config = struct();
    config.Ma_inf = 7.0;
    config.Re_inf = 1.0e5;
    config.T_inf = 191.0;
    config.gamma = 1.4;
    config.Pr = 0.71;
    config.x_hinge = 0.0;
    config.n_eigs = 6;
    config.datafile = 'double_wedge_baseflow.dat';
end
