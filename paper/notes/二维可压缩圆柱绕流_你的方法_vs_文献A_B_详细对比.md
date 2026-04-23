# 二维可压缩圆柱绕流全局稳定性分析方法对比文档

本文对以下三套方法进行统一记号、统一框架下的详细对比：

- 你的方法：二维可压缩圆柱绕流，全局稳定性分析，贴体坐标，高阶有限差分，阿诺尔迪迭代法与位移求逆法。
- 文献A：*Bi-global stability of supersonic backward-facing step flow*，JFM 2024。
- 文献B：*Occurrence of global instability in hypersonic compression corner flow*，JFM 2021。

文献C *Three-dimensionality of hypersonic laminar flow over a double cone*，JFM 2022 不作为第三个主对比对象，而仅作为补充，用来说明文献B所采用的“有限体积残量雅可比矩阵”构造方式。

---

## 1. 符号统一与对比原则

### 1.1 统一符号

记基本流为

\[
\bar{\rho},\quad \bar{u},\quad \bar{v},\quad \bar{w},\quad \bar{T},\quad \bar{p},
\]

扰动量为

\[
\rho',\quad u',\quad v',\quad w',\quad T',\quad p'.
\]

若采用模态分解，则统一写成

\[
q'(x,y,z,t)=\hat{q}(x,y)\,\mathrm{e}^{i\beta z-i\omega t},
\]

其中

\[
\omega=\omega_r+i\omega_i,\qquad \beta=\frac{2\pi}{\lambda}.
\]

### 1.2 三套方法的本质区别

三套方法在“基本物理模型”层面是一致的，都是从可压缩 Navier-Stokes 方程出发；真正的差别主要体现在以下三点：

- 扰动未知量选取不同。
- 空间离散方法不同。
- 全局矩阵的构造路径不同。

最关键的一句话是：

- 你的方法和文献A都属于“连续方程先整理成系数矩阵型，再做高阶有限差分”的路线。
- 文献B属于“先构造有限体积单元残量，再对残量对状态量求偏导，形成全局雅可比矩阵”的路线。

---

## 2. 你的方法：标准化整理

本节依据你截图中的正文第 1–2 章、式 (1.1)–(2.58) 以及附录A、附录B整理。

### 2.1 总体特征值问题

你在总述部分先把全局稳定性问题写成动力系统

\[
B(q;Re;Ma)\frac{\partial q}{\partial t}=A(q;Re;Ma)q,
\tag{U-1}
\]

并在空间离散后写成广义特征值问题

\[
\hat{A}\,\hat{q}=\omega \hat{B}\,\hat{q}.
\tag{U-2}
\]

这一步的含义是：

- \(\hat{A}\) 与 \(\hat{B}\) 是离散后的稀疏矩阵。
- 特征值 \(\omega=\omega_r+i\omega_i\) 的实部或虚部决定增长与振荡，具体取决于你采用的时间因子约定。
- 你的正文后续实际采用的是 \(\mathrm{e}^{-i\omega t}\) 形式，因此 \(\omega_i>0\) 对应增长。

### 2.2 基本流控制方程

你在直角坐标系 \((x,y)\) 下写出的二维可压缩方程为

\[
\frac{\partial \rho}{\partial t}
+\frac{\partial (\rho u)}{\partial x}
+\frac{\partial (\rho v)}{\partial y}=0,
\tag{U-3}
\]

\[
\frac{\partial (\rho u)}{\partial t}
+\frac{\partial (\rho u^2)}{\partial x}
+\frac{\partial (\rho uv)}{\partial y}
=-\frac{\partial p}{\partial x}
+\frac{1}{Re}\left(
\frac{\partial \tau_{xx}}{\partial x}
+\frac{\partial \tau_{xy}}{\partial y}
\right),
\tag{U-4}
\]

\[
\frac{\partial (\rho v)}{\partial t}
+\frac{\partial (\rho uv)}{\partial x}
+\frac{\partial (\rho v^2)}{\partial y}
=-\frac{\partial p}{\partial y}
+\frac{1}{Re}\left(
\frac{\partial \tau_{yx}}{\partial x}
+\frac{\partial \tau_{yy}}{\partial y}
\right),
\tag{U-5}
\]

\[
\frac{\partial (\rho e)}{\partial t}
+\frac{\partial (\rho u e+p u)}{\partial x}
+\frac{\partial (\rho v e+p v)}{\partial y}
=\frac{1}{Re}
\left[
\frac{\partial (u\tau_{xx}+v\tau_{xy}+q_x)}{\partial x}
+\frac{\partial (u\tau_{yx}+v\tau_{yy}+q_y)}{\partial y}
\right].
\tag{U-6}
\]

这里需要特别说明：你的记号里把热传导项写成 \(+q_x,+q_y\) 的形式，同时又定义了

\[
q_x=\kappa\frac{\partial T}{\partial x},\qquad
q_y=\kappa\frac{\partial T}{\partial y}.
\tag{U-7}
\]

这与很多文献中常见的 Fourier 热流记号

\[
q_x^{(F)}=-\kappa T_x,\qquad q_y^{(F)}=-\kappa T_y
\]

只差一个符号约定；写代码时必须前后一致，不能混用。

### 2.3 黏性应力、状态方程与无量纲化

你给出的黏性应力为

\[
\tau_{xx}=2\mu\left(\frac{\partial u}{\partial x}-\frac13\mathrm{div}\,\boldsymbol{u}\right),
\tag{U-8}
\]

\[
\tau_{yy}=2\mu\left(\frac{\partial v}{\partial y}-\frac13\mathrm{div}\,\boldsymbol{u}\right),
\tag{U-9}
\]

\[
\tau_{xy}=\tau_{yx}
=\mu\left(\frac{\partial u}{\partial y}+\frac{\partial v}{\partial x}\right),
\tag{U-10}
\]

\[
\mathrm{div}\,\boldsymbol{u}=\frac{\partial u}{\partial x}+\frac{\partial v}{\partial y}.
\tag{U-11}
\]

你采用量热完全气体模型，能量和状态方程写成

\[
p=(\gamma-1)\rho\left(e-\frac12(u^2+v^2)\right),
\tag{U-12}
\]

或者等价地

\[
e=\frac{T}{\gamma(\gamma-1)Ma^2}+\frac12(u^2+v^2),
\qquad
p=\frac{\rho T}{\gamma Ma^2}.
\tag{U-13}
\]

你还采用 Sutherland 黏度公式

\[
\frac{\mu}{\mu_\infty}
=\left(\frac{T}{T_\infty}\right)^{3/2}
\frac{T_\infty+C}{T+C},
\tag{U-14}
\]

并以自由来流量进行无量纲化。根据正文和上下文可恢复为

\[
x=\frac{\tilde{x}}{L},\quad
y=\frac{\tilde{y}}{L},\quad
u=\frac{\tilde{u}}{U_\infty},\quad
v=\frac{\tilde{v}}{U_\infty},\quad
\rho=\frac{\tilde{\rho}}{\rho_\infty},
\tag{U-15}
\]

\[
T=\frac{\tilde{T}}{T_\infty},\quad
p=\frac{\tilde{p}}{\rho_\infty U_\infty^2},\quad
t=\frac{\tilde{t}U_\infty}{L}.
\tag{U-16}
\]

### 2.4 基本流方程

令

\[
\rho=\bar{\rho},\quad u=\bar{u},\quad v=\bar{v},\quad T=\bar{T},\quad p=\bar{p},
\qquad
\frac{\partial}{\partial t}=0,
\]

则基本流满足

\[
\frac{\partial (\bar{\rho}\bar{u})}{\partial x}
+\frac{\partial (\bar{\rho}\bar{v})}{\partial y}=0,
\tag{U-17}
\]

\[
\frac{\partial (\bar{\rho}\bar{u}^2)}{\partial x}
+\frac{\partial (\bar{\rho}\bar{u}\bar{v})}{\partial y}
=-\frac{\partial \bar{p}}{\partial x}
+\frac{1}{Re}\left(
\frac{\partial \bar{\tau}_{xx}}{\partial x}
+\frac{\partial \bar{\tau}_{xy}}{\partial y}
\right),
\tag{U-18}
\]

\[
\frac{\partial (\bar{\rho}\bar{u}\bar{v})}{\partial x}
+\frac{\partial (\bar{\rho}\bar{v}^2)}{\partial y}
=-\frac{\partial \bar{p}}{\partial y}
+\frac{1}{Re}\left(
\frac{\partial \bar{\tau}_{yx}}{\partial x}
+\frac{\partial \bar{\tau}_{yy}}{\partial y}
\right),
\tag{U-19}
\]

\[
\frac{\partial (\bar{\rho}\bar{u}\bar{e}+\bar{p}\bar{u})}{\partial x}
+\frac{\partial (\bar{\rho}\bar{v}\bar{e}+\bar{p}\bar{v})}{\partial y}
=\frac{1}{Re}
\left[
\frac{\partial (\bar{u}\bar{\tau}_{xx}+\bar{v}\bar{\tau}_{xy}+\bar{q}_x)}{\partial x}
+\frac{\partial (\bar{u}\bar{\tau}_{yx}+\bar{v}\bar{\tau}_{yy}+\bar{q}_y)}{\partial y}
\right].
\tag{U-20}
\]

这就是你后续稳定性分析所依赖的二维稳态基本流。

### 2.5 扰动分解与线性化

你的扰动分解写为

\[
q=q_0+q',
\qquad
q_0=(\rho_0,u_0,v_0,T_0)^T,
\qquad
q'=(\rho',u',v',T')^T.
\tag{U-21}
\]

压强扰动通过状态方程消去：

\[
p'=\frac{\rho_0T'+T_0\rho'}{\gamma Ma^2}.
\tag{U-22}
\]

由此得到的线性连续方程为

\[
\frac{\partial \rho'}{\partial t}
+u_0\frac{\partial \rho'}{\partial x}
+v_0\frac{\partial \rho'}{\partial y}
+\rho_0\frac{\partial u'}{\partial x}
+\rho_0\frac{\partial v'}{\partial y}
+\left(\frac{\partial u_0}{\partial x}+\frac{\partial v_0}{\partial y}\right)\rho'
+\frac{\partial \rho_0}{\partial x}u'
+\frac{\partial \rho_0}{\partial y}v'=0.
\tag{U-23}
\]

\(x\) 动量方程的一阶部分可整理成

\[
\frac{\partial (\rho_0u'+u_0\rho')}{\partial t}
+\frac{\partial}{\partial x}
\left[
\left(u_0^2+\frac{T_0}{\gamma Ma^2}\right)\rho'
+2\rho_0u_0u'
+\frac{\rho_0}{\gamma Ma^2}T'
\right]
\]
\[
+\frac{\partial}{\partial y}
\left[
u_0v_0\rho'
+\rho_0v_0u'
+\rho_0u_0v'
\right]
=\frac{1}{Re}\left(
\frac{\partial \tau'_{xx}}{\partial x}
+\frac{\partial \tau'_{xy}}{\partial y}
\right).
\tag{U-24}
\]

\(y\) 动量方程对应为

\[
\frac{\partial (\rho_0v'+v_0\rho')}{\partial t}
+\frac{\partial}{\partial x}
\left[
u_0v_0\rho'
+\rho_0v_0u'
+\rho_0u_0v'
\right]
\]
\[
+\frac{\partial}{\partial y}
\left[
\left(v_0^2+\frac{T_0}{\gamma Ma^2}\right)\rho'
+2\rho_0v_0v'
+\frac{\rho_0}{\gamma Ma^2}T'
\right]
=\frac{1}{Re}\left(
\frac{\partial \tau'_{yx}}{\partial x}
+\frac{\partial \tau'_{yy}}{\partial y}
\right).
\tag{U-25}
\]

温度方程可从你的正文式 (2.22)–(2.29) 及附录A恢复为

\[
C_v\rho_0\frac{\partial T'}{\partial t}
+C_v\rho_0u_0\frac{\partial T'}{\partial x}
+C_v\rho_0v_0\frac{\partial T'}{\partial y}
+p_0\left(
\frac{\partial u'}{\partial x}+\frac{\partial v'}{\partial y}
\right)
+\text{基流梯度零阶项}
\]
\[
=\frac{1}{Re\,Pr}
\left(
\frac{\partial^2 T'}{\partial x^2}
+\frac{\partial^2 T'}{\partial y^2}
\right)
+\frac{1}{Re}\,\text{黏性耗散线性项}.
\tag{U-26}
\]

这里“基流梯度零阶项”与“黏性耗散线性项”在你的附录A中都已经展开到 \(D\) 矩阵和附加零阶项中。

### 2.6 直角坐标下的系数矩阵

你把方程写成

\[
\Gamma \frac{\partial q'}{\partial t}
+A\frac{\partial q'}{\partial x}
+B\frac{\partial q'}{\partial y}
+Dq'
=V_{xx}\frac{\partial^2 q'}{\partial x^2}
+V_{xy}\frac{\partial^2 q'}{\partial x\partial y}
+V_{yy}\frac{\partial^2 q'}{\partial y^2}.
\tag{U-27}
\]

附录A给出的时间矩阵 \(\Gamma\) 可清楚识别为

\[
\Gamma=
\begin{bmatrix}
1 & 0 & 0 & 0\\
u_0 & \rho_0 & 0 & 0\\
v_0 & 0 & \rho_0 & 0\\
0 & 0 & 0 & C_v\rho_0
\end{bmatrix}.
\tag{U-28}
\]

一阶导数主系数矩阵 \(A,B\) 的前三行可由式 (U-23)–(U-25) 直接读出：

\[
A=
\begin{bmatrix}
u_0 & \rho_0 & 0 & 0\\
u_0^2+\dfrac{T_0}{\gamma Ma^2} & 2\rho_0u_0 & 0 & \dfrac{\rho_0}{\gamma Ma^2}\\
u_0v_0 & \rho_0 v_0 & \rho_0u_0 & 0\\
\ast & \ast & \ast & C_v\rho_0u_0
\end{bmatrix},
\tag{U-29}
\]

\[
B=
\begin{bmatrix}
v_0 & 0 & \rho_0 & 0\\
u_0v_0 & \rho_0v_0 & \rho_0u_0 & 0\\
v_0^2+\dfrac{T_0}{\gamma Ma^2} & 0 & 2\rho_0v_0 & \dfrac{\rho_0}{\gamma Ma^2}\\
\ast & \ast & \ast & C_v\rho_0v_0
\end{bmatrix}.
\tag{U-30}
\]

这里最后一行中的 \(\ast\) 来自温度方程与状态方程、黏性耗散的耦合项；附录A给出了逐项表达，但原图分辨率不足以完整逐项转录。就实现而言，更稳定的处理方式是直接从式 (U-26) 自动装配。

二阶主部矩阵的结构在附录A中非常清楚：

\[
V_{xx}=
\begin{bmatrix}
0 & 0 & 0 & 0\\
0 & \dfrac{4}{3Re}\mu_0 & 0 & 0\\
0 & 0 & \dfrac{1}{Re}\mu_0 & 0\\
0 & 0 & 0 & \dfrac{1}{Re\,Pr}\kappa_0
\end{bmatrix},
\tag{U-31}
\]

\[
V_{yy}=
\begin{bmatrix}
0 & 0 & 0 & 0\\
0 & \dfrac{1}{Re}\mu_0 & 0 & 0\\
0 & 0 & \dfrac{4}{3Re}\mu_0 & 0\\
0 & 0 & 0 & \dfrac{1}{Re\,Pr}\kappa_0
\end{bmatrix},
\tag{U-32}
\]

\[
V_{xy}=
\begin{bmatrix}
0 & 0 & 0 & 0\\
0 & 0 & \dfrac{1}{3Re}\mu_0 & 0\\
0 & \dfrac{1}{3Re}\mu_0 & 0 & 0\\
0 & 0 & 0 & 0
\end{bmatrix}.
\tag{U-33}
\]

零阶矩阵 \(D\) 的物理来源可分解为

\[
D=D_c+D_p+D_\mu+D_\kappa,
\tag{U-34}
\]

其中：

- \(D_c\) 来自基本流速度与密度的梯度。
- \(D_p\) 来自状态方程代入后的压力零阶项。
- \(D_\mu\) 来自黏度 \(\mu(T)\) 的线性化。
- \(D_\kappa\) 来自热导率 \(\kappa(T)\) 的线性化。

你的附录A已经把这些项全部展开，因此从实现角度看，你的方法并不是“只给出结构”，而是已经到达了“可直接编码”的级别。

### 2.7 贴体坐标变换

你随后引入一般曲线坐标

\[
x=x(\xi,\eta),\qquad y=y(\xi,\eta),
\tag{U-35}
\]

并定义 Jacobian（雅可比，即坐标变换行列式）

\[
J=x_\xi y_\eta-x_\eta y_\xi.
\tag{U-36}
\]

一阶导数变换为

\[
\frac{\partial}{\partial x}=\xi_x\frac{\partial}{\partial \xi}+\eta_x\frac{\partial}{\partial \eta},
\qquad
\frac{\partial}{\partial y}=\xi_y\frac{\partial}{\partial \xi}+\eta_y\frac{\partial}{\partial \eta},
\tag{U-37}
\]

其中度量项为

\[
\xi_x=\frac{y_\eta}{J},\qquad
\xi_y=-\frac{x_\eta}{J},\qquad
\eta_x=-\frac{y_\xi}{J},\qquad
\eta_y=\frac{x_\xi}{J}.
\tag{U-38}
\]

代入后，直角坐标方程变成

\[
\Gamma \frac{\partial q'}{\partial t}
+A_\xi \frac{\partial q'}{\partial \xi}
+B_\eta \frac{\partial q'}{\partial \eta}
+D' q'
=V_{\xi\xi}\frac{\partial^2 q'}{\partial \xi^2}
+V_{\xi\eta}\frac{\partial^2 q'}{\partial \xi\partial \eta}
+V_{\eta\eta}\frac{\partial^2 q'}{\partial \eta^2}.
\tag{U-39}
\]

附录B给出的变换关系可写成

\[
A_\xi=\xi_x A+\xi_y B-\xi_{xx}V_{xx}-\xi_{xy}V_{xy}-\xi_{yy}V_{yy},
\tag{U-40}
\]

\[
B_\eta=\eta_x A+\eta_y B-\eta_{xx}V_{xx}-\eta_{xy}V_{xy}-\eta_{yy}V_{yy},
\tag{U-41}
\]

\[
V_{\xi\xi}=\xi_x^2V_{xx}+\xi_x\xi_yV_{xy}+\xi_y^2V_{yy},
\tag{U-42}
\]

\[
V_{\eta\eta}=\eta_x^2V_{xx}+\eta_x\eta_yV_{xy}+\eta_y^2V_{yy},
\tag{U-43}
\]

\[
V_{\xi\eta}=2\xi_x\eta_xV_{xx}+(\xi_x\eta_y+\xi_y\eta_x)V_{xy}+2\xi_y\eta_yV_{yy}.
\tag{U-44}
\]

这一部分是你的方法与文献A、文献B差别最大的地方，因为那两篇文献正文都没有显式给出贴体坐标与度量项公式。

### 2.8 边界条件

你的正文第 2.2.2 节给出两类边界：

- 远场边界；
- 壁面边界。

根据正文与截图可还原为如下连续形式：

远场无扰动边界：

\[
\rho'=0,\qquad u'=0,\qquad v'=0,\qquad T'=0,
\quad \text{on } \Gamma_\infty.
\tag{U-45}
\]

壁面无滑移、绝热边界：

\[
u'=0,\qquad v'=0,\qquad \frac{\partial T'}{\partial n}=0,
\quad \text{on } \Gamma_w.
\tag{U-46}
\]

你还用状态方程推得

\[
p'=\frac{\rho_0T'+T_0\rho'}{\gamma Ma^2},
\tag{U-47}
\]

若壁面取 \(\partial_n p'=0\) 且 \(\partial_nT'=0\)，则有

\[
\frac{\partial \rho'}{\partial n}=0.
\tag{U-48}
\]

因此你的壁面热边界是“绝热壁面”；这与文献A、文献B的“等温壁面”是一个实质差别。

### 2.9 空间离散

你在第 2.2.1 节明确采用四阶有限差分。按 \(\xi\) 方向写，内部点 \(i=3,\dots,n-2\) 的一阶导数为

\[
\left(\frac{\partial q}{\partial \xi}\right)_i
=\frac{q_{i-2}-8q_{i-1}+8q_{i+1}-q_{i+2}}{12\Delta \xi},
\tag{U-49}
\]

二阶导数为

\[
\left(\frac{\partial^2 q}{\partial \xi^2}\right)_i
=\frac{-q_{i+2}+16q_{i+1}-30q_i+16q_{i-1}-q_{i-2}}{12\Delta \xi^2}.
\tag{U-50}
\]

混合导数按张量积展开为

\[
\left(\frac{\partial^2 q}{\partial \xi\partial \eta}\right)_{i,j}
=\frac{1}{144\Delta \xi\Delta \eta}
\sum_{m=-2}^{2}\sum_{n=-2}^{2}c_mc_n\,q_{i+m,j+n},
\quad
[c_{-2},c_{-1},c_0,c_1,c_2]=[1,-8,0,8,-1].
\tag{U-51}
\]

边界点采用单边差分。正文和截图对应的代表性格式为

\[
\left(\frac{\partial q}{\partial \xi}\right)_1
=\frac{-11q_1+18q_2-9q_3+2q_4}{6\Delta \xi},
\tag{U-52}
\]

\[
\left(\frac{\partial^2 q}{\partial \xi^2}\right)_1
=\frac{2q_1-5q_2+4q_3-q_4}{\Delta \xi^2}.
\tag{U-53}
\]

这些公式说明你的空间离散是典型的“结构化网格高阶有限差分”路线，与文献A高度相近，与文献B明显不同。

### 2.10 特征值问题、位移求逆与阿诺尔迪法

采用时间模态

\[
q'(\xi,\eta,t)=\hat{q}(\xi,\eta)\,\mathrm{e}^{-i\omega t},
\tag{U-54}
\]

则离散后得到广义特征值问题

\[
\mathsf{N}\hat{q}=i\omega\,\mathsf{\Gamma}\hat{q}.
\tag{U-55}
\]

为提取谱内部最不稳定模态，你进一步采用位移求逆法。设位移参数为 \(\delta\)，则

\[
(\mathsf{N}-\delta\mathsf{\Gamma})\hat{q}
=(i\omega-\delta)\mathsf{\Gamma}\hat{q}.
\tag{U-56}
\]

两边左乘 \((\mathsf{N}-\delta\mathsf{\Gamma})^{-1}\) 得

\[
\mathsf{M}\hat{q}=\mu \hat{q},
\qquad
\mathsf{M}=(\mathsf{N}-\delta\mathsf{\Gamma})^{-1}\mathsf{\Gamma},
\qquad
\mu=\frac{1}{i\omega-\delta}.
\tag{U-57}
\]

再对 \(\mathsf{M}\) 施加阿诺尔迪法，即在 Krylov 子空间

\[
\mathcal{K}_K(\mathsf{M},v_1)=\mathrm{span}\{v_1,\mathsf{M}v_1,\dots,\mathsf{M}^{K-1}v_1\}
\tag{U-58}
\]

中构造 Hessenberg（海森堡）小矩阵并求其 Ritz（里兹）特征值近似。

这一部分与你的方法截图第 2.3 节和文献B是完全一致的；文献A正文没有明确写出位移求逆，因此这里只能说你与文献B更接近。

---

## 3. 文献A：基本流与全局稳定性

文献A：*Bi-global stability of supersonic backward-facing step flow*，JFM 2024。

### 3.1 基本流控制方程

文献A §2.1，p.4，式 (2.1)–(2.2)：

\[
\frac{\partial \boldsymbol{U}}{\partial t}
+\frac{\partial \boldsymbol{F}}{\partial x}
+\frac{\partial \boldsymbol{G}}{\partial y}
+\frac{\partial \boldsymbol{H}}{\partial z}
=
\frac{\partial \boldsymbol{F}_v}{\partial x}
+\frac{\partial \boldsymbol{G}_v}{\partial y}
+\frac{\partial \boldsymbol{H}_v}{\partial z},
\tag{A-1}
\]

\[
\boldsymbol{U}=
\begin{bmatrix}
\rho\\ \rho u\\ \rho v\\ \rho w\\ \rho e
\end{bmatrix},
\tag{A-2}
\]

\[
\boldsymbol{F}=
\begin{bmatrix}
\rho u\\ \rho u^2+p\\ \rho uv\\ \rho uw\\ (\rho e+p)u
\end{bmatrix},
\qquad
\boldsymbol{F}_v=
\begin{bmatrix}
0\\ \tau_{xx}\\ \tau_{xy}\\ \tau_{xz}\\ u\tau_{xx}+v\tau_{xy}+w\tau_{xz}-q_x
\end{bmatrix}.
\tag{A-3}
\]

其闭合关系是：

- 完全气体模型；
- 牛顿黏性定律；
- Fourier 导热定律；
- Sutherland 黏度律。

二维稳态基本流满足

\[
\frac{\partial}{\partial t}=0,\qquad
\frac{\partial}{\partial z}=0,\qquad
\bar{w}=0.
\tag{A-4}
\]

因此文献A的基本流方程在连续层面与式 (U-17)–(U-20) 本质一致。

### 3.2 基本流边界条件与数值方法

文献A的基本流边界条件为：

- 左边界、上边界：自由来流。
- 出口：外推。
- 壁面：等温、无滑移。

基流求解方法为：

- 有限体积法；
- 修正 Steger-Warming 通量分裂；
- MUSCL/van-Leer 重构；
- 黏性通量二阶中心；
- 隐式点松弛推进。

因此文献A的基本流是“有限体积基本流 + 有限差分稳定性”的混合路线。

### 3.3 扰动分解与特征值问题

文献A §2.2，p.5：

\[
\boldsymbol{q}=[u,v,w,T,p]^T,
\qquad
\boldsymbol{q}=\bar{\boldsymbol{q}}+\boldsymbol{q}',
\tag{A-5}
\]

\[
\boldsymbol{q}'(x,y,z,t)
=\hat{\boldsymbol{q}}(x,y)\,\mathrm{e}^{i\beta z-i\omega t}.
\tag{A-6}
\]

代入后得到广义特征值问题

\[
\mathsf{A}(\bar{q};\beta)\hat{q}
=\omega\,\mathsf{B}\hat{q}.
\tag{A-7}
\]

这里文献A选择的是原始变量

\[
\hat{q}_A=[u',v',w',T',p']^T,
\tag{A-8}
\]

与您的方法

\[
\hat{q}_U=[\rho',u',v',T']^T
\]

相比，有两个核心差别：

- 它保留了 \(p'\) 作为独立未知量。
- 它保留了跨向速度 \(w'\) 和跨向波数 \(\beta\)。

### 3.4 文献A 的稳定性离散方法

文献A稳定性部分采用：

- 结构化多区域网格；
- 内部点四阶中心有限差分；
- 边界附近三阶差分；
- 半人工黏性；
- 阿诺尔迪迭代法。

因此其离散矩阵在结构上可写成

\[
\mathsf{K}_A
=\mathsf{C}_0
+\mathsf{C}_x D_x
+\mathsf{C}_y D_y
+\mathsf{C}_{xx}D_{xx}
+\mathsf{C}_{xy}D_{xy}
+\mathsf{C}_{yy}D_{yy}
+i\beta\mathsf{C}_\beta
+\beta^2\mathsf{C}_{\beta\beta}
+\varepsilon_{av}\mathsf{S}_{av}.
\tag{A-9}
\]

这一路线和你的方法是同一类型，只是文献A没有把贴体坐标与度量项显式写出来。

### 3.5 文献A 的边界条件

文献A §2.2，p.6，式 (2.7)：

\[
u'=v'=w'=T'=0,\qquad \boldsymbol{n}\cdot \nabla p'=0
\quad \text{on wall}.
\tag{A-10}
\]

同时：

- 入口扰动为零；
- 出口线性外推；
- 远场与出口附近施加海绵层。

因此文献A在热边界上是“等温壁面”，而你的方法是“绝热壁面”。

---

## 4. 文献B：基本流与全局稳定性

文献B：*Occurrence of global instability in hypersonic compression corner flow*，JFM 2021。

### 4.1 基本流控制方程与无量纲化

文献B §2，p.4，式 (2.1)–(2.2) 与文献A同型，也是三维可压缩守恒式：

\[
\frac{\partial \boldsymbol{U}}{\partial t}
+\nabla\cdot \boldsymbol{\mathcal{F}}(\boldsymbol{U})
=\nabla\cdot \boldsymbol{\mathcal{F}}_v(\boldsymbol{U},\nabla \boldsymbol{U}).
\tag{B-1}
\]

但文献B比文献A多给出了一条非常关键的信息：所有变量都以自由来流和长度 \(L\) 进行无量纲化，控制参数是

\[
M_\infty,\qquad Re_L,\qquad \theta,\qquad T_w/T_0.
\tag{B-2}
\]

这一点与您的方法更接近，因为你的方法也显式写了无量纲化过程。

### 4.2 文献B 的扰动未知量

文献B §3.3，p.6：

\[
\boldsymbol{U}=\boldsymbol{U}_{2D}+\boldsymbol{U}',
\tag{B-3}
\]

\[
\boldsymbol{U}'(x,y,z,t)
=\hat{\boldsymbol{U}}(x,y)\,
\mathrm{e}^{-i\omega t+i2\pi z/\lambda}.
\tag{B-4}
\]

其扰动未知量是守恒变量：

\[
\hat{U}_B=
\begin{bmatrix}
\rho'\\
(\rho u)'\\
(\rho v)'\\
(\rho w)'\\
(\rho e)'
\end{bmatrix}.
\tag{B-5}
\]

这与您的方法和文献A都不同。

### 4.3 文献B 的通量雅可比矩阵

文献B虽然没有把所有雅可比矩阵逐项印在正文里，但其无黏主系数矩阵就是守恒变量通量雅可比：

\[
\mathsf{A}_x=\frac{\partial \boldsymbol{F}}{\partial \boldsymbol{U}},
\qquad
\mathsf{A}_y=\frac{\partial \boldsymbol{G}}{\partial \boldsymbol{U}},
\qquad
\mathsf{A}_z=\frac{\partial \boldsymbol{H}}{\partial \boldsymbol{U}}.
\tag{B-6}
\]

其中

\[
\boldsymbol{U}=[\rho,m,n,l,E]^T,
\qquad
m=\rho u,\ n=\rho v,\ l=\rho w.
\]

其 \(x\) 向雅可比矩阵为

\[
\mathsf{A}_x=
\begin{bmatrix}
0 & 1 & 0 & 0 & 0\\
\frac{\gamma-3}{2}u^2+\frac{\gamma-1}{2}(v^2+w^2) & (3-\gamma)u & -(\gamma-1)v & -(\gamma-1)w & \gamma-1\\
-uv & v & u & 0 & 0\\
-uw & w & 0 & u & 0\\
u\!\left(\frac{\gamma-1}{2}(u^2+v^2+w^2)-H\right) & H-(\gamma-1)u^2 & -(\gamma-1)uv & -(\gamma-1)uw & \gamma u
\end{bmatrix},
\tag{B-7}
\]

\(y\) 向与 \(z\) 向雅可比矩阵同理。

这说明文献B的“系数矩阵”并不是 \(A,B,D,V_{xx}\) 这种偏微分方程块矩阵，而是“残量对守恒变量的偏导矩阵”。

### 4.4 文献B 的稳定性离散方法

文献B全局稳定性分析采用：

- 守恒变量扰动；
- 单元中心有限体积法；
- 修正 Steger-Warming 通量分裂；
- Ducros 激波传感器；
- 光滑区中心格式；
- 黏性项二阶中心；
- 位移求逆；
- 阿诺尔迪法。

其单元级扰动残量可写成

\[
\frac{\mathrm{d} \boldsymbol{U}'_c}{\mathrm{d}t}
+\frac{1}{V_c}
\sum_{f\in \partial c}
\delta \boldsymbol{\Phi}_f=0,
\tag{B-8}
\]

其中

\[
\delta \boldsymbol{\Phi}_f
=\delta \boldsymbol{\Phi}_f^{(\text{无黏})}
-\delta \boldsymbol{\Phi}_f^{(\text{黏性})}
+i\beta\,\delta \boldsymbol{\Phi}_f^{(z)}.
\tag{B-9}
\]

把所有单元残量堆叠后得到

\[
\delta \mathsf{R}
=\mathsf{J}\,\delta \boldsymbol{U},
\qquad
\mathsf{J}=\frac{\partial \mathsf{R}}{\partial \boldsymbol{U}}.
\tag{B-10}
\]

再得到特征值问题

\[
\mathsf{J}(\beta)\hat{U}_B=-i\omega\,\mathsf{M}\hat{U}_B.
\tag{B-11}
\]

这正是文献B与您的方法最大的差别：

- 你的矩阵来自“微分算子差分化”。
- 文献B的矩阵来自“有限体积残量雅可比”。

### 4.5 文献C 对文献B 的补充

文献C在轴对称双锥问题中，把与文献B同类型的方法写得更明确：

- 先在控制体上积分扰动方程；
- 再对无黏面通量、黏性面通量、几何源项分别求雅可比；
- 最终得到全局特征值矩阵。

因此可以把文献B的全局矩阵理解为

\[
\mathsf{K}_B
=
\mathsf{J}_{\text{inviscid}}
+\mathsf{J}_{\text{viscous}}
+\mathsf{J}_{\text{source}}.
\tag{B-12}
\]

对于文献B的平面压缩拐角问题，\(\mathsf{J}_{\text{source}}\) 基本为零或只包含边界/海绵处理，因此主干就是无黏与黏性面通量的雅可比矩阵。

### 4.6 文献B 的边界条件与特征值方法

文献B壁面边界为

\[
u'=v'=w'=T'=0,\qquad \partial_n p'=0.
\tag{B-13}
\]

并采用：

- 出口外推；
- 远场/出口海绵层；
- 位移求逆；
- ARPACK 中的隐式重启阿诺尔迪法。

因此在“特征值算法”层面，文献B与你的方法是高度一致的。

---

## 5. 三套方法的变量映射

### 5.1 你的方法与文献A

你的状态向量为

\[
\hat{q}_U=
\begin{bmatrix}
\rho'\\ u'\\ v'\\ T'
\end{bmatrix},
\qquad
\hat{q}_A=
\begin{bmatrix}
u'\\ v'\\ w'\\ T'\\ p'
\end{bmatrix}.
\]

二维极限下，两者之间有

\[
\hat{q}_A=\mathsf{T}_{U\to A}\hat{q}_U,
\tag{C-1}
\]

\[
\mathsf{T}_{U\to A}
=
\begin{bmatrix}
0 & 1 & 0 & 0\\
0 & 0 & 1 & 0\\
0 & 0 & 0 & 0\\
0 & 0 & 0 & 1\\
\dfrac{T_0}{\gamma Ma^2} & 0 & 0 & \dfrac{\rho_0}{\gamma Ma^2}
\end{bmatrix}.
\tag{C-2}
\]

这说明：

- 若要与你的方法严格对齐文献A，就必须增加 \(w'\)。
- 若要与你的方法严格对齐文献A，就不能再把 \(p'\) 消去。

### 5.2 你的方法与文献B

\[
\hat{U}_B=\mathsf{T}_{U\to B}\hat{q}_U,
\tag{C-3}
\]

其中

\[
\mathsf{T}_{U\to B}
=
\begin{bmatrix}
1 & 0 & 0 & 0\\
u_0 & \rho_0 & 0 & 0\\
v_0 & 0 & \rho_0 & 0\\
0 & 0 & 0 & 0\\
e_0 & \rho_0u_0 & \rho_0v_0 & \dfrac{\rho_0}{\gamma(\gamma-1)Ma^2}
\end{bmatrix},
\tag{C-4}
\]

\[
e_0=\frac{T_0}{\gamma(\gamma-1)Ma^2}+\frac12(u_0^2+v_0^2).
\tag{C-5}
\]

因此：

- 你的方法与文献B在连续层面是可变换的；
- 但由于离散方式不同，这种变换不能直接保证离散矩阵相似。

---

## 6. 三方逐项对比总表

| 项目 | 你的方法 | 文献A | 文献B | 判断 |
|---|---|---|---|---|
| 基本流方程 | 二维可压缩 N-S | 三维守恒式，基流取二维稳态 | 三维守恒式，基流取二维稳态 | 物理模型本质一致 |
| 无量纲化 | 显式给出 | 文中未系统展开 | 显式给出 | 你与B更接近 |
| 扰动变量 | \([\rho',u',v',T']\) | \([u',v',w',T',p']\) | \([\rho',(\rho u)',(\rho v)',(\rho w)',(\rho e)']\) | 三者不同 |
| 压力处理 | 由状态方程消去 | 保留为独立未知量 | 由守恒变量恢复 | 你最紧凑 |
| 坐标变换 | 贴体坐标显式推导 | 正文未给 | 正文未给 | 你的方法最完整 |
| 系数矩阵 | \(\Gamma,A,B,D,V_{xx},V_{xy},V_{yy}\) | 同类局部块矩阵，正文未逐项印出 | 通量雅可比矩阵/残量雅可比矩阵 | A更接近你 |
| 空间离散 | 五点四阶有限差分 | 四阶中心差分，边界三阶差分 | 二阶有限体积 | 你与A最接近 |
| 边界热条件 | 绝热壁面 | 等温壁面 | 等温壁面 | 与A/B不同 |
| 特征值问题 | 广义特征值问题 | 广义特征值问题 | 残量雅可比特征值问题 | 三者可统一到 \(\mathsf{K}\phi=\omega \mathsf{M}\phi\) |
| 位移求逆 | 明确使用 | 正文未明确 | 明确使用 | 你与B更接近 |
| 阿诺尔迪法 | 明确使用 | 明确使用 | 明确使用 | 三者一致 |

---

## 7. 结论：哪篇文献更接近你的方法

### 7.1 总体判断

总体上，文献A更接近你的推导框架。

原因有三点：

- 你和文献A都采用“连续方程先整理、再用高阶有限差分离散”的思路。
- 你和文献A都更容易写成“系数矩阵 + 导数算子”的形式。
- 你的贴体坐标推导可以看成是对文献A路线的进一步完善。

### 7.2 与文献A严格对齐时需要修改的地方

若要让你的方法与文献A严格对齐，需要做四件事：

- 把二维扰动扩展成双全局三维扰动，引入 \(w'\)。
- 把 \(p'\) 从“由状态方程消元”改成“独立未知量”。
- 在连续方程中加入 \(i\beta\) 与 \(-\beta^2\) 项。
- 把壁面热边界从绝热改成等温。

### 7.3 与文献B严格对齐时需要修改的地方

若要让你的方法与文献B严格对齐，除上述三维扩展外，还需要根本性改变离散方式：

- 不再从 \(\Gamma,A,B,D,V\) 直接组装差分矩阵；
- 改为先写单元残量；
- 对单元残量对守恒变量求偏导；
- 形成全局有限体积雅可比矩阵；
- 引入通量分裂与激波传感器。

因此，文献B不能简单说成“与你的方法相同”，更准确的说法是：

> 文献B与本文方法在基本物理模型与特征值求解策略上相容，但在线性化变量选择、空间离散方法及全局矩阵构造方式上不同。

---

## 8. 对实现与验证的直接建议

### 8.1 若你的目标是和文献A做数值对齐

优先顺序建议如下：

- 先把壁面热边界统一。
- 再把二维扰动扩展为三维双全局扰动。
- 最后再考虑是否保留压力作为独立未知量。

原因是：

- 壁面热条件会直接改基本流；
- 基本流不同，后续特征值自然不同；
- 即使系数矩阵形式相近，也无法直接比较。

### 8.2 若你的目标是和文献B做实现级对齐

优先顺序建议如下：

- 保留你当前的连续推导作为理论基线；
- 另建一套守恒变量有限体积线性化程序；
- 用同一基本流分别跑“高阶有限差分版”和“有限体积雅可比版”；
- 再比较主导特征值与模态形状。

这样能最清楚地区分：

- 连续模型差异；
- 离散误差差异；
- 边界处理差异；
- 特征值算法差异。

---

## 9. 本文档的使用方式

这份文档可以直接用于三种用途：

- 核对你自己的推导与附录矩阵。
- 修改代码实现时确定“到底应按文献A还是文献B靠齐”。
- 写论文中的“方法对比”章节。

如果后续需要继续细化，最值得做的下一步是：

- 把你的附录A、附录B逐块转写成完全的 LaTeX 矩阵；
- 或者把本文件改写成论文正文格式。

