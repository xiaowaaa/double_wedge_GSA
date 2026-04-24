function [row_sets, audit] = get_wall_thermal_bc_rows(layout, wall_model)
%GET_WALL_THERMAL_BC_ROWS Return primitive-five wall row sets for one wall model.

    wall_model = normalize_wall_model(wall_model, ...
        'ErrorIdentifier', 'get_wall_thermal_bc_rows:WallModel');
    row_sets = struct('dirichlet', [], 'neumann', []);
    audit = struct( ...
        'wall_model', wall_model, ...
        'thermal_constraint', '', ...
        'temperature_row_type', '');

    switch layout.name
        case 'primitive5_u_v_w_T_p'
            row_sets.dirichlet = [layout.components.u, layout.components.v, layout.components.w];
            row_sets.neumann = layout.components.p;
            switch wall_model
                case 'adiabatic'
                    row_sets.neumann = [layout.components.T, row_sets.neumann];
                    audit.thermal_constraint = 'dT_dn=0';
                    audit.temperature_row_type = 'neumann';
                case 'isothermal'
                    row_sets.dirichlet = [row_sets.dirichlet, layout.components.T];
                    audit.thermal_constraint = 'T_prime=0';
                    audit.temperature_row_type = 'dirichlet';
            end
        otherwise
            error('get_wall_thermal_bc_rows:Layout', ...
                'Unsupported state layout "%s".', layout.name);
    end
end
