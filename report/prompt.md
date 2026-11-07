# Lab3 提示词汇总

按模块收录实验报告中的最终提示词和独立提示词文件的原文。

## Trap 入口与上下文恢复

### 实验报告中的最终提示词

来源为[实验报告](report.md)第四节。

``` text
[PROMPT]

任务：
完成 Lab3 功能模块一：Trap 上下文恢复与 Trap 入口功能。

需要修改 kern/trap/trapentry.S，补充 RESTORE_ALL 和 __alltraps 两处代码。

本模块主要完成 Trap 发生后的上下文恢复，以及汇编代码到 C 语言处理函数 trap(struct trapframe *tf) 的调用衔接，使系统能够完成 Trap 进入、保存上下文、处理 Trap、恢复上下文和返回的完整过程。

操作要求：
1. 直接修改项目中的实际文件，不要只给出代码。
2. 修改前先阅读相关代码，主要包括 trapentry.S、trap.h、trap.c、riscv.h，以及相关测试文件。
3. 以当前项目的实际代码为准，不要直接套用其他版本的 ucore。
4. 只修改 trapentry.S 中两个标记为 lab3 function1 YOUR CODE 的位置。
5. 保留已经完成的 SAVE_ALL、struct trapframe、trap() 和原有的返回流程，不要修改其他功能模块的代码。

输出要求：
完成后检查代码是否与现有的上下文保存方式、TrapFrame 布局和 RISC-V 函数调用约定一致，并尽可能进行编译和测试。最后说明修改了哪些位置、实现了什么功能，以及实际进行了哪些检查。

[RELY]

1. 当前项目使用 RISC-V 64 位架构，libs/riscv.h 中已经定义了 LOAD、STORE 和 REGBYTES 等宏，可以直接使用。

2. trapentry.S 中已经实现 SAVE_ALL，负责保存 Trap 发生时的通用寄存器和相关 CSR。执行完成后，sp 指向 TrapFrame 的起始位置。

3. struct trapframe 定义在 kern/trap/trap.h 中，包含通用寄存器以及 status、epc、badvaddr、cause 等字段。需要结合实际结构体定义确定各字段的偏移，保证汇编访问顺序与 C 语言结构体布局一致。

4. C 语言处理函数已经存在，接口为：
void trap(struct trapframe *tf);

5. 根据 RISC-V 函数调用约定，第一个参数通过 a0 传递，函数调用使用 ra 保存返回地址，sp 用作栈指针，调用前需要满足 16 字节对齐要求。

6. 当前 trapentry.S 已经提供了基本流程：
__alltraps -> SAVE_ALL -> 调用 trap() -> __trapret -> RESTORE_ALL -> sret

[GUARANTEE]

本次需要完成两个部分：

1. RESTORE_ALL：根据 TrapFrame 中保存的信息恢复需要恢复的通用寄存器和相关 CSR。

2. __alltraps：将当前 TrapFrame 的地址作为参数传递给 trap()，并保证函数返回后能够正确进入 __trapret。

不得修改 SAVE_ALL、struct trapframe 和 trap() 的接口，也不要修改其他模块。

[SPECIFICATION]

1. RESTORE_ALL

Pre-Condition：
SAVE_ALL 已经完成上下文保存，当前 sp 指向有效的 TrapFrame。C 语言处理函数可能会修改 TrapFrame 中的部分内容。

Post-Condition：
正确恢复 Trap 发生前的寄存器状态和返回所需的 CSR，最终能够通过 sret 正确返回。

具体要求：
- 恢复的寄存器和 CSR 必须与 SAVE_ALL 的保存布局对应，不能遗漏需要恢复的寄存器。
- 注意 sp 的特殊处理，必须在不再需要访问 TrapFrame 后再恢复原始 sp。
- 如果恢复过程中使用了临时寄存器，也必须保证其原始值能够正确恢复。
- sstatus 和 sepc 必须使用 TrapFrame 中当前保存的值，不能忽略 C 语言处理函数对它们的修改。
- 不要擅自修改返回地址或跳过触发 Trap 的指令。

2. __alltraps

Pre-Condition：
SAVE_ALL 已经执行完毕，当前 sp 指向 TrapFrame 的起始位置。

Post-Condition：
将当前 TrapFrame 正确传递给 trap(struct trapframe *tf)，处理函数返回后继续进入 __trapret。

具体要求：
- 正确传递 TrapFrame 地址，不能传递错误的指针。
- 调用 trap() 前保证 sp 正确，并满足 RISC-V 64 位函数调用约定的栈对齐要求。
- trap() 返回后，sp 必须仍然指向原来的 TrapFrame，不能因为函数调用导致栈指针发生偏移。
- 保证原有的寄存器信息不会因为函数调用而丢失。

验证要求：

1. 阅读 tools/test_lab3_context.S，了解其中对通用寄存器保存和恢复的测试。
2. 阅读 tools/test_lab3.c，了解 test_lab3_exception_context() 的调用过程。
3. 阅读 tools/grade.sh，了解 Test 1 的具体验收要求。
4. 修改完成后检查代码，确认只修改了指定的两个位置。
5. 尽可能单独进行汇编编译检查，再根据项目实际情况尝试完整编译或测试。
6. 如果完整测试因为 Lab2 代码尚未迁移或其他功能模块尚未完成而无法通过，不要擅自修改其他模块，应说明具体原因。

最后说明代码修改情况、实现思路和实际测试结果。没有实际执行的测试不要声称已经通过。
```

### 独立提示词

来源为 [trapentry_prompt.md](prompt/trapentry_prompt.md)。

```text
[PROMPT]

任务：
完成 Lab3 功能模块一：Trap 上下文恢复与 Trap 入口功能。

需要修改 kern/trap/trapentry.S，补充 RESTORE_ALL 和 __alltraps 两处代码。

本模块主要完成 Trap 发生后的上下文恢复，以及汇编代码到 C 语言处理函数 trap(struct trapframe *tf) 的调用衔接，使系统能够完成 Trap 进入、保存上下文、处理 Trap、恢复上下文和返回的完整过程。

操作要求：
1. 直接修改项目中的实际文件，不要只给出代码。
2. 修改前先阅读相关代码，主要包括 trapentry.S、trap.h、trap.c、riscv.h，以及相关测试文件。
3. 以当前项目的实际代码为准，不要直接套用其他版本的 ucore。
4. 只修改 trapentry.S 中两个标记为 lab3 function1 YOUR CODE 的位置。
5. 保留已经完成的 SAVE_ALL、struct trapframe、trap() 和原有的返回流程，不要修改其他功能模块的代码。

输出要求：
完成后检查代码是否与现有的上下文保存方式、TrapFrame 布局和 RISC-V 函数调用约定一致，并尽可能进行编译和测试。最后说明修改了哪些位置、实现了什么功能，以及实际进行了哪些检查。

[RELY]

1. 当前项目使用 RISC-V 64 位架构，libs/riscv.h 中已经定义了 LOAD、STORE 和 REGBYTES 等宏，可以直接使用。

2. trapentry.S 中已经实现 SAVE_ALL，负责保存 Trap 发生时的通用寄存器和相关 CSR。执行完成后，sp 指向 TrapFrame 的起始位置。

3. struct trapframe 定义在 kern/trap/trap.h 中，包含通用寄存器以及 status、epc、badvaddr、cause 等字段。需要结合实际结构体定义确定各字段的偏移，保证汇编访问顺序与 C 语言结构体布局一致。

4. C 语言处理函数已经存在，接口为：
void trap(struct trapframe *tf);

5. 根据 RISC-V 函数调用约定，第一个参数通过 a0 传递，函数调用使用 ra 保存返回地址，sp 用作栈指针，调用前需要满足 16 字节对齐要求。

6. 当前 trapentry.S 已经提供了基本流程：
__alltraps -> SAVE_ALL -> 调用 trap() -> __trapret -> RESTORE_ALL -> sret

[GUARANTEE]

本次需要完成两个部分：

1. RESTORE_ALL：根据 TrapFrame 中保存的信息恢复需要恢复的通用寄存器和相关 CSR。

2. __alltraps：将当前 TrapFrame 的地址作为参数传递给 trap()，并保证函数返回后能够正确进入 __trapret。

不得修改 SAVE_ALL、struct trapframe 和 trap() 的接口，也不要修改其他模块。

[SPECIFICATION]

1. RESTORE_ALL

Pre-Condition：
SAVE_ALL 已经完成上下文保存，当前 sp 指向有效的 TrapFrame。C 语言处理函数可能会修改 TrapFrame 中的部分内容。

Post-Condition：
正确恢复 Trap 发生前的寄存器状态和返回所需的 CSR，最终能够通过 sret 正确返回。

具体要求：
- 恢复的寄存器和 CSR 必须与 SAVE_ALL 的保存布局对应，不能遗漏需要恢复的寄存器。
- 注意 sp 的特殊处理，必须在不再需要访问 TrapFrame 后再恢复原始 sp。
- 如果恢复过程中使用了临时寄存器，也必须保证其原始值能够正确恢复。
- sstatus 和 sepc 必须使用 TrapFrame 中当前保存的值，不能忽略 C 语言处理函数对它们的修改。
- 不要擅自修改返回地址或跳过触发 Trap 的指令。

2. __alltraps

Pre-Condition：
SAVE_ALL 已经执行完毕，当前 sp 指向 TrapFrame 的起始位置。

Post-Condition：
将当前 TrapFrame 正确传递给 trap(struct trapframe *tf)，处理函数返回后继续进入 __trapret。

具体要求：
- 正确传递 TrapFrame 地址，不能传递错误的指针。
- 调用 trap() 前保证 sp 正确，并满足 RISC-V 64 位函数调用约定的栈对齐要求。
- trap() 返回后，sp 必须仍然指向原来的 TrapFrame，不能因为函数调用导致栈指针发生偏移。
- 保证原有的寄存器信息不会因为函数调用而丢失。

验证要求：

1. 阅读 tools/test_lab3_context.S，了解其中对通用寄存器保存和恢复的测试。
2. 阅读 tools/test_lab3.c，了解 test_lab3_exception_context() 的调用过程。
3. 阅读 tools/grade.sh，了解 Test 1 的具体验收要求。
4. 修改完成后检查代码，确认只修改了指定的两个位置。
5. 尽可能单独进行汇编编译检查，再根据项目实际情况尝试完整编译或测试。
6. 如果完整测试因为 Lab2 代码尚未迁移或其他功能模块尚未完成而无法通过，不要擅自修改其他模块，应说明具体原因。

最后说明代码修改情况、实现思路和实际测试结果。没有实际执行的测试不要声称已经通过。
```


## 中断处理

### 实验报告中的最终提示词

来源为[实验报告](report.md)第四节。

````markdown
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
````

### 独立提示词

来源为 [inr_prompt.md](prompt/inr_prompt.md)。

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

## 异常处理

### 实验报告中的最终提示词

来源为[实验报告](report.md)第四节。

```markdown
[Prompt]

**任务**
- 完成异常处理模块 void exception_handler(struct trapframe *tf)，根据 Trap 原因正确分类和处理异常。

**操作要求**
- 直接修改并保存项目中的 kern/trap/trap.c。

**输出要求**
- 简要说明修改位置和验证结果，未运行的测试如实注明。

[RELY]

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
```

### 独立提示词

来源为 [exc_prompt.md](prompt/exc_prompt.md)。

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
