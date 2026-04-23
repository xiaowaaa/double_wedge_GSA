function [Kav_local, info] = build_shock_localized_sav_matrix(dX, Ny, Nx, varargin)
%BUILD_SHOCK_LOCALIZED_SAV_MATRIX Restrict the SAV filter to a dilated shock band.

    p = inputParser;
    p.FunctionName = 'build_shock_localized_sav_matrix';
    addParameter(p, 'StateLayout', 'primitive5_u_v_w_T_p', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'Percentile', 90.0, @(x) isnumeric(x) && isscalar(x) && x > 0 && x < 100);
    addParameter(p, 'DilationSteps', 3, @(x) isnumeric(x) && isscalar(x) && x >= 0);
    addParameter(p, 'ShockMask', [], @(x) isempty(x) || islogical(x) || isnumeric(x));
    parse(p, varargin{:});

    grad_rho = hypot(dX.rhox, dX.rhoy);
    if isempty(p.Results.ShockMask)
        shock_threshold = local_percentile(grad_rho(:), p.Results.Percentile);
        shock_mask = grad_rho > shock_threshold;
        shock_mask_dilated = shock_mask;
        for k = 1:round(p.Results.DilationSteps)
            shock_mask_dilated = local_dilate_mask(shock_mask_dilated);
        end
    else
        shock_threshold = NaN;
        shock_mask = logical(p.Results.ShockMask);
        shock_mask_dilated = shock_mask;
    end

    [Kav_full, full_info] = build_semi_artificial_viscosity_matrix(Ny, Nx, ...
        'StateLayout', p.Results.StateLayout);
    layout = get_state_layout_info(p.Results.StateLayout);
    selector = repelem(shock_mask_dilated(:), layout.nvar);
    row_selector = spdiags(double(selector), 0, layout.nvar * Ny * Nx, layout.nvar * Ny * Nx);
    Kav_local = row_selector * Kav_full;

    info = struct();
    info.state_layout = full_info.state_layout;
    info.shock_threshold = shock_threshold;
    info.shock_mask = shock_mask;
    info.shock_mask_dilated = shock_mask_dilated;
    info.active_points = nnz(shock_mask_dilated);
    info.active_rows = nnz(selector);
end

function mask_out = local_dilate_mask(mask_in)
%LOCAL_DILATE_MASK Dilate a logical mask with a 5-point stencil.

    mask_out = dilate_mask_no_wrap(mask_in);
end

function value = local_percentile(data_value, pct)
%LOCAL_PERCENTILE Toolbox-free percentile helper.

    data_value = sort(data_value(:));
    if isempty(data_value)
        value = 0.0;
        return;
    end

    pct = min(max(pct, 0.0), 100.0);
    idx = 1 + (numel(data_value) - 1) * pct / 100.0;
    i_lo = floor(idx);
    i_hi = ceil(idx);
    if i_lo == i_hi
        value = data_value(i_lo);
    else
        w_hi = idx - i_lo;
        w_lo = 1.0 - w_hi;
        value = w_lo * data_value(i_lo) + w_hi * data_value(i_hi);
    end
end
