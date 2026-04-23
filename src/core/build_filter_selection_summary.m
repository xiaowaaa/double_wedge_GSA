function summary = build_filter_selection_summary(num_modes, mask_res, mask_wall, mask_checker, mask_selected)
%BUILD_FILTER_SELECTION_SUMMARY Summarize the strict v5 filter pipeline.

    if nargin < 5
        error('build_filter_selection_summary:InputCount', ...
            'Expected num_modes plus four logical masks.');
    end

    summary = struct();
    summary.strict_mode_ranking = true;
    summary.num_input_modes = num_modes;
    summary.num_rank_modes = num_modes;
    summary.num_residual_modes = nnz(mask_res);
    summary.num_wall_modes = nnz(mask_res & mask_wall);
    summary.num_checker_modes = nnz(mask_res & mask_wall & mask_checker);
    summary.num_quality_modes = nnz(mask_selected);
    summary.num_selected_modes = nnz(mask_selected);
    summary.leading_is_strict = any(mask_selected);
    summary.leading_is_relaxed_fallback = ~any(mask_selected);

    if any(mask_selected)
        summary.status = 'strict_leading_mode';
        summary.relaxed_reason = '';
    elseif ~any(mask_res)
        summary.status = 'no_residual_clean_mode';
        summary.relaxed_reason = 'no mode passed the residual threshold';
    elseif ~any(mask_res & mask_wall)
        summary.status = 'no_wall_supported_mode';
        summary.relaxed_reason = 'residual-clean modes failed the wall-energy gate';
    elseif ~any(mask_res & mask_wall & mask_checker)
        summary.status = 'no_checker_clean_mode';
        summary.relaxed_reason = 'wall-supported residual-clean modes failed the checker gate';
    else
        summary.status = 'relaxed_fallback_no_strict_mode';
        summary.relaxed_reason = 'strict filter pipeline produced no selected mode';
    end
end
