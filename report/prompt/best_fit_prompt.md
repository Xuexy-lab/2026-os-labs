[PROMPT]

**任务：**

结合已经经过修改的pmm.c文件，参考 `kern/mm/default_pmm.c` 中的 First-Fit 实现，在 `kern/mm/best_fit_pmm.c` 中实现完整的 Best-Fit 连续物理内存分配器，并在 `kern/mm/pmm.c` 中启用该管理器。

**操作要求：**

1. 必须直接修改项目中的实际文件，而不是仅输出代码。
2. 在 `best_fit_pmm.c` 标记为 `lab2` 和 `YOUR CODE` 的位置补全实现，保留 `lab2` 注释，将 `YOUR CODE` 替换为 `[我的学号]`。
3. 不得修改 `basic_check()` 和 `best_fit_check()` 的任何代码。
4. 除切换物理内存管理器所需的代码外，不得修改 `pmm.c` 的其他逻辑。
5. 可以参考 First-Fit 的初始化、回收和合并逻辑，但分配策略必须改为 Best-Fit。
6. 不引入无关功能，不修改测试标准。

**输出要求：**

完成文件修改后，说明新增的函数、主要实现逻辑和修改位置，并运行项目现有的编译与测试命令进行验证。若测试失败，分析原因并修复，不得通过修改测试函数使测试通过。

[RELY]

请先阅读项目中的以下文件，以真实代码为准：

- `kern/mm/default_pmm.c`：参考 First-Fit 的完整实现。
- `kern/mm/best_fit_pmm.c`：确认需要补全的位置及现有测试。
- `kern/mm/pmm.h`：读取 `struct Page`、`struct pmm_manager` 及相关接口。
- `kern/mm/best_fit_pmm.h`：确认 Best-Fit 管理器的声明。
- `kern/mm/pmm.c`：检查 `init_pmm_manager()` 的实现。
- `libs/list.h` 或项目中实际对应的 `list.h`：确认双向链表操作接口。

本模块需要使用以下结构和机制：

1. `free_area_t`：保存空闲链表及空闲页总数。
2. `struct Page`：通过 `property` 记录空闲块大小，通过 `PG_property` 标记空闲块头页，通过 `page_link` 连接链表。
3. `free_list`：按物理地址升序排列的双向循环链表。
4. `nr_free`：记录当前空闲物理页的总数。
5. `PageReserved()`、`PageProperty()`、`SetPageProperty()`、`ClearPageProperty()` 等页面状态操作。
6. `list_init()`、`list_add()`、`list_add_before()`、`list_del()` 等链表操作。
7. `basic_check()` 和 `best_fit_check()`：已有的正确性测试，其中直接访问 `free_list` 和 `nr_free`，实现必须符合这一状态约定。

所有数据结构、宏定义、函数签名及头文件路径均以项目源码为准，不得自行虚构接口。

[GUARANTEE]

在 `best_fit_pmm.c` 中实现以下主要接口：

```c
static void best_fit_init(void);

static void best_fit_init_memmap(struct Page *base, size_t n);

static struct Page *best_fit_alloc_pages(size_t n);

static void best_fit_free_pages(struct Page *base, size_t n);

static size_t best_fit_nr_free_pages(void);
```

同时定义并注册：

```c
const struct pmm_manager best_fit_pmm_manager;
```

管理器的 `check` 成员必须绑定现有 `best_fit_check()`，其他成员分别绑定对应的 Best-Fit 管理函数。

在 `pmm.c` 的 `init_pmm_manager()` 中，将当前管理器切换为 `best_fit_pmm_manager`，并确保相关声明可见。

允许增加必要的模块内部静态变量和辅助函数，但不改变公开接口。

[SPECIFICATION]

## 1. best_fit_init()

**Pre-Condition：**
- 物理内存管理器开始初始化。

**Post-Condition：**
- 空闲链表初始化为空。
- 空闲页总数为 0。

## 2. best_fit_init_memmap()

**Pre-Condition：**
- `base` 指向待初始化的连续物理页区域。
- `n > 0`，该区域包含 `n` 个可登记的物理页。
- 页面处于允许初始化的保留状态。

**Post-Condition：**
- 清空各页的管理信息和引用计数。
- 将 `base` 标记为空闲块头页，其 `property` 设置为 `n`。
- 将空闲块按照物理地址升序插入空闲链表。
- 空闲页总数增加 `n`。

## 3. best_fit_alloc_pages()

**Pre-Condition：**
- `n > 0`。
- 空闲链表及空闲页数量记录有效。

**Post-Condition：**
- 如果分配成功，返回连续 `n` 个物理页的起始 `Page` 指针，更新空闲链表及空闲页数量。
- 如果分配失败，返回 `NULL`，不改变空闲内存管理状态。

**Case 1：没有满足要求的空闲块**

遍历后不存在大小不小于 `n` 的连续空闲块，返回 `NULL`。即使总空闲页数足够，也不能将不连续的页面拼接成一个分配结果。

**Case 2：存在满足要求的空闲块**

遍历整个空闲链表，在所有大小不小于 `n` 的空闲块中选择大小最小的块。

如果存在多个同样大小的候选块，可以选择遍历时最先遇到的块。

**Case 3：选中的空闲块恰好等于 n**

直接分配整个空闲块，将它从空闲链表移除，并清除相应的空闲块头页标志。

**Case 4：选中的空闲块大于 n**

分配该块的前 `n` 页，将剩余连续页面组成新的空闲块，设置新的头页、空闲块大小及标志，并保持链表地址有序。

**Requirements：**
- 必须实现真正的 Best-Fit，而不是找到第一个合适空闲块就停止。
- 分配成功后 `nr_free` 减少 `n`。
- 不得破坏其他空闲块的链表关系。

## 4. best_fit_free_pages()

**Pre-Condition：**
- `base` 指向待回收的连续页面。
- `n > 0`。
- 待回收页面应满足合法回收条件。

**Post-Condition：**
- 清空待回收页面的管理状态及引用计数。
- 将回收区域重新登记为空闲块。
- 空闲页总数增加 `n`。
- 空闲链表保持地址升序。
- 与前后物理地址连续的空闲块完成合并。

**Case 1：不存在相邻空闲块**

将回收区域作为独立空闲块插入链表。

**Case 2：与前一个空闲块连续**

将回收区域合并到前一个空闲块，更新其 `property`，移除多余链表节点及头页标志。

**Case 3：与后一个空闲块连续**

将后一个空闲块合并到当前空闲块，更新其 `property`，移除后一个空闲块的节点及头页标志。

**Case 4：与前后两个空闲块均连续**

将三个区域合并为一个连续空闲块，并确保链表中只保留合并后空闲块的头页节点。

## 5. best_fit_nr_free_pages()

**Pre-Condition：**
- 分配器已经初始化。

**Post-Condition：**
- 返回当前空闲物理页总数，不改变管理器状态。

## 6. best_fit_pmm_manager 与 init_pmm_manager()

**Post-Condition：**
- `best_fit_pmm_manager` 的全部函数指针正确绑定。
- `check` 指向未经修改的 `best_fit_check()`。
- `init_pmm_manager()` 选择 Best-Fit 作为当前物理内存管理器。
- 内核运行时实际调用 Best-Fit 的分配与回收逻辑。

## 7. 测试与验证

1. 不得修改 `basic_check()` 和 `best_fit_check()`。
2. 保持 `free_list` 和 `nr_free` 与测试函数使用的状态约定一致。
3. 正确处理空闲块拆分、完全分配、回收和前后合并。
4. 通过现有测试验证 Best-Fit 是否优先选择能够满足请求的最小空闲块。
5. 运行项目支持的编译和测试命令，报告真实结果。
6. 如果测试失败，保留关键错误信息，分析并修复实现中的问题，不得绕过断言。
