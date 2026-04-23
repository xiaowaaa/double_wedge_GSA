function test_sigma_frequency_convention()
%TEST_SIGMA_FREQUENCY_CONVENTION Verify sigma = -i*omega conversions.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    sigma_vals = [0.20 + 0.48i; -0.03 - 0.25i];
    info_nd = interpret_sigma_eigenvalues(sigma_vals);

    assert(max(abs(info_nd.omega - 1i * sigma_vals)) < 1.0e-12, ...
        'omega should equal 1i * sigma.');
    assert(max(abs(info_nd.growth_rate - real(sigma_vals))) < 1.0e-12, ...
        'growth rate should equal real(sigma).');
    assert(max(abs(info_nd.angular_frequency + imag(sigma_vals))) < 1.0e-12, ...
        'angular frequency should equal -imag(sigma).');
    assert(max(abs(info_nd.freq_nd_signed + imag(sigma_vals) / (2 * pi))) < 1.0e-12, ...
        'Signed nondimensional frequency should equal -imag(sigma)/(2*pi).');
    assert(all(info_nd.freq_nd_abs >= 0), ...
        'Absolute nondimensional frequency should be non-negative.');

    info_st = interpret_sigma_eigenvalues(sigma_vals, 'U_ref', 2.0, 'L_ref', 0.5);
    expected_st_signed = info_nd.freq_nd_signed * 0.5 / 2.0;
    assert(max(abs(info_st.St_signed - expected_st_signed)) < 1.0e-12, ...
        'Signed Strouhal number should scale with L_ref / U_ref.');
    assert(max(abs(info_st.St_abs - abs(expected_st_signed))) < 1.0e-12, ...
        'Absolute Strouhal number should be the magnitude of the signed value.');

    fprintf('[test_sigma_frequency_convention] PASS\n');
end
