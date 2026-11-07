# Lab3 — uCore 中断与异常处理

本仓库每次操作系统实验使用独立分支。Lab3 的工程位于 `code/`，实验报告、提示词和截图位于 `report/`。

## 实验内容

- **Trap 入口与返回**。通过 `stvec` 注册统一入口，由 `trapentry.S` 将现场保存到栈上的 `trapframe`，处理结束后恢复寄存器并执行 `sret`。
- **时钟中断**。`trap.c` 根据 `scause` 分发 Trap。S 态时钟中断会安排下一次时钟事件并累加 `ticks`，每 100 次输出一次计数信息。
- **异常处理**。断点和非法指令异常会打印触发地址，根据实验涉及的 16 位或 32 位指令长度推进 `tf->epc`，由统一返回流程跳过触发指令。

## 处理流程

```text
中断或异常 → stvec → __alltraps → SAVE_ALL
  → trap() → trap_dispatch() → 中断或异常处理函数
  → RESTORE_ALL → sret
```

## 运行与调试

准备 RISC-V 裸机工具链、QEMU、GNU Make 和 Python 3，在 Linux 或 WSL 的 `code/` 目录执行：

```bash
make          # 构建内核
make qemu     # 启动并观察时钟中断输出
make grade    # 运行实验评测
make debug    # 启动 QEMU 并等待 GDB
make gdb      # 在另一终端连接 GDB
```

Makefile 默认使用 `riscv64-unknown-elf-` 工具链前缀和 `qemu-system-riscv64`。可通过 `make GCCPREFIX=<前缀> QEMU=<可执行文件路径>` 覆盖编译工具和 QEMU。使用 `make gdb` 时，确保 `riscv64-unknown-elf-gdb` 在 PATH 中。

报告附有 QEMU 和评测截图。评测脚本覆盖 Trap 入口与断点返回、非法指令与异常分发，以及持续的时钟中断。

## 项目目录

```text
.
├── code/
│   ├── kern/              # 内核，包括 Trap、时钟与内存管理
│   ├── libs/              # 公共库
│   ├── tools/             # 链接脚本、调试与 Lab3 评测
│   └── Makefile
└── report/
    ├── report.md          # Lab3 实验报告
    ├── prompt.md          # Lab3 提示词汇总
    ├── prompt/            # 独立提示词
    └── images/            # 报告图片与截图
```

- [实验报告](report/report.md)
- [提示词汇总](report/prompt.md)
