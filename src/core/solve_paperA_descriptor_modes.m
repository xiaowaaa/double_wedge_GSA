function result = solve_paperA_descriptor_modes(LNS_L, LNS_Gam, Config)
%SOLVE_PAPERA_DESCRIPTOR_MODES Solve the scaled descriptor pencil around low-frequency shifts.

    [A_scaled, B_scaled, Dr, Dc, active_mask, MatrixHealth] = ...
        build_scaled_descriptor_pencil_v6(LNS_L, LNS_Gam); %#ok<ASGLU>

    [EigVals_all, EigVecs_scaled_all, SolveAudit] = ...
        local_solve_shift_family(A_scaled, B_scaled, Config, Config.n_eigs, local_get_sigma_shifts(Config));
    if isempty(EigVals_all)
        error('solve_paperA_descriptor_modes:NoEigenpairs', ...
            ['No finite eigenpairs were produced by the descriptor solve. ' ...
             'Tried Krylov p = [%s].'], ...
            local_format_integer_list(SolveAudit.krylov_candidates));
    end

    EigVecs_all = Dc * EigVecs_scaled_all;
    [residuals_all, residuals_active_all, residuals_algebraic_all, residuals_scaled_all] = ...
        local_compute_residuals(LNS_L, LNS_Gam, A_scaled, B_scaled, ...
        EigVals_all, EigVecs_all, EigVecs_scaled_all, active_mask);
    keep_idx = local_deduplicate_modes(EigVals_all, residuals_all);

    result = struct();
    result.EigVals = EigVals_all(keep_idx);
    result.EigVecs = EigVecs_all(:, keep_idx);
    result.residuals = residuals_all(keep_idx);
    result.residuals_active = residuals_active_all(keep_idx);
    result.residuals_algebraic = residuals_algebraic_all(keep_idx);
    result.residuals_scaled = residuals_scaled_all(keep_idx);
    result.active_mask = active_mask;
    result.MatrixHealth = MatrixHealth;
    result.SolveAudit = SolveAudit;
end

function [EigVals_all, EigVecs_scaled_all, SolveAudit] = local_solve_shift_family(A_scaled, B_scaled, Config, n_eigs, shifts)
%LOCAL_SOLVE_SHIFT_FAMILY Solve around one or more configured shifts.

    shifts = shifts(:).';
    if isempty(shifts)
        shifts = 0.00 + 0.010i;
    end

    n_sys = size(A_scaled, 1);
    solve_plan = local_build_shift_solve_plan(Config, n_eigs, n_sys, shifts);
    shifts = solve_plan.shifts;

    EigVals_all = [];
    EigVecs_scaled_all = [];
    modes_per_shift = zeros(numel(shifts), 1);
    status = 'ok';
    shift_attempts = repmat(struct( ...
        'shift', 0.0 + 0.0i, ...
        'k_requested', NaN, ...
        'p_requested', NaN, ...
        'status', 'not_run', ...
        'message', '', ...
        'num_modes', 0), 0, 1);

    for s = 1:numel(shifts)
        sigma_shift = shifts(s);
        solved_shift = false;
        last_message = '';
        attempted_p = [];
        for k_idx = 1:numel(solve_plan.k_candidates)
            k_try = min(solve_plan.k_candidates(k_idx), max(n_sys - 2, 1));
            if k_try < 1
                continue;
            end

            use_full = n_sys <= max(k_try + 2, 400);
            if use_full
                [V_full, D_full] = eig(full(A_scaled), full(B_scaled), 'vector');
                finite_mask = isfinite(D_full);
                D_full = D_full(finite_mask);
                V_full = V_full(:, finite_mask);
                if isempty(D_full)
                    continue;
                end
                [~, order_full] = sort(abs(D_full - sigma_shift), 'ascend');
                take = order_full(1:min(k_try, numel(order_full)));
                D_shift = D_full(take);
                V_shift = V_full(:, take);
                shift_attempts(end + 1, 1) = struct( ... %#ok<AGROW>
                    'shift', sigma_shift, ...
                    'k_requested', k_try, ...
                    'p_requested', NaN, ...
                    'status', 'success', ...
                    'message', 'full_eig', ...
                    'num_modes', numel(D_shift));
                solved_shift = true;
                break;
            end

            p_candidates = local_build_krylov_candidates(Config, solve_plan.target_total_modes, numel(shifts), n_sys, k_try);
            attempted_p = unique([attempted_p, p_candidates], 'stable'); %#ok<AGROW>
            for p_idx = 1:numel(p_candidates)
                p_try = p_candidates(p_idx);
                opts = struct();
                opts.tol = 1.0e-10;
                opts.maxit = 800;
                opts.p = p_try;
                opts.disp = 0;
                try
                    [V_shift, D_mat] = eigs(A_scaled, B_scaled, k_try, sigma_shift, opts);
                    D_shift = diag(D_mat);
                    shift_attempts(end + 1, 1) = struct( ... %#ok<AGROW>
                        'shift', sigma_shift, ...
                        'k_requested', k_try, ...
                        'p_requested', p_try, ...
                        'status', 'success', ...
                        'message', '', ...
                        'num_modes', numel(D_shift));
                    solved_shift = true;
                    break;
                catch ME
                    last_message = ME.message;
                    shift_attempts(end + 1, 1) = struct( ... %#ok<AGROW>
                        'shift', sigma_shift, ...
                        'k_requested', k_try, ...
                        'p_requested', p_try, ...
                        'status', 'failed', ...
                        'message', last_message, ...
                        'num_modes', 0);
                    if ~local_is_memory_error(ME)
                        warning('solve_paperA_descriptor_modes:ShiftSolve', ...
                            'Shift %.4e%+.4ei failed with "%s".', real(sigma_shift), imag(sigma_shift), last_message);
                        break;
                    end
                end
            end
            if solved_shift || (~isempty(last_message) && ~local_is_memory_error(struct('message', last_message)))
                break;
            end
        end

        if ~solved_shift
            warning('solve_paperA_descriptor_modes:ShiftSolve', ...
                ['Shift %.4e%+.4ei failed with "%s". ' ...
                 'Tried Krylov p = [%s] and k = [%s].'], ...
                real(sigma_shift), imag(sigma_shift), last_message, ...
                local_format_integer_list(attempted_p), ...
                local_format_integer_list(solve_plan.k_candidates));
            status = 'partial_shift_failure';
            continue;
        end

        finite_mask = isfinite(D_shift);
        D_shift = D_shift(finite_mask);
        V_shift = V_shift(:, finite_mask);
        modes_per_shift(s) = numel(D_shift);
        EigVals_all = [EigVals_all; D_shift(:)]; %#ok<AGROW>
        EigVecs_scaled_all = [EigVecs_scaled_all, V_shift]; %#ok<AGROW>
        if numel(EigVals_all) >= solve_plan.target_total_modes
            if solve_plan.is_low_memory
                status = 'low_memory_success';
            end
            break;
        end
    end

    SolveAudit = struct();
    SolveAudit.shifts = shifts;
    SolveAudit.k_local = solve_plan.k_candidates(1);
    SolveAudit.k_local_candidates = solve_plan.k_candidates(:).';
    SolveAudit.krylov_dimension = solve_plan.krylov_candidates(1);
    SolveAudit.krylov_candidates = solve_plan.krylov_candidates(:).';
    SolveAudit.status = status;
    SolveAudit.modes_per_shift = modes_per_shift;
    SolveAudit.num_raw_modes = numel(EigVals_all);
    SolveAudit.shift_attempts = shift_attempts;
    SolveAudit.memory_policy = solve_plan.memory_policy;
    SolveAudit.requested_n_eigs = solve_plan.requested_total_modes;
    SolveAudit.target_n_eigs = solve_plan.target_total_modes;
    SolveAudit.requested_shifts = solve_plan.requested_shifts(:).';
    SolveAudit.truncated_for_memory = solve_plan.is_low_memory;
end

function p_candidates = local_build_krylov_candidates(Config, n_eigs, n_shifts, n_sys, k_local)
%LOCAL_BUILD_KRYLOV_CANDIDATES Choose progressively cheaper eigs subspaces.

    solver_cfg = local_get_descriptor_solver_config(Config);
    p_floor = local_get_numeric_field(Config, 'krylov_dimension_floor', 120);
    p_cap = local_get_numeric_field(Config, 'krylov_dimension_cap', 180);
    if n_sys >= solver_cfg.huge_system_threshold
        p_floor = min(p_floor, solver_cfg.krylov_floor_huge);
        p_cap = min(p_cap, solver_cfg.krylov_cap_huge);
        p_target = 2 * k_local + 6;
    elseif n_sys >= solver_cfg.large_system_threshold
        p_floor = min(p_floor, solver_cfg.krylov_floor_large);
        p_cap = min(p_cap, solver_cfg.krylov_cap_large);
        p_target = 3 * k_local + 8;
    elseif n_eigs <= 12 && n_shifts <= 2
        p_floor = min(p_floor, 60);
        p_cap = min(p_cap, 96);
        p_target = 6 * k_local;
    else
        p_target = 10 * k_local;
    end

    p_floor = max(p_floor, k_local + 2);
    p_cap = max(p_cap, p_floor);
    p_upper = min(n_sys - 1, p_cap);
    p_min = min(max(k_local + 2, 12), p_upper);
    p_nominal = min(max(p_floor, p_target), p_upper);

    raw_candidates = [ ...
        p_nominal, ...
        min(max(k_local + 2, round(0.85 * p_nominal)), p_upper), ...
        min(max(k_local + 2, round(0.65 * p_nominal)), p_upper), ...
        min(max(k_local + 2, round(0.50 * p_nominal)), p_upper), ...
        p_min];

    p_candidates = zeros(1, numel(raw_candidates));
    keep = false(size(raw_candidates));
    for k = 1:numel(raw_candidates)
        value = min(max(round(raw_candidates(k)), k_local + 2), p_upper);
        p_candidates(k) = value;
        if ~any(p_candidates(1:k-1) == value)
            keep(k) = true;
        end
    end
    p_candidates = p_candidates(keep);
end

function solve_plan = local_build_shift_solve_plan(Config, n_eigs, n_sys, shifts)
%LOCAL_BUILD_SHIFT_SOLVE_PLAN Build one low-memory-aware descriptor solve plan.

    solver_cfg = local_get_descriptor_solver_config(Config);
    primary_shift = local_get_primary_shift(Config, shifts);
    requested_shifts = local_prepare_shifts(shifts, primary_shift);

    solve_plan = struct();
    solve_plan.requested_shifts = requested_shifts;
    solve_plan.requested_total_modes = max(1, round(n_eigs));
    solve_plan.memory_policy = 'standard';
    solve_plan.is_low_memory = false;

    if n_sys >= solver_cfg.huge_system_threshold
        solve_plan.memory_policy = 'huge_system_low_memory';
        solve_plan.is_low_memory = true;
        shift_limit = min(numel(requested_shifts), solver_cfg.max_shifts_huge);
        target_total = min(solve_plan.requested_total_modes, solver_cfg.max_total_modes_huge);
        max_per_shift = solver_cfg.max_modes_per_shift_huge;
    elseif n_sys >= solver_cfg.large_system_threshold
        solve_plan.memory_policy = 'large_system_low_memory';
        solve_plan.is_low_memory = true;
        shift_limit = min(numel(requested_shifts), solver_cfg.max_shifts_large);
        target_total = min(solve_plan.requested_total_modes, solver_cfg.max_total_modes_large);
        max_per_shift = solver_cfg.max_modes_per_shift_large;
    else
        shift_limit = numel(requested_shifts);
        target_total = solve_plan.requested_total_modes;
        max_per_shift = max(target_total, solver_cfg.max_modes_per_shift_large);
    end

    shift_limit = max(1, shift_limit);
    solve_plan.shifts = requested_shifts(1:shift_limit);
    solve_plan.target_total_modes = max(1, target_total);

    if solve_plan.is_low_memory
        k_start = min(max_per_shift, max(solver_cfg.min_modes_per_shift, ceil(solve_plan.target_total_modes / shift_limit)));
        k_candidates = [ ...
            k_start, ...
            max(solver_cfg.min_modes_per_shift, ceil(0.75 * k_start)), ...
            max(solver_cfg.min_modes_per_shift, ceil(0.50 * k_start)), ...
            solver_cfg.min_modes_per_shift];
    else
        k_nominal = max(10, ceil(1.25 * solve_plan.target_total_modes / shift_limit) + 6);
        k_candidates = [ ...
            k_nominal, ...
            max(8, ceil(0.75 * k_nominal)), ...
            max(6, ceil(0.50 * k_nominal))];
    end

    k_candidates = round(k_candidates(:).');
    k_candidates = k_candidates(k_candidates >= 1 & k_candidates <= max(n_sys - 2, 1));
    if isempty(k_candidates)
        k_candidates = min(max(2, solver_cfg.min_modes_per_shift), max(n_sys - 2, 1));
    end
    solve_plan.k_candidates = local_unique_integer_preserve(k_candidates);
    solve_plan.krylov_candidates = local_build_krylov_candidates( ...
        Config, solve_plan.target_total_modes, numel(solve_plan.shifts), n_sys, solve_plan.k_candidates(1));
end

function shifts = local_prepare_shifts(shifts_in, primary_shift)
%LOCAL_PREPARE_SHIFTS Deduplicate shifts and order them by proximity to the primary shift.

    shifts_unique = local_unique_complex_preserve(shifts_in(:).');
    [~, order] = sort(abs(shifts_unique - primary_shift), 'ascend');
    shifts = shifts_unique(order);
end

function value = local_get_primary_shift(Config, shifts)
%LOCAL_GET_PRIMARY_SHIFT Return the first shift to try under memory pressure.

    if isfield(Config, 'sigma') && isnumeric(Config.sigma) && isscalar(Config.sigma) && isfinite(Config.sigma)
        value = Config.sigma;
    else
        value = shifts(1);
    end
end

function solver_cfg = local_get_descriptor_solver_config(Config)
%LOCAL_GET_DESCRIPTOR_SOLVER_CONFIG Return low-memory solver defaults with overrides.

    solver_cfg = struct( ...
        'large_system_threshold', 4.0e5, ...
        'huge_system_threshold', 1.0e6, ...
        'max_total_modes_large', 18, ...
        'max_total_modes_huge', 8, ...
        'max_shifts_large', 3, ...
        'max_shifts_huge', 1, ...
        'max_modes_per_shift_large', 6, ...
        'max_modes_per_shift_huge', 3, ...
        'min_modes_per_shift', 2, ...
        'krylov_floor_large', 24, ...
        'krylov_cap_large', 48, ...
        'krylov_floor_huge', 10, ...
        'krylov_cap_huge', 20);

    if ~isstruct(Config) || ~isfield(Config, 'descriptor_solver') || ~isstruct(Config.descriptor_solver)
        return;
    end

    names = fieldnames(solver_cfg);
    for k = 1:numel(names)
        name = names{k};
        if isfield(Config.descriptor_solver, name)
            value = Config.descriptor_solver.(name);
            if isnumeric(value) && isscalar(value) && isfinite(value)
                solver_cfg.(name) = value;
            end
        end
    end
end

function values = local_unique_integer_preserve(values_in)
%LOCAL_UNIQUE_INTEGER_PRESERVE Deduplicate integer vectors without sorting.

    values = zeros(1, numel(values_in));
    count = 0;
    for k = 1:numel(values_in)
        value = round(values_in(k));
        if count == 0 || ~any(values(1:count) == value)
            count = count + 1;
            values(count) = value;
        end
    end
    values = values(1:count);
end

function values = local_unique_complex_preserve(values_in)
%LOCAL_UNIQUE_COMPLEX_PRESERVE Deduplicate complex vectors without sorting.

    values = complex(zeros(1, numel(values_in)));
    count = 0;
    for k = 1:numel(values_in)
        value = values_in(k);
        if count == 0 || ~any(abs(values(1:count) - value) <= 1.0e-14 * (1.0 + abs(value)))
            count = count + 1;
            values(count) = value;
        end
    end
    values = values(1:count);
end

function tf = local_is_memory_error(ME)
%LOCAL_IS_MEMORY_ERROR True when eigs failed due to memory pressure.

    message_text = lower(string(ME.message));
    tf = contains(message_text, "out of memory") || ...
        contains(message_text, "not enough memory") || ...
        contains(message_text, "内存不足") || ...
        contains(message_text, "insufficient memory") || ...
        contains(message_text, "maximum array size");
end

function text_value = local_format_integer_list(values)
%LOCAL_FORMAT_INTEGER_LIST Format one integer vector for warnings.

    values = round(values(:).');
    if isempty(values)
        text_value = '';
        return;
    end
    parts = arrayfun(@(x) sprintf('%d', x), values, 'UniformOutput', false);
    text_value = strjoin(parts, ', ');
end

function value = local_get_numeric_field(S, name, default_value)
%LOCAL_GET_NUMERIC_FIELD Return one scalar config field or a fallback default.

    value = default_value;
    if isstruct(S) && isfield(S, name) && isnumeric(S.(name)) && isscalar(S.(name)) && isfinite(S.(name))
        value = S.(name);
    end
end

function [residuals, residuals_active, residuals_algebraic, residuals_scaled] = ...
        local_compute_residuals(LNS_L, LNS_Gam, A_scaled, B_scaled, EigVals, EigVecs, EigVecs_scaled, active_mask)
%LOCAL_COMPUTE_RESIDUALS Compute total, active, algebraic, and scaled residuals.

    num_modes = numel(EigVals);
    residuals = zeros(num_modes, 1);
    residuals_active = zeros(num_modes, 1);
    residuals_algebraic = zeros(num_modes, 1);
    residuals_scaled = zeros(num_modes, 1);

    for k = 1:num_modes
        qk = EigVecs(:, k);
        rk = LNS_L * qk - EigVals(k) * (LNS_Gam * qk);
        denom_total = norm(LNS_L * qk);
        residuals(k) = norm(rk) / max(denom_total, eps);
        residuals_active(k) = norm(rk(active_mask)) / max(denom_total, eps);
        residuals_algebraic(k) = norm(rk(~active_mask)) / max(denom_total, eps);

        xk = EigVecs_scaled(:, k);
        rk_scaled = A_scaled * xk - EigVals(k) * (B_scaled * xk);
        residuals_scaled(k) = norm(rk_scaled) / max(norm(A_scaled * xk), eps);
    end
end

function keep_idx = local_deduplicate_modes(EigVals, residuals)
%LOCAL_DEDUPLICATE_MODES Keep the lowest-residual representative of each sigma cluster.

    num_modes = numel(EigVals);
    if num_modes <= 1
        keep_idx = (1:num_modes).';
        return;
    end

    [~, by_quality] = sortrows([residuals(:), -real(EigVals(:)), abs(imag(EigVals(:)))], [1, 2, 3]);
    keep_idx = zeros(num_modes, 1);
    keep_count = 0;
    tol_sigma = 1.0e-6;
    kept_vals = complex([]);

    for ii = 1:num_modes
        idx = by_quality(ii);
        sigma_i = EigVals(idx);
        if any(abs(sigma_i - kept_vals) <= tol_sigma * (1.0 + max(abs(sigma_i), abs(kept_vals))))
            continue;
        end
        keep_count = keep_count + 1;
        keep_idx(keep_count) = idx;
        kept_vals(end + 1, 1) = sigma_i; %#ok<AGROW>
    end

    keep_idx = sort(keep_idx(1:keep_count));
end

function shifts = local_get_sigma_shifts(Config)
%LOCAL_GET_SIGMA_SHIFTS Return the configured low-frequency shifts.

    if isfield(Config, 'sigma_triplet') && ~isempty(Config.sigma_triplet)
        shifts = Config.sigma_triplet;
    elseif isfield(Config, 'sigma') && ~isempty(Config.sigma)
        shifts = Config.sigma;
    else
        shifts = [0.00 + 0.005i, 0.00 + 0.010i, 0.00 + 0.020i, 0.02 + 0.020i, 0.05 + 0.020i];
    end
end
