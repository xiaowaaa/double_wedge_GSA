# 双楔全局稳定性可验证内容汇总

Last updated: 2026-04-16

## 1. 目的

这份文档只做一件事:
把双楔全局稳定性程序里“可以拿文献直接对照”的内容整理成可执行清单。

重点分成四类:

1. 可对照的模态图片
2. 基本流工况与分离泡几何
3. 具体的特征值或增长率或频率
4. 特征值谱或分支拓扑

这里优先放一手论文里可以直接核对的 benchmark.
对于只能从图上估读的量, 文中会明确标成 `A`:

- `E`: 论文正文/表格/图注里直接给出的数值
- `A`: 只能从图或上下文推断得到, 只能当近似参考

## 2. 先看哪一层

建议永远按这个顺序验:

1. 先验 `base flow`
2. 再验 `leading mode` 的空间支撑区域
3. 再验增长率/频率/最危险波长
4. 最后验整张谱图或模态分支拓扑

不要先看一张模态云图就判定“算对了”.

另外, 当前仓库自带的 `270 x 128` 结果仍然只应当当作结构 benchmark, 不能当最终物理验收基准。

## 3. 当前仓库里这些量分别在哪

| 验证类别 | 当前仓库对应输出 |
| --- | --- |
| 基本流工况 | `Part1_Results.mat`, `Part2_Results.mat`, `BaseflowPhysicsAudit`, `GeometryAudit`, `BaseflowMasks`, `Part2Diagnostics` |
| 模态图片 | `Part4_Results.mat` 中的 `u_hat`, `v_hat`, `w_hat`, `T_hat`, `p_hat`, `rho_hat`; 参考图 `Fig18`, `Fig19`, `Fig22` |
| 特征值 | `EigVals_s`, `OmegaVals_s`, `freq_s`, `freq_signed_s`, `ranking_table`, `selection_summary`, `ModeSelectionAudit` |
| 特征值谱 | `Fig13_EigenvalueSpectrum.png` 和原始 `EigVals_s` |
| 波长扫描 | `run/run_sigma_shift_scan_v6.m` 适合做 shift 扫描; `beta`/波长扫描需要单独留表 |

如果后续要把文献对标做扎实, 每次正式 run 最好都输出一张统一表:

| case | Ma | Re | geometry | wall BC | beta / lambda_z | sigma / shift | leading eigenvalue | mode family | bubble overlap | shock overlap |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

## 4. 一览表

| 文献 | 最接近的工况 | 可直接对照的内容 | 适合拿来核的等级 |
| --- | --- | --- | --- |
| Sidharth et al. 2018, Phys. Rev. Fluids | Mach 5 slender double wedge, `12-20` / `12-22` | 模态图片, 分离/再附位置, 临界稳定性, 最危险波长, 谱分支 | 第一优先级 |
| Sawant et al. 2022, JFM | Mach 7 `30-55` double wedge, DSMC | bubble/shock 同步三维失稳, 增长率, 低频 `St`, 模态空间结构 | 第一优先级 |
| Hao et al. 2021, JFM | Mach 7.7 compression corner, 但含 double-wedge 稳定性汇总 | 稳定边界, scaled-angle 准则, 波长随参数变化 | 第二优先级 |
| Yang et al. 2007 / 2012 experiment | Mach 5 double ramp / double wedge experiment | 壁面温度条纹, 压力/热流足迹, 分离区位置 | 支持性实验基准 |
| Expósito et al. 2019, AST | double wedge mean heating computation | 平均热流/热峰/再附峰位置 | 支持性 base-flow 基准 |

## 5. Benchmark A: Sidharth et al. 2018

Source:
- [Onset of three-dimensionality in supersonic flow over a slender double wedge](https://doi.org/10.1103/PhysRevFluids.3.093901)

### 5.1 这篇最适合拿来核什么

- bifurcation 附近的主导三维 stationary 模态
- separation bubble 主导, 而不是 shock-core 孤立假模态
- `12-20` 和 `12-22` 这两类 slender double wedge 的谱分支结构
- 墙温条纹和模态波长的一致性

### 5.2 可直接对照的基本流量

- `E` Mach number: `Mach 5`
- `E` 参考实验几何: `12°-22° double wedge`
- `E` bifurcation 后用于主分析的失稳几何: `12°-20° double wedge`
- `E` 分离位置: 边界层在铰点上游 `12.15 mm` 处分离
- `E` 再附位置: 分离剪切层在铰点下游 `11.4 mm` 再附
- `E` 分离处边界层厚度: `delta_99 = 1 mm`
- `E` 墙面: `adiabatic wall`

这些量主要见论文 Fig. 3, Fig. 17-19 及正文说明。

### 5.3 可直接对照的模态图片

- `E` 临界附近最不稳定模态是三维 `stationary` 模态, 主支撑在 separation bubble 和 reattached boundary layer
- `E` bifurcation 模态里, `w'` 主要局限在 separation bubble
- `E` 温度扰动条纹出现在 corner 下游, 并延伸到第二段楔面
- `E` 压力扰动沿流向的周期大约等于 separation bubble 长度
- `E` `u'` 和 `v'` 在 spanwise 上同相
- `E` wave-maker 位于 separation bubble core, 不在 separation / reattachment 两端的离心不稳定区域
- `E` 在 `theta = 10°` 的 `12-22` 情形下:
  - 最不稳定 stationary 分支 `B2` 的 `w'` 集中在 bubble core 且略偏 corner 下游
  - 分支 `B1` 的 `w'` 则铺满整个 separation bubble
  - 这两种空间结构应当能从你自己的 `w_hat` 图里直接区分

你自己的结果如果出现:

- 主模态只是一团远离 bubble 的上层紧凑包
- 或者几乎完全贴 shock band, 对 bubble overlap 很弱

那它更像可疑数值模态, 而不像这篇文献里的物理主导模态。

### 5.4 可直接对照的特征值/波长

- `E` 在 bifurcation 附近, `theta = 7.5°` 时 flow remains two-dimensional
- `E` 在 bifurcation 附近, `theta = 8.0°` 时 flow becomes three-dimensional
- `E` 临界附近最不稳定模态是 non-oscillatory
- `E` 论文在最危险波长处给出的谱图对应 `lambda_z ~ 6.28`
- `E` DNS 表 1 给出的 spanwise cases:
  - `theta = 8.0°`, `Lz = 14 mm`, `Lz / lambda_z = 2`
  - `theta = 7.5°`, `Lz = 14 mm`, `Lz / lambda_z = 2`
  - `theta = 8.0°`, `Lz = 28 mm`, `Lz / lambda_z = 4`
- `A` 由上面几项综合看, 临界附近最危险波长约在 `6.3-7.0 mm` 量级
- `E` 对 `theta = 10°`, 最危险波长图注给出 `lambda_z / L ~ 2.3`
- `A` 由于前文 `L = 1 mm`, 可把该最危险波长近似理解为 `lambda_z ~ 2.3 mm`
- `E` `theta = 10°` 下 oscillatory 分支 `B5` 有固定 nondimensional angular frequency `omega_r = 0.1`

### 5.5 可直接对照的谱图/分支拓扑

- `E` bifurcation 谱图见 Fig. 5:
  - `theta = 7.5°` 和 `8°` 只差一个很小角度时, 最不稳定 stationary 分支跨过 `omega_i = 0`
- `E` `theta = 10°` 谱图见 Fig. 17 和 Fig. 20:
  - 不再是单一 stationary branch
  - 会出现多组 unstable branches
  - 最不稳定模态仍是 stationary, 但已不是 `theta = 8°` 的同一空间结构
  - 除 stationary 分支外, 还有 oscillatory `B4` / `B5`
  - `B4` 可理解为在两组 stationary instability 之间“振荡”

### 5.6 这篇文献对应你程序里该导出的最低集

- `Baseflow`: separation point, reattachment point, bubble length, `delta_99`
- `Eigen`: 至少前 `20-50` 个 eigenvalues
- `Branch`: 每个 branch 的 `stationary / oscillatory` 标签
- `Mode fields`: `u_hat`, `v_hat`, `w_hat`, `T_hat`, `p_hat`
- `Wall footprint`: 壁面 `T'` 或 heat-flux-like footprint 的 spanwise wavelength

### 5.7 最适合拿来做的对标结论

- 如果你的 `theta` 扫描在 `7.5°` 稳定而在 `8°` 左右失稳, 方向是对的
- 如果主导模态在 bubble core 附近启动并能解释 reattachment 下游的 wall-temperature streaks, 性质上是对的
- 如果 `theta = 10°` 还能看见 stationary + oscillatory branches 共存, 谱拓扑更接近文献

## 6. Benchmark B: Sawant et al. 2022

Source:
- [On the synchronisation of three-dimensional shock layer and laminar separation bubble instabilities in hypersonic flow over a double wedge](https://doi.org/10.1017/jfm.2022.276)

### 6.1 这篇最适合拿来核什么

- `30-55` 双楔下 bubble 与 shock-layer 的同步三维失稳
- rarefied / DSMC 条件下的增长率与低频 unsteadiness
- shock-layer 里是否真的存在与 bubble 同步的 spanwise structures

### 6.2 可直接对照的基本流工况

- `E` geometry: `30°-55° double wedge`
- `E` gas: nitrogen
- `E` `Ma = 7.02`
- `E` `Re = 5.22 x 10^4 m^-1`
- `E` `Kn = 3.2 x 10^-3`
- `E` `u_x,1 = 3812 m/s`
- `E` `T_tr,1 = 710 K`
- `E` `T_s = 298.5 K`
- `E` separation-bubble length `L_s = 40 mm`
- `E` 用于 nondimensional growth-rate 的 `delta_99 = 3.35 mm`
- `E` 前缘斜激波后速度 `u_x,2 = 2930.8 m/s`

### 6.3 可直接对照的模态图片

- `E` bubble 内存在 stationary growing LSB instability
- `E` bubble 外包络大约在 `H_l ~ 0.15 L_y`
- `E` separation shock layer 内也有同步的 spanwise-periodic structures
- `E` 这些 shock-layer 结构位于 `0.36 < H_l / L_y < 0.44`
- `E` bubble 内和 separation shock 内的结构同相, 且 spanwise-periodicity length 相同
- `E` detached shock layer 内也有结构, 但振幅更弱
- `E` detached shock 中的结构相对 separation shock 为 `180°` out of phase
- `E` reattached boundary layer 中仍可见 spanwise-periodic structures
- `E` 结论上, 全局模态集中在 separation shock / detached shock / bubble 相互作用区, 但最强耦合发生在 separation shock 与 LSB 之间

如果你的高马赫双楔结果里:

- bubble 内几乎没有结构
- shock-layer 独自很强而与 bubble 不同步
- 或 separation shock 与 detached shock 的相位关系完全混乱

那就很难说和这篇文献一致。

### 6.4 可直接对照的增长率/频率

- `E` 所有 probe 的平均线性增长率: `Omega_i = 5.0 kHz`
- `E` 标准差约 `6.7%`
- `E` 论文把它换成无量纲后得到 `Omega_i = 0.0057`
- `E` triple point 低频 oscillation 的平均周期约 `46 T`
- `E` 由此得到 `St = 0.0283 +/- 0.003`
- `E` 文中还给出两个具体周期 `51 T` 和 `41 T`

### 6.5 这篇文献能不能拿来核特征值谱

可以, 但方式不同。

这篇不是传统线性 EVP 的完整谱图 benchmark, 更像:

- `temporal growth benchmark`
- `low-frequency unsteadiness benchmark`
- `shock/bubble synchronisation benchmark`

所以它更适合核:

- 你提取的增长率
- 你算出的低频 `St`
- 你模态在 bubble 和 shock-layer 的相对支撑区域

而不适合拿来逐点对照一整张 `sigma` 谱。

### 6.6 这篇文献对应你程序里该额外输出什么

- bubble 区与 shock 区分区能量
- bubble / separation-shock / detached-shock 三块区域的 overlap
- 主模态相位关系
- 如果做时推进, 需要一张 probe-signal growth table

## 7. Benchmark C: Hao et al. 2021

Source:
- [Occurrence of global instability in hypersonic compression corner flow](https://doi.org/10.1017/jfm.2021.372)

### 7.1 这篇为什么仍然值得保留

它不是双楔, 但给了非常有用的“稳定边界 sanity check”.
尤其适合你在真实工况还没完全对上的时候, 先判断自己的结果是不是远离已知 instability window.

### 7.2 可直接对照的工况和数值

- `E` compression-corner case: `M_inf = 7.7`
- `E` `Re_inf = 4.2 x 10^6 m^-1`
- `E` flat-plate length `L = 100 mm`
- `E` 墙温比考虑 `T_w / T_0 = 0.18`, `0.54`, `0.86`
- `E` 对 `T_w / T_0 = 0.18`, 在 `alpha = 13°` 时出现 global instability
- `E` 该点最不稳定波长为 `lambda / L = 0.168`
- `E` scaled-angle instability criterion: `3.44 < alpha* < 4.59`
- `E` 文中对双楔文献的归纳:
  - Mach 5 double wedge 在 turn angle `7.8°` 时 marginally stable
  - 在 `10°` 时 unstable

### 7.3 这篇更适合拿来做什么

- 把你自己的几何/来流先折算成 `scaled angle`
- 看它是否已经落入已知 instability window
- 判断“明明 scaled angle 还很低, 却报出一堆强失稳”是不是值得先怀疑数值污染

## 8. 支持性实验与 base-flow 文献

下面这些更适合拿来核 `base flow`, 壁面足迹和热流峰, 不适合直接核特征值:

- Yang et al. 2007, AIAA 2007-118
  - `12-22` double wedge 的 temperature-sensitive paint / pressure-sensitive paint 实验
  - 适合核 wall-temperature streaks 的 spanwise spacing 与起始位置
- Yang et al. 2012, *Experimental Thermal and Fluid Science*
  - [Investigation of the double ramp in hypersonic flow using luminescent measurement systems](https://doi.org/10.1016/j.expthermflusci.2012.01.032)
  - 适合核 surface pressure / temperature footprint 和分离区变化
- Expósito et al. 2019, *Aerospace Science and Technology*
  - [Computational investigations into heat transfer over a double wedge in hypersonic flows](https://doi.org/10.1016/j.ast.2019.07.013)
  - 适合核 mean heating / reattachment heat peak

## 9. 真正落地时, 你至少要导出这四张对照表

### 9.1 基本流表

| quantity | your run | literature | note |
| --- | --- | --- | --- |
| geometry |  |  |  |
| Ma |  |  |  |
| Re |  |  |  |
| wall BC / Tw |  |  |  |
| separation location |  |  |  |
| reattachment location |  |  |  |
| bubble length |  |  |  |
| delta_99 at separation |  |  |  |

### 9.2 模态性质表

| mode id | stationary / oscillatory | bubble-core support | shock support | near-wall support | comment |
| --- | --- | --- | --- | --- | --- |

### 9.3 特征值表

| mode id | sigma_r / omega_i | sigma_i / omega_r | beta or lambda_z | source benchmark | exactness |
| --- | --- | --- | --- | --- | --- |

### 9.4 谱图说明表

| figure | what to compare | pass signal | reject signal |
| --- | --- | --- | --- |
| eigenspectrum | least-stable branch topology | stationary branch crosses stability boundary where expected | isolated compact branch dominates with weak bubble support |
| wavelength scan | peak wavelength | most unstable wavelength near literature value | peak drifts violently under minor numerics changes |
| mode image | support region | bubble-core and reattached-BL consistent with literature | upper-layer compact packet or shock-only packet |

## 10. 一条最实用的判断线

如果你的结果同时满足下面几条, 才更接近“文献支持下的可信结果”:

- 基本流的分离/再附位置先大体对上
- 主导模态首先落在 separation bubble, 而不是孤立 shock packet
- 最危险波长和文献同量级
- stationary / oscillatory 分支的基本拓扑与文献一致
- 小改网格、边界、shift、弱滤波后, 主导分支不会乱跳

反过来, 如果出现下面这些信号, 应先怀疑数值问题:

- 模态只贴 shock band, 对 bubble overlap 很弱
- 主模态位置随 `sigma shift` 或轻微 regularization 大幅漂移
- 图上看起来很“干净”, 但 raw eigenvalues 没有形成文献里的分支结构
- `beta != 0` 后突然只剩局部高频小包, 且无文献可支持

## 11. 当前最值得优先复现的对标顺序

1. 先复现 `Sidharth 2018` 的性质:
   `stationary`, `bubble-core`, `wall-temperature streak`
2. 再用 `Sawant 2022` 检查高马赫下的 shock/bubble 同步结构和低频 `St`
3. 最后用 `Hao 2021` 的 scaled-angle 思路检查你的真实工况是否落在合理 instability window

## 12. 参考文献

- Sidharth, G.S., Dwivedi, A., Candler, G.V. & Nichols, J.W. 2018. *Onset of three-dimensionality in supersonic flow over a slender double wedge*. Phys. Rev. Fluids 3, 093901. [DOI](https://doi.org/10.1103/PhysRevFluids.3.093901)
- Sawant, S.S., Theofilis, V. & Levin, D.A. 2022. *On the synchronisation of three-dimensional shock layer and laminar separation bubble instabilities in hypersonic flow over a double wedge*. J. Fluid Mech. 941, A7. [DOI](https://doi.org/10.1017/jfm.2022.276)
- Hao, J., Cao, S., Wen, C.-Y. & Olivier, H. 2021. *Occurrence of global instability in hypersonic compression corner flow*. J. Fluid Mech. 919, A4. [DOI](https://doi.org/10.1017/jfm.2021.372)
- Yang, L., Zare-Behtash, H., Erdem, E. & Kontis, K. 2012. *Investigation of the double ramp in hypersonic flow using luminescent measurement systems*. Exp. Therm. Fluid Sci. 40, 50-56. [DOI](https://doi.org/10.1016/j.expthermflusci.2012.01.032)
- Expósito, A., Collado Morata, E., Rana, Z.A. & Morgans, A.S. 2019. *Computational investigations into heat transfer over a double wedge in hypersonic flows*. Aerosp. Sci. Technol. 92, 839-846. [DOI](https://doi.org/10.1016/j.ast.2019.07.013)
