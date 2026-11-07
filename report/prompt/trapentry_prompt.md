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
