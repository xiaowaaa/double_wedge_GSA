function tbl = build_mode_component_norms(fields, RHO, velocity_weight)
%BUILD_MODE_COMPONENT_NORMS Summarize component magnitudes and energy shares.

    components = {'rho', 'u', 'v', 'w', 'T', 'p'};
    keep = false(size(components));
    for k = 1:numel(components)
        keep(k) = isfield(fields, components{k});
    end
    components = components(keep);

    rows = cell(numel(components), 1);
    linf_vals = zeros(numel(components), 1);
    l2_vals = zeros(numel(components), 1);
    weighted_energy = NaN(numel(components), 1);

    for k = 1:numel(components)
        comp = components{k};
        data = fields.(comp);
        rows{k} = comp;
        linf_vals(k) = max(abs(data(:)));
        l2_vals(k) = norm(data(:));
        switch comp
            case 'rho'
                weighted_energy(k) = sum(abs(data(:)).^2);
            case {'u', 'v', 'w'}
                weighted_energy(k) = velocity_weight * sum(RHO(:) .* abs(data(:)).^2);
            case 'T'
                weighted_energy(k) = velocity_weight * sum(abs(data(:)).^2);
            otherwise
                weighted_energy(k) = NaN;
        end
    end

    energy_total = sum(weighted_energy(isfinite(weighted_energy)));
    if energy_total <= 0
        energy_share = NaN(size(weighted_energy));
    else
        energy_share = weighted_energy / energy_total;
    end
    tbl = table(rows, linf_vals, l2_vals, weighted_energy, energy_share, ...
        'VariableNames', {'component', 'linf', 'l2', 'weighted_energy', 'energy_share'});
end
