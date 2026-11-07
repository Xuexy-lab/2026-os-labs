#include <slub.h>
#include <buddy_system_pmm.h>
#include <list.h>
#include <stdio.h>
#include <string.h>

#define ALIGNMENT 16
#define CACHE_COUNT 8
#define MAX_SLOTS (PGSIZE / ALIGNMENT)
#define SIZE_MAX_VALUE ((size_t)-1)
#define SLUB_MAGIC 0x534c55424c495645ULL

enum allocation_kind { SMALL = 1, LARGE = 2 };
struct cache {
    size_t size;
    list_entry_t available;
};
struct slot { struct slot *next; };

/* All links and allocation bits belong to this page-local header, never Page.
 * live includes full slabs and large blocks, allowing pointer validation before
 * dereferencing a purported header (including pointers into returned pages).
 * A stale pointer to a subsequently reused object cannot be distinguished from
 * its new owner; callers must obey the usual allocation lifetime contract. */
struct slab {
    uint64_t magic;
    enum allocation_kind kind;
    struct cache *cache;
    struct Page *page;
    size_t npages, total, used;
    struct slot *freelist;
    list_entry_t available, live;
    uint8_t allocated[MAX_SLOTS / 8];
} __attribute__((aligned(ALIGNMENT)));

#define HEADER_SIZE sizeof(struct slab)
typedef char header_fits_first_page[(HEADER_SIZE < PGSIZE &&
                                    HEADER_SIZE % ALIGNMENT == 0) ? 1 : -1];
static struct cache caches[CACHE_COUNT];
static list_entry_t live;

static void *page_address(struct Page *page) {
    /* KADDR is disabled in this tree; use its actual direct-map offset. */
    return (void *)(page2pa(page) + va_pa_offset);
}

static void *objects(struct slab *s) {
    return (char *)s + HEADER_SIZE;
}

static bool bit_set(struct slab *s, size_t i) {
    return (s->allocated[i / 8] >> (i % 8)) & 1;
}

/* No dereference of ptr or its rounded address until it matches a live head. */
static struct slab *find_slab(void *ptr) {
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
        struct slab *s = to_struct(le, struct slab, live);
        if ((uintptr_t)s == base) {
            return s;
        }
    }
    return NULL;
}

static bool slot_index(struct slab *s, void *ptr, size_t *index) {
    uintptr_t start = (uintptr_t)objects(s), addr = (uintptr_t)ptr;
    if (addr < start || (addr - start) % s->cache->size != 0) {
        return 0;
    }
    *index = (addr - start) / s->cache->size;
    return *index < s->total;
}

void slub_init(void) {
    list_init(&live);
    for (size_t i = 0; i < CACHE_COUNT; ++i) {
        caches[i].size = (size_t)ALIGNMENT << i;
        list_init(&caches[i].available);
    }
}

static struct slab *new_slab(size_t npages, struct cache *cache) {
    struct Page *page = alloc_pages(npages);
    if (page == NULL) {
        return NULL;
    }
    struct slab *s = page_address(page);
    memset(s, 0, HEADER_SIZE);
    s->magic = SLUB_MAGIC;
    s->kind = cache == NULL ? LARGE : SMALL;
    s->cache = cache;
    s->page = page;
    s->npages = npages; /* caller already rounded to Buddy's actual block size */
    list_init(&s->available);
    list_add(&live, &s->live);
    if (cache != NULL) {
        s->total = (PGSIZE - HEADER_SIZE) / cache->size;
        for (size_t i = s->total; i != 0; --i) {
            struct slot *slot = (void *)((char *)objects(s) + (i - 1) * cache->size);
            slot->next = s->freelist;
            s->freelist = slot;
        }
        list_add(&cache->available, &s->available);
    }
    return s;
}

/* Division/remainder avoids overflow in the conventional +PGSIZE-1 formula.
 * Check rounding and byte capacity as well as the physical-memory bound. */
static bool large_pages(size_t size, size_t *result) {
    if (size > SIZE_MAX_VALUE - HEADER_SIZE) {
        return 0;
    }
    size_t bytes = size + HEADER_SIZE;
    size_t needed = bytes / PGSIZE + (bytes % PGSIZE != 0);
    size_t count = 1;
    while (count < needed) {
        if (count > SIZE_MAX_VALUE / 2) {
            return 0;
        }
        count *= 2;
    }
    if (count > SIZE_MAX_VALUE / PGSIZE || npage <= nbase ||
        count > npage - nbase) {
        return 0;
    }
    *result = count;
    return 1;
}

void *kmalloc(size_t size) {
    if (size == 0) {
        return NULL;
    }
    size_t i = 0;
    while (i < CACHE_COUNT && caches[i].size < size) {
        ++i;
    }
    if (i == CACHE_COUNT) {
        size_t npages;
        if (!large_pages(size, &npages)) {
            return NULL;
        }
        struct slab *s = new_slab(npages, NULL);
        return s == NULL ? NULL : objects(s);
    }
    struct cache *cache = &caches[i];
    struct slab *s = list_empty(&cache->available) ? new_slab(1, cache) :
        to_struct(list_next(&cache->available), struct slab, available);
    if (s == NULL) {
        return NULL;
    }
    struct slot *slot = s->freelist;
    size_t index;
    assert(slot != NULL && slot_index(s, slot, &index) && !bit_set(s, index));
    s->freelist = slot->next;
    s->allocated[index / 8] |= 1U << (index % 8);
    if (++s->used == s->total) {
        list_del_init(&s->available);
    }
    return slot;
}

static void release_slab(struct slab *s) {
    struct Page *page = s->page;
    size_t npages = s->npages;
    list_del_init(&s->available);
    list_del_init(&s->live);
    s->magic = 0;
    free_pages(page, npages);
    /* The header is no longer owned; do not touch s again. */
}

void kfree(void *ptr) {
    if (ptr == NULL) {
        return;
    }
    struct slab *s = find_slab(ptr);
    assert(s != NULL && s->magic == SLUB_MAGIC);
    if (s->kind == LARGE) {
        assert(ptr == objects(s));
        release_slab(s);
        return;
    }
    size_t index;
    assert(s->kind == SMALL && slot_index(s, ptr, &index));
    assert(bit_set(s, index) && s->used > 0);
    s->allocated[index / 8] &= ~(1U << (index % 8));
    if (s->used == s->total) {
        assert(list_empty(&s->available));
        list_add(&s->cache->available, &s->available);
    }
    struct slot *slot = ptr;
    slot->next = s->freelist;
    s->freelist = slot;
    if (--s->used == 0) {
        release_slab(s);
    }
}

/* 检查 cache、slab、空闲对象链表及计数的一致性。 */
static void slub_check_invariants(void) {
    size_t available_count[CACHE_COUNT] = {0}, live_count = 0;
    assert(npage > nbase);
    assert(list_next(list_prev(&live)) == &live &&
           list_prev(list_next(&live)) == &live);
    for (size_t ci = 0; ci < CACHE_COUNT; ++ci) {
        assert(caches[ci].size == ((size_t)ALIGNMENT << ci));
    }
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
        assert(++live_count <= npage - nbase); /* bounds cycles in live */
        struct slab *s = to_struct(le, struct slab, live);
        assert(s->magic == SLUB_MAGIC && page_address(s->page) == s);
        assert(list_prev(list_next(le)) == le && list_next(list_prev(le)) == le);
        assert((uintptr_t)s % PGSIZE == 0 && (uintptr_t)s % ALIGNMENT == 0);
        assert(HEADER_SIZE % ALIGNMENT == 0 && HEADER_SIZE < PGSIZE);
        assert((uintptr_t)objects(s) == (uintptr_t)s + HEADER_SIZE);
        assert((uintptr_t)objects(s) % ALIGNMENT == 0);
        assert(page2ppn(s->page) >= nbase && page2ppn(s->page) < npage);
        assert(s->npages > 0 && s->npages <= npage - page2ppn(s->page));
        assert((s->npages & (s->npages - 1)) == 0);
        assert(s->page->property == s->npages && !PageProperty(s->page));
        assert(s->page->u >= 0 && s->page->u < sizeof(size_t) * 8);
        assert(((size_t)1 << s->page->u) == s->npages);
        for (size_t p = 0; p < s->npages; ++p) {
            assert(!PageReserved(s->page + p) && !PageProperty(s->page + p));
            assert(list_empty(&s->page[p].page_link));
        }
        /* Earlier live blocks must not overlap this block. */
        for (list_entry_t *qle = list_next(&live); qle != le; qle = list_next(qle)) {
            struct slab *q = to_struct(qle, struct slab, live);
            assert(s->page + s->npages <= q->page ||
                   q->page + q->npages <= s->page);
        }
        if (s->kind == LARGE) {
            assert(s->cache == NULL && list_empty(&s->available));
            assert(s->freelist == NULL && s->total == 0 && s->used == 0);
            continue;
        }
        assert(s->kind == SMALL && s->npages == 1);
        size_t ci = 0;
        while (ci < CACHE_COUNT && s->cache != &caches[ci]) { ++ci; }
        assert(ci < CACHE_COUNT);
        assert(s->total == (PGSIZE - HEADER_SIZE) / s->cache->size);
        assert(s->total > 0 && s->total <= MAX_SLOTS);
        assert(s->used > 0 && s->used <= s->total);
        uint8_t seen[MAX_SLOTS / 8] = {0};
        size_t free_count = 0, used_count = 0;
        for (struct slot *slot = s->freelist; slot != NULL; slot = slot->next) {
            size_t index;
            assert(slot_index(s, slot, &index) && !bit_set(s, index));
            assert((uintptr_t)slot % ALIGNMENT == 0);
            assert(!(seen[index / 8] & (1U << (index % 8))));
            seen[index / 8] |= 1U << (index % 8);
            assert(++free_count <= s->total);
        }
        for (size_t i = 0; i < s->total; ++i) {
            uintptr_t slot = (uintptr_t)objects(s) + i * s->cache->size;
            assert(slot % ALIGNMENT == 0 && slot >= (uintptr_t)s + HEADER_SIZE);
            assert(slot + s->cache->size <= (uintptr_t)s + PGSIZE);
            used_count += bit_set(s, i);
            assert(bit_set(s, i) != ((seen[i / 8] >> (i % 8)) & 1));
        }
        for (size_t i = s->total; i < MAX_SLOTS; ++i) { assert(!bit_set(s, i)); }
        assert(used_count == s->used && s->used + free_count == s->total);
        assert(list_empty(&s->available) == (s->used == s->total));
        available_count[ci] += free_count != 0;
    }
    for (size_t ci = 0; ci < CACHE_COUNT; ++ci) {
        size_t count = 0;
        list_entry_t *head = &caches[ci].available;
        assert(list_next(list_prev(head)) == head && list_prev(list_next(head)) == head);
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
            assert(++count <= available_count[ci]); /* catches cycles/duplicates */
            struct slab *s = to_struct(le, struct slab, available);
            /* A returned page must not be referenced by a cache. */
            assert(find_slab(s) == s && s->cache == &caches[ci]);
            assert(s->kind == SMALL && s->used > 0 && s->used < s->total);
            assert(list_prev(list_next(le)) == le && list_next(list_prev(le)) == le);
        }
        assert(count == available_count[ci]);
    }
}

/* 执行全部 SLUB 分配与释放测试。 Only these two functions are test helpers. */
void slub_check(void) {
    /* Boot-time test: no clients yet; do not reinitialize either allocator.
     * Exact block sizes indexed by Page identify the entire original free set.
     * Bounds derive from this kernel's supported physical map, not addresses
     * chosen as test allocations. No reserved pages are used as test storage. */
    enum { PAGE_LIMIT = (PHYSICAL_MEMORY_END - DRAM_BASE) / PGSIZE };
    static unsigned int free_blocks[PAGE_LIMIT];
    static struct { struct Page *page; size_t count; } held[PAGE_LIMIT];
    static void *slots[MAX_SLOTS + 1];
    assert(npage > nbase && npage - nbase <= PAGE_LIMIT && list_empty(&live));
    size_t before = nr_free_pages(), sum = 0;
    for (size_t i = 0; i < npage - nbase; ++i) {
        free_blocks[i] = PageProperty(&pages[i]) ? pages[i].property : 0;
        sum += free_blocks[i];
    }
    assert(sum == before);
    slub_check_invariants();

    /* Multiple rounds change allocation/free ordering, retaining other classes
     * while each object is freed and replaced. */
    for (size_t round = 0; round < 3; ++round) {
        const size_t sizes[] = {1, 15, 16, 17, 31, 32, 33, 63, 64, 65,
            127, 128, 129, 255, 256, 257, 511, 512, 513, 1023, 1024,
            1025, 2047, 2048, 2049, PGSIZE - HEADER_SIZE - 1,
            PGSIZE - HEADER_SIZE, PGSIZE - HEADER_SIZE + 1, PGSIZE,
            2 * PGSIZE - HEADER_SIZE, 2 * PGSIZE - HEADER_SIZE + 1,
            2 * PGSIZE, 4 * PGSIZE};
        enum { N = sizeof(sizes) / sizeof(sizes[0]) };
        void *ptrs[N];
        for (size_t i = 0; i < N; ++i) {
            size_t ci = 0, old = nr_free_pages();
            while (ci < CACHE_COUNT && caches[ci].size < sizes[i]) { ++ci; }
            bool fresh = ci < CACHE_COUNT && list_empty(&caches[ci].available);
            ptrs[i] = kmalloc(sizes[i]);
            assert(ptrs[i] != NULL && (uintptr_t)ptrs[i] % ALIGNMENT == 0);
            struct slab *s = find_slab(ptrs[i]);
            assert(s != NULL);
            if (ci < CACHE_COUNT) {
                assert(s->kind == SMALL && s->cache == &caches[ci]);
                assert(ci == 0 || caches[ci - 1].size < sizes[i]);
                assert(s->total == (PGSIZE - HEADER_SIZE) / caches[ci].size);
                assert(old - nr_free_pages() == (fresh ? 1 : 0));
            } else {
                /* Independent expected value, not large_pages() under test. */
                size_t expected = 1;
                while (expected * PGSIZE < sizes[i] + HEADER_SIZE) { expected *= 2; }
                assert(s->kind == LARGE && s->npages == expected);
                assert(ptrs[i] == objects(s) && (uintptr_t)ptrs[i] < (uintptr_t)s + PGSIZE);
                assert((uintptr_t)ptrs[i] + sizes[i] <= (uintptr_t)s + expected * PGSIZE);
                assert(old - nr_free_pages() == expected);
            }
            for (size_t j = 0; j < i; ++j) {
                assert((uintptr_t)ptrs[i] + sizes[i] <= (uintptr_t)ptrs[j] ||
                       (uintptr_t)ptrs[j] + sizes[j] <= (uintptr_t)ptrs[i]);
            }
            memset(ptrs[i], (int)(i + round + 1), sizes[i]);
            slub_check_invariants();
        }

        /* No-op and failing requests preserve every live header and freelist
         * link (the content checks below also cover all allocated bytes). */
        const size_t failures[] = {0, SIZE_MAX_VALUE,
            SIZE_MAX_VALUE - HEADER_SIZE + 1, SIZE_MAX_VALUE - HEADER_SIZE,
            (npage - nbase) * PGSIZE};
        for (size_t f = 0; f < sizeof(failures) / sizeof(failures[0]); ++f) {
            struct slab saved[N];
            struct slab *heads[N];
            list_entry_t saved_live = live;
            struct cache saved_caches[CACHE_COUNT];
            memcpy(saved_caches, caches, sizeof(caches));
            for (size_t i = 0; i < N; ++i) {
                heads[i] = find_slab(ptrs[i]);
                saved[i] = *heads[i];
            }
            /* Reuse bounded scratch while no exhaustion blocks are held. */
            for (size_t i = 0; i < npage - nbase; ++i) {
                held[i].count = PageProperty(&pages[i]) ? pages[i].property : 0;
            }
            size_t old = nr_free_pages();
            kfree(NULL);
            assert(kmalloc(failures[f]) == NULL && nr_free_pages() == old);
            assert(memcmp(&saved_live, &live, sizeof(live)) == 0);
            assert(memcmp(saved_caches, caches, sizeof(caches)) == 0);
            for (size_t i = 0; i < N; ++i) {
                assert(memcmp(&saved[i], heads[i], HEADER_SIZE) == 0);
            }
            for (size_t i = 0; i < npage - nbase; ++i) {
                assert((PageProperty(&pages[i]) ? pages[i].property : 0) == held[i].count);
                held[i].count = 0;
            }
            slub_check_invariants();
        }
        for (size_t step = 0; step < N; ++step) {
            size_t i = (step + round * 7) % N;
            /* Check every survivor before changing one class. */
            for (size_t j = 0; j < N; ++j) {
                if (ptrs[j] != NULL) {
                    for (size_t k = 0; k < sizes[j]; ++k) {
                        assert(((uint8_t *)ptrs[j])[k] == (uint8_t)(j + round + 1));
                    }
                }
            }
            struct slab *s = find_slab(ptrs[i]);
            bool last = s->kind == LARGE || s->used == 1;
            size_t released = last ? s->npages : 0, old = nr_free_pages();
            void *head_address = s;
            kfree(ptrs[i]);
            ptrs[i] = NULL;
            assert(nr_free_pages() == old + released);
            if (last) { assert(find_slab(head_address) == NULL); }
            slub_check_invariants();
            /* Interleave a temporary replacement while other classes live. */
            void *replacement = kmalloc(sizes[i]);
            assert(replacement != NULL && (uintptr_t)replacement % ALIGNMENT == 0);
            memset(replacement, 0xe7, sizes[i]);
            slub_check_invariants();
            for (size_t k = 0; k < sizes[i]; ++k) {
                assert(((uint8_t *)replacement)[k] == 0xe7);
            }
            kfree(replacement);
            slub_check_invariants();
        }

        /* Actual capacity, full -> partial -> full, crossing into another slab,
         * LIFO slot reuse with other objects retained, and last-object return. */
        for (size_t ci = 0; ci < CACHE_COUNT; ++ci) {
            size_t size = caches[ci].size, count = (PGSIZE - HEADER_SIZE) / size;
            assert(count > 0 && count <= MAX_SLOTS);
            for (size_t i = 0; i <= count; ++i) {
                slots[i] = kmalloc(size);
                assert(slots[i] != NULL && (uintptr_t)slots[i] % ALIGNMENT == 0);
                assert(find_slab(slots[i])->cache == &caches[ci]);
                memset(slots[i], (int)(i % 251) + 1, size);
                assert(nr_free_pages() == before - (i < count ? 1 : 2));
                slub_check_invariants();
            }
            struct slab *first = find_slab(slots[0]);
            assert(first != find_slab(slots[count]));
            assert(first->used == count && first->total == count);
            assert(list_empty(&first->available));
            for (size_t i = 0; i < count; ++i) { assert(find_slab(slots[i]) == first); }
            /* A one-slot slab is returned immediately, not made partial. */
            if (count > 1) {
                size_t holes = count / 2;
                for (size_t i = 0; i < holes; ++i) {
                    kfree(slots[i]);
                    assert(first->used == count - i - 1);
                    assert(!list_empty(&first->available));
                    assert(nr_free_pages() == before - 2);
                    slub_check_invariants();
                }
                /* Existing kfree prepends each slot; kmalloc takes the head. */
                for (size_t i = holes; i-- > 0;) {
                    void *replacement = kmalloc(size);
                    assert(replacement == slots[i]);
                    memset(replacement, (int)(i % 251) + 1, size);
                    assert(nr_free_pages() == before - 2);
                    slub_check_invariants();
                }
                assert(first->used == count && list_empty(&first->available));
            }
            for (size_t i = 0; i <= count; ++i) {
                for (size_t j = 0; j < size; ++j) {
                    assert(((uint8_t *)slots[i])[j] == (uint8_t)(i % 251 + 1));
                }
            }
            for (size_t i = count + 1; i-- > 0;) {
                struct slab *s = find_slab(slots[i]);
                bool last = s->used == 1;
                size_t old = nr_free_pages();
                void *head_address = s;
                kfree(slots[i]);
                slots[i] = NULL;
                assert(nr_free_pages() == old + (last ? 1 : 0));
                if (last) { assert(find_slab(head_address) == NULL); }
                slub_check_invariants();
            }
        }

        /* Consume actual free blocks; restore solely via free_pages, never by
         * changing the free counter or reinitializing allocator metadata. */
        void *kept = kmalloc(caches[0].size);
        assert(kept != NULL);
        memset(kept, 0xa5, caches[0].size);
        struct slab *s = find_slab(kept);
        assert(s->used == 1 && s->total > 1);
        size_t held_count = 0, count = 1;
        while (count <= nr_free_pages() / 2) { count *= 2; }
        for (; count != 0; count /= 2) {
            struct Page *page;
            while ((page = alloc_pages(count)) != NULL) {
                assert(held_count < PAGE_LIMIT && !PageReserved(page));
                assert(page->property == count);
                held[held_count].page = page;
                held[held_count++].count = count;
            }
        }
        assert(nr_free_pages() == 0);
        struct slab saved = *s;
        struct cache saved_caches[CACHE_COUNT];
        memcpy(saved_caches, caches, sizeof(caches));
        list_entry_t saved_live = live;
        for (size_t ci = 1; ci < CACHE_COUNT; ++ci) {
            assert(kmalloc(caches[ci].size) == NULL);
            slub_check_invariants();
        }
        assert(kmalloc(caches[CACHE_COUNT - 1].size + 1) == NULL);
        assert(nr_free_pages() == 0 && memcmp(&saved, s, HEADER_SIZE) == 0);
        assert(memcmp(saved_caches, caches, sizeof(caches)) == 0);
        assert(memcmp(&saved_live, &live, sizeof(live)) == 0);
        void *reused = kmalloc(caches[0].size);
        assert(reused != NULL && reused != kept && find_slab(reused) == s);
        assert(s->used == 2 && nr_free_pages() == 0);
        memset(reused, 0x5a, caches[0].size);
        for (size_t i = 0; i < caches[0].size; ++i) {
            assert(((uint8_t *)kept)[i] == 0xa5 && ((uint8_t *)reused)[i] == 0x5a);
        }
        slub_check_invariants();
        while (held_count != 0) {
            --held_count;
            free_pages(held[held_count].page, held[held_count].count);
            held[held_count].page = NULL;
            held[held_count].count = 0;
        }
        kfree(reused);
        assert(nr_free_pages() == before - 1);
        kfree(kept);
        assert(find_slab(kept) == NULL);
        slub_check_invariants();

        /* Compare the exact free block set, not a count or a lossy hash.
         * Also verify each restored block's order, alignment and list links. */
        assert(list_empty(&live) && nr_free_pages() == before);
        sum = 0;
        for (size_t i = 0; i < npage - nbase; ++i) {
            struct Page *p = &pages[i];
            assert((PageProperty(p) ? p->property : 0) == free_blocks[i]);
            if (free_blocks[i] != 0) {
                assert(!PageReserved(p) && p->u >= 0 && p->u < sizeof(size_t) * 8);
                assert(((size_t)1 << p->u) == free_blocks[i]);
                assert((page2ppn(p) & (free_blocks[i] - 1)) == 0);
                assert(list_next(list_prev(&p->page_link)) == &p->page_link);
                assert(list_prev(list_next(&p->page_link)) == &p->page_link);
            }
            sum += free_blocks[i];
        }
        assert(sum == before);
    }
    memset(free_blocks, 0, sizeof(free_blocks));
    cprintf("slub check passed: 3 rounds, boundaries, isolation, reuse, full/partial, reclaim, large, OOM, exact free-block restoration\n");
}

/* Adapters must call Buddy directly, never the dispatching PMM wrappers. */
static void combined_init(void) {
    buddy_system_pmm_manager.init();
    slub_init();
}
static void combined_init_memmap(struct Page *base, size_t n) {
    buddy_system_pmm_manager.init_memmap(base, n);
}
static struct Page *combined_alloc_pages(size_t n) {
    return buddy_system_pmm_manager.alloc_pages(n);
}
static void combined_free_pages(struct Page *base, size_t n) {
    buddy_system_pmm_manager.free_pages(base, n);
}
static size_t combined_nr_free_pages(void) {
    return buddy_system_pmm_manager.nr_free_pages();
}
static void combined_check(void) {
    buddy_system_pmm_manager.check();
    slub_check();
}
const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager (Buddy + SLUB)",
    .init = combined_init,
    .init_memmap = combined_init_memmap,
    .alloc_pages = combined_alloc_pages,
    .free_pages = combined_free_pages,
    .nr_free_pages = combined_nr_free_pages,
    .check = combined_check,
};
