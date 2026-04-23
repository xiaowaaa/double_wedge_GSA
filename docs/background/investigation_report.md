# Double-Wedge Stability Investigation Report

Date: 2026-04-14  
Scope: Round 1 audit only. No solver/source patch applied in this round.

## Audit Method

- Static audit of the production chain:
  `Main_DoubleWedge_Part1_v6.m -> Main_DoubleWedge_Part2_v6.m -> Main_DoubleWedge_Part3_v6.m -> Main_DoubleWedge_Part4_v6.m`
- Targeted reads of the high-risk helpers in `src/core`
- Minimal MATLAB experiments on:
  - state layout / permutation / reshape consistency
  - shock dilation behavior
  - bundled structural benchmark artifacts under `outputs/mat/paperA_validation_270x128_v6/`
- Retained test subset execution:
  `run/run_phase2_validation.m`

## 1. 项目结构与数据流总结

### 1.1 Part1 -> Part4 的职责与 MAT 语义

| Part | 主要输入 | 主要输出 | 关键语义 |
| --- | --- | --- | --- |
| `Main_DoubleWedge_Part1_v6.m` | baseflow 文件、stride、ExpectedDims、物理参数 | `Part1_Results.mat` | 读取 baseflow，预处理热力学量，构建 `Config`，保存 `X/Y/U/V/W/TT/RHO/PP/MU/dMU_dT/d2MU_dT2/BaseValidation/Nx/Ny` |
| `Main_DoubleWedge_Part2_v6.m` | `Part1_Results.mat` | `Part2_Results.mat` | 计算 `Metrics/ops/dX`，构建 `BoundaryMasks/BoundaryInfo`，生成 `BaseflowPhysicsAudit/GeometryAudit/BaseflowMasks` |
| `Main_DoubleWedge_Part3_v6.m` | `Part2_Results.mat` | `Part3_Results.mat` | 用 primitive-five 组装 `LNS_L q = lambda * LNS_Gam q`，应用 shock clipping / SAV / BC rows，保存 `LNS_L/LNS_Gam/OperatorHealth/ShockInfo/SavInfo` |
| `Main_DoubleWedge_Part4_v6.m` | `Part3_Results.mat` | `Part4_Results.mat` | 求解 descriptor EVP，排序、筛选、选默认绘图模态、相位对齐、保存绘图用主模态和排序表 |

### 1.2 MAT 文件字段链路

实际检查了保留 benchmark `outputs/mat/paperA_validation_270x128_v6/Part1_Results.mat` 到 `Part4_Results.mat`。

- `Part1_Results.mat`
  - `Config`, `X`, `Y`, `U`, `V`, `W`, `TT`, `RHO`, `PP`, `MU`, `dMU_dT`, `d2MU_dT2`, `BaseValidation`, `Nx`, `Ny`
- `Part2_Results.mat`
  - 在 Part1 基础上新增 `Metrics`, `ops`, `dX`, `BoundaryMasks`, `BoundaryInfo`, `Part2Diagnostics`, `BaseflowPhysicsAudit`, `GeometryAudit`, `BaseflowMasks`
- `Part3_Results.mat`
  - 在 Part2 基础上新增 `LNS_L`, `LNS_Gam`, `Ndof`, `ShockInfo`, `SavInfo`, `OperatorHealth`, `BCRowAudit`, `DerivativeClipInfo`, `sigma_sp`
- `Part4_Results.mat`
  - 在 Part3 基础上新增 `EigVals_s`, `EigVecs_s`, `res_s`, `res_active_s`, `res_algebraic_s`, `res_scaled_s`, `freq_s`, `freq_signed_s`, `OmegaVals_s`, `ranking_table`, `selection_summary`, `ModeSelectionAudit`, `mode_validity_report`, `lambda_max`, `u_hat/v_hat/w_hat/T_hat/p_hat/rho_hat`

### 1.3 网格、reshape、线性索引、状态布局

当前代码的默认语义是清楚的，而且我做了最小实验验证：

- 二维标量场线性化采用 MATLAB 列主序：`field(:)`
- `Part2` 的导数回写采用：
  `reshape(op * data_field(:), Ny, Nx)`  
  位置：`Main_DoubleWedge_Part2_v6.m:97-101`
- `Part3` 先按 block ordering 组装五块变量：
  `[u(all nodes); v(all nodes); w(all nodes); T(all nodes); p(all nodes)]`  
  位置：`Main_DoubleWedge_Part3_v6.m:142-153`
- 随后用 `P = local_block_to_interleaved_permutation(N,5)` 变为 node-interleaved ordering：
  `[u1 v1 w1 T1 p1 u2 v2 w2 T2 p2 ...]`  
  位置：`Main_DoubleWedge_Part3_v6.m:155-157`, `323-337`
- `extract_state_component` 也是按 interleaved 语义提取：
  `q_mode(comp_idx:info.nvar:end)`  
  位置：`src/core/extract_state_component.m:24`
- 状态布局常量是：
  `primitive5_u_v_w_T_p`，单节点变量顺序明确为 `u, v, w, T, p`  
  位置：`src/core/get_state_layout_info.m:8-12`

### 1.4 本轮已确认一致、暂时不是最高优先级的问题

以下几项已经做了最小验证，当前没有看到明显错位：

- `Dx/Dy` 与 `reshape(field(:),Ny,Nx)` 的方向一致
  - 自定义脚本验证：`reshape(ops.Dx*F(:),Ny,Nx)` 与 `fd4_uniform(F,2,1)` 匹配到 `1e-14`
- block -> interleaved permutation 与 `extract_state_component` 一致
  - 自定义脚本验证：`permutation_extract_consistent = 1`
- BC 替换后的代数行数与边界点数一致
  - benchmark 上 `gamma_zero_rows = 3960 = 792 boundary points * 5 vars`
- 频率符号约定本身内部一致
  - `interpret_sigma_eigenvalues.m:14-18`
  - `tests/test_sigma_frequency_convention.m` 通过

结论：本轮更像是“上游 mask/regularization + 下游选模/解释”在系统性污染结果，而不是最基础的 reshape 或 permutation 完全错了。

## 2. 前 8 个最可疑点的初始排序

### 1. Shock dilation 使用 `circshift` 造成边界 wrap-around

- 位置
  - `Main_DoubleWedge_Part3_v6.m:425-433`, `510-515`
  - `src/core/build_shock_localized_sav_matrix.m:42-50`
- 问题机制
  - `circshift` 会把上边界扩到下边界、左边界扩到右边界
  - 这不是正常的几何膨胀，而是拓扑环绕
- 为什么会导致错误结果
  - 被污染的 `shock_mask` 会继续进入：
    - `local_clip_baseflow_derivatives(...)`
    - `suppress_viscosity_gradient_terms_in_shock`
    - shock-localized SAV 行选择
  - 相当于把不该 regularize 的区域也当成 shock band
- 已有证据
  - 合成实验：`part3_top_seed_bottom_wrap=1`, `part3_left_seed_right_wrap=1`, `sav_left_seed_right_wrap=1`
  - 保留 benchmark 上：
    - `ShockInfo.shock_raw` 边界计数：`top=0, bottom=257, left=0, right=8`
    - `ShockInfo.shock_mask` 边界计数：`top=265, bottom=0, left=10, right=11`
  - 这说明底部 shock 在 dilation 后真实污染到了顶部
- 影响类型
  - 高危静默错误
  - 既会改数值稳定性，也会改物理主模态形态
- 置信度
  - 高
- 最小验证方法
  - 把 `local_dilate_mask` 改成无 wrap 的显式邻域扩张后，比较 `ShockInfo.shock_mask` 边界计数和主特征值漂移

### 2. Part4 会在没有物理解候选时，回退到 debug-only 模态照样绘图

- 位置
  - `src/core/rank_paperA_modes.m:57-67`, `69-116`, `190-205`
  - `src/core/select_paperA_plot_lead_index.m:10-45`
- 问题机制
  - `plot_candidate_mask` 只硬约束 residual/checker
  - 如果 `physical_plot_mask` 为空，则 `selected_for_plots` 直接回退到前 4 个排序模态
- 为什么会导致错误结果
  - 代码可以“正常完成”，但默认输出的主模态其实是明确不满足物理筛选的 debug 模态
- 已有证据
  - 保留 benchmark `selection_summary`：
    - `status = residual_checker_modes`
    - `num_physical_plot_candidates = 0`
    - `num_selected_modes = 4`
    - `publication_allowed = 0`
    - `primary_reason = bubble_support_too_low`
  - 前 4 个 selected-for-plots 模态的 `shock_energy_frac` 约 `0.57 ~ 0.75`
- 影响类型
  - 直接导致“能跑，但主模态/图像/物理解读错”
- 置信度
  - 高
- 最小验证方法
  - 强制 `selected_for_plots = physical_plot_mask(order)`，若为空则 fail hard，不再 fallback；比较默认图和 `lambda_max`

### 3. `selection_summary.leading_mode_index`、`plot_leading_mode_index`、`lambda_max` 语义错位

- 位置
  - `Main_DoubleWedge_Part4_v6.m:44-49`
  - `Main_DoubleWedge_Part4_v6.m:75-86`
  - `Main_DoubleWedge_Part4_v6.m:117-138`
- 问题机制
  - `selection_summary.leading_mode_index = ranking.original_mode_index(1)` 表示排序第一
  - 但 `lambda_max`, `St_max`, `u_hat/v_hat/...` 用的是 `plot_leading_mode_index`
- 为什么会导致错误结果
  - 下游如果把 `selection_summary.leading_mode_index` 和 `lambda_max` 当同一个模态，会静默读错对象
- 已有证据
  - 保留 benchmark：
    - `selection.leading_mode_index = 10`
    - `selection.plot_leading_mode_index = 13`
    - `selection.plot_leading_mode_position = 2`
    - `lambda_max = EigVals_s(plot_leading_mode_index)`
    - `EigVals_s(1) != lambda_max`
- 影响类型
  - MAT 语义错误 / 后处理解释错误
- 置信度
  - 高
- 最小验证方法
  - 在 `Part4_Results.mat` 里同时保存 `lambda_sorted_1` 与 `lambda_plotted`，核对调用端到底消费哪一个

### 4. “bubble overlap” 实际用的是大幅扩张后的 `bubble_support_mask`，不是 core bubble

- 位置
  - `src/core/build_paperA_baseflow_context.m:33-36`, `67-76`, `129-152`
  - `src/core/build_paperA_mode_masks.m:6-18`
- 问题机制
  - `masks.bubble` 优先拿 `bubble_support_mask`
  - `bubble_support_mask` 会在 `x` 方向向下游扩到 `+0.55*bubble_len`，在 `y` 方向抬高到 `bubble_top + max(0.75*bubble_h, 0.04*Ly)`
- 为什么会导致错误结果
  - 许多“靠近剪切层/下游/较高 y”的模态会被记成 bubble-supported
  - 排序与相位锚定都会受影响
- 已有证据
  - 保留 benchmark 上：
    - `bubble_core_points = 360`
    - `bubble_support_points = 10060`
    - `support/core ratio = 27.94`
    - core extent: `[30.49, 44.82] x [17.60, 26.60]`
    - support extent: `[21.47, 58.38] x [12.46, 45.98]`
- 影响类型
  - 模态排序偏移 / 相位对齐锚点偏移 / 物理解读偏宽松
- 置信度
  - 高
- 最小验证方法
  - 在同一批 eigenpairs 上并行计算 `bubble_core_overlap` 与 `bubble_support_overlap`，比较主模态排序是否重排

### 5. `continuity_residual_max` 命名和物理意义不一致

- 位置
  - `Main_DoubleWedge_Part2_v6.m:53`, `61-70`, `132-151`
  - `src/core/build_paperA_baseflow_context.m:38-52`
- 问题机制
  - 当前定义只是 `dX.div = ux + vy`
  - 没有 `rho` 输运项，也没有 `beta*w` 项，更不是完整可压缩 continuity residual
- 为什么会导致错误结果
  - `Part2` 里它被命名成 `continuity_residual_max`
  - 对真实 `812x382` 物理案例还作为 hard gate 使用
  - 容易误筛掉好 baseflow，或误放过坏 baseflow
- 已有证据
  - 定义位置明确，且变量名与物理意义不一致
- 影响类型
  - 上游审计误判 / 误导排障方向
- 置信度
  - 高
- 最小验证方法
  - 另存一个 `velocity_divergence_max`，并独立计算真正的线性化 continuity / steady mass residual，再对比门槛行为

### 6. Part3 的 pressure block / mass block 闭合方式值得重点怀疑

- 位置
  - `Main_DoubleWedge_Part3_v6.m:84-88`, `117-153`
- 问题机制
  - `pressure_scale = 1/a0^2`
  - `G5 = D(pressure_scale)`
  - `LPu/LPv/LPw/LPP` 构成 pressure evolution block
  - 但 `LPT = Z`
- 为什么会导致错误结果
  - 如果这套 primitive-five 写法要和 `rho' = p'/(R T0) - rho0*T'/T0`、energy equation、自变量选择完全自洽，则 pressure closure 的推导必须非常明确
  - 当前实现看起来更像某种 pressure-evolution closure，而不是显式 continuity + EOS 的直接展开
  - 这未必一定错，但它是 Part3 数学层面最值得下一轮推导核对的块
- 当前证据性质
  - 这是“高风险数学/建模红旗”，不是已实证 bug
- 影响类型
  - 若推导有偏差，会系统性偏移整个本征谱
- 置信度
  - 中
- 最小验证方法
  - 对照手推线性化，把 pressure row 与 `G_block(5,5)` 逐项核对，特别核查 `LPT=0` 是否合理

### 7. mode ranking 使用的 support field 是明显的 `u`-dominant 指标

- 位置
  - `src/core/compute_mode_filter_metrics.m:79-115`
  - `src/core/compute_mode_filter_metrics.m:119-145`
- 问题机制
  - 只要 `u` 分量非零，`support_field = RHO .* abs(u).^2`
  - `v/w/T/p` 只有在 `u` 基本全零时才进入 fallback
- 为什么会导致错误结果
  - 对于真实压缩模态，热/压力/法向速度主导而 `u` 不占优的情形，会被系统性低估
  - `bubble_overlap`, `shock_energy_frac`, `near_wall_energy_frac`, `u_peak_in_bubble` 全部随之偏移
- 已有证据
  - 代码实现非常明确
  - 现有测试 `tests/test_mode_filter_metrics.m` 只覆盖了“bubble u-mode vs checkerboard”，没有覆盖非 `u` 主导模态
- 影响类型
  - 模态排序偏差
- 置信度
  - 中
- 最小验证方法
  - 构造同一空间分布、但能量主导分量分别是 `u`、`v`、`T`、`p` 的合成模态，比较 ranking metrics 是否发生不合理重排

### 8. `eos_relative_error` 采用 pointwise max，易被少量坏点支配

- 位置
  - `src/core/preprocess_baseflow.m:13-25`
  - `Main_DoubleWedge_Part2_v6.m:139-145`
- 问题机制
  - `eos_rel = abs(p - R*rho*T) ./ max(abs(p), eps)`
  - 最终只取 `max(eos_rel(:))`
- 为什么会导致错误结果
  - 对真实导入数据，只要有极少数异常点，就会把整场打成 fail
  - 这更像导入审计指标设计过于激进，而不是稳定性求解本身的物理判据
- 已有证据
  - 代码定义明确
  - 当前 runner 里已经专门补了 `run_baseflow_import_audit_v6(...)`，也说明原先单一 `max` 指标信息量不足
- 影响类型
  - 上游物理 baseflow 审核误判
- 置信度
  - 中高
- 最小验证方法
  - 同时保存 `median/p95/max` 和压力比统计，再看 hard gate 是否仍然合理

## 3. 关键证据摘要

### 3.1 这不是一个“基础 reshape 完全错了”的问题

- 自定义实验确认：
  - `reshape(ops.Dx * F(:), Ny, Nx)` 与 `fd4_uniform(F,2,1)` 一致
  - `reshape(ops.Dy * F(:), Ny, Nx)` 与 `fd4_uniform(F,1,1)` 一致
- 自定义实验确认：
  - `local_block_to_interleaved_permutation` 与 `extract_state_component` 一致

结论：当前更像高层逻辑污染，而不是最底层方向错了。

### 3.2 这也不是一个“矩阵健康指标明显报警”的问题

在保留 benchmark 的 `Part3_Results.mat` 上：

- `zero_rows = 0`
- `zero_cols = 0`
- `active_rows = 168840 / 172800`
- `row_ratio_before = 1.35978e5`
- `shock_to_nonshock_row_ratio = 0.105341`

但同一 benchmark 的 `Part4_Results.mat` 却能出现：

- `publication_allowed = 0`
- 默认绘图主模态 `shock_energy_frac` 很高

结论：当前健康度指标不足以暴露“谱已被污染但矩阵仍看起来健康”的情况。

### 3.3 保留测试集通过，不代表当前主问题被覆盖

2026-04-14 实际执行：

- `run_phase2_validation` 通过
  - 除 `test_matrix_sizes` 因缺少指定 MAT 文件而 `SKIP`
  - 其余保留测试 `PASS`

但当前测试没有覆盖：

- `local_dilate_mask` 的 wrap-around
- `physical_plot_mask` 为空时的 fallback 绘图策略
- `selection_summary.leading_mode_index` 与 `lambda_max` 的语义错位
- `bubble_support_mask` 对 `bubble_overlap` 的放大效应

## 4. 当前最强判断

第一轮审计下，最可能的错误链路不是单点 bug，而是下面这条叠加链：

1. `ShockInfo.shock_mask` 因 `circshift` wrap-around 被污染  
2. shock 区域 derivative clipping / viscosity-gradient suppression / SAV 行选择跟着污染  
3. Part3 算子局部结构被不该 regularize 的区域改写  
4. Part4 没有找到真正“publication-ready”的物理解模态  
5. 代码却仍 fallback 选出 debug-only 模态作默认图  
6. `lambda_max` / `u_hat` / `selection_summary.leading_mode_index` 语义又不是同一个模态  
7. 最终表现为“程序跑通，但主导特征值/频率/模态图/排序解释不可信”

这条链路目前比“基础导数错了”或“permutation 完全错了”更有证据支撑。

## 5. 下一轮最值得做的最小验证

1. 把 `local_dilate_mask` 临时替换成无 wrap 版本，只比较：
   - `ShockInfo.shock_mask` 边界计数
   - `selection_summary`
   - `lambda_max`
2. 禁用 plot fallback，只允许 `physical_plot_mask`
   - 若为空则 fail hard
   - 观察当前 benchmark 是否直接暴露“没有可发表物理解模态”
3. 并行保存 `bubble_core_overlap` 与 `bubble_support_overlap`
   - 看前 10 个排序是否重排
4. 在 `Part4_Results.mat` 中同时保存：
   - `lambda_sorted_1`
   - `lambda_plotted`
   - `leading_sorted_mode_index`
   - `leading_plotted_mode_index`
5. 对 pressure row 做逐项手推核对
   - 尤其是 `LPT = 0` 和 `G5 = 1/a0^2` 的闭合理由

## 6. 本轮结论

- 当前最高优先级不是“大改求解器”，而是先拆掉两个最强静默污染源：
  - shock dilation wrap-around
  - debug-mode fallback 被当成默认主模态输出
- 在这两个问题没被隔离之前，继续拿当前默认 `lambda_max`、主模态图和排序表做物理解读，风险很高。
- 第二轮如果进入补丁阶段，应该优先做局部、可回滚、可验证的小修：
  - 先修 `local_dilate_mask`
  - 再把 plotting fallback 改成显式 fail/debug 标记
  - 然后再检查 Part3 pressure/energy closure
