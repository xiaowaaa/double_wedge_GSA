function validity = build_mode_validity_report(selection_summary, leading_diag, report)
%BUILD_MODE_VALIDITY_REPORT Decide whether the current leader is publishable.

    [rejection_tags, ~] = evaluate_mode_validity_tags(leading_diag, report);

    validity = struct();
    validity.selection_status = selection_summary.status;
    validity.rejection_tags = rejection_tags;
    if strcmp(selection_summary.status, 'strict_leading_mode') && isempty(rejection_tags)
        validity.publication_allowed = true;
        validity.debug_only = false;
        validity.primary_reason = 'strict_leading_mode';
        validity.title_prefix = 'Physical leading mode';
    else
        validity.publication_allowed = false;
        validity.debug_only = true;
        if isempty(rejection_tags)
            validity.primary_reason = char(string(selection_summary.status));
            if isempty(validity.primary_reason)
                validity.primary_reason = 'relaxed_fallback_no_strict_mode';
            end
        else
            validity.primary_reason = rejection_tags{1};
        end
        validity.title_prefix = sprintf('Debug-only pseudo-mode (%s)', validity.primary_reason);
    end
end
