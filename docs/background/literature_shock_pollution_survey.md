# 仓库文献中“激波污染 / shock-dominated mode”处理方式调查

日期：2026-04-14

## 1. 调查范围

本次调查覆盖仓库 `paper/` 下全部文献：

- `paper/A.pdf`
- `paper/B.pdf`
- `paper/H.pdf`
- `paper/Hildebrand_umn_0130E_20139.pdf`
- `paper/M.pdf`
- `paper/S.pdf`
- `paper/V.pdf`
- `paper/notes/README_任务收获与后续改造依据.md`
- `paper/notes/二维可压缩圆柱绕流_你的方法_vs_文献A_B_详细对比.md`

其中：

- `A/B/H/M/V` 可直接提取文本。
- `S.pdf` 是图片型 PDF，本次通过本机 `tesseract` 做了 OCR 抽取关键页。
- 两份 `paper/notes/*.md` 更像仓库内部读书笔记，不作为原始文献证据，只作为辅助整理。

## 2. 先给结论

仓库文献里对“激波污染”并没有一种完全统一的单招，但有非常清晰的共同思路：

1. 把“边界反射问题”和“激波附近离散伪模态问题”分开处理。  
   `sponge layer` 主要负责外边界非反射，不负责清理 shock-core 假模态。

2. 如果稳定性算子采用 centered finite difference，一般会加很弱的、尺度选择性的人工耗散或滤波，只针对最短可分辨波长。  
   文献里最接近当前代码路线的是 Hildebrand 系列的 fourth-derivative filter，强度量级约 `1e-2`，而且反复强调要做敏感性分析，确保“不改变物理模态，只压最脏的最小尺度数值模态”。

3. 如果采用 finite-volume Jacobian 路线，往往不直接在扰动方程上再叠加一个很重的 shock-band 修补；更多是依赖底层 shock sensor / flux splitting / central-in-smooth + upwind-near-discontinuity 的离散方式来控制 discontinuity 附近的数值污染。

4. 文献都会检查 sponge/filter 的“无害性”：
   - sponge 不能侵入 recirculation bubble / separation bubble
   - filter 强度不能改变感兴趣本征模态
   - 需要做参数敏感性或网格独立性验证

5. 没有哪篇文献支持“先默认接受一个 shock-heavy mode 当主导模态，再靠后处理解释它”。  
   相反，文献默认做法是先保证数值处理对物理模态足够温和，再讨论模态物理意义。

## 3. 分文献结果

### 3.1 `A.pdf`：JFM 2024，supersonic backward-facing step

最相关位置：

- `paper/A.pdf` 第 5 页
- `paper/A.pdf` 第 6 页

文献明确写了 4 件事：

1. 稳定性方程采用 primitive five：
   `q=[u,v,w,T,p]^T`

2. GSA 离散采用：
   - interior: centered fourth-order finite difference
   - boundary: third-order finite difference

3. 基流里有激波时，求解器会加入 `semi-artificial viscosity`：
   - 目的：稳定数值格式
   - 强度：`order of 10^-2`
   - 方式：经过测试和敏感性分析后选取

4. 远场和出流附近使用 `sponge layers`，目的是避免扰动反射，引用 `Mani 2012`

这篇文献对我们最重要的启发是：

- 它明确支持“FD 稳定性算子 + 很弱的人工耗散/滤波 + sponge”的路线。
- 但它强调这个人工耗散是“carefully picked”，不是激进修补，更不是把物理解区域大面积改写。
- 它没有支持“重度 shock-core clipping + 大范围 mask 修补 + fallback 继续选模”的做法。

### 3.2 `B.pdf`：JFM 2021，hypersonic compression corner

最相关位置：

- `paper/B.pdf` 第 6 页

这篇文献的路线和当前仓库的 `v6` 直接 FD 路线不一样，它走的是 finite-volume Jacobian：

- `linearized Navier-Stokes` 用 conservative variables 写
- inviscid Jacobian 在不连续附近使用 `modified Steger-Warming`
- 通过改进的 `Ducros shock sensor` 检测 discontinuity
- smooth region 里切回 central scheme 以减少数值耗散
- viscous Jacobian 用 second-order central difference
- far field / outflow 仍然加 `sponge layer`

这篇文献对当前问题的启发是：

- 它并没有在 perturbation operator 上再加一个文献正文可见的强 shock-band 滤波链。
- 它主要依赖离散格式本身对 discontinuity 的处理来控制激波附近的数值问题。
- 所以如果我们坚持当前 `v6` 的 centered-FD primitive-five 直装配路线，就不能简单套用 `B` 的“有 shock sensor 就够了”；因为 `B` 的稳定性离散基础和我们现在不同。

### 3.3 `H.pdf`：Phys. Rev. Fluids 2018，oblique SWBLI

最相关位置：

- `paper/H.pdf` 第 8 页
- `paper/H.pdf` 第 9 页
- `paper/H.pdf` 第 15–16 页

这篇文章在方法上和我们现在最接近：

- 基流 / DNS：
  - KEC low-dissipation scheme
  - inviscid flux 前面乘 shock-detecting switch
  - 只在 shock 周围加耗散

- 稳定性分析：
  - stretched mesh 上的 centered fourth-order finite differences
  - `numerical filter` 加入少量尺度选择性人工耗散
  - 目标是压制 `spurious modes associated with the smallest wavelengths allowed by the mesh`

- 外边界：
  - top / left / right 使用 sponge layers
  - 文中明确说 eigenspectra 和 eigenmodes 对 sponge 厚度和强度不敏感，只要 sponge 不侵入 recirculation bubble

这篇文献最关键的启发有两条：

1. `sponge` 是边界处理，不是清理激波核伪模态的主工具。
2. 真正针对 spurious modes 的，是“minor amounts of scale-selective artificial dissipation”，而且作者专门验证它不改变关心的离散模态。

### 3.4 `Hildebrand_umn_0130E_20139.pdf`：2019 博士论文

最相关位置：

- `paper/Hildebrand_umn_0130E_20139.pdf` 第 39 页
- `paper/Hildebrand_umn_0130E_20139.pdf` 第 43–45 页
- `paper/Hildebrand_umn_0130E_20139.pdf` 第 49–53 页

这篇论文是当前仓库里对 shock pollution 处理写得最细的来源。

#### 3.4.1 Sponge 层怎么做

第 43–44 页给了明确建模：

- sponge 用来让 outgoing 信息离开计算域而不向内反射
- 形式是对扰动变量加入阻尼项
- 使用平滑的空间函数 `sigma(x,y)`
- 具体示例是类似
  `sigma = S_str * (0.1*psi^2 + psi^8)`
  这种平滑增长函数

这和当前仓库的认知是一致的：

- sponge 应该是外边界阻尼
- 不是拿来处理主计算区激波伪模态的

#### 3.4.2 Filter 怎么做

第 44–45 页给了非常关键的细节：

- centered spatial finite differences 缺少耗散
- under-resolved Fourier components 会传播而不衰减
- 因此需要 scale-selective artificial dissipation 来抑制 shortest resolvable wavelengths

更重要的是，论文明确说在 GSA/TGA 里使用：

- fourth-derivative filter
- 加到 Jacobian operator 的 `main block diagonal`
- 常用强度约：
  `F_str = 0.0125`

而且作者反复强调：

- 测过不同 `F_str`，包括 `F_str = 0`
- 最终选择很小的值
- 目标是不改变整体物理，只针对 numerics

这和当前仓库的差别非常大：

- 文献里的 filter 是清晰、统一、尺度选择性的高阶滤波
- 当前仓库除了 `Kav` 以外，还叠加了：
  - shock mask 扩张
  - 二阶导数 clipping
  - shock 区二阶导数清零
  - 黏性梯度项压制
- 这比文献里的“轻量 filter”激进得多，也更容易改动物理模态本身

### 3.5 `M.pdf`：Mani 2012，numerical sponge layers

最相关位置：

- `paper/M.pdf` 第 1–6 页
- `paper/M.pdf` 第 12 页

这篇不是稳定性主文献，但它是 sponge 的方法学来源。

文献核心结论：

- sponge 会自己产生反射，不是“越强越好”
- 常值 sponge profile 很差，往往要很长才有效
- 平滑增长的 profile 更好
- 对目标衰减 `20–60 dB`，quadratic sponge 是很实用的折中
- 如果波前方向已知，最好让 sponge 等值线尽量和 outgoing wavefront 对齐
- 还可以和网格拉伸 / 高阶耗散联合使用，但要小心新的反射源

对当前仓库的直接意义：

- 如果我们重新启用 sponge，重点应该是“边界反射控制”和“不要侵入 bubble”
- 不该把 sponge 和 shock-core pseudo-mode 清理混成一个东西

### 3.6 `S.pdf`：Phys. Rev. Fluids 2018，slender double wedge

最相关位置：

- `paper/S.pdf` 第 4–8 页，OCR 提取

这篇对当前 double wedge 最有针对性。

它的路线是：

- 线性化后的扰动方程用 conserved-variable finite-volume 离散
- inviscid perturbation flux 理论上可以接 limiters
- 但作者明确说：这项工作里 **不对 perturbation variables 使用 limiters**
- 原因是他们求的是 temporal eigenproblem，不是直接时间推进扰动
- 对他们研究的 slender double wedge，小 shock angle 情况下，second-order symmetric perturbation flux 已足以得到 physical eigenproblem

同时它也使用 sponge：

- upstream near leading edge
- downstream on shoulder
- wall-normal near freestream
- 用 blending function 从 interior 的 0 平滑过渡到边界区的 1
- 并明确说只要 sponge 远离 recirculation region，模态对 sponge 的强度和位置不敏感

这篇文献给我们的启发很强：

- 对 double wedge，作者没有默认“激波区一定要强修补”
- 相反，他们倾向于保持 perturbation operator 尽可能干净，把边界吸收和主计算区模态分开
- 这和我们当前 `shock mask + clipping + suppress + SAV + fallback plot` 的叠加链路形成鲜明对比

### 3.7 `V.pdf`：AIAA 2006，spectral multidomain BiGlobal

最相关位置：

- `paper/V.pdf` 第 1–3 页

这篇文献主要贡献是 `multidomain` BiGlobal 框架：

- 复杂几何分块
- 子域耦合
- Arnoldi 求解

它几乎不讨论 shock pollution 本身，但它是 `A.pdf` 多区域策略的来源之一。  
所以它的意义主要是：

- 解释为什么 `A.pdf` 会用 multi-domain
- 但不能直接指导我们怎么清理激波伪模态

### 3.8 仓库内部笔记 `paper/notes/*.md`

这两份笔记的结论与上面文献原文基本一致：

- `A` 路线更接近当前仓库的高阶 FD + EVP 思路
- `B` 路线更接近 finite-volume Jacobian
- `Hildebrand` 明确补齐了 sponge 和 fourth-derivative filter 的可实现形式

它们适合做辅助归纳，但不能替代原文证据。

## 4. 文献共识映射到当前仓库后的判断

### 4.1 当前仓库哪些做法和文献一致

- 有 boundary sponge 的概念
- 有第四差分风格的 `semi-artificial viscosity` 概念
- 有 shock-aware 的稳定化意图
- 有用 shift-invert Arnoldi 解广义特征值问题

### 4.2 当前仓库哪些做法明显偏离文献

1. `shock mask` 的几何构造不安全  
   文献里所有 shock/sponge/filter 都默认几何区域是可信的；当前仓库 `circshift` wrap-around 会先把区域做错。

2. 当前 shock regularization 过于“叠加式”  
   文献主线是：
   - 要么用 FV/Jacobian + shock sensor
   - 要么用很弱的 scale-selective filter
   当前仓库是：
   - clipping
   - zeroing second derivatives
   - suppressing viscosity gradients
   - shock-localized SAV
   四层叠加，强于文献常规做法。

3. 当前 filter / SAV 的无害性没有做到文献那种程度的敏感性验证  
   文献反复强调：
   - filter 不能改变关心模态
   - sponge 不能侵入 bubble
   当前仓库还没有把这两点验证到位。

4. 当前默认选模逻辑没有文献依据  
   文献没有支持“physical candidate 为空时仍默认画 relaxed/debug 模态”的做法。

5. 当前 `u` 主导 support field 不是文献方法的一部分  
   这是仓库自己的启发式，会和 shock 条纹叠加出偏置。

## 5. 从文献反推，最应该怎么改

### 第一优先级：把 boundary treatment 和 shock-mode suppression 分开

- `sponge` 只负责边界反射
- `filter/SAV` 只负责最短波长伪模态
- 不要让一个错误的 shock mask 同时主导：
  - 导数 clipping
  - 黏性梯度屏蔽
  - SAV 定位
  - 默认选模解释

### 第二优先级：把当前 shock-band regularization 收敛到更接近 Hildebrand 的轻量路线

更接近文献的路线应该是：

- 一个几何上可信的 mask
- 一个弱的、尺度选择性的高阶滤波
- 明确做 `epsilon/F_str` 敏感性分析
- 证明主模态不因滤波小改动而大漂移

而不是先做一整套激进的局部改写，再看模态会不会变。

### 第三优先级：double wedge 真实算例要单独评估“是否真的需要如此强的 shock-core 修补”

从 `S.pdf` 看，double wedge 的文献路线更偏：

- 尽量保持 perturbation operator 干净
- 依靠底层离散和边界 sponge
- 不轻易对 perturbation 方程再加很重的人造修补

所以当前仓库更合理的方向不是继续加更多局部补丁，而是先回答：

- 仅修正 shock mask 几何错误后，现有 `Kav` 是否已经足够？
- 是否真的需要继续保留：
  - `zero_second_derivatives_in_shock`
  - `suppress_viscosity_gradient_terms_in_shock`

### 第四优先级：默认出图必须只对应“通过物理门槛”的模态

这不是文献里直接写出来的算法，但它和文献工作流是一致的：

- 文献先确保数值路线不会污染物理模态
- 然后才把最不稳定模态当结果展示

当前仓库如果没有 physical candidate，就不该默认给一张“主导模态图”。

## 6. 对当前 `beta=8` 问题的文献化判断

基于仓库文献，当前 `beta=8` 图像里“强烈受激波影响”的结果，最合理的解释不是单一一句话，而是：

1. 高 `beta` 本来就更容易放大 shock-sensitive 分支。
2. 当前仓库 shock 区附近确实存在真实基流坏点。
3. 当前 shock mask 还有已确认的几何 bug。
4. 当前 shock regularization 比文献常规路线更激进。
5. 当前默认选图逻辑又允许 relaxed/debug 模态继续被画出来。

所以在文献标准下，这个 `beta=8` 结果更应该被视为：

- “一个需要先消除数值污染再判断的可疑分支”

而不是：

- “已经足够可信的物理主导模态”

## 7. 直接可执行的后续修改顺序

按文献优先级，建议顺序是：

1. 修 `shock mask` 的 `circshift` wrap-around bug。
2. 把 `Part4` 的 default plotted mode 改成只允许 physical candidate。
3. 给 `Kav/filter` 做小参数扫描，直接比：
   - `0`
   - `0.005`
   - `0.01`
   - `0.0125`
   - `0.02`
4. 单独评估是否保留：
   - shock 区二阶导数清零
   - 黏性梯度项屏蔽
5. 最后再重新看 `beta = 8` 是否仍然表现为 shock-dominated。

## 8. 最终结论

如果只用仓库现有文献来回答“遇到激波污染，他们通常怎么做”，最准确的答案是：

- 先用 `sponge` 把外边界反射问题隔离出去；
- 再用很弱的、尺度选择性的滤波或人工耗散去压制最短波长伪模态；
- 并通过敏感性分析证明这些处理不会改掉真正的物理全局模态；
- 而不是依赖一个激进的 shock-core 局部修补链，再用后处理把结果解释成物理模态。
