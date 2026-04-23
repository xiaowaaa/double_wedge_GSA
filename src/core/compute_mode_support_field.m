function [support_field, components] = compute_mode_support_field(q_mode, Ny, Nx, layout_name, RHO, Cv_nd, varargin)
%COMPUTE_MODE_SUPPORT_FIELD Build one reusable support field for mode diagnostics.

    p = inputParser;
    p.FunctionName = 'compute_mode_support_field';
    addParameter(p, 'Weighting', 'u_dominant', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    parse(p, varargin{:});

    layout = get_state_layout_info(layout_name);
    components = local_extract_components(q_mode, Ny, Nx, layout.name);

    kinetic_u = local_weighted_component(RHO, components.u);
    kinetic_v = local_weighted_component(RHO, components.v);
    kinetic_w = local_weighted_component(RHO, components.w);
    thermal = local_weighted_component(RHO * Cv_nd, components.T);
    pressure = local_weighted_component(ones(Ny, Nx), components.p);

    components.energy_u = kinetic_u;
    components.energy_v = kinetic_v;
    components.energy_w = kinetic_w;
    components.energy_T = thermal;
    components.energy_p = pressure;
    components.energy_total = kinetic_u + kinetic_v + kinetic_w + thermal + pressure;

    weighting = lower(strtrim(char(string(p.Results.Weighting))));
    switch weighting
        case 'u_dominant'
            support_field = kinetic_u;
            if all(support_field(:) <= 1.0e-60)
                support_field = support_field + kinetic_v;
            end
            if all(support_field(:) <= 1.0e-60)
                support_field = support_field + kinetic_w;
            end
            if all(support_field(:) <= 1.0e-60)
                support_field = thermal;
            end
            if all(support_field(:) <= 1.0e-60)
                support_field = pressure;
            end
        case 'component_energy'
            support_field = components.energy_total;
        case 'w_dominant'
            support_field = kinetic_w;
            if all(support_field(:) <= 1.0e-60)
                support_field = kinetic_u + kinetic_v;
            end
            if all(support_field(:) <= 1.0e-60)
                support_field = thermal + pressure;
            end
        otherwise
            error('compute_mode_support_field:UnknownWeighting', ...
                'Unknown support-field weighting "%s".', weighting);
    end
end

function components = local_extract_components(q_mode, Ny, Nx, layout_name)
%LOCAL_EXTRACT_COMPONENTS Extract one primitive-five state view.

    component_names = {'rho', 'u', 'v', 'w', 'T', 'p'};
    components = struct();
    for k = 1:numel(component_names)
        name = component_names{k};
        components.(name) = extract_state_component(q_mode, Ny, Nx, layout_name, name);
    end
end

function weighted = local_weighted_component(weight_field, component_field)
%LOCAL_WEIGHTED_COMPONENT Weighted squared-amplitude helper.

    if all(isnan(component_field(:)))
        weighted = zeros(size(weight_field));
    else
        weighted = weight_field .* abs(component_field).^2;
    end
end
