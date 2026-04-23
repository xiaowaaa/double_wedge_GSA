function [EigVals, EigVecs, residuals, active_mask] = solve_generalized_evp(LNS_L, LNS_Gam, n_eigs, sigma_shift)
%SOLVE_GENERALIZED_EVP Solve a sparse generalized EVP with BC rows removed.

    gamma_diag = full(diag(LNS_Gam));
    active_mask = abs(gamma_diag) > 0;
    A = LNS_L(active_mask, active_mask);
    B = LNS_Gam(active_mask, active_mask);

    k = min(max(1, round(n_eigs)), max(1, size(A, 1) - 2));
    use_full = size(A, 1) <= 300;

    if use_full
        [V_small, D_vals] = eig(full(A), full(B), 'vector');
    else
        opts = struct();
        opts.tol = 1.0e-10;
        opts.maxit = 400;
        opts.disp = 0;
        try
            [V_small, D_mat] = eigs(A, B, k, sigma_shift, opts);
            D_vals = diag(D_mat);
        catch
            [V_small, D_vals] = eig(full(A), full(B), 'vector');
        end
    end

    finite_mask = isfinite(D_vals);
    D_vals = D_vals(finite_mask);
    V_small = V_small(:, finite_mask);

    [~, order] = sort(real(D_vals), 'descend');
    D_vals = D_vals(order);
    V_small = V_small(:, order);
    if size(V_small, 2) > n_eigs
        D_vals = D_vals(1:n_eigs);
        V_small = V_small(:, 1:n_eigs);
    end

    EigVals = D_vals;
    EigVecs = zeros(size(LNS_L, 1), numel(EigVals));
    EigVecs(active_mask, :) = V_small;

    residuals = zeros(numel(EigVals), 1);
    for k = 1:numel(EigVals)
        qk = EigVecs(:, k);
        residuals(k) = norm(LNS_L * qk - EigVals(k) * (LNS_Gam * qk)) / ...
            max(norm(LNS_L * qk), eps);
    end
end
