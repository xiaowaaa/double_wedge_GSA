function D = build_uniform_fd_matrix(N, derivative_order, varargin)
%BUILD_UNIFORM_FD_MATRIX Build 4th-order interior / biased boundary FD rows.

    p = inputParser;
    p.FunctionName = 'build_uniform_fd_matrix';
    addParameter(p, 'Spacing', 1.0, @(x) isnumeric(x) && isscalar(x) && x > 0);
    parse(p, varargin{:});
    h = p.Results.Spacing;

    if derivative_order ~= 1 && derivative_order ~= 2
        error('build_uniform_fd_matrix:DerivativeOrder', ...
            'Only first and second derivatives are supported.');
    end
    if N < 5
        error('build_uniform_fd_matrix:GridSize', ...
            'Need at least 5 points for the current fourth-order stencil family.');
    end

    D = spalloc(N, N, 5 * N);

    for i = 1:N
        if derivative_order == 1
            stencil = local_select_first_derivative_stencil(i, N);
        else
            stencil = local_select_second_derivative_stencil(i, N);
        end
        x_nodes = (stencil - i) * h;
        weights = local_fd_weights(0.0, x_nodes, derivative_order);
        D(i, stencil) = weights(:).';
    end
end

function stencil = local_select_first_derivative_stencil(i, N)
%LOCAL_SELECT_FIRST_DERIVATIVE_STENCIL Pick the intended biased stencil.

    if i <= 2
        stencil = 1:4;
    elseif i >= N - 1
        stencil = N-3:N;
    else
        stencil = i-2:i+2;
    end
end

function stencil = local_select_second_derivative_stencil(i, N)
%LOCAL_SELECT_SECOND_DERIVATIVE_STENCIL Pick the intended biased stencil.

    if i == 1
        stencil = 1:4;
    elseif i == 2
        stencil = 1:3;
    elseif i == N - 1
        stencil = N-2:N;
    elseif i == N
        stencil = N-3:N;
    else
        stencil = i-2:i+2;
    end
end

function weights = local_fd_weights(x0, x_nodes, derivative_order)
%LOCAL_FD_WEIGHTS Solve for finite-difference weights on one stencil.

    n = numel(x_nodes);
    A = zeros(n, n);
    b = zeros(n, 1);
    shifted = x_nodes(:) - x0;
    for row = 1:n
        A(row, :) = shifted(:).' .^ (row - 1);
        if row - 1 == derivative_order
            b(row) = factorial(derivative_order);
        end
    end
    weights = A \ b;
end
