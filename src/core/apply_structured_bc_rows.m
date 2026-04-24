function [LNS_L, LNS_Gam, report] = apply_structured_bc_rows(LNS_L, LNS_Gam, mask, X, varargin)
%APPLY_STRUCTURED_BC_ROWS Replace boundary rows using explicit edge masks.

    p = inputParser;
    p.FunctionName = 'apply_structured_bc_rows';
    addParameter(p, 'Verbose', true, @(x) islogical(x) && isscalar(x));
    addParameter(p, 'StateLayout', 'primitive5_u_v_w_T_p', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    addParameter(p, 'WallModel', 'adiabatic', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    parse(p, varargin{:});

    layout = get_state_layout_info(p.Results.StateLayout);
    wall_model = normalize_wall_model(p.Results.WallModel, ...
        'ErrorIdentifier', 'apply_structured_bc_rows:WallModel');
    south_specs = local_build_south_specs(layout, wall_model);
    [Ny, Nx] = size(X);
    idx = @(j, i, var) (i - 1) * Ny * layout.nvar + (j - 1) * layout.nvar + var;

    cN = [-25, 48, -36, 16, -3] / 12.0;
    cE = [1, -4, 6, -4, 1];

    counts = struct('inlet', 0, 'outlet', 0, 'farfield', 0, 'wall', 0, 'symmetry', 0);
    boundary_row_mask = false(size(LNS_L, 1), 1);

    for j = 1:Ny
        for i = 1:Nx
            if mask.inlet(j, i)
                counts.inlet = counts.inlet + 1;
                for var = 1:layout.nvar
                    row = idx(j, i, var);
                    boundary_row_mask(row) = true;
                    [LNS_L, LNS_Gam] = local_set_dirichlet_row(LNS_L, LNS_Gam, row);
                end
            elseif mask.farfield(j, i)
                counts.farfield = counts.farfield + 1;
                for var = 1:layout.nvar
                    row = idx(j, i, var);
                    boundary_row_mask(row) = true;
                    [LNS_L, LNS_Gam] = local_set_dirichlet_row(LNS_L, LNS_Gam, row);
                end
            elseif mask.outlet(j, i)
                counts.outlet = counts.outlet + 1;
                for var = 1:layout.nvar
                    row = idx(j, i, var);
                    boundary_row_mask(row) = true;
                    cols = arrayfun(@(ii) idx(j, ii, var), Nx-4:Nx);
                    [LNS_L, LNS_Gam] = local_set_algebraic_row(LNS_L, LNS_Gam, row, cols, cE);
                end
            elseif mask.symmetry(j, i)
                counts.symmetry = counts.symmetry + 1;
                [LNS_L, LNS_Gam, replaced_rows] = local_apply_south_condition(LNS_L, LNS_Gam, ...
                    idx, i, south_specs.symmetry, cN);
                boundary_row_mask(replaced_rows) = true;
            elseif mask.wall(j, i)
                counts.wall = counts.wall + 1;
                [LNS_L, LNS_Gam, replaced_rows] = local_apply_south_condition(LNS_L, LNS_Gam, ...
                    idx, i, south_specs.wall, cN);
                boundary_row_mask(replaced_rows) = true;
            end
        end
    end

    report = struct();
    report.counts = counts;
    report.state_layout = layout.name;
    report.wall_model = south_specs.wall.wall_model;
    report.wall_thermal_constraint = south_specs.wall.thermal_constraint;
    report.wall_temperature_row_type = south_specs.wall.temperature_row_type;
    report.boundary_row_mask = boundary_row_mask;
    report.overwritten_rows = find(boundary_row_mask);
    report.num_overwritten_rows = nnz(boundary_row_mask);
end

function south_specs = local_build_south_specs(layout, wall_model)
%LOCAL_BUILD_SOUTH_SPECS Precompute south-edge row sets for one solve.

    south_specs = struct();
    south_specs.symmetry = local_get_south_row_sets(layout, 'symmetry', wall_model);
    south_specs.wall = local_get_south_row_sets(layout, 'wall', wall_model);
end

function [LNS_L, LNS_Gam, replaced_rows] = local_apply_south_condition(LNS_L, LNS_Gam, idx, i, row_sets, cN)
%LOCAL_APPLY_SOUTH_CONDITION Apply symmetry/wall rules on the south edge.
    replaced_rows = zeros(numel(row_sets.dirichlet) + numel(row_sets.neumann), 1);
    ptr = 0;

    for k = 1:numel(row_sets.dirichlet)
        row = idx(1, i, row_sets.dirichlet(k));
        ptr = ptr + 1;
        replaced_rows(ptr) = row;
        [LNS_L, LNS_Gam] = local_set_dirichlet_row(LNS_L, LNS_Gam, row);
    end

    for k = 1:numel(row_sets.neumann)
        row = idx(1, i, row_sets.neumann(k));
        ptr = ptr + 1;
        replaced_rows(ptr) = row;
        cols = arrayfun(@(jj) idx(jj, i, row_sets.neumann(k)), 1:5);
        [LNS_L, LNS_Gam] = local_set_algebraic_row(LNS_L, LNS_Gam, row, cols, cN);
    end
    replaced_rows = replaced_rows(1:ptr);
end

function row_sets = local_get_south_row_sets(layout, bc_name, wall_model)
%LOCAL_GET_SOUTH_ROW_SETS Return variable groups for south-edge BCs.

    row_sets = struct('dirichlet', [], 'neumann', [], ...
        'wall_model', '', 'thermal_constraint', '', 'temperature_row_type', '');
    switch layout.name
        case 'primitive5_u_v_w_T_p'
            if strcmp(bc_name, 'symmetry')
                row_sets.dirichlet = layout.components.v;
                row_sets.neumann = [layout.components.u, layout.components.w, layout.components.T, layout.components.p];
            else
                [row_sets, thermal_audit] = get_wall_thermal_bc_rows(layout, wall_model);
                row_sets.wall_model = thermal_audit.wall_model;
                row_sets.thermal_constraint = thermal_audit.thermal_constraint;
                row_sets.temperature_row_type = thermal_audit.temperature_row_type;
            end
        otherwise
            error('apply_structured_bc_rows:Layout', ...
                'Unsupported state layout "%s".', layout.name);
    end
end

function [LNS_L, LNS_Gam] = local_set_dirichlet_row(LNS_L, LNS_Gam, row)
%LOCAL_SET_DIRICHLET_ROW Replace one row by an algebraic identity.

    LNS_L(row, :) = 0;
    LNS_Gam(row, :) = 0;
    LNS_L(row, row) = 1;
end

function [LNS_L, LNS_Gam] = local_set_algebraic_row(LNS_L, LNS_Gam, row, cols, vals)
%LOCAL_SET_ALGEBRAIC_ROW Replace one row by a fixed algebraic relation.

    LNS_L(row, :) = 0;
    LNS_Gam(row, :) = 0;
    LNS_L(row, cols) = vals;
end
