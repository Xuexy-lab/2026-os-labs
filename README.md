# 2026-os-labs
## 大二上操作系统实验作业汇总
### 文件分布说明：
- 一个分支对应一次实验，并以 `labx` 命名，例如 `lab1`、`lab2`。
- 每个分支包含 `code` 和 `report` 两个文件夹。
- `code`：对应实验实现后的代码。
- `report`：实验报告 `report.md`、汇总提示词 `prompt.md`，以及测试截图目录 `images/`。

# Lab2 — 物理内存和页表

## 实验内容

在 Lab1 内核启动的基础上，完成物理内存初始化与分配，并通过调试理解 RISC-V Sv39 地址转换，主要包括：

- 通过设备树探测物理内存，初始化 `Page` 描述符并登记可分配物理页。
- 分析 First-Fit，实现 Best-Fit 连续物理页分配与回收。
- 实现 Buddy System，完成按阶分配、块拆分及伙伴合并。
- 扩展简化 SLUB，在 Buddy 之上通过 `kmalloc`、`kfree` 管理不同大小的内存对象。
- 使用双 GDB 调试 QEMU 与 uCore，观察 `satp`、页表项及 Sv39 地址转换过程。

## 内存管理流程

```text
设备树提供 RAM 范围
    ↓
page_init：建立 Page 描述符，保留已占用页面
    ↓
pmm_manager：注册并管理空闲物理页
    ↓
页级分配：First-Fit / Best-Fit / Buddy System
    ↓
Buddy + SLUB：页块管理 → 按字节分配和释放对象
```

当前代码在 `kern/mm/pmm.c` 中选择 `slub_pmm_manager`，由 Buddy 提供底层物理页管理，并依次执行 Buddy 与 SLUB 自检。

## 运行与调试

准备 Linux / WSL、RISC-V 交叉工具链、QEMU 与 GDB，在 `code/` 目录执行：

```bash
make          # 编译
make qemu     # 运行
make debug    # 启动调试模式
make gdb      # 连接内核调试器
make grade    # 执行评分脚本
```

`Makefile` 中的默认 QEMU 路径对应本地实验环境，其他环境可通过命令行覆盖：

```bash
make qemu QEMU=/path/to/qemu-system-riscv64
make debug QEMU=/path/to/qemu-system-riscv64
```

报告记录了物理页初始化、Best-Fit、Buddy 的运行截图、Best-Fit 评分结果，以及 Sv39 地址转换调试：虚拟地址 `0xffffffffc0204000` 通过 1 GiB 大页映射到物理地址 `0x80204000`。具体测试条件与结果见实验报告。

## 项目目录

```text
lab2/
├── README.md
├── code/                  # 实验代码与本地构建产物
│   ├── kern/              # 内核、物理内存分配器与 SLUB
│   ├── libs/              # 公共库与 RISC-V 支持
│   ├── tools/             # 链接、调试与测试工具
│   ├── bin/               # 本地内核镜像
│   ├── obj/               # 本地编译及反汇编产物
│   └── Makefile
└── report/
    ├── report.md          # 实验报告
    ├── prompt.md          # 本实验提示词汇总
    ├── prompt/            # 保留的分模块提示词
    └── images/            # 实验报告图片与测试截图
```

## 参考

详细实现、测试截图与双 GDB 调试过程见 [实验报告](report/report.md)，AI 协作记录见 [提示词汇总](report/prompt.md)。
