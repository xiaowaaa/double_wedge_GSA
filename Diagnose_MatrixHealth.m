function report = Diagnose_MatrixHealth(result_file)
%DIAGNOSE_MATRIXHEALTH Inspect row norms, block scales, and zero rows/cols.

    if nargin < 1 || isempty(result_file)
        result_file = 'Part3_Results.mat';
    end
    if exist(result_file, 'file') ~= 2
        error('Diagnose_MatrixHealth:MissingFile', ...
            'Unable to find %s.', result_file);
    end

    data = load(result_file, 'LNS_L', 'LNS_Gam', 'Config', 'Ndof', 'Ny', 'Nx');
    row_norms = full(max(abs(data.LNS_L), [], 2));
    col_norms = full(max(abs(data.LNS_L), [], 1)).';
    active_mask = abs(full(diag(data.LNS_Gam))) > 0;
    active_rows = row_norms(active_mask);
    row_ratio = max(active_rows) / max(min(active_rows(active_rows > 0)), 1.0e-30);

    G_diag = full(diag(data.LNS_Gam));
    Dr = spdiags(1.0 ./ max(row_norms, 1.0e-30), 0, data.Ndof, data.Ndof);
    Dc = spdiags(sqrt(max(abs(G_diag), 1.0e-30)), 0, data.Ndof, data.Ndof);
    A_scaled = Dr * data.LNS_L * Dc;
    scaled_row_norms = full(max(abs(A_scaled), [], 2));
    active_scaled_rows = scaled_row_norms(active_mask);
    scaled_ratio = max(active_scaled_rows) / max(min(active_scaled_rows(active_scaled_rows > 0)), 1.0e-30);

    layout = char(string(data.Config.state_layout));
    layout_info = get_state_layout_info(layout);
    nvar = layout_info.nvar;

    block_report = table('Size', [nvar, 4], ...
        'VariableTypes', {'double', 'double', 'double', 'double'}, ...
        'VariableNames', {'row_max_mean', 'row_max_max', 'gamma_mean', 'gamma_max'});
    for var = 1:nvar
        block_rows = var:nvar:data.Ndof;
        block_report.row_max_mean(var) = mean(row_norms(block_rows));
        block_report.row_max_max(var) = max(row_norms(block_rows));
        block_report.gamma_mean(var) = mean(abs(G_diag(block_rows)));
        block_report.gamma_max(var) = max(abs(G_diag(block_rows)));
    end

    zero_rows = find(row_norms < 1.0e-30);
    zero_cols = find(col_norms < 1.0e-30);

    report = struct();
    report.result_file = result_file;
    report.state_layout = layout;
    report.row_norm_ratio_before = row_ratio;
    report.row_norm_ratio_after = scaled_ratio;
    report.zero_rows = zero_rows;
    report.zero_cols = zero_cols;
    report.block_report = block_report;

    fprintf('[Diagnose_MatrixHealth] state_layout=%s\n', layout);
    fprintf('[Diagnose_MatrixHealth] row ratio before: %.3e\n', row_ratio);
    fprintf('[Diagnose_MatrixHealth] row ratio after : %.3e\n', scaled_ratio);
    fprintf('[Diagnose_MatrixHealth] zero rows=%d zero cols=%d\n', numel(zero_rows), numel(zero_cols));
    disp(block_report);
end
