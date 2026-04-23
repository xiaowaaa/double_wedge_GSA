function info = interpret_sigma_eigenvalues(sigma_vals, varargin)
%INTERPRET_SIGMA_EIGENVALUES Convert sigma to omega/frequency conventions.

    p = inputParser;
    p.FunctionName = 'interpret_sigma_eigenvalues';
    addParameter(p, 'U_ref', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
    addParameter(p, 'L_ref', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
    parse(p, varargin{:});

    sigma_vals = sigma_vals(:);

    info = struct();
    info.sigma = sigma_vals;
    info.omega = 1i * sigma_vals;
    info.growth_rate = real(sigma_vals);
    info.angular_frequency = -imag(sigma_vals);
    info.freq_nd_signed = info.angular_frequency / (2 * pi);
    info.freq_nd_abs = abs(info.freq_nd_signed);

    if ~isempty(p.Results.U_ref) && ~isempty(p.Results.L_ref)
        scale = p.Results.L_ref / p.Results.U_ref;
        info.St_signed = info.freq_nd_signed * scale;
        info.St_abs = abs(info.St_signed);
    else
        info.St_signed = [];
        info.St_abs = [];
    end
end
