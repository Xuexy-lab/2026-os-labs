# 功能模块二：进程创建及初始化功能

来源：`report/report.md` 第四部分对应模块的“最终提示词”。

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
