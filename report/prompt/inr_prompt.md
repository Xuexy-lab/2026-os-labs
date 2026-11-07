[Prompt]
**任务**
- 完成中断处理模块 void interrupt_handler(struct trapframe *tf)，根据 Trap 原因正确分类和处理中断。

**操作要求**
- 直接修改并保存项目中的 kern/trap/trap.c，保持原有架构。

**输出要求**
- 简要说明修改位置和验证结果，未运行的测试如实注明。

[rely]
1. 宏定义：
- IRQ_S_TIMER：S 模式时钟中断编号。
- TICK_NUM：每累计多少次时钟中断输出一次统计信息。
- SHUTDOWN_AFTER：累计输出多少次统计信息后关机。
- 其他中断编号复用框架已有宏。阈值和输出格式以实验要求及测试为准；若关机阈值缺失，不自行猜测。

2. 数据结构与变量：
- 复用 struct trapframe，通过 tf->cause 提取中断编号。
- 复用 ticks，记录已处理的时钟中断次数。
- 保持 tf->epc 和其他现场字段不变。

3. 已有函数：
- trap_dispatch()：沿用已有分发逻辑，由它将中断交给 interrupt_handler()。
- clock_set_next_event()：安排下一次时钟事件。
- 复用框架已有的统计和提示输出接口。
- print_trapframe(tf)：输出完整 Trap 现场。
- sbi_shutdown()：使用 libs/sbi.h 提供的关机接口。

4. 修改范围：
- 仅实现 interrupt_handler() 及必要的局部辅助定义。
- 不修改函数签名、TrapFrame 布局、分发与恢复流程，以及其他函数或模块。

[GUARANTEE]
- 实现 void interrupt_handler(struct trapframe *tf)。
- 正确处理时钟中断、其他已知中断和未知中断。
- 未关机时正常返回统一 Trap 恢复流程，保留原执行流的返回位置。

[SPECIFICATION]
1. 中断识别：
- 从 tf->cause 中去除表示“中断”的最高标志位，提取具体中断编号。
- 使用局部变量保存编号，不修改 tf->cause。

2. 时钟中断：
- 识别 IRQ_S_TIMER 后，调用 clock_set_next_event()，设置下一次时钟事件。
- 每处理一次时钟中断，ticks 恰好增加一次。
- 当更新后的 ticks 达到 TICK_NUM 的整数倍时，按规定格式输出一次统计信息。
- 累计输出达到 SHUTDOWN_AFTER 后，先完成该次输出，再调用 sbi_shutdown()。关机条件按输出次数判断。

3. 其他中断：
- 已知中断按类型输出框架要求的提示。
- 未知中断调用 print_trapframe(tf) 输出完整现场。
- 非时钟中断不更新 ticks，不重新设置时钟事件。

4. 返回位置与 PC：
- 保持 tf->epc 不变，不跳过原执行流中的指令。
- 正常返回后，由 RESTORE_ALL 将 tf->epc 写回 sepc，再由 sret 令 PC = sepc，从原定位置继续执行。
- 不直接修改硬件 sepc，不自行恢复上下文、执行 sret 或改变返回特权级。

5. 验收条件：
- 时钟中断能够持续按期触发，计数、输出和关机条件符合要求。
- 其他中断能够正确区分并输出提示或完整现场。
- 正常返回时不破坏被打断执行流的寄存器与返回状态。