function dF = fd4_uniform(F, dim, derivative_order, varargin)
%FD4_UNIFORM Apply the uniform-grid finite-difference matrix to a field.

    p = inputParser;
    p.FunctionName = 'fd4_uniform';
    addParameter(p, 'Spacing', 1.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
    parse(p, varargin{:});

    if dim ~= 1 && dim ~= 2
        error('fd4_uniform:Dimension', 'dim must be 1 (rows) or 2 (columns).');
    end

    if dim == 1
        D = build_uniform_fd_matrix(size(F, 1), derivative_order, 'Spacing', p.Results.Spacing);
        dF = D * F;
    else
        D = build_uniform_fd_matrix(size(F, 2), derivative_order, 'Spacing', p.Results.Spacing);
        dF = F * D.';
    end
end
