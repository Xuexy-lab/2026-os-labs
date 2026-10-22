#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <riscv.h>
#include <dtb.h>

// virtual address of physical page array
struct Page *pages;
// amount of physical memory (in pages)
size_t npage = 0;
// the kernel image is mapped at VA=KERNBASE and PA=info.base
uint64_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
// DRAM_BASE defined in riscv.h as 0x80000000
const size_t nbase = DRAM_BASE / PGSIZE;

// virtual address of boot-time page directory
uintptr_t *satp_virtual = NULL;
// physical address of boot-time page directory
uintptr_t satp_physical;

// physical memory management
const struct pmm_manager *pmm_manager;


static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &default_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
}

//lab2 function1 YOUR CODE
/* page_init - probe the physical memory from the device tree, build the Page
 * descriptor array and register every complete free physical page to the
 * current pmm manager.
 *
 * Memory layout (physical addresses; `end`/`pages` are kernel VAs, translate
 * them with PADDR() to obtain the physical addresses shown below):
 *   [DRAM_BASE, KERNEL_BEGIN_PADDR)    OpenSBI               -> reserved
 *   [KERNEL_BEGIN_PADDR, end_pa)       kernel image          -> reserved
 *   [pages_pa, descriptor_end)         Page descriptor array -> reserved
 *   [freemem, npage*PGSIZE)            complete free pages   -> init_memmap
 *
 * Everything below freemem (OpenSBI, kernel, descriptors and the page-alignment
 * gap) stays reserved.
 */
static void page_init(void) {
    extern char end[];

    uint64_t mem_base = get_memory_base();
    uint64_t mem_size = get_memory_size();

    // The kernel image is loaded at PA KERNEL_BEGIN_PADDR and mapped at VA
    // KERNBASE, so every kernel VA maps to its PA via VA - PHYSICAL_MEMORY_OFFSET.
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;

    // The device tree must report exactly the fixed DRAM base; any other base is
    // incompatible with the kernel's fixed loading layout.
    if (mem_base != DRAM_BASE || mem_size == 0) {
        panic("page_init: incompatible memory layout (base=0x%lx, size=0x%lx)",
              (unsigned long)mem_base, (unsigned long)mem_size);
    }
    uint64_t mem_end = mem_base + mem_size;
    if (mem_end < mem_base) {  // address overflow
        panic("page_init: memory range overflow");
    }

    // Respect the kernel's supported physical-memory upper bound: never manage
    // pages beyond the mapped/addressable range.
    if (mem_end > PHYSICAL_MEMORY_END) {
        cprintf("page_init: memory end 0x%lx exceeds PHYSICAL_MEMORY_END, clamping\n",
                (unsigned long)mem_end);
        mem_end = PHYSICAL_MEMORY_END;
    }

    // The (possibly clamped) range must still cover the kernel image.
    if (mem_end <= KERNEL_BEGIN_PADDR) {
        panic("page_init: memory does not cover the kernel image (end=0x%lx)",
              (unsigned long)mem_end);
    }

    // npage is the exclusive upper bound of the managed physical page numbers;
    // pages[0] describes PPN nbase, so the array covers PPN in [nbase, npage).
    npage = mem_end / PGSIZE;
    if (npage <= nbase) {
        panic("page_init: no manageable physical memory");
    }

    // Place the descriptor array right after the kernel image, page-aligned.
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    // Check the descriptor array fits before writing it, so a too-large array
    // never causes an out-of-bounds write followed by a panic.
    uintptr_t descriptor_end =
        PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
    if (descriptor_end > mem_end) {
        panic("page_init: not enough memory for page descriptors");
    }

    // Give every descriptor a well-defined state and reserve it. Free pages are
    // unreserved and finalized later by init_memmap().
    for (size_t i = 0; i < npage - nbase; i++) {
        struct Page *p = pages + i;
        p->ref = 0;
        p->flags = 0;
        p->property = 0;
        SetPageReserved(p);
    }

    // Free memory is [freemem, npage*PGSIZE): only complete pages after the
    // descriptor array. npage*PGSIZE (== ROUNDDOWN(mem_end, PGSIZE)) drops any
    // trailing partial page, so a partial page is never handed to the allocator.
    uintptr_t freemem = ROUNDUP(descriptor_end, PGSIZE);
    uintptr_t managed_end = (uintptr_t)npage * PGSIZE;

    // Register the contiguous run of complete free pages. They are still marked
    // reserved here, which matches the allocator's contract: init_memmap()
    // asserts the pages are reserved and then clears their flags.
    if (freemem < managed_end) {
        size_t free_base = PPN(freemem) - nbase;
        init_memmap(pages + free_base, npage - nbase - free_base);
    }

    cprintf("physical memory: base=0x%lx size=0x%lx end=0x%lx\n",
            (unsigned long)mem_base, (unsigned long)mem_size,
            (unsigned long)mem_end);
    cprintf("page_init: npage=0x%lx pages=0x%016lx freemem=0x%lx\n",
            (unsigned long)npage, (uintptr_t)pages, (unsigned long)freemem);
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    // First we should init a physical memory manager(pmm) based on the framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();

    extern char boot_page_table_sv39[];
    satp_virtual = (pte_t*)boot_page_table_sv39;
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}
