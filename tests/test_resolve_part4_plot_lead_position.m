function test_resolve_part4_plot_lead_position()
%TEST_RESOLVE_PART4_PLOT_LEAD_POSITION Validate plotted-lead metadata resolution.

    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_root);
    addpath(fullfile(project_root, 'src', 'core'));

    part4 = struct();
    part4.EigVals_s = [0.1 + 0.2i; 0.0 + 0.1i; -0.1 + 0.1i];
    part4.ranking_table = table([11; 12; 13], ...
        'VariableNames', {'mode_index'});
    part4.plot_leading_mode_position = 2;
    part4.plot_leading_mode_index = 12;
    [lead_position, lead_original_index, audit] = resolve_part4_plot_lead_position(part4);
    assert(lead_position == 2, 'Explicit sorted-position metadata should be used directly.');
    assert(lead_original_index == 12, 'The original mode index should be recovered from ranking_table.');
    assert(strcmp(audit.source, 'plot_leading_mode_position'), ...
        'The audit should record the explicit position source.');

    legacy_part4 = rmfield(part4, 'plot_leading_mode_position');
    legacy_part4.plot_leading_mode_index = 13;
    [lead_position, lead_original_index, audit] = resolve_part4_plot_lead_position(legacy_part4);
    assert(lead_position == 3, 'Original mode indices should be mapped back through ranking_table.');
    assert(lead_original_index == 13, 'The resolved original mode index should be preserved.');
    assert(audit.used_original_index_lookup, ...
        'The audit should record that ranking_table lookup was used.');

    no_plot_part4 = struct();
    no_plot_part4.EigVals_s = [0.1 + 0.2i; 0.0 + 0.1i];
    no_plot_part4.selection_summary = struct('plot_status', 'no_physical_plot_candidates');
    [lead_position, lead_original_index, audit] = resolve_part4_plot_lead_position(no_plot_part4);
    assert(isnan(lead_position), 'No-plot metadata should stay NaN rather than silently falling back.');
    assert(isnan(lead_original_index), 'No-plot metadata should not fabricate an original mode index.');
    assert(strcmp(audit.status, 'no_physical_plot_candidate'), ...
        'The audit should preserve the explicit no-plot status.');

    fprintf('[test_resolve_part4_plot_lead_position] PASS\n');
end
