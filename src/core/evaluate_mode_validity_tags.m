function [rejection_tags, thresholds] = evaluate_mode_validity_tags(leading_diag, report)
%EVALUATE_MODE_VALIDITY_TAGS Evaluate physical-publication rejection tags.

    thresholds = struct( ...
        'support_fraction_min', 0.005, ...
        'upper_layer_penalty', 0.80, ...
        'farfield_energy_ratio', 0.55, ...
        'peak_distance_to_farfield_min', 0.05);
    if nargin >= 2 && isstruct(report) && isfield(report, 'thresholds')
        names = fieldnames(report.thresholds);
        for k = 1:numel(names)
            thresholds.(names{k}) = report.thresholds.(names{k});
        end
    end

    rejection_tags = {};
    if leading_diag.support_fraction < thresholds.support_fraction_min
        rejection_tags{end + 1} = 'rejected_compact_support_mode'; %#ok<AGROW>
    end
    if leading_diag.upper_layer_penalty > thresholds.upper_layer_penalty
        rejection_tags{end + 1} = 'rejected_upper_layer_mode'; %#ok<AGROW>
    end
    if leading_diag.farfield_energy_ratio > thresholds.farfield_energy_ratio || ...
            leading_diag.peak_distance_to_farfield < thresholds.peak_distance_to_farfield_min
        rejection_tags{end + 1} = 'rejected_farfield_mode'; %#ok<AGROW>
    end
end
