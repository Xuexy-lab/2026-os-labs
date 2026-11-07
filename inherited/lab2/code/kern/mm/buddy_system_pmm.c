#include <buddy_system_pmm.h>
#include <list.h>
#include <stdio.h>

/* Private flags, meaningful only while this manager is selected. Managed is
 * set on EVERY registered page, allocated on EVERY page of a live allocation.
 * Reserved/unregistered pages are never inspected for an order.
 *
 * Free head:      Property=1, Allocated=0, u>=0, property=2^u, linked once.
 * Allocated head: Property=0, Allocated=1, u>=0, property=2^u, unlinked.
 * Interior:      Property=0, u=-1, property=0, unlinked. Allocated distinguishes
 *                allocated interiors from free interiors.
 * Neither fit implementation uses these flags or u.
 */
#define BUDDY_MANAGED   (1UL << 2)
#define BUDDY_ALLOCATED (1UL << 3)
#define BUDDY_MAX_ORDER ((int)(sizeof(unsigned int) * 8 - 1))
#define BUDDY_NO_ORDER  (-1)

static free_area_t free_area;
#define free_list (free_area.free_list)
#define nr_free   (free_area.nr_free)

static size_t
block_pages(int u) {
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
    return (size_t)1 << u;
}

/* Check the descriptor address numerically BEFORE subtraction/dereference. */
static bool
valid_page(struct Page *p) {
    uintptr_t addr = (uintptr_t)p, first = (uintptr_t)pages;
    return npage > nbase && addr >= first &&
           (addr - first) % sizeof(struct Page) == 0 &&
           (addr - first) / sizeof(struct Page) < npage - nbase;
}

static bool
request_order(size_t n, int *u) {
    if (n == 0 || n > block_pages(BUDDY_MAX_ORDER) ||
        npage <= nbase || n > npage - nbase) {
        return 0;
    }
    *u = 0;
    while (block_pages(*u) < n) {
        ++*u;  /* bounded above before shifting; cannot overflow */
    }
    return 1;
}

static void
clear_head(struct Page *p) {
    ClearPageProperty(p);
    p->property = 0;
    p->u = BUDDY_NO_ORDER;
    assert(list_empty(&p->page_link));
}

static void
set_free_head(struct Page *p, int u) {
    assert((p->flags & BUDDY_MANAGED) && !PageReserved(p));
    assert(!(p->flags & BUDDY_ALLOCATED));
    assert(list_empty(&p->page_link));
    p->u = u;
    p->property = block_pages(u);
    SetPageProperty(p);
}

static void
insert_free(struct Page *p) {
    assert(PageProperty(p) && list_empty(&p->page_link));
    list_entry_t *le = list_next(&free_list);
    while (le != &free_list &&
           page2ppn(le2page(le, page_link)) < page2ppn(p)) {
        le = list_next(le);
    }
    list_add_before(le, &p->page_link);
}

/* The caller has already inserted p. Only a neighbour ON THIS LIST can merge:
 * this also keeps temporarily detached lists in check() completely isolated.
 * Two adjacent free buddy blocks certify the whole parent as managed; a gap,
 * reserved page or live allocation cannot be crossed.
 */
static void
merge_free(struct Page *p) {
    while (p->u < BUDDY_MAX_ORDER) {
        size_t size = block_pages(p->u);
        ppn_t ppn = page2ppn(p), buddy_ppn = ppn ^ size;
        list_entry_t *le = buddy_ppn < ppn ? list_prev(&p->page_link)
                                          : list_next(&p->page_link);
        if (le == &free_list) {
            break;
        }
        struct Page *q = le2page(le, page_link);
        if (page2ppn(q) != buddy_ppn || !PageProperty(q) || q->u != p->u) {
            break;
        }
        assert(!PageReserved(q) && (q->flags & BUDDY_MANAGED) &&
               !(q->flags & BUDDY_ALLOCATED));
        struct Page *low = buddy_ppn < ppn ? q : p;
        struct Page *high = buddy_ppn < ppn ? p : q;
        assert(low + size == high);
        assert((page2ppn(low) & ((size << 1) - 1)) == 0);
        assert((size << 1) <= npage - page2ppn(low));
        int next_u = p->u + 1;
        list_del_init(&high->page_link);
        clear_head(high);
        low->u = next_u;
        low->property = block_pages(next_u);
        p = low;
    }
}

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
}

static void
default_init_memmap(struct Page *base, size_t n) {
    assert(valid_page(base) && n > 0);
    assert(n <= npage - page2ppn(base));
    assert(n <= (size_t)~0U - nr_free);
    /* Validate the ENTIRE input before changing any descriptor. */
    for (size_t i = 0; i < n; ++i) {
        assert(PageReserved(base + i));
    }
    for (size_t i = 0; i < n; ++i) {
        struct Page *p = base + i;
        p->flags = BUDDY_MANAGED;
        p->property = 0;
        p->u = BUDDY_NO_ORDER;
        set_page_ref(p, 0);
        list_init(&p->page_link);
    }
    nr_free += n;
    /* Greedy aligned decomposition in absolute physical page numbers. */
    while (n != 0) {
        int u = 0;
        ppn_t ppn = page2ppn(base);
        while (u < BUDDY_MAX_ORDER && block_pages(u + 1) <= n &&
               (ppn & (block_pages(u + 1) - 1)) == 0) {
            ++u;
        }
        size_t size = block_pages(u);
        set_free_head(base, u);
        insert_free(base);
        merge_free(base);
        base += size;
        n -= size;
    }
}

static struct Page *
default_alloc_pages(size_t n) {
    int u;
    if (!request_order(n, &u) || block_pages(u) > nr_free) {
        return NULL;
    }
    list_entry_t *le = list_next(&free_list);
    while (le != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->u >= u) {
            int i = p->u;
            list_del_init(&p->page_link);
            clear_head(p);
            while (i > u) {
                --i;
                struct Page *right = p + block_pages(i);
                set_free_head(right, i);
                insert_free(right);
            }
            size_t size = block_pages(u);
            for (size_t j = 0; j < size; ++j) {
                assert(!PageReserved(p + j) && !PageProperty(p + j));
                assert((p[j].flags & BUDDY_MANAGED) &&
                       !(p[j].flags & BUDDY_ALLOCATED));
                p[j].flags |= BUDDY_ALLOCATED;
            }
            p->u = u;
            p->property = size;
            nr_free -= size;
            return p;
        }
        le = list_next(le);
    }
    return NULL;
}

static void
default_free_pages(struct Page *base, size_t n) {
    int u;
    assert(valid_page(base) && request_order(n, &u));
    assert(!PageReserved(base) && (base->flags & BUDDY_MANAGED));
    assert((base->flags & BUDDY_ALLOCATED) && !PageProperty(base));
    assert(base->u >= 0 && base->u <= BUDDY_MAX_ORDER);
    /* Accept the original request or any size in the same rounding class,
     * including the actual size. Partial blocks cannot be freed.
     */
    assert(base->u == u);
    size_t size = block_pages(base->u);
    assert(base->property == size && size <= npage - page2ppn(base));
    assert((page2ppn(base) & (size - 1)) == 0);
    assert(size <= (size_t)~0U - nr_free);
    for (size_t i = 0; i < size; ++i) {
        struct Page *p = base + i;
        assert(!PageReserved(p) && !PageProperty(p));
        assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
        assert(list_empty(&p->page_link));
        if (i != 0) {
            assert(p->u == BUDDY_NO_ORDER && p->property == 0);
        }
    }
    for (size_t i = 0; i < size; ++i) {
        base[i].flags &= ~BUDDY_ALLOCATED;
        set_page_ref(base + i, 0);
    }
    set_free_head(base, u);
    nr_free += size;  /* merging never changes this count */
    insert_free(base);
    merge_free(base);
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}

/* Check free heads, physical alignment, ordering and maximal coalescing. */
static void
buddy_check_invariants(void) {
    size_t total = 0, count = 0;
    struct Page *previous = NULL;
    list_entry_t *le = list_next(&free_list);
    assert(list_next(list_prev(&free_list)) == &free_list);
    while (le != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(valid_page(p) && PageProperty(p));
        size_t size = block_pages(p->u);
        assert(p->property == size && size <= npage - page2ppn(p));
        assert((page2ppn(p) & (size - 1)) == 0);
        assert(list_prev(list_next(le)) == le && list_next(list_prev(le)) == le);
        if (previous != NULL) {
            assert(previous + previous->property <= p);
            assert(previous->u != p->u ||
                   (page2ppn(previous) ^ size) != page2ppn(p));
        }
        for (size_t i = 0; i < size; ++i) {
            struct Page *q = p + i;
            assert(!PageReserved(q) && (q->flags & BUDDY_MANAGED));
            assert(!(q->flags & BUDDY_ALLOCATED));
            if (i != 0) {
                assert(!PageProperty(q) && q->u == BUDDY_NO_ORDER &&
                       q->property == 0 && list_empty(&q->page_link));
            }
        }
        total += size;
        assert(total <= nr_free && ++count <= nr_free);
        previous = p;
        le = list_next(le);
    }
    assert(total == nr_free_pages());
}

/* All fixtures use sixteen pages of an existing aligned free block. The
 * original sentinel and descriptors are saved verbatim; other free blocks
 * stay unreachable and untouched throughout the test. No reserved page is
 * converted into test memory. Only these two functions are test helpers.
 */
static void
default_check(void) {
    buddy_check_invariants();
    size_t original_free = nr_free_pages();
    struct Page *arena = NULL;
    for (list_entry_t *le = list_next(&free_list); le != &free_list;
         le = list_next(le)) {
        struct Page *p = le2page(le, page_link);
        if (p->u >= 4) {
            arena = p;
            break;
        }
    }
    assert(arena != NULL && valid_page(arena + 15));
    assert((page2ppn(arena) & 15) == 0);
    free_area_t saved_area = free_area;
    list_entry_t saved_sentinel = free_list;
    struct Page saved_pages[16];
    for (size_t i = 0; i < 16; ++i) {
        assert(!PageReserved(arena + i));
        saved_pages[i] = arena[i];
    }
    /* Do not unlink from the saved list: its neighbour links must remain
     * identical. The saved arena head and sentinel complete that list again
     * at the end. While isolated, only the new sentinel is traversed.
     */
    list_init(&free_list);
    list_init(&arena->page_link);
    set_free_head(arena, 4);
    insert_free(arena);
    nr_free = 16;
    buddy_check_invariants();

    /* Basic requests: exact first-fit addresses, rounding, all live pages,
     * non-overlap, and freeing by the ORIGINAL request (especially 3 and 5).
     */
    const size_t requests[] = {1, 2, 3, 5};
    const size_t sizes[] = {1, 2, 4, 8};
    const size_t offsets[] = {0, 2, 4, 8};
    struct Page *blocks[4];
    for (size_t i = 0; i < 4; ++i) {
        size_t before = nr_free_pages();
        blocks[i] = alloc_pages(requests[i]);
        assert(blocks[i] == arena + offsets[i]);
        assert(blocks[i]->u == (int)i && blocks[i]->property == sizes[i]);
        assert(before - nr_free_pages() == sizes[i]);
        assert((page2ppn(blocks[i]) & (sizes[i] - 1)) == 0);
        for (size_t j = 0; j < sizes[i]; ++j) {
            struct Page *p = blocks[i] + j;
            assert(!PageReserved(p) && !PageProperty(p));
            assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
            assert(list_empty(&p->page_link));
            if (j != 0) {
                assert(p->u == BUDDY_NO_ORDER && p->property == 0);
            }
        }
        for (size_t j = 0; j < i; ++j) {
            assert(blocks[j] + sizes[j] <= blocks[i] ||
                   blocks[i] + sizes[i] <= blocks[j]);
        }
        buddy_check_invariants();
    }
    assert(nr_free_pages() == 1);
    assert(free_list.next == &arena[1].page_link &&
           free_list.prev == &arena[1].page_link && arena[1].u == 0);
    for (size_t i = 4; i-- > 0;) {
        size_t before = nr_free_pages();
        free_pages(blocks[i], requests[i]);
        assert(nr_free_pages() == before + sizes[i]);
        buddy_check_invariants();
    }
    assert(nr_free_pages() == 16 && arena->u == 4);
    assert(free_list.next == &arena->page_link && free_list.prev == &arena->page_link);

    /* Split an isolated aligned eight-page block, then restore it in two
     * different orders. Holding the lower eight pages prevents cross merges.
     */
    for (size_t round = 0; round < 2; ++round) {
        struct Page *held = alloc_pages(8), *slots[8];
        assert(held == arena && held->u == 3 && held->property == 8);
        struct Page *base = arena + 8;
        assert(nr_free_pages() == 8 && base->u == 3 && base->property == 8);
        assert(free_list.next == &base->page_link && free_list.prev == &base->page_link);
        buddy_check_invariants();
        slots[0] = alloc_page();
        assert(slots[0] == base && base->u == 0 && base->property == 1);
        assert(nr_free_pages() == 7);
        list_entry_t *le = list_next(&free_list);
        for (int u = 0; u < 3; ++u) {
            struct Page *p = base + block_pages(u);
            assert(le == &p->page_link && PageProperty(p));
            assert(p->u == u && p->property == block_pages(u));
            le = list_next(le);
        }
        assert(le == &free_list);
        buddy_check_invariants();
        for (size_t i = 1; i < 8; ++i) {
            slots[i] = alloc_page();
            assert(slots[i] == base + i && slots[i]->u == 0 && slots[i]->property == 1);
            assert(nr_free_pages() == 7 - i);
            buddy_check_invariants();
        }
        const size_t orders[2][8] = {{0, 1, 2, 3, 4, 5, 6, 7},
                                     {3, 6, 1, 4, 7, 0, 5, 2}};
        for (size_t i = 0; i < 8; ++i) {
            free_page(slots[orders[round][i]]);
            assert(nr_free_pages() == i + 1);
            buddy_check_invariants();
            if (round == 0 && (i == 1 || i == 3 || i == 7)) {
                int u = i == 1 ? 1 : i == 3 ? 2 : 3;
                assert(PageProperty(base) && base->u == u &&
                       base->property == block_pages(u));
            }
        }
        assert(base->u == 3 && base->property == 8);
        assert(free_list.next == &base->page_link && free_list.prev == &base->page_link);
        free_pages(held, 8);
        buddy_check_invariants();
        assert(nr_free_pages() == 16 && arena->u == 4);
    }

    /* Failure snapshots cover a whole free block, exhaustion, and external
     * fragmentation. In the latter, only pages 1 and 2 of the first aligned
     * four-page interval are free: adjacent, but NOT physical buddies.
     */
    for (size_t scenario = 0; scenario < 3; ++scenario) {
        struct Page *slots[16];
        if (scenario != 0) {
            for (size_t i = 0; i < 16; ++i) {
                slots[i] = alloc_page();
                assert(slots[i] == arena + i && slots[i]->u == 0 &&
                       slots[i]->property == 1);
                buddy_check_invariants();
            }
            assert(nr_free_pages() == 0 && list_empty(&free_list));
        }
        if (scenario == 2) {
            free_page(slots[1]);
            buddy_check_invariants();
            free_page(slots[2]);
            buddy_check_invariants();
            assert(nr_free_pages() == 2);
            assert(slots[1]->u == 0 && slots[2]->u == 0);
            assert(slots[1]->property == 1 && slots[2]->property == 1);
            assert(free_list.next == &slots[1]->page_link &&
                   slots[1]->page_link.next == &slots[2]->page_link &&
                   free_list.prev == &slots[2]->page_link);
            assert((page2ppn(slots[1]) ^ 1) != page2ppn(slots[2]));
        }
        const size_t failures[] = {0, (size_t)-1,
            block_pages(BUDDY_MAX_ORDER) + 1, 17,
            scenario == 0 ? 17 : scenario == 1 ? 1 : 2};
        for (size_t f = 0; f < sizeof(failures) / sizeof(failures[0]); ++f) {
            size_t before_count = nr_free_pages();
            list_entry_t before_list = free_list;
            struct Page before[16];
            for (size_t i = 0; i < 16; ++i) {
                before[i] = arena[i];
            }
            assert(alloc_pages(failures[f]) == NULL);
            assert(nr_free_pages() == before_count);
            assert(free_list.next == before_list.next &&
                   free_list.prev == before_list.prev);
            for (size_t i = 0; i < 16; ++i) {
                assert(arena[i].flags == before[i].flags &&
                       arena[i].ref == before[i].ref &&
                       arena[i].u == before[i].u &&
                       arena[i].property == before[i].property &&
                       arena[i].page_link.next == before[i].page_link.next &&
                       arena[i].page_link.prev == before[i].page_link.prev);
            }
            buddy_check_invariants();
        }
        if (scenario != 0) {
            for (size_t i = 0; i < 16; ++i) {
                if (scenario == 2 && (i == 1 || i == 2)) {
                    continue;
                }
                free_page(slots[i]);
                buddy_check_invariants();
            }
        }
        /* Verify actual allocator restoration BEFORE restoring the fixture. */
        assert(nr_free_pages() == 16 && arena->u == 4 && arena->property == 16);
        assert(free_list.next == &arena->page_link && free_list.prev == &arena->page_link);
    }

    /* Restore every descriptor the fixture could touch, including refcounts,
     * flags and both links. Every other original block was never modified;
     * restoring the original head and sentinel recovers the EXACT block set,
     * rather than merely its count or a hash.
     */
    for (size_t i = 0; i < 16; ++i) {
        arena[i] = saved_pages[i];
    }
    free_area = saved_area;
    assert(nr_free_pages() == original_free);
    assert(arena->u == saved_pages[0].u && arena->property == saved_pages[0].property);
    assert(list_next(list_prev(&arena->page_link)) == &arena->page_link &&
           list_prev(list_next(&arena->page_link)) == &arena->page_link);
    assert(free_list.next == saved_sentinel.next &&
           free_list.prev == saved_sentinel.prev);
    buddy_check_invariants();
    cprintf("buddy_system_pmm check passed: rounding, split/merge, boundaries, failures, restoration\n");
}

const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};
