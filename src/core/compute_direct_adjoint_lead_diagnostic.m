function audit = compute_direct_adjoint_lead_diagnostic(LNS_L, LNS_Gam, lambda_direct, q_direct, data, Config, masks)
%COMPUTE_DIRECT_ADJOINT_LEAD_DIAGNOSTIC Compute one direct/adjoint wavemaker audit.

    [A_scaled, B_scaled, ~, Dc, ~, ~] = build_scaled_descriptor_pencil_v6(LNS_L, LNS_Gam);
    q_direct_scaled = Dc \ q_direct;

    lambda_target = conj(lambda_direct);
    [lambda_adj, q_adj_scaled, solve_meta] = local_solve_adjoint_mode(A_scaled, B_scaled, lambda_target); %#ok<ASGLU>
    q_adj = Dc * q_adj_scaled;

    overlap_mass = q_adj' * (LNS_Gam * q_direct);
    if isfinite(overlap_mass) && abs(overlap_mass) > 1.0e-12
        q_adj = q_adj / overlap_mass;
    else
        q_adj = q_adj / max(norm(q_adj), 1.0e-30);
    end

    if isfield(data, 'RHO') && ~isempty(data.RHO)
        rho_ref = data.RHO;
    else
        rho_ref = ones(data.Ny, data.Nx);
    end
    if isfield(Config, 'Cv_nd') && ~isempty(Config.Cv_nd)
        Cv_nd = Config.Cv_nd;
    else
        Cv_nd = 0.0;
    end

    direct_support = compute_mode_support_field(q_direct, data.Ny, data.Nx, Config.state_layout, rho_ref, Cv_nd, ...
        'Weighting', 'component_energy');
    adjoint_support = compute_mode_support_field(q_adj, data.Ny, data.Nx, Config.state_layout, rho_ref, Cv_nd, ...
        'Weighting', 'component_energy');
    wavemaker_map = abs(direct_support) .* abs(adjoint_support);

    total_direct = max(sum(direct_support(:)), 1.0e-30);
    total_adjoint = max(sum(adjoint_support(:)), 1.0e-30);
    total_wavemaker = max(sum(wavemaker_map(:)), 1.0e-30);

    [peak_value, peak_idx] = max(wavemaker_map(:)); %#ok<ASGLU>
    if isempty(peak_idx) || ~isfinite(peak_idx)
        peak_row = NaN;
        peak_col = NaN;
    else
        [peak_row, peak_col] = ind2sub(size(wavemaker_map), peak_idx);
    end

    audit = struct();
    audit.enabled = true;
    audit.lambda_direct = lambda_direct;
    audit.lambda_adjoint = conj(lambda_adj);
    audit.solve_meta = solve_meta;
    audit.biorthogonality_mass = overlap_mass;
    audit.direct_residual = local_mode_residual(LNS_L, LNS_Gam, lambda_direct, q_direct);
    audit.adjoint_residual = local_mode_residual(LNS_L', LNS_Gam', conj(lambda_adj), q_adj);
    audit.direct_norm = norm(q_direct);
    audit.adjoint_norm = norm(q_adj);
    audit.direct_support_map = direct_support;
    audit.adjoint_support_map = adjoint_support;
    audit.wavemaker_map = wavemaker_map / total_wavemaker;
    audit.direct_bubble_frac = sum(direct_support(masks.bubble_support), 'all') / total_direct;
    audit.direct_shock_frac = sum(direct_support(masks.shock), 'all') / total_direct;
    audit.adjoint_bubble_frac = sum(adjoint_support(masks.bubble_support), 'all') / total_adjoint;
    audit.adjoint_shock_frac = sum(adjoint_support(masks.shock), 'all') / total_adjoint;
    audit.wavemaker_bubble_frac = sum(wavemaker_map(masks.bubble_support), 'all') / total_wavemaker;
    audit.wavemaker_shock_frac = sum(wavemaker_map(masks.shock), 'all') / total_wavemaker;
    audit.wavemaker_outlet_frac = sum(wavemaker_map(masks.outlet), 'all') / total_wavemaker;
    audit.wavemaker_outlet_wall_frac = sum(wavemaker_map(masks.outlet_wall), 'all') / total_wavemaker;
    audit.wavemaker_free_stream_frac = sum(wavemaker_map(masks.free_stream), 'all') / total_wavemaker;
    audit.wavemaker_peak_row = peak_row;
    audit.wavemaker_peak_col = peak_col;
    if isfinite(peak_row) && isfinite(peak_col)
        audit.wavemaker_peak_x = data.X(peak_row, peak_col);
        audit.wavemaker_peak_y = data.Y(peak_row, peak_col);
        audit.wavemaker_peak_in_bubble = masks.bubble_support(peak_row, peak_col);
        audit.wavemaker_peak_in_shock = masks.shock(peak_row, peak_col);
        audit.wavemaker_peak_in_outlet_wall = masks.outlet_wall(peak_row, peak_col);
        audit.wavemaker_peak_in_free_stream = masks.free_stream(peak_row, peak_col);
    else
        audit.wavemaker_peak_x = NaN;
        audit.wavemaker_peak_y = NaN;
        audit.wavemaker_peak_in_bubble = false;
        audit.wavemaker_peak_in_shock = false;
        audit.wavemaker_peak_in_outlet_wall = false;
        audit.wavemaker_peak_in_free_stream = false;
    end
end

function [lambda_adj, q_adj_scaled, solve_meta] = local_solve_adjoint_mode(A_scaled, B_scaled, lambda_target)
%LOCAL_SOLVE_ADJOINT_MODE Solve the left-eigenvector partner around one target shift.

    n_sys = size(A_scaled, 1);
    solve_meta = struct('solver', 'eigs', 'status', 'ok');
    if n_sys <= 320
        [V_all, D_all] = eig(full(A_scaled'), full(B_scaled'), 'vector');
        finite_mask = isfinite(D_all);
        D_all = D_all(finite_mask);
        V_all = V_all(:, finite_mask);
        if isempty(D_all)
            error('compute_direct_adjoint_lead_diagnostic:NoAdjointModes', ...
                'No finite adjoint eigenpairs were found.');
        end
        [~, idx] = min(abs(D_all - lambda_target));
        lambda_adj = D_all(idx);
        q_adj_scaled = V_all(:, idx);
        solve_meta.solver = 'full_eig';
        solve_meta.status = 'ok';
        return;
    end

    opts = struct();
    opts.tol = 1.0e-10;
    opts.maxit = 600;
    opts.p = min(max(24, 10), max(n_sys - 2, 12));
    opts.disp = 0;
    try
        [V_adj, D_adj] = eigs(A_scaled', B_scaled', 1, lambda_target, opts);
        lambda_adj = D_adj(1, 1);
        q_adj_scaled = V_adj(:, 1);
    catch ME
        solve_meta.solver = 'full_fallback_after_eigs_failure';
        solve_meta.status = ME.message;
        [V_all, D_all] = eig(full(A_scaled'), full(B_scaled'), 'vector');
        finite_mask = isfinite(D_all);
        D_all = D_all(finite_mask);
        V_all = V_all(:, finite_mask);
        if isempty(D_all)
            error('compute_direct_adjoint_lead_diagnostic:NoAdjointModes', ...
                'No finite adjoint eigenpairs were found after fallback.');
        end
        [~, idx] = min(abs(D_all - lambda_target));
        lambda_adj = D_all(idx);
        q_adj_scaled = V_all(:, idx);
    end
end

function residual = local_mode_residual(A, B, lambda_value, q_mode)
%LOCAL_MODE_RESIDUAL Normalized generalized-eigen residual.

    numer = norm(A * q_mode - lambda_value * (B * q_mode));
    denom = max(norm(A * q_mode) + abs(lambda_value) * norm(B * q_mode), 1.0e-30);
    residual = numer / denom;
end
