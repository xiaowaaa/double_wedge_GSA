# 812x382 Real-Case Wrong-Mode Follow-Up Prompt

You are my senior MATLAB stability-solver refactoring engineer. Work directly in the current repository and make code changes, but keep the external workflow and main script chain compatible.

Background:
- The final physical target case is still the double-wedge `812 x 382` case.
- A user-provided screenshot review on 2026-04-09 shows that the currently selected unstable mode has `sigma_r ~= +2.098e-01` and `St ~= 0.0664`.
- The mode shape is not the desired separation-bubble global mode. Its strongest support is a compact, smooth, isolated packet near `x ~= 56 to 60`, `y ~= 46 to 50`, above the downstream wedge segment.
- Do not focus the investigation on downsampling. Treat downsampling only as background context, not as the primary explanation.
- The current likely failure is that mode ranking is too permissive for smooth localized interior pseudo-modes.

Goals:
1. Improve mode-selection credibility without rewriting the solver architecture.
2. Keep the current production path usable.
3. Reject or heavily demote compact upper-layer pseudo-modes that do not overlap the main separation bubble.
4. Preserve physically plausible bubble-dominated modes.

Preferred implementation focus:
- `src/core/compute_mode_diagnostics.m`
- `src/core/rank_mode_candidates.m`
- Any directly related plotting or report helper needed to expose the new diagnostics

What to add:
- A bubble-overlap or bubble-energy-fraction metric
- A compact-support penalty based on connected support area, footprint size, or similar robust indicator
- An upper-layer or shock-band penalty so modes concentrated away from the separation bubble are demoted
- Saved diagnostics in the mode reports so the next run can explain why a mode was selected or rejected

Constraints:
- Do not do a large architecture rewrite
- Do not change unrelated numerical paths
- Keep comments concise and professional
- Update any affected docs and validation entry points

Acceptance standard:
- The repository should make it much harder for the `sigma_r ~= +2.098e-01`, `St ~= 0.0664` type of compact interior mode to rank as the preferred physical mode.
- The new diagnostics should be inspectable from saved results or logs.
- Run the relevant validation, smoke tests, and report what passed, skipped, or remains risky.
