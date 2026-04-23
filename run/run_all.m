function results = run_all(cfg)
%RUN_ALL Execute the modular reader path and, when available, the legacy chain.

    setup_double_wedge_paths();
    if nargin < 1 || isempty(cfg)
        cfg = config_case();
    end

    base = read_phenglei_baseflow(cfg);
    base = preprocess_baseflow(base, cfg);

    results = struct();
    results.base = base;
    results.completed_parts = {'reader', 'preprocess'};

    if exist('main_double_wedge_part1', 'file') == 2 && ...
            exist('main_double_wedge_part2', 'file') == 2 && ...
            exist('main_double_wedge_part3', 'file') == 2 && ...
            exist('main_double_wedge_part4', 'file') == 2
        main_double_wedge_part1();
        main_double_wedge_part2();
        main_double_wedge_part3();
        main_double_wedge_part4();
        results.completed_parts = {'reader', 'preprocess', 'part1', 'part2', 'part3', 'part4'};
    end
end
