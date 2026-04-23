function [Kav, info] = build_semi_artificial_viscosity_matrix(Ny, Nx, varargin)
%BUILD_SEMI_ARTIFICIAL_VISCOSITY_MATRIX Build the interior fourth-difference filter.

    p = inputParser;
    p.FunctionName = 'build_semi_artificial_viscosity_matrix';
    addParameter(p, 'StateLayout', 'primitive5_u_v_w_T_p', @(x) ischar(x) || (isstring(x) && isscalar(x)));
    parse(p, varargin{:});

    layout = get_state_layout_info(p.Results.StateLayout);
    Ndof = layout.nvar * Ny * Nx;
    idx = @(j, i, var) (i - 1) * Ny * layout.nvar + (j - 1) * layout.nvar + var;

    rows = [];
    cols = [];
    vals = [];
    active_points = 0;

    for i = 3:Nx-2
        for j = 3:Ny-2
            active_points = active_points + 1;
            for var = 1:layout.nvar
                row = idx(j, i, var);
                stencil_cols = [ ...
                    idx(j-2, i, var), ...
                    idx(j-1, i, var), ...
                    idx(j, i-2, var), ...
                    idx(j, i-1, var), ...
                    idx(j, i, var), ...
                    idx(j, i+1, var), ...
                    idx(j, i+2, var), ...
                    idx(j+1, i, var), ...
                    idx(j+2, i, var)];
                stencil_vals = [-1, 4, -1, 4, -12, 4, -1, 4, -1];

                rows = [rows; repmat(row, numel(stencil_cols), 1)]; %#ok<AGROW>
                cols = [cols; stencil_cols(:)]; %#ok<AGROW>
                vals = [vals; stencil_vals(:)]; %#ok<AGROW>
            end
        end
    end

    Kav = sparse(rows, cols, vals, Ndof, Ndof);

    info = struct();
    info.state_layout = layout.name;
    info.active_points = active_points;
    info.active_rows = active_points * layout.nvar;
end
