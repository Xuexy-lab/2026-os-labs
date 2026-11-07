#ifndef __KERN_MM_SLUB_H__
#define __KERN_MM_SLUB_H__

#include <defs.h>

struct pmm_manager;
extern const struct pmm_manager slub_pmm_manager;

/* Single-threaded allocator, like the existing PMM. Invalid frees panic.
 * Only the original returned pointer may be freed; NULL is a no-op. */
void slub_init(void);
void *kmalloc(size_t size);
void kfree(void *ptr);
void slub_check(void);

#endif
