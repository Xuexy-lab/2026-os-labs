# Lab4 提示词汇总

以下提示词均原文提取自 [实验报告](report.md) 第四部分，不包含本次报告整理或上传指令。

## 功能模块一：虚拟内存页操作功能

来源：实验报告第四部分对应模块；[独立提示词](prompt/module1_page_mapping.md)。

````text

[prompt]
**任务**
补全 `kern/mm/pmm.c` 中空缺的两个函数：
1. `int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm);`
2. `void page_remove(pde_t *pgdir, uintptr_t la);`

分别实现：将物理页映射到指定线性地址、安全撤销已有映射。

**操作要求**
直接修改项目中的实际文件，保留现有代码，只在标记位置补全，不修改其他函数。

**输出要求**
完成文件修改后，简要说明实现要点和验证结果；未运行的测试须明确标注。

[RELY]
- 复用已有接口：`get_pte()`、`pte_create()`、`page2ppn()`、`pte2page()`、`page_ref_inc()`、`page_ref_dec()`、`free_page()`、`tlb_invalidate()` 等。
- 使用现有类型和宏：`pde_t`、`pte_t`、`struct Page`、`PTE_V`、`PTE_U`、`PTE_W`、`PTE_R`。
- 先阅读相关接口定义，确认参数和返回值含义。

[GUARANTEE]
- `page_insert`：
  1. 原地址未映射：目标页引用计数加一。
  2. 原地址映射到同一物理页：引用计数不变，仅更新权限，避免误释放。
  3. 原地址映射到其他物理页：目标页引用计数加一；旧页引用计数减一，归零时释放。
  4. 成功后映射到目标页，权限按 `perm` 重新设置，不残留旧权限，返回 `0`。
  5. 获取页表项失败时返回 `-E_NO_MEM`，不改变目标页引用计数和已有映射。

- `page_remove`：
  1. 目标地址无映射时安静返回，不分配页表。
  2. 有映射时清空 PTE，使对应 TLB 条目失效；旧页引用计数减一，归零后释放。
  3. 返回类型为 `void`，无需返回错误码，也无需回收中间页表页。

[SPECIFICATION]
- 同步维护三个状态：PTE、物理页引用计数、TLB。
- 插入使用 `get_pte(pgdir, la, 1)`；删除使用 `get_pte(pgdir, la, 0)`。
- 使用 `pte_create()` 构造新 PTE，正确设置物理页号、有效位和权限。
- 映射或权限更新后，调用 `tlb_invalidate(pgdir, la)`。
- 重点检查：同页重复插入、替换旧页、多地址共享同一页、重复删除、页表分配失败。
````

## 功能模块二：进程创建及初始化功能

来源：实验报告第四部分对应模块；[独立提示词](prompt/module2_process_creation.md)。

````text
**任务：**

完成 Lab4 功能模块二：进程创建及初始化功能。

需要修改 `kern/process/proc.c`，实现以下六个函数：

```c
static struct proc_struct *alloc_proc(void);
void proc_init(void);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
static void copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf);
static int copy_mm(uint32_t clone_flags, struct proc_struct *proc);
```

本模块主要完成进程控制块的分配与初始化、内核线程的创建、内核栈及执行上下文的准备，以及进程登记和唤醒，使系统能够创建 `idleproc` 和 `initproc`，为后续进程调度提供基础。

**操作要求：**

1. 直接修改项目中的实际文件，不要只给出代码。
2. 修改前阅读 `proc.c`、`proc.h`、`entry.S`、`trap.h`、`pmm.h`、`memlayout.h`、`sched.c`、`switch.S` 等相关文件。
3. 以当前项目实际代码为准，不要直接套用其他版本的 uCore。
4. 主要修改 `proc.c` 中标记为 `LAB4 function2 YOUR CODE` 的位置，必要时补充头文件和函数声明。
5. 保留已经实现的内存管理、Trap 处理和进程调度代码，不修改其他功能模块。

**[RELY]**

1. 当前项目使用 RISC-V 64 位架构，已经完成物理内存管理、Sv39 页表及基本 Trap 处理机制。

2. `proc.h` 中已经定义 `struct proc_struct`、`struct context` 和进程状态枚举，可直接使用。

3. `proc.c` 中已经提供 `setup_kstack()`、`put_kstack()`、`get_pid()`、`hash_proc()`、`find_proc()`、`forkret()`、`init_main()` 等辅助函数。

4. 已有 `kmalloc()`、`kfree()`、`alloc_pages()`、`free_pages()`、`list_init()`、`list_add()`、`wakeup_proc()` 等内存分配与进程管理接口。

5. `entry.S` 中的 `kernel_thread_entry` 使用 `s0` 保存线程执行函数地址，`s1` 保存函数参数。

6. 新线程首次运行依赖 `switch_to -> forkret -> forkrets -> __trapret`，其中 `forkret()` 已经实现。

7. 当前实验仅要求创建内核线程，所有内核线程共享内核地址空间，不需要复制独立的用户地址空间。

**[GUARANTEE]**

本次需要完成六个函数：

1. `alloc_proc()`：分配并初始化进程控制块。
2. `proc_init()`：初始化进程管理结构，创建 `idleproc` 和 `initproc`。
3. `kernel_thread()`：将普通函数和参数封装为内核线程的初始执行现场。
4. `do_fork()`：完成新线程的资源分配、PID 分配、登记与唤醒。
5. `copy_thread()`：复制 TrapFrame 并初始化新线程的上下文。
6. `copy_mm()`：处理内核线程共享地址空间的初始化。

不得修改已有的 `proc_run()`、`cpu_idle()`、`schedule()`、`switch_to()` 等模块三函数，也不要实现超出本次实验要求的用户进程功能。

**[SPECIFICATION]**

**1. alloc_proc**

Pre-Condition：

内核堆分配器已经初始化，可以通过 `kmalloc()` 分配进程控制块。

Post-Condition：

返回完成基础初始化的 `proc_struct`，分配失败返回 `NULL`。

具体要求：

- 分配 PCB 并清零所有字段。
- 设置初始状态为 `PROC_UNINIT`、PID 为 `-1`。
- 初始化内核栈、地址空间、上下文、TrapFrame、调度标记等字段。
- 初始化进程链表和哈希链表节点。
- 设置有效的内核页表地址。

**2. proc_init**

Pre-Condition：

进程管理所依赖的内存管理和相关基础设施已经初始化。

Post-Condition：

成功建立 `idleproc`、`initproc` 和 `current`，完成进程管理全局结构初始化。

具体要求：

- 初始化 `proc_list` 和 `hash_list`。
- 创建 `idleproc`，设置 PID 为 0、状态为 `PROC_RUNNABLE`。
- 复用启动内核栈 `bootstack`，设置 `current = idleproc`。
- 设置 `idleproc->need_resched = 1`。
- 调用 `kernel_thread()` 创建执行 `init_main()` 的 `initproc`。
- 使用 `find_proc()` 找到新线程，设置名称并检查 PID。
- 正确维护 `nr_process`。

**3. kernel_thread**

Pre-Condition：

提供有效的内核线程入口函数 `fn` 和参数 `arg`。

Post-Condition：

完成初始 TrapFrame 构造，并调用 `do_fork()` 返回新线程 PID 或负错误码。

具体要求：

- 清零临时 `trapframe`。
- 将 `fn` 和 `arg` 分别保存到 `s0`、`s1` 对应字段。
- 设置 `epc` 指向 `kernel_thread_entry`。
- 正确设置 `sstatus` 中的 SPP、SPIE 和 SIE 位。
- 调用 `do_fork()` 创建共享内核地址空间的线程。

**4. do_fork**

Pre-Condition：

提供合法的创建标志、栈地址和 TrapFrame，内存分配及进程管理接口可用。

Post-Condition：

创建成功返回 PID，失败返回负错误码并释放已经申请的资源。

具体要求：

- 检查进程数量上限。
- 调用 `alloc_proc()` 分配 PCB。
- 设置父进程，申请内核栈。
- 调用 `copy_mm()` 和 `copy_thread()`。
- 通过 `get_pid()` 分配 PID。
- 将线程加入进程链表和 PID 哈希表。
- 更新进程数量，并使用 `wakeup_proc()` 将线程设置为 `PROC_RUNNABLE`。
- 在必要的临界区内关闭中断。
- 正确处理资源分配失败时的清理流程。

**5. copy_thread**

Pre-Condition：

新线程已分配内核栈，且存在有效的初始 TrapFrame。

Post-Condition：

新线程具备首次上下文切换和执行所需的 TrapFrame、context。

具体要求：

- 在新内核栈顶部安放 TrapFrame。
- 复制传入的 TrapFrame。
- 设置子线程返回值 `a0 = 0`。
- 正确设置新线程栈指针。
- 将 `context.ra` 设置为 `forkret`。
- 将 `context.sp` 设置为新 TrapFrame 的地址。
- 保证初始化布局与后续汇编恢复流程一致。

**6. copy_mm**

Pre-Condition：

当前实验只运行共享内核地址空间的内核线程。

Post-Condition：

新线程使用有效的内核地址空间，成功返回 0。

具体要求：

- 不进行用户地址空间复制。
- 将 `mm` 设置为 `NULL`。
- 设置线程的内核页表地址。
- 保留函数接口，供后续用户进程实验扩展。

**验证要求：**

1. 检查 `proc.h` 中的 PCB 字段是否全部初始化。
2. 检查 `entry.S` 和 `switch.S`，确认寄存器及 context 布局一致。
3. 检查 `trap.h` 和 Trap 返回汇编代码，确认 TrapFrame 字段与首次运行流程匹配。
4. 检查进程创建失败时是否存在资源泄漏。
5. 确认只修改模块二对应位置及必要的头文件引用。
6. 尽可能执行 `make` 和 QEMU 测试，检查 `initproc` 是否成功运行。
7. 如果其他模块未完成导致测试失败，不要擅自修改其他模块，应说明具体原因。

````

## 功能模块三：进程调度

来源：实验报告第四部分对应模块；[独立提示词](prompt/module3_scheduling.md)。

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

