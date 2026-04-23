function report = assert_realcase_boundary_contract(base, cfg, contract)
%ASSERT_REALCASE_BOUNDARY_CONTRACT Enforce the explicit inlet top-edge contract.

    if ~isfield(base, 'boundary') || ~isfield(base.boundary, 'masks')
        error('assert_realcase_boundary_contract:BoundaryInfo', ...
            'Baseflow does not contain explicit boundary masks.');
    end

    masks = base.boundary.masks;
    north_mask = masks.top;
    if isfield(masks, 'left') && isfield(masks, 'right')
        north_mask = north_mask & ~masks.left & ~masks.right;
    end
    if isempty(north_mask) || ~any(north_mask(:))
        error('assert_realcase_boundary_contract:NorthEdge', ...
            'The imported baseflow does not expose any north-edge nodes.');
    end

    north_counts = struct();
    north_counts.inlet = nnz(masks.inlet & north_mask);
    north_counts.outlet = nnz(masks.outlet & north_mask);
    north_counts.farfield = nnz(masks.farfield & north_mask);
    north_counts.wall = nnz(masks.wall & north_mask);
    north_counts.symmetry = nnz(masks.symmetry & north_mask);
    north_counts.total = nnz(north_mask);

    report = struct();
    report.case_tag = contract.case_tag;
    report.expected_dims = contract.expected_dims;
    report.raw_dims = [size(base.raw.x, 2), size(base.raw.x, 1)];
    report.working_dims = [base.Nx, base.Ny];
    report.top_type_cfg = cfg.bc.top_type;
    report.top_type_base = base.boundary.top_type;
    report.north_counts = north_counts;
    report.north_contract_excludes_side_corners = true;
    report.boundary_counts = base.boundary.counts;
    report.bottom_split_ok = base.validation.bottom_split_ok;

    if isempty(cfg.bc.top_type)
        error('assert_realcase_boundary_contract:TopTypeMissing', ...
            'cfg.bc.top_type must be explicitly set for the 812x382 real case.');
    end
    if ~strcmpi(cfg.bc.top_type, contract.top_type)
        error('assert_realcase_boundary_contract:TopTypeMismatch', ...
            'cfg.bc.top_type="%s" does not match the contract top_type="%s".', ...
            cfg.bc.top_type, contract.top_type);
    end
    if ~strcmpi(base.boundary.top_type, contract.top_type)
        error('assert_realcase_boundary_contract:BaseTopTypeMismatch', ...
            'Imported baseflow top_type="%s" does not match the contract top_type="%s".', ...
            base.boundary.top_type, contract.top_type);
    end
    if any(report.raw_dims ~= contract.expected_dims)
        error('assert_realcase_boundary_contract:RawDims', ...
            'Baseflow raw dimensions [%d, %d] do not match expected [%d, %d].', ...
            report.raw_dims(1), report.raw_dims(2), ...
            contract.expected_dims(1), contract.expected_dims(2));
    end
    if north_counts.inlet ~= north_counts.total || any([ ...
            north_counts.outlet, north_counts.farfield, north_counts.wall, north_counts.symmetry] > 0)
        error('assert_realcase_boundary_contract:NorthLabel', ...
            ['The 812x382 contract requires every north-edge node to be inlet. ' ...
             'Observed counts: inlet=%d, outlet=%d, farfield=%d, wall=%d, symmetry=%d, total=%d.'], ...
            north_counts.inlet, north_counts.outlet, north_counts.farfield, ...
            north_counts.wall, north_counts.symmetry, north_counts.total);
    end
end
