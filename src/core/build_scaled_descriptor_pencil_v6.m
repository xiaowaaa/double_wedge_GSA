function [A_scaled, B_scaled, Dr, Dc, active_mask, MatrixHealth] = build_scaled_descriptor_pencil_v6(LNS_L, LNS_Gam)
%BUILD_SCALED_DESCRIPTOR_PENCIL_V6 Apply the v6 descriptor row/column scaling.

    Ndof = size(LNS_L, 1);

    L_row_max = full(max(abs(LNS_L), [], 2));
    L_row_max(L_row_max < 1.0e-30) = 1.0;
    Dr = spdiags(1.0 ./ L_row_max, 0, Ndof, Ndof);

    G_diag_abs = abs(full(diag(LNS_Gam)));
    G_diag_abs(G_diag_abs < 1.0e-30) = 1.0;
    Dc_vec = sqrt(G_diag_abs);
    Dc = spdiags(Dc_vec, 0, Ndof, Ndof);

    A_scaled = Dr * LNS_L * Dc;
    B_scaled = Dr * LNS_Gam * Dc;

    gamma_diag = full(diag(LNS_Gam));
    active_mask = abs(gamma_diag) > 0;
    As_rn = full(max(abs(A_scaled), [], 2));
    As_active = As_rn(active_mask);
    row_ratio_after = max(As_active) / max(min(As_active), 1.0e-30);
    L_active = L_row_max(active_mask);
    row_ratio_before = max(L_active) / max(min(L_active), 1.0e-30);

    MatrixHealth = struct();
    MatrixHealth.row_norm_ratio_before = row_ratio_before;
    MatrixHealth.row_norm_ratio_after = row_ratio_after;
    MatrixHealth.num_active_rows = nnz(active_mask);
    MatrixHealth.zero_rows = find(As_rn <= 1.0e-30);
    col_norm = full(max(abs(A_scaled), [], 1)).';
    MatrixHealth.zero_cols = find(col_norm <= 1.0e-30);
end
