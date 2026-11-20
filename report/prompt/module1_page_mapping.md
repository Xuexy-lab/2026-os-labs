# 功能模块一：虚拟内存页操作功能

来源：`report/report.md` 第四部分对应模块的“最终提示词”。

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
