# 功能模块三：进程调度

来源：`report/report.md` 第四部分对应模块的“最终提示词”。

````text
[PROMPT]

任务：完成 Lab4 的进程调度功能，使系统能够从进程链表中选择可运行的内核线程，并通过上下文切换使不同线程真正运行起来。

涉及文件及功能：
1. kern/process/proc.c：实现 cpu_idle() 和 proc_run()。
2. kern/schedule/sched.c：实现 schedule()。
3. kern/process/switch.S：实现 switch_to()。

操作要求：
必须直接修改项目中的实际文件，只允许在上述三个文件中对应的 //LAB4 function3 YOUR CODE 标记下方填写代码。

严格遵守以下要求：
- 只能在 function3 YOUR CODE 标记下方编写代码。
- 不允许修改标记区域之外的任何代码。
- 不允许修改其他文件，包括头文件。
- 不允许增加其他位置的函数、变量、宏或 include。
- 不允许修改其他功能的占位区域。
- 保留原有代码、注释、函数声明和标记。
- 不要新建文件。

输出要求：
直接进行文件操作，完成整个进程调度功能。使用下面的 RELY、GUARANTEE 和 SPECIFICATION 中的信息，以工程中的实际定义为准，不要引入无关功能。

[RELY]

1. 数据结构（kern/process/proc.h）

struct context 保存进程切换需要的寄存器，包含：
ra、sp、s0、s1、s2、s3、s4、s5、s6、s7、s8、s9、s10、s11，共14个寄存器，类型均为 uintptr_t。

struct proc_struct 中与本功能有关的成员：
- state：进程状态
- runs：运行次数
- need_resched：是否需要重新调度
- context：进程上下文
- pgdir：页表根节点的物理地址
- list_link：进程链表节点

进程状态：
PROC_UNINIT、PROC_SLEEPING、PROC_RUNNABLE、PROC_ZOMBIE。

2. 全局变量和链表

- proc_list：所有进程的双向循环链表。
- current：当前运行的进程。
- idleproc：空闲进程。

已有链表接口：
list_next()、list_empty()、le2proc()。

3. 中断控制（kern/sync/sync.h）

已有接口：
local_intr_save(intr_flag)
local_intr_restore(intr_flag)

需要正确保存和恢复原来的中断状态，保证调度和进程切换过程的原子性。

4. 页表与 RISC-V 接口

- boot_pgdir_pa：内核页表根节点的物理地址。
- SATP_MODE_SV39：Sv39 分页模式，值为 8。
- RISCV_PGSHIFT：页偏移位数，值为 12。
- read_csr()、write_csr()：读取和写入 CSR。
- flush_tlb()：刷新 TLB。

本实验使用 RISC-V 64 位架构，proc_struct 中的 pgdir 保存页表根节点的物理地址。

satp 使用 Sv39 模式，MODE 位需要放在最高4位，PPN 由页表根物理地址右移 RISCV_PGSHIFT 得到。

注意：不要使用 libs/riscv.h 中的 lsatp()，它是 Sv32 遗留接口。页表切换可以参考 kern/mm/pmm.c 中 enable_paging() 的实现。

5. 上下文切换相关代码

项目中已有：
- forkret()：新线程第一次运行时的入口。
- forkrets()：将新线程的 trapframe 交给异常返回代码。
- __trapret：恢复 trapframe。
- kernel_thread_entry：进入内核线程实际执行函数。

新线程第一次运行时，需要保证原有的首次运行恢复链路能够正常工作。

[GUARANTEE]

必须实现以下四个函数，函数签名保持一致：

```c
void cpu_idle(void);
void schedule(void);
void proc_run(struct proc_struct *proc);
void switch_to(struct context *from, struct context *to);
```

对应文件：
- cpu_idle()、proc_run()：kern/process/proc.c
- schedule()：kern/schedule/sched.c
- switch_to()：kern/process/switch.S

只能在指定的 function3 YOUR CODE 区域完成上述函数，不允许增加其他辅助函数或修改公开接口。

[SPECIFICATION]

## 1. cpu_idle()

Pre-Condition：
当前运行的是已经初始化的空闲线程，进程管理结构已经建立。

Post-Condition：
空闲线程持续运行，在需要重新调度时主动让出 CPU，使其他可运行线程有机会执行。

Case 1：
当前线程不需要重新调度时，继续保持空闲循环。

Case 2：
当前线程需要重新调度时，调用 schedule()，调度返回后继续检查是否需要再次调度。

Requirements：
该函数不会正常返回。

## 2. schedule()

Pre-Condition：
进程链表已经初始化，当前进程和空闲进程有效，链表中的进程具有合法状态。

Post-Condition：
完成一次调度选择，将当前进程的 need_resched 清零，并选择合适的可运行进程交给 CPU 执行。

Case 1：
当前进程是 idleproc 时，从 proc_list 链表头开始查找其他处于 PROC_RUNNABLE 状态的进程。

Case 2：
当前进程不是 idleproc 时，从当前进程的下一个链表节点开始查找，按照循环链表顺序寻找下一个处于 PROC_RUNNABLE 状态的进程，实现轮转调度。

Case 3：
遍历完成后没有找到其他可运行进程时，使用 idleproc 作为保底进程。

Case 4：
选出的进程就是 current 时，不进行无意义的重复切换。

Requirements：
- 只能选择 PROC_RUNNABLE 状态的普通进程。
- 正确处理循环链表的头节点、尾节点和空链表情况，不能遗漏节点或无限循环。
- idleproc 作为没有其他可运行进程时的保底选择。
- 每次调度都应清除当前进程的 need_resched。
- 调度选择和切换过程必须保证原子性，正确处理临界区中的中断状态。
- 恢复进入 schedule 前的中断状态，不能无条件开启中断。
- 不额外引入优先级、时间片等其他调度策略。

## 3. proc_run()

Pre-Condition：
传入的进程控制块已经完成必要初始化，具有有效的进程上下文和页表信息。

Post-Condition：
目标进程成为当前运行进程，CPU 使用目标进程对应的页表，并恢复目标进程的执行现场。

Case 1：
目标进程就是当前进程时，不需要进行切换。

Case 2：
目标进程与当前进程不同时，完成当前进程和目标进程之间的切换，使目标进程成为新的 current。

Case 3：
目标进程切换后，CPU 使用其对应的 Sv39 页表，地址转换和 TLB 状态保持正确。

Requirements：
- 更新 current、切换页表和切换上下文的过程必须保持原子性。
- 正确处理 satp 的 Sv39 模式和物理页号，不能混淆物理地址与物理页号。
- 写入 satp 后正确刷新 TLB。
- 正确保存和恢复原来的中断状态。
- 不能破坏原进程的上下文和内核栈。
- 不要重新初始化目标进程的 context 或 trapframe。

## 4. switch_to()

Pre-Condition：
传入两个有效的 struct context，分别表示切换前和切换后的进程上下文。

Post-Condition：
切换前进程需要保存的寄存器状态得到保留，切换后进程的寄存器状态得到恢复，CPU 能够从新进程原来的执行位置继续运行。

Case 1：
普通进程切换时，能够正确保存旧进程的执行现场，并恢复新进程之前保存的现场，使其以后可以继续执行。

Case 2：
新线程第一次运行时，能够正确使用预先初始化的上下文进入 forkret，并继续完成原有的首次运行恢复过程。

Requirements：
- 保存和恢复的寄存器必须与 struct context 完全对应，包括 ra、sp、s0~s11。
- 严格按照结构体字段顺序确定寄存器偏移，不能出现错位。
- 当前工程使用 RV64，每个 uintptr_t 占8字节。
- 遵循 RISC-V 函数调用约定，只保存上下文切换所需要的寄存器，不要把整个 trapframe 当作 context 保存。
- 不要破坏新线程第一次运行所依赖的 ra 和 sp。
- 不要修改现有的 forkrets、__trapret 和 kernel_thread_entry。

[最终检查]

1. 检查四个函数是否全部实现，函数签名是否正确。
2. 检查所有新增代码是否严格位于三个 function3 YOUR CODE 标记下方。
3. 检查是否有任何标记区域以外的代码被修改。
4. 检查上下文结构体与汇编寄存器偏移是否一致。
5. 检查调度时的各种进程状态和链表边界。
6. 检查中断状态是否正确保存和恢复。
7. 检查 Sv39 页表切换和 TLB 刷新。
8. 检查新线程第一次运行的恢复链路。
9. 参考 tools/test_lab4.c 中的 test_lab4_schedule，检查多个线程是否都能获得运行机会。
10. 使用工程现有编译配置检查修改的 C 文件和汇编文件。如果完整构建或运行测试受到其他未完成代码的影响，说明具体原因，不要修改允许范围以外的代码。

完成后简要说明修改的文件、实现的功能、编译和测试结果，以及尚未验证的内容。
````
