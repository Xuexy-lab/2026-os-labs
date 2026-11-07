[Prompt]
**任务**
- 完成异常处理模块 void exception_handler(struct trapframe *tf)，根据 Trap 原因正确分类和处理异常。

**操作要求**
- 直接修改并保存项目中的 kern/trap/trap.c。

**输出要求**
- 简要说明修改位置和验证结果，未运行的测试如实注明。

[rely]
1. 宏定义：
- CAUSE_ILLEGAL_INSTRUCTION：非法指令异常。
- CAUSE_BREAKPOINT：断点异常。

2. 数据结构：
- 复用 struct trapframe，不修改布局。
- tf->cause：判断异常类型。
- tf->epc：读取和调整 Trap 返回位置。

3. 已有函数：
- print_trapframe(tf)：输出完整现场。
- cprintf() 等已有输出接口。
- 具体定义和输出格式以框架及测试要求为准。

4. 修改范围：
- 仅修改 exception_handler() 及必要的局部辅助定义。
- 不修改函数签名、已有分发逻辑、其他函数或内核模块。

[GUARANTEE]
- 实现 void exception_handler(struct trapframe *tf)。
- 正确处理非法指令、断点及其他异常，并与统一 Trap 返回流程衔接。
- 除规定的 tf->epc 调整外，保持其他现场不变。

[SPECIFICATION]
1. 非法指令异常：
- 按规定格式输出 “Illegal instruction at ...”，包含调整前的异常地址。
- 根据实际指令长度更新 tf->epc，跳过触发指令。

2. 断点异常：
- 按规定格式输出 “Breakpoint at ...”，包含调整前的断点地址。
- 区分 16 位压缩断点和 32 位普通断点，分别增加 2 或 4 字节。

3. 指令长度：
- 根据实际编码判断实验涉及的 16/32 位指令长度。
- 不按异常类型固定长度，不统一增加固定偏移。

4. 其他异常：
- 调用 print_trapframe(tf)，保持 tf->epc 不变，不额外实现恢复策略。

5. 返回位置与 PC：
- 设触发异常的指令地址为 A，指令长度为 L。
- 对本实验要求跳过的非法指令和断点异常，将 tf->epc 更新为 A + L；其他异常保持不变。
- 修改 tf->epc 不会立即改变 PC，处理函数仍正常执行并返回。
- 后续 RESTORE_ALL 将 tf->epc 写回 sepc，sret 再令 PC = sepc，使指定异常返回后执行下一条指令。
- 不直接修改硬件 sepc，不自行恢复上下文、执行 sret 或改变返回特权级。

6. 验收条件：
- 输出符合规定格式。
- 指定异常返回后继续执行下一条指令，不反复触发同一异常。
- 其他异常输出现场且不改变返回位置。
- 不破坏被打断执行流的寄存器与返回状态。