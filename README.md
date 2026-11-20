# Lab4 — 进程管理

## 文件分布说明

- 一个分支对应一次实验，本分支为 `lab4`。
- `code/` 保存本次实验工程；`report/` 保存实验报告、提示词和两张测试截图。

## 实验内容

基于 RISC-V 64 位 uCore，实现共享内核地址空间的内核线程管理：

- **虚拟内存页操作**：通过 `page_insert()`、`page_remove()` 建立、更新和撤销映射，维护物理页引用计数及 TLB。
- **进程创建与初始化**：初始化 PCB 和进程管理结构，创建 `idleproc`、`initproc`，准备内核栈、TrapFrame 和 context，并处理创建失败时的资源回收。
- **进程调度**：按进程链表顺序选择可运行线程，通过页表设置和寄存器上下文切换使线程运行，并保存、恢复临界区中断状态。

## 主要流程

```text
内存与中断等基础初始化
    ↓
proc_init：建立进程管理结构，创建 idleproc 和 initproc
    ↓
cpu_idle → schedule → proc_run → switch_to
    ↓
新线程首次运行：forkret → forkrets → __trapret → kernel_thread_entry
```

## 运行与调试

在具备 GNU Make、RISC-V 交叉工具链、QEMU、Python 3 和常用 Unix 工具的 Linux/WSL 环境中，于 `code/` 目录执行：

```bash
make          # 编译内核
make qemu     # 在 QEMU Virt Machine 中启动
make grade    # 注入并运行实验评分测试
make debug    # 启动 QEMU，等待 GDB 连接
make gdb      # 在另一终端连接调试器
```

默认工具链前缀为 `riscv64-unknown-elf-`，默认模拟器为 `qemu-system-riscv64`，可通过 `GCCPREFIX`、`QEMU` 覆盖，例如 `make GCCPREFIX=/path/to/bin/riscv64-unknown-elf- qemu`。`make gdb` 中的调试器命令为固定名称，需要位于 `PATH` 中。

报告记录了内存管理相关自检通过、`initproc` 成功运行，以及 PMM、进程创建、进程调度三项评分均为 `OK`，总分为 **30/30**。截图同时记录了线程入口函数指针类型警告，以及普通启动在线程退出时触发的 `process exit!!` panic；当前工程的 `do_exit()` 仍以该 panic 作为占位实现。本次上传未重新执行构建、QEMU 或评分测试。

## 项目目录

```text
README.md
code/
├── Makefile
├── CMakeLists.txt
├── kern/              # 内核初始化、内存管理、线程与调度等实现
├── libs/              # 公共库与 RISC-V 接口
└── tools/             # 链接、调试、评分及测试注入工具
report/
├── report.md          # 完整实验报告
├── prompt.md          # 三个模块的提示词汇总
├── images/
│   ├── lab4_qemu.png
│   └── lab4_grade.png
└── prompt/
    ├── module1_page_mapping.md
    ├── module2_process_creation.md
    └── module3_scheduling.md
```

## 报告与提示词

- [实验报告](report/report.md)
- [提示词汇总](report/prompt.md)
- [模块一提示词](report/prompt/module1_page_mapping.md)
- [模块二提示词](report/prompt/module2_process_creation.md)
- [模块三提示词](report/prompt/module3_scheduling.md)
