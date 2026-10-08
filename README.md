# 2026-os-labs
## 大二上操作系统实验作业汇总
### 文件分布说明：
- 一个分支对应一次实验，并以`labx`命名
> 例如：`lab1`
- 每一个分支中两个文件夹，分别以`code`和`report`命名
 - code文件夹包含:
   - 对应实验的实现后的代码
 - report文件夹中包含:
   - 实验报告（markdown文件，以`report.md`命名）
   - 提示词（markdown文件，以`prompt.md`命名，汇总本实验所有的prompt）
   - 测试截图文件夹（以`images`命名，包含实验报告中提及的测试结果的截图）。
     
# Lab1 — RISC-V 内核启动

## 实验内容

基于 QEMU + OpenSBI 实现最小 uCore 内核，主要包括：

- 理解链接脚本、Makefile 与交叉编译过程。
- 分析 `kern_entry`、启动栈及 `kern_init`。
- 通过 SBI 实现控制台输出。
- 使用 GDB 跟踪 RISC-V 启动流程。

## 启动流程

```text
QEMU (0x1000)
    ↓
OpenSBI (0x80000000)
    ↓
kern_entry (0x80200000)
    ↓
设置启动栈 → kern_init
    ↓
BSS 清零 → SBI 输出 → 无限循环
```

## 运行与调试

在 `code/` 目录执行：

```bash
make          # 编译
make qemu     # 运行
make debug    # 启动调试模式
```

## 项目目录

```text
lab1/
├── code/              # 实验代码
└── report/
    ├── report.md      # 实验报告
    ├── prompt.md      # AI 提示词记录
    └── images/        # 测试截图
```

## 参考

详细实现与 GDB 调试记录见 [实验报告](report/report.md)。
