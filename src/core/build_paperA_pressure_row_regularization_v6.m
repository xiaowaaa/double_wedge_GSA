function [coeffs, audit] = build_paperA_pressure_row_regularization_v6(px_coeff, py_coeff, div_coeff, shock_mask, Config)
%BUILD_PAPERA_PRESSURE_ROW_REGULARIZATION_V6 Regularize pressure-row coefficients near shocks.

    coeffs = struct( ...
        'px', px_coeff(:), ...
        'py', py_coeff(:), ...
        'div', div_coeff(:));

    shock_mask = logical(shock_mask(:));
    settings = local_get_settings(Config);

    audit = struct();
    audit.enabled = settings.enabled;
    audit.shock_point_count = nnz(shock_mask);
    audit.total_point_count = numel(shock_mask);
    audit.coverage_fraction = audit.shock_point_count / max(audit.total_point_count, 1);
    audit.gradient_clip_percentile = settings.gradient_clip_percentile;
    audit.divergence_clip_percentile = settings.divergence_clip_percentile;
    audit.fields = struct();

    if ~settings.enabled
        audit.fields.px = local_build_passthrough_audit(coeffs.px, shock_mask);
        audit.fields.py = local_build_passthrough_audit(coeffs.py, shock_mask);
        audit.fields.div = local_build_passthrough_audit(coeffs.div, shock_mask);
        audit.total_clipped = 0;
        audit.total_zeroed = 0;
        return;
    end

    [coeffs.px, audit.fields.px] = local_regularize_field( ...
        coeffs.px, shock_mask, settings.gradient_clip_percentile, settings.suppress_pressure_gradients_in_shock);
    [coeffs.py, audit.fields.py] = local_regularize_field( ...
        coeffs.py, shock_mask, settings.gradient_clip_percentile, settings.suppress_pressure_gradients_in_shock);
    [coeffs.div, audit.fields.div] = local_regularize_field( ...
        coeffs.div, shock_mask, settings.divergence_clip_percentile, settings.suppress_divergence_in_shock);
    audit.total_clipped = audit.fields.px.num_clipped + audit.fields.py.num_clipped + audit.fields.div.num_clipped;
    audit.total_zeroed = audit.fields.px.num_zeroed + audit.fields.py.num_zeroed + audit.fields.div.num_zeroed;
end

function settings = local_get_settings(Config)
%LOCAL_GET_SETTINGS Normalize the pressure-row regularization settings.

    settings = struct( ...
        'enabled', false, ...
        'gradient_clip_percentile', 95.0, ...
        'divergence_clip_percentile', 95.0, ...
        'suppress_pressure_gradients_in_shock', false, ...
        'suppress_divergence_in_shock', false);

    if isstruct(Config) && isfield(Config, 'pressure_row_regularization') && isstruct(Config.pressure_row_regularization)
        raw = Config.pressure_row_regularization;
        names = fieldnames(settings);
        for k = 1:numel(names)
            name = names{k};
            if isfield(raw, name)
                settings.(name) = raw.(name);
            end
        end
    end

    settings.enabled = logical(settings.enabled);
    settings.suppress_pressure_gradients_in_shock = logical(settings.suppress_pressure_gradients_in_shock);
    settings.suppress_divergence_in_shock = logical(settings.suppress_divergence_in_shock);
end

function [field_out, field_audit] = local_regularize_field(field_in, shock_mask, pct, suppress_in_shock)
%LOCAL_REGULARIZE_FIELD Clip or suppress one weighted pressure-row field.

    field_out = field_in(:);
    field_audit = local_build_passthrough_audit(field_out, shock_mask);
    if isempty(field_out)
        field_audit.clip_abs = inf;
        return;
    end

    if suppress_in_shock
        field_out(shock_mask) = 0.0;
        field_audit.num_zeroed = nnz(shock_mask);
        field_audit.max_abs_final = max(abs(field_out));
        field_audit.max_abs_final_shock = local_masked_abs_max(field_out, shock_mask);
        return;
    end

    reference_values = abs(field_out(~shock_mask));
    reference_values = reference_values(isfinite(reference_values));
    if isempty(reference_values)
        clip_hi = inf;
        n_clipped = 0;
    else
        clip_hi = local_percentile(reference_values, pct);
        if ~(isfinite(clip_hi) && clip_hi > 0)
            clip_hi = max(reference_values);
        end
        if ~(isfinite(clip_hi) && clip_hi > 0)
            clip_hi = inf;
            n_clipped = 0;
        else
            clip_mask = shock_mask & (abs(field_out) > clip_hi);
            field_out(clip_mask) = sign(field_out(clip_mask)) .* clip_hi;
            n_clipped = nnz(clip_mask);
        end
    end

    field_audit.clip_abs = clip_hi;
    field_audit.num_clipped = n_clipped;
    field_audit.max_abs_final = max(abs(field_out));
    field_audit.max_abs_final_shock = local_masked_abs_max(field_out, shock_mask);
end

function field_audit = local_build_passthrough_audit(field_value, shock_mask)
%LOCAL_BUILD_PASSTHROUGH_AUDIT Build the default audit for one field.

    field_value = field_value(:);
    field_audit = struct();
    field_audit.num_clipped = 0;
    field_audit.num_zeroed = 0;
    field_audit.clip_abs = inf;
    field_audit.max_abs_raw = max(abs(field_value));
    field_audit.max_abs_raw_shock = local_masked_abs_max(field_value, shock_mask);
    field_audit.max_abs_raw_nonshock = local_masked_abs_max(field_value, ~shock_mask);
    field_audit.max_abs_final = field_audit.max_abs_raw;
    field_audit.max_abs_final_shock = field_audit.max_abs_raw_shock;
end

function value = local_masked_abs_max(field_value, mask)
%LOCAL_MASKED_ABS_MAX Return max(abs(field(mask))) with empty-mask protection.

    if any(mask)
        value = max(abs(field_value(mask)));
    else
        value = 0.0;
    end
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
