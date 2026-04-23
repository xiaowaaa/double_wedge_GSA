function summary = summarize_mode_selection(report)
%SUMMARIZE_MODE_SELECTION Convert ranking metadata into a compact status struct.

    summary = struct();
    summary.strict_mode_ranking = logical(report.strict_mode_ranking);
    summary.num_quality_modes = report.num_quality_modes;
    summary.num_rank_modes = report.num_rank_modes;
    summary.relaxed_reason = char(string(report.relaxed_reason));

    if report.strict_mode_ranking
        if report.num_quality_modes > 0
            summary.status = 'strict_leading_mode';
            summary.leading_is_strict = true;
            summary.leading_is_relaxed_fallback = false;
        else
            summary.status = 'relaxed_fallback_no_strict_mode';
            summary.leading_is_strict = false;
            summary.leading_is_relaxed_fallback = true;
        end
    else
        summary.status = 'ranking_without_strict_gate';
        summary.leading_is_strict = false;
        summary.leading_is_relaxed_fallback = false;
    end
end
