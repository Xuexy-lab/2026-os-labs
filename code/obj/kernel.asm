
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00005517          	auipc	a0,0x5
ffffffffc0200050:	afc50513          	addi	a0,a0,-1284 # ffffffffc0204b48 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00005517          	auipc	a0,0x5
ffffffffc0200066:	b0650513          	addi	a0,a0,-1274 # ffffffffc0204b68 <etext+0x22>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	ad858593          	addi	a1,a1,-1320 # ffffffffc0204b46 <etext>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	b1250513          	addi	a0,a0,-1262 # ffffffffc0204b88 <etext+0x42>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	0000b597          	auipc	a1,0xb
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc020b018 <free_area>
ffffffffc020008a:	00005517          	auipc	a0,0x5
ffffffffc020008e:	b1e50513          	addi	a0,a0,-1250 # ffffffffc0204ba8 <etext+0x62>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	000ac597          	auipc	a1,0xac
ffffffffc020009a:	8ba58593          	addi	a1,a1,-1862 # ffffffffc02ab950 <end>
ffffffffc020009e:	00005517          	auipc	a0,0x5
ffffffffc02000a2:	b2a50513          	addi	a0,a0,-1238 # ffffffffc0204bc8 <etext+0x82>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	000ac597          	auipc	a1,0xac
ffffffffc02000ae:	ca558593          	addi	a1,a1,-859 # ffffffffc02abd4f <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00005517          	auipc	a0,0x5
ffffffffc02000d0:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0204be8 <etext+0xa2>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	0000b517          	auipc	a0,0xb
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc020b018 <free_area>
ffffffffc02000e0:	000ac617          	auipc	a2,0xac
ffffffffc02000e4:	87060613          	addi	a2,a2,-1936 # ffffffffc02ab950 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	209040ef          	jal	ra,ffffffffc0204af8 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00005517          	auipc	a0,0x5
ffffffffc0200100:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0204c18 <etext+0xd2>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	7b9010ef          	jal	ra,ffffffffc02020c4 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	5a2040ef          	jal	ra,ffffffffc02046e2 <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	56c040ef          	jal	ra,ffffffffc02046e2 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	000ab317          	auipc	t1,0xab
ffffffffc02001c6:	74630313          	addi	t1,t1,1862 # ffffffffc02ab908 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00005517          	auipc	a0,0x5
ffffffffc02001f6:	a4650513          	addi	a0,a0,-1466 # ffffffffc0204c38 <etext+0xf2>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00005517          	auipc	a0,0x5
ffffffffc020020c:	a0850513          	addi	a0,a0,-1528 # ffffffffc0204c10 <etext+0xca>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	0490406f          	j	ffffffffc0204a64 <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00005517          	auipc	a0,0x5
ffffffffc0200226:	a3650513          	addi	a0,a0,-1482 # ffffffffc0204c58 <etext+0x112>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	0000b597          	auipc	a1,0xb
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc0200250:	00005517          	auipc	a0,0x5
ffffffffc0200254:	a1850513          	addi	a0,a0,-1512 # ffffffffc0204c68 <etext+0x122>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	0000b417          	auipc	s0,0xb
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc020b008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00005517          	auipc	a0,0x5
ffffffffc020026a:	a1250513          	addi	a0,a0,-1518 # ffffffffc0204c78 <etext+0x132>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00005517          	auipc	a0,0x5
ffffffffc020027a:	a1a50513          	addi	a0,a0,-1510 # ffffffffc0204c90 <etext+0x14a>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfe3459d>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00005917          	auipc	s2,0x5
ffffffffc0200334:	9b090913          	addi	s2,s2,-1616 # ffffffffc0204ce0 <etext+0x19a>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00005497          	auipc	s1,0x5
ffffffffc0200342:	99a48493          	addi	s1,s1,-1638 # ffffffffc0204cd8 <etext+0x192>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00005517          	auipc	a0,0x5
ffffffffc0200396:	9c650513          	addi	a0,a0,-1594 # ffffffffc0204d58 <etext+0x212>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00005517          	auipc	a0,0x5
ffffffffc02003a2:	9f250513          	addi	a0,a0,-1550 # ffffffffc0204d90 <etext+0x24a>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00005517          	auipc	a0,0x5
ffffffffc02003e2:	8d250513          	addi	a0,a0,-1838 # ffffffffc0204cb0 <etext+0x16a>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	692040ef          	jal	ra,ffffffffc0204a7e <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	6d8040ef          	jal	ra,ffffffffc0204ad2 <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	624040ef          	jal	ra,ffffffffc0204ab4 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00005517          	auipc	a0,0x5
ffffffffc02004a8:	84450513          	addi	a0,a0,-1980 # ffffffffc0204ce8 <etext+0x1a2>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00004517          	auipc	a0,0x4
ffffffffc0200576:	79650513          	addi	a0,a0,1942 # ffffffffc0204d08 <etext+0x1c2>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00004517          	auipc	a0,0x4
ffffffffc0200588:	79c50513          	addi	a0,a0,1948 # ffffffffc0204d20 <etext+0x1da>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00004517          	auipc	a0,0x4
ffffffffc020059a:	7aa50513          	addi	a0,a0,1962 # ffffffffc0204d40 <etext+0x1fa>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00004517          	auipc	a0,0x4
ffffffffc02005a6:	7ee50513          	addi	a0,a0,2030 # ffffffffc0204d90 <etext+0x24a>
        memory_base = mem_base;
ffffffffc02005aa:	000ab797          	auipc	a5,0xab
ffffffffc02005ae:	3687b323          	sd	s0,870(a5) # ffffffffc02ab910 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	000ab797          	auipc	a5,0xab
ffffffffc02005b6:	3767b323          	sd	s6,870(a5) # ffffffffc02ab918 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	000ab517          	auipc	a0,0xab
ffffffffc02005c0:	35453503          	ld	a0,852(a0) # ffffffffc02ab910 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	000ab517          	auipc	a0,0xab
ffffffffc02005ca:	35253503          	ld	a0,850(a0) # ffffffffc02ab918 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005d0:	0000b797          	auipc	a5,0xb
ffffffffc02005d4:	a4878793          	addi	a5,a5,-1464 # ffffffffc020b018 <free_area>
ffffffffc02005d8:	e79c                	sd	a5,8(a5)
ffffffffc02005da:	e39c                	sd	a5,0(a5)
}

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02005dc:	0007a823          	sw	zero,16(a5)
}
ffffffffc02005e0:	8082                	ret

ffffffffc02005e2 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02005e2:	0000b517          	auipc	a0,0xb
ffffffffc02005e6:	a4656503          	lwu	a0,-1466(a0) # ffffffffc020b028 <free_area+0x10>
ffffffffc02005ea:	8082                	ret

ffffffffc02005ec <insert_free>:
    assert(PageProperty(p) && list_empty(&p->page_link));
ffffffffc02005ec:	651c                	ld	a5,8(a0)
ffffffffc02005ee:	8b89                	andi	a5,a5,2
ffffffffc02005f0:	c7ad                	beqz	a5,ffffffffc020065a <insert_free+0x6e>
ffffffffc02005f2:	711c                	ld	a5,32(a0)
ffffffffc02005f4:	01850313          	addi	t1,a0,24
ffffffffc02005f8:	06f31163          	bne	t1,a5,ffffffffc020065a <insert_free+0x6e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02005fc:	0000b617          	auipc	a2,0xb
ffffffffc0200600:	a1c60613          	addi	a2,a2,-1508 # ffffffffc020b018 <free_area>
ffffffffc0200604:	6618                	ld	a4,8(a2)
    while (le != &free_list &&
ffffffffc0200606:	04c70263          	beq	a4,a2,ffffffffc020064a <insert_free+0x5e>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020060a:	000ab897          	auipc	a7,0xab
ffffffffc020060e:	31e8b883          	ld	a7,798(a7) # ffffffffc02ab928 <pages>
ffffffffc0200612:	411506b3          	sub	a3,a0,a7
ffffffffc0200616:	868d                	srai	a3,a3,0x3
ffffffffc0200618:	00007817          	auipc	a6,0x7
ffffffffc020061c:	29883803          	ld	a6,664(a6) # ffffffffc02078b0 <error_string+0x38>
ffffffffc0200620:	030686b3          	mul	a3,a3,a6
ffffffffc0200624:	00007597          	auipc	a1,0x7
ffffffffc0200628:	29c5b583          	ld	a1,668(a1) # ffffffffc02078c0 <nbase>
ffffffffc020062c:	96ae                	add	a3,a3,a1
ffffffffc020062e:	a021                	j	ffffffffc0200636 <insert_free+0x4a>
ffffffffc0200630:	6718                	ld	a4,8(a4)
ffffffffc0200632:	00c70c63          	beq	a4,a2,ffffffffc020064a <insert_free+0x5e>
           page2ppn(le2page(le, page_link)) < page2ppn(p)) {
ffffffffc0200636:	fe870793          	addi	a5,a4,-24
ffffffffc020063a:	411787b3          	sub	a5,a5,a7
ffffffffc020063e:	878d                	srai	a5,a5,0x3
ffffffffc0200640:	030787b3          	mul	a5,a5,a6
ffffffffc0200644:	97ae                	add	a5,a5,a1
    while (le != &free_list &&
ffffffffc0200646:	fed7e5e3          	bltu	a5,a3,ffffffffc0200630 <insert_free+0x44>
    __list_add(elm, listelm->prev, listelm);
ffffffffc020064a:	631c                	ld	a5,0(a4)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020064c:	00673023          	sd	t1,0(a4)
ffffffffc0200650:	0067b423          	sd	t1,8(a5)
    elm->next = next;
ffffffffc0200654:	f118                	sd	a4,32(a0)
    elm->prev = prev;
ffffffffc0200656:	ed1c                	sd	a5,24(a0)
ffffffffc0200658:	8082                	ret
insert_free(struct Page *p) {
ffffffffc020065a:	1141                	addi	sp,sp,-16
    assert(PageProperty(p) && list_empty(&p->page_link));
ffffffffc020065c:	00004697          	auipc	a3,0x4
ffffffffc0200660:	74c68693          	addi	a3,a3,1868 # ffffffffc0204da8 <etext+0x262>
ffffffffc0200664:	00004617          	auipc	a2,0x4
ffffffffc0200668:	77460613          	addi	a2,a2,1908 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020066c:	04800593          	li	a1,72
ffffffffc0200670:	00004517          	auipc	a0,0x4
ffffffffc0200674:	78050513          	addi	a0,a0,1920 # ffffffffc0204df0 <etext+0x2aa>
insert_free(struct Page *p) {
ffffffffc0200678:	e406                	sd	ra,8(sp)
    assert(PageProperty(p) && list_empty(&p->page_link));
ffffffffc020067a:	b49ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020067e <block_pages.part.0>:
block_pages(int u) {
ffffffffc020067e:	1141                	addi	sp,sp,-16
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc0200680:	00004697          	auipc	a3,0x4
ffffffffc0200684:	79068693          	addi	a3,a3,1936 # ffffffffc0204e10 <etext+0x2ca>
ffffffffc0200688:	00004617          	auipc	a2,0x4
ffffffffc020068c:	75060613          	addi	a2,a2,1872 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200690:	45e9                	li	a1,26
ffffffffc0200692:	00004517          	auipc	a0,0x4
ffffffffc0200696:	75e50513          	addi	a0,a0,1886 # ffffffffc0204df0 <etext+0x2aa>
block_pages(int u) {
ffffffffc020069a:	e406                	sd	ra,8(sp)
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc020069c:	b27ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02006a0 <set_free_head>:
    assert((p->flags & BUDDY_MANAGED) && !PageReserved(p));
ffffffffc02006a0:	651c                	ld	a5,8(a0)
set_free_head(struct Page *p, int u) {
ffffffffc02006a2:	1141                	addi	sp,sp,-16
ffffffffc02006a4:	e406                	sd	ra,8(sp)
    assert((p->flags & BUDDY_MANAGED) && !PageReserved(p));
ffffffffc02006a6:	4711                	li	a4,4
ffffffffc02006a8:	0057f693          	andi	a3,a5,5
ffffffffc02006ac:	02e69863          	bne	a3,a4,ffffffffc02006dc <set_free_head+0x3c>
    assert(!(p->flags & BUDDY_ALLOCATED));
ffffffffc02006b0:	0087f713          	andi	a4,a5,8
ffffffffc02006b4:	e735                	bnez	a4,ffffffffc0200720 <set_free_head+0x80>
    assert(list_empty(&p->page_link));
ffffffffc02006b6:	7114                	ld	a3,32(a0)
ffffffffc02006b8:	01850713          	addi	a4,a0,24
ffffffffc02006bc:	04e69263          	bne	a3,a4,ffffffffc0200700 <set_free_head+0x60>
    p->u = u;
ffffffffc02006c0:	c94c                	sw	a1,20(a0)
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc02006c2:	477d                	li	a4,31
ffffffffc02006c4:	02b76c63          	bltu	a4,a1,ffffffffc02006fc <set_free_head+0x5c>
}
ffffffffc02006c8:	60a2                	ld	ra,8(sp)
    return (size_t)1 << u;
ffffffffc02006ca:	4705                	li	a4,1
ffffffffc02006cc:	00b715b3          	sll	a1,a4,a1
    SetPageProperty(p);
ffffffffc02006d0:	0027e793          	ori	a5,a5,2
    p->property = block_pages(u);
ffffffffc02006d4:	c90c                	sw	a1,16(a0)
    SetPageProperty(p);
ffffffffc02006d6:	e51c                	sd	a5,8(a0)
}
ffffffffc02006d8:	0141                	addi	sp,sp,16
ffffffffc02006da:	8082                	ret
    assert((p->flags & BUDDY_MANAGED) && !PageReserved(p));
ffffffffc02006dc:	00004697          	auipc	a3,0x4
ffffffffc02006e0:	75468693          	addi	a3,a3,1876 # ffffffffc0204e30 <etext+0x2ea>
ffffffffc02006e4:	00004617          	auipc	a2,0x4
ffffffffc02006e8:	6f460613          	addi	a2,a2,1780 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02006ec:	03e00593          	li	a1,62
ffffffffc02006f0:	00004517          	auipc	a0,0x4
ffffffffc02006f4:	70050513          	addi	a0,a0,1792 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc02006f8:	acbff0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc02006fc:	f83ff0ef          	jal	ra,ffffffffc020067e <block_pages.part.0>
    assert(list_empty(&p->page_link));
ffffffffc0200700:	00004697          	auipc	a3,0x4
ffffffffc0200704:	78068693          	addi	a3,a3,1920 # ffffffffc0204e80 <etext+0x33a>
ffffffffc0200708:	00004617          	auipc	a2,0x4
ffffffffc020070c:	6d060613          	addi	a2,a2,1744 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200710:	04000593          	li	a1,64
ffffffffc0200714:	00004517          	auipc	a0,0x4
ffffffffc0200718:	6dc50513          	addi	a0,a0,1756 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc020071c:	aa7ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!(p->flags & BUDDY_ALLOCATED));
ffffffffc0200720:	00004697          	auipc	a3,0x4
ffffffffc0200724:	74068693          	addi	a3,a3,1856 # ffffffffc0204e60 <etext+0x31a>
ffffffffc0200728:	00004617          	auipc	a2,0x4
ffffffffc020072c:	6b060613          	addi	a2,a2,1712 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200730:	03f00593          	li	a1,63
ffffffffc0200734:	00004517          	auipc	a0,0x4
ffffffffc0200738:	6bc50513          	addi	a0,a0,1724 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc020073c:	a87ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200740 <request_order>:
    if (n == 0 || n > block_pages(BUDDY_MAX_ORDER) ||
ffffffffc0200740:	800007b7          	lui	a5,0x80000
ffffffffc0200744:	fff50713          	addi	a4,a0,-1
ffffffffc0200748:	fff7c793          	not	a5,a5
ffffffffc020074c:	04e7e063          	bltu	a5,a4,ffffffffc020078c <request_order+0x4c>
        npage <= nbase || n > npage - nbase) {
ffffffffc0200750:	000ab797          	auipc	a5,0xab
ffffffffc0200754:	1d07b783          	ld	a5,464(a5) # ffffffffc02ab920 <npage>
ffffffffc0200758:	00007717          	auipc	a4,0x7
ffffffffc020075c:	16873703          	ld	a4,360(a4) # ffffffffc02078c0 <nbase>
    if (n == 0 || n > block_pages(BUDDY_MAX_ORDER) ||
ffffffffc0200760:	02f77663          	bgeu	a4,a5,ffffffffc020078c <request_order+0x4c>
        npage <= nbase || n > npage - nbase) {
ffffffffc0200764:	8f99                	sub	a5,a5,a4
ffffffffc0200766:	02a7e363          	bltu	a5,a0,ffffffffc020078c <request_order+0x4c>
    *u = 0;
ffffffffc020076a:	0005a023          	sw	zero,0(a1)
    while (block_pages(*u) < n) {
ffffffffc020076e:	4781                	li	a5,0
    return (size_t)1 << u;
ffffffffc0200770:	4685                	li	a3,1
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc0200772:	02000613          	li	a2,32
ffffffffc0200776:	a029                	j	ffffffffc0200780 <request_order+0x40>
        ++*u;  /* bounded above before shifting; cannot overflow */
ffffffffc0200778:	2785                	addiw	a5,a5,1
ffffffffc020077a:	c19c                	sw	a5,0(a1)
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc020077c:	00c78a63          	beq	a5,a2,ffffffffc0200790 <request_order+0x50>
    return (size_t)1 << u;
ffffffffc0200780:	00f69733          	sll	a4,a3,a5
    while (block_pages(*u) < n) {
ffffffffc0200784:	fea76ae3          	bltu	a4,a0,ffffffffc0200778 <request_order+0x38>
ffffffffc0200788:	4505                	li	a0,1
ffffffffc020078a:	8082                	ret
        return 0;
ffffffffc020078c:	4501                	li	a0,0
}
ffffffffc020078e:	8082                	ret
request_order(size_t n, int *u) {
ffffffffc0200790:	1141                	addi	sp,sp,-16
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc0200792:	00004697          	auipc	a3,0x4
ffffffffc0200796:	67e68693          	addi	a3,a3,1662 # ffffffffc0204e10 <etext+0x2ca>
ffffffffc020079a:	00004617          	auipc	a2,0x4
ffffffffc020079e:	63e60613          	addi	a2,a2,1598 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02007a2:	45e9                	li	a1,26
ffffffffc02007a4:	00004517          	auipc	a0,0x4
ffffffffc02007a8:	64c50513          	addi	a0,a0,1612 # ffffffffc0204df0 <etext+0x2aa>
request_order(size_t n, int *u) {
ffffffffc02007ac:	e406                	sd	ra,8(sp)
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc02007ae:	a15ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02007b2 <merge_free>:
    while (p->u < BUDDY_MAX_ORDER) {
ffffffffc02007b2:	4950                	lw	a2,20(a0)
ffffffffc02007b4:	47f9                	li	a5,30
ffffffffc02007b6:	10c7c463          	blt	a5,a2,ffffffffc02008be <merge_free+0x10c>
merge_free(struct Page *p) {
ffffffffc02007ba:	7179                	addi	sp,sp,-48
    p->property = 0;
ffffffffc02007bc:	5f7d                	li	t5,-1
merge_free(struct Page *p) {
ffffffffc02007be:	f022                	sd	s0,32(sp)
ffffffffc02007c0:	f406                	sd	ra,40(sp)
ffffffffc02007c2:	ec26                	sd	s1,24(sp)
ffffffffc02007c4:	e84a                	sd	s2,16(sp)
ffffffffc02007c6:	e44e                	sd	s3,8(sp)
ffffffffc02007c8:	000ab317          	auipc	t1,0xab
ffffffffc02007cc:	16033303          	ld	t1,352(t1) # ffffffffc02ab928 <pages>
ffffffffc02007d0:	00007897          	auipc	a7,0x7
ffffffffc02007d4:	0f08b883          	ld	a7,240(a7) # ffffffffc02078c0 <nbase>
        assert((size << 1) <= npage - page2ppn(low));
ffffffffc02007d8:	000ab417          	auipc	s0,0xab
ffffffffc02007dc:	14843403          	ld	s0,328(s0) # ffffffffc02ab920 <npage>
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc02007e0:	4e7d                	li	t3,31
    return (size_t)1 << u;
ffffffffc02007e2:	4e85                	li	t4,1
ffffffffc02007e4:	00007817          	auipc	a6,0x7
ffffffffc02007e8:	0cc83803          	ld	a6,204(a6) # ffffffffc02078b0 <error_string+0x38>
        if (le == &free_list) {
ffffffffc02007ec:	0000bf97          	auipc	t6,0xb
ffffffffc02007f0:	82cf8f93          	addi	t6,t6,-2004 # ffffffffc020b018 <free_area>
        assert(!PageReserved(q) && (q->flags & BUDDY_MANAGED) &&
ffffffffc02007f4:	4391                	li	t2,4
        assert(low + size == high);
ffffffffc02007f6:	02800293          	li	t0,40
    p->property = 0;
ffffffffc02007fa:	1f02                	slli	t5,t5,0x20
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc02007fc:	14ce6263          	bltu	t3,a2,ffffffffc0200940 <merge_free+0x18e>
ffffffffc0200800:	40650733          	sub	a4,a0,t1
ffffffffc0200804:	870d                	srai	a4,a4,0x3
ffffffffc0200806:	03070733          	mul	a4,a4,a6
    return (size_t)1 << u;
ffffffffc020080a:	00ce95b3          	sll	a1,t4,a2
ffffffffc020080e:	9746                	add	a4,a4,a7
        ppn_t ppn = page2ppn(p), buddy_ppn = ppn ^ size;
ffffffffc0200810:	00b74933          	xor	s2,a4,a1
                                          : list_next(&p->page_link);
ffffffffc0200814:	0ae97363          	bgeu	s2,a4,ffffffffc02008ba <merge_free+0x108>
    return listelm->prev;
ffffffffc0200818:	6d04                	ld	s1,24(a0)
        if (le == &free_list) {
ffffffffc020081a:	09f48963          	beq	s1,t6,ffffffffc02008ac <merge_free+0xfa>
        struct Page *q = le2page(le, page_link);
ffffffffc020081e:	fe848793          	addi	a5,s1,-24
ffffffffc0200822:	406786b3          	sub	a3,a5,t1
ffffffffc0200826:	868d                	srai	a3,a3,0x3
ffffffffc0200828:	030686b3          	mul	a3,a3,a6
ffffffffc020082c:	96c6                	add	a3,a3,a7
        if (page2ppn(q) != buddy_ppn || !PageProperty(q) || q->u != p->u) {
ffffffffc020082e:	06d91f63          	bne	s2,a3,ffffffffc02008ac <merge_free+0xfa>
ffffffffc0200832:	ff04b683          	ld	a3,-16(s1)
ffffffffc0200836:	0026f993          	andi	s3,a3,2
ffffffffc020083a:	06098963          	beqz	s3,ffffffffc02008ac <merge_free+0xfa>
ffffffffc020083e:	ffc4a483          	lw	s1,-4(s1)
ffffffffc0200842:	06c49563          	bne	s1,a2,ffffffffc02008ac <merge_free+0xfa>
        assert(!PageReserved(q) && (q->flags & BUDDY_MANAGED) &&
ffffffffc0200846:	8ab5                	andi	a3,a3,13
ffffffffc0200848:	0c769c63          	bne	a3,t2,ffffffffc0200920 <merge_free+0x16e>
        struct Page *low = buddy_ppn < ppn ? q : p;
ffffffffc020084c:	00e97563          	bgeu	s2,a4,ffffffffc0200856 <merge_free+0xa4>
ffffffffc0200850:	873e                	mv	a4,a5
ffffffffc0200852:	87aa                	mv	a5,a0
ffffffffc0200854:	853a                	mv	a0,a4
        assert(low + size == high);
ffffffffc0200856:	00c29733          	sll	a4,t0,a2
ffffffffc020085a:	972a                	add	a4,a4,a0
ffffffffc020085c:	0ae79263          	bne	a5,a4,ffffffffc0200900 <merge_free+0x14e>
ffffffffc0200860:	40650733          	sub	a4,a0,t1
ffffffffc0200864:	870d                	srai	a4,a4,0x3
ffffffffc0200866:	03070733          	mul	a4,a4,a6
        assert((page2ppn(low) & ((size << 1) - 1)) == 0);
ffffffffc020086a:	0586                	slli	a1,a1,0x1
ffffffffc020086c:	fff58693          	addi	a3,a1,-1
ffffffffc0200870:	9746                	add	a4,a4,a7
ffffffffc0200872:	8ef9                	and	a3,a3,a4
ffffffffc0200874:	e6b5                	bnez	a3,ffffffffc02008e0 <merge_free+0x12e>
        assert((size << 1) <= npage - page2ppn(low));
ffffffffc0200876:	40e40733          	sub	a4,s0,a4
ffffffffc020087a:	04b76363          	bltu	a4,a1,ffffffffc02008c0 <merge_free+0x10e>
    __list_del(listelm->prev, listelm->next);
ffffffffc020087e:	6f84                	ld	s1,24(a5)
ffffffffc0200880:	738c                	ld	a1,32(a5)
    ClearPageProperty(p);
ffffffffc0200882:	6794                	ld	a3,8(a5)
        int next_u = p->u + 1;
ffffffffc0200884:	0016071b          	addiw	a4,a2,1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200888:	e48c                	sd	a1,8(s1)
    next->prev = prev;
ffffffffc020088a:	e184                	sd	s1,0(a1)
        list_del_init(&high->page_link);
ffffffffc020088c:	01878613          	addi	a2,a5,24
    ClearPageProperty(p);
ffffffffc0200890:	9af5                	andi	a3,a3,-3
    elm->prev = elm->next = elm;
ffffffffc0200892:	f390                	sd	a2,32(a5)
ffffffffc0200894:	ef90                	sd	a2,24(a5)
ffffffffc0200896:	e794                	sd	a3,8(a5)
    p->property = 0;
ffffffffc0200898:	01e7b823          	sd	t5,16(a5)
    return (size_t)1 << u;
ffffffffc020089c:	00ee97b3          	sll	a5,t4,a4
        int next_u = p->u + 1;
ffffffffc02008a0:	0007061b          	sext.w	a2,a4
        low->u = next_u;
ffffffffc02008a4:	c958                	sw	a4,20(a0)
        low->property = block_pages(next_u);
ffffffffc02008a6:	c91c                	sw	a5,16(a0)
    while (p->u < BUDDY_MAX_ORDER) {
ffffffffc02008a8:	f5c61ae3          	bne	a2,t3,ffffffffc02007fc <merge_free+0x4a>
}
ffffffffc02008ac:	70a2                	ld	ra,40(sp)
ffffffffc02008ae:	7402                	ld	s0,32(sp)
ffffffffc02008b0:	64e2                	ld	s1,24(sp)
ffffffffc02008b2:	6942                	ld	s2,16(sp)
ffffffffc02008b4:	69a2                	ld	s3,8(sp)
ffffffffc02008b6:	6145                	addi	sp,sp,48
ffffffffc02008b8:	8082                	ret
    return listelm->next;
ffffffffc02008ba:	7104                	ld	s1,32(a0)
ffffffffc02008bc:	bfb9                	j	ffffffffc020081a <merge_free+0x68>
ffffffffc02008be:	8082                	ret
        assert((size << 1) <= npage - page2ppn(low));
ffffffffc02008c0:	00004697          	auipc	a3,0x4
ffffffffc02008c4:	67868693          	addi	a3,a3,1656 # ffffffffc0204f38 <etext+0x3f2>
ffffffffc02008c8:	00004617          	auipc	a2,0x4
ffffffffc02008cc:	51060613          	addi	a2,a2,1296 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02008d0:	06a00593          	li	a1,106
ffffffffc02008d4:	00004517          	auipc	a0,0x4
ffffffffc02008d8:	51c50513          	addi	a0,a0,1308 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc02008dc:	8e7ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert((page2ppn(low) & ((size << 1) - 1)) == 0);
ffffffffc02008e0:	00004697          	auipc	a3,0x4
ffffffffc02008e4:	62868693          	addi	a3,a3,1576 # ffffffffc0204f08 <etext+0x3c2>
ffffffffc02008e8:	00004617          	auipc	a2,0x4
ffffffffc02008ec:	4f060613          	addi	a2,a2,1264 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02008f0:	06900593          	li	a1,105
ffffffffc02008f4:	00004517          	auipc	a0,0x4
ffffffffc02008f8:	4fc50513          	addi	a0,a0,1276 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc02008fc:	8c7ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(low + size == high);
ffffffffc0200900:	00004697          	auipc	a3,0x4
ffffffffc0200904:	5f068693          	addi	a3,a3,1520 # ffffffffc0204ef0 <etext+0x3aa>
ffffffffc0200908:	00004617          	auipc	a2,0x4
ffffffffc020090c:	4d060613          	addi	a2,a2,1232 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200910:	06800593          	li	a1,104
ffffffffc0200914:	00004517          	auipc	a0,0x4
ffffffffc0200918:	4dc50513          	addi	a0,a0,1244 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc020091c:	8a7ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(!PageReserved(q) && (q->flags & BUDDY_MANAGED) &&
ffffffffc0200920:	00004697          	auipc	a3,0x4
ffffffffc0200924:	58068693          	addi	a3,a3,1408 # ffffffffc0204ea0 <etext+0x35a>
ffffffffc0200928:	00004617          	auipc	a2,0x4
ffffffffc020092c:	4b060613          	addi	a2,a2,1200 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200930:	06400593          	li	a1,100
ffffffffc0200934:	00004517          	auipc	a0,0x4
ffffffffc0200938:	4bc50513          	addi	a0,a0,1212 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc020093c:	887ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc0200940:	00004697          	auipc	a3,0x4
ffffffffc0200944:	4d068693          	addi	a3,a3,1232 # ffffffffc0204e10 <etext+0x2ca>
ffffffffc0200948:	00004617          	auipc	a2,0x4
ffffffffc020094c:	49060613          	addi	a2,a2,1168 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200950:	45e9                	li	a1,26
ffffffffc0200952:	00004517          	auipc	a0,0x4
ffffffffc0200956:	49e50513          	addi	a0,a0,1182 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc020095a:	869ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020095e <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc020095e:	715d                	addi	sp,sp,-80
ffffffffc0200960:	f052                	sd	s4,32(sp)
    return npage > nbase && addr >= first &&
ffffffffc0200962:	000aba17          	auipc	s4,0xab
ffffffffc0200966:	fbea0a13          	addi	s4,s4,-66 # ffffffffc02ab920 <npage>
ffffffffc020096a:	000a3783          	ld	a5,0(s4)
default_free_pages(struct Page *base, size_t n) {
ffffffffc020096e:	f44e                	sd	s3,40(sp)
ffffffffc0200970:	e486                	sd	ra,72(sp)
ffffffffc0200972:	e0a2                	sd	s0,64(sp)
ffffffffc0200974:	fc26                	sd	s1,56(sp)
ffffffffc0200976:	f84a                	sd	s2,48(sp)
ffffffffc0200978:	ec56                	sd	s5,24(sp)
    return npage > nbase && addr >= first &&
ffffffffc020097a:	00007997          	auipc	s3,0x7
ffffffffc020097e:	f469b983          	ld	s3,-186(s3) # ffffffffc02078c0 <nbase>
           (addr - first) % sizeof(struct Page) == 0 &&
ffffffffc0200982:	14f9f163          	bgeu	s3,a5,ffffffffc0200ac4 <default_free_pages+0x166>
    uintptr_t addr = (uintptr_t)p, first = (uintptr_t)pages;
ffffffffc0200986:	000aba97          	auipc	s5,0xab
ffffffffc020098a:	fa2a8a93          	addi	s5,s5,-94 # ffffffffc02ab928 <pages>
ffffffffc020098e:	000ab703          	ld	a4,0(s5)
ffffffffc0200992:	892a                	mv	s2,a0
ffffffffc0200994:	84aa                	mv	s1,a0
    return npage > nbase && addr >= first &&
ffffffffc0200996:	12e56763          	bltu	a0,a4,ffffffffc0200ac4 <default_free_pages+0x166>
           (addr - first) % sizeof(struct Page) == 0 &&
ffffffffc020099a:	40e50733          	sub	a4,a0,a4
ffffffffc020099e:	02800693          	li	a3,40
ffffffffc02009a2:	02d77633          	remu	a2,a4,a3
    return npage > nbase && addr >= first &&
ffffffffc02009a6:	10061f63          	bnez	a2,ffffffffc0200ac4 <default_free_pages+0x166>
           (addr - first) / sizeof(struct Page) < npage - nbase;
ffffffffc02009aa:	02d75733          	divu	a4,a4,a3
ffffffffc02009ae:	413787b3          	sub	a5,a5,s3
           (addr - first) % sizeof(struct Page) == 0 &&
ffffffffc02009b2:	10f77963          	bgeu	a4,a5,ffffffffc0200ac4 <default_free_pages+0x166>
ffffffffc02009b6:	852e                	mv	a0,a1
    assert(valid_page(base) && request_order(n, &u));
ffffffffc02009b8:	006c                	addi	a1,sp,12
ffffffffc02009ba:	d87ff0ef          	jal	ra,ffffffffc0200740 <request_order>
ffffffffc02009be:	10050363          	beqz	a0,ffffffffc0200ac4 <default_free_pages+0x166>
    assert(!PageReserved(base) && (base->flags & BUDDY_MANAGED));
ffffffffc02009c2:	00893883          	ld	a7,8(s2)
ffffffffc02009c6:	4791                	li	a5,4
ffffffffc02009c8:	0058f713          	andi	a4,a7,5
ffffffffc02009cc:	18f71c63          	bne	a4,a5,ffffffffc0200b64 <default_free_pages+0x206>
    assert((base->flags & BUDDY_ALLOCATED) && !PageProperty(base));
ffffffffc02009d0:	00a8f793          	andi	a5,a7,10
ffffffffc02009d4:	4721                	li	a4,8
ffffffffc02009d6:	24e79763          	bne	a5,a4,ffffffffc0200c24 <default_free_pages+0x2c6>
    assert(base->u >= 0 && base->u <= BUDDY_MAX_ORDER);
ffffffffc02009da:	01492503          	lw	a0,20(s2)
ffffffffc02009de:	47fd                	li	a5,31
ffffffffc02009e0:	22a7e263          	bltu	a5,a0,ffffffffc0200c04 <default_free_pages+0x2a6>
    assert(base->u == u);
ffffffffc02009e4:	45b2                	lw	a1,12(sp)
ffffffffc02009e6:	1eb51f63          	bne	a0,a1,ffffffffc0200be4 <default_free_pages+0x286>
    assert(base->property == size && size <= npage - page2ppn(base));
ffffffffc02009ea:	01096783          	lwu	a5,16(s2)
    return (size_t)1 << u;
ffffffffc02009ee:	4405                	li	s0,1
ffffffffc02009f0:	00a41433          	sll	s0,s0,a0
    assert(base->property == size && size <= npage - page2ppn(base));
ffffffffc02009f4:	1c879863          	bne	a5,s0,ffffffffc0200bc4 <default_free_pages+0x266>
ffffffffc02009f8:	000ab683          	ld	a3,0(s5)
ffffffffc02009fc:	00007717          	auipc	a4,0x7
ffffffffc0200a00:	eb473703          	ld	a4,-332(a4) # ffffffffc02078b0 <error_string+0x38>
ffffffffc0200a04:	000a3783          	ld	a5,0(s4)
ffffffffc0200a08:	40d906b3          	sub	a3,s2,a3
ffffffffc0200a0c:	868d                	srai	a3,a3,0x3
ffffffffc0200a0e:	02e686b3          	mul	a3,a3,a4
ffffffffc0200a12:	01368733          	add	a4,a3,s3
ffffffffc0200a16:	8f99                	sub	a5,a5,a4
ffffffffc0200a18:	1a87e663          	bltu	a5,s0,ffffffffc0200bc4 <default_free_pages+0x266>
    assert((page2ppn(base) & (size - 1)) == 0);
ffffffffc0200a1c:	fff40693          	addi	a3,s0,-1
ffffffffc0200a20:	8ef9                	and	a3,a3,a4
ffffffffc0200a22:	18069163          	bnez	a3,ffffffffc0200ba4 <default_free_pages+0x246>
    assert(size <= (size_t)~0U - nr_free);
ffffffffc0200a26:	0000a997          	auipc	s3,0xa
ffffffffc0200a2a:	5f298993          	addi	s3,s3,1522 # ffffffffc020b018 <free_area>
ffffffffc0200a2e:	0109e783          	lwu	a5,16(s3)
ffffffffc0200a32:	537d                	li	t1,-1
ffffffffc0200a34:	02035613          	srli	a2,t1,0x20
ffffffffc0200a38:	8e1d                	sub	a2,a2,a5
ffffffffc0200a3a:	8746                	mv	a4,a7
ffffffffc0200a3c:	87ca                	mv	a5,s2
        assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
ffffffffc0200a3e:	4831                	li	a6,12
            assert(p->u == BUDDY_NO_ORDER && p->property == 0);
ffffffffc0200a40:	1302                	slli	t1,t1,0x20
    assert(size <= (size_t)~0U - nr_free);
ffffffffc0200a42:	00867463          	bgeu	a2,s0,ffffffffc0200a4a <default_free_pages+0xec>
ffffffffc0200a46:	aa3d                	j	ffffffffc0200b84 <default_free_pages+0x226>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200a48:	6798                	ld	a4,8(a5)
ffffffffc0200a4a:	00377613          	andi	a2,a4,3
ffffffffc0200a4e:	ea59                	bnez	a2,ffffffffc0200ae4 <default_free_pages+0x186>
        assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
ffffffffc0200a50:	8b31                	andi	a4,a4,12
ffffffffc0200a52:	0d071963          	bne	a4,a6,ffffffffc0200b24 <default_free_pages+0x1c6>
        assert(list_empty(&p->page_link));
ffffffffc0200a56:	7390                	ld	a2,32(a5)
ffffffffc0200a58:	01878713          	addi	a4,a5,24
ffffffffc0200a5c:	0ae61463          	bne	a2,a4,ffffffffc0200b04 <default_free_pages+0x1a6>
        if (i != 0) {
ffffffffc0200a60:	c681                	beqz	a3,ffffffffc0200a68 <default_free_pages+0x10a>
            assert(p->u == BUDDY_NO_ORDER && p->property == 0);
ffffffffc0200a62:	6b98                	ld	a4,16(a5)
ffffffffc0200a64:	0e671063          	bne	a4,t1,ffffffffc0200b44 <default_free_pages+0x1e6>
    for (size_t i = 0; i < size; ++i) {
ffffffffc0200a68:	0685                	addi	a3,a3,1
ffffffffc0200a6a:	02878793          	addi	a5,a5,40
ffffffffc0200a6e:	fcd41de3          	bne	s0,a3,ffffffffc0200a48 <default_free_pages+0xea>
ffffffffc0200a72:	02800793          	li	a5,40
ffffffffc0200a76:	00a797b3          	sll	a5,a5,a0
ffffffffc0200a7a:	97ca                	add	a5,a5,s2
ffffffffc0200a7c:	a019                	j	ffffffffc0200a82 <default_free_pages+0x124>
        base[i].flags &= ~BUDDY_ALLOCATED;
ffffffffc0200a7e:	0084b883          	ld	a7,8(s1)
ffffffffc0200a82:	ff78f893          	andi	a7,a7,-9
ffffffffc0200a86:	0114b423          	sd	a7,8(s1)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200a8a:	0004a023          	sw	zero,0(s1)
    for (size_t i = 0; i < size; ++i) {
ffffffffc0200a8e:	02848493          	addi	s1,s1,40
ffffffffc0200a92:	fe9796e3          	bne	a5,s1,ffffffffc0200a7e <default_free_pages+0x120>
    set_free_head(base, u);
ffffffffc0200a96:	854a                	mv	a0,s2
ffffffffc0200a98:	c09ff0ef          	jal	ra,ffffffffc02006a0 <set_free_head>
    nr_free += size;  /* merging never changes this count */
ffffffffc0200a9c:	0109a783          	lw	a5,16(s3)
    insert_free(base);
ffffffffc0200aa0:	854a                	mv	a0,s2
    nr_free += size;  /* merging never changes this count */
ffffffffc0200aa2:	9c3d                	addw	s0,s0,a5
ffffffffc0200aa4:	0089a823          	sw	s0,16(s3)
    insert_free(base);
ffffffffc0200aa8:	b45ff0ef          	jal	ra,ffffffffc02005ec <insert_free>
    merge_free(base);
ffffffffc0200aac:	854a                	mv	a0,s2
ffffffffc0200aae:	d05ff0ef          	jal	ra,ffffffffc02007b2 <merge_free>
}
ffffffffc0200ab2:	60a6                	ld	ra,72(sp)
ffffffffc0200ab4:	6406                	ld	s0,64(sp)
ffffffffc0200ab6:	74e2                	ld	s1,56(sp)
ffffffffc0200ab8:	7942                	ld	s2,48(sp)
ffffffffc0200aba:	79a2                	ld	s3,40(sp)
ffffffffc0200abc:	7a02                	ld	s4,32(sp)
ffffffffc0200abe:	6ae2                	ld	s5,24(sp)
ffffffffc0200ac0:	6161                	addi	sp,sp,80
ffffffffc0200ac2:	8082                	ret
    assert(valid_page(base) && request_order(n, &u));
ffffffffc0200ac4:	00004697          	auipc	a3,0x4
ffffffffc0200ac8:	49c68693          	addi	a3,a3,1180 # ffffffffc0204f60 <etext+0x41a>
ffffffffc0200acc:	00004617          	auipc	a2,0x4
ffffffffc0200ad0:	30c60613          	addi	a2,a2,780 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200ad4:	0c400593          	li	a1,196
ffffffffc0200ad8:	00004517          	auipc	a0,0x4
ffffffffc0200adc:	31850513          	addi	a0,a0,792 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200ae0:	ee2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200ae4:	00004697          	auipc	a3,0x4
ffffffffc0200ae8:	5e468693          	addi	a3,a3,1508 # ffffffffc02050c8 <etext+0x582>
ffffffffc0200aec:	00004617          	auipc	a2,0x4
ffffffffc0200af0:	2ec60613          	addi	a2,a2,748 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200af4:	0d200593          	li	a1,210
ffffffffc0200af8:	00004517          	auipc	a0,0x4
ffffffffc0200afc:	2f850513          	addi	a0,a0,760 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200b00:	ec2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(list_empty(&p->page_link));
ffffffffc0200b04:	00004697          	auipc	a3,0x4
ffffffffc0200b08:	37c68693          	addi	a3,a3,892 # ffffffffc0204e80 <etext+0x33a>
ffffffffc0200b0c:	00004617          	auipc	a2,0x4
ffffffffc0200b10:	2cc60613          	addi	a2,a2,716 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200b14:	0d400593          	li	a1,212
ffffffffc0200b18:	00004517          	auipc	a0,0x4
ffffffffc0200b1c:	2d850513          	addi	a0,a0,728 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200b20:	ea2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
ffffffffc0200b24:	00004697          	auipc	a3,0x4
ffffffffc0200b28:	5cc68693          	addi	a3,a3,1484 # ffffffffc02050f0 <etext+0x5aa>
ffffffffc0200b2c:	00004617          	auipc	a2,0x4
ffffffffc0200b30:	2ac60613          	addi	a2,a2,684 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200b34:	0d300593          	li	a1,211
ffffffffc0200b38:	00004517          	auipc	a0,0x4
ffffffffc0200b3c:	2b850513          	addi	a0,a0,696 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200b40:	e82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(p->u == BUDDY_NO_ORDER && p->property == 0);
ffffffffc0200b44:	00004697          	auipc	a3,0x4
ffffffffc0200b48:	5ec68693          	addi	a3,a3,1516 # ffffffffc0205130 <etext+0x5ea>
ffffffffc0200b4c:	00004617          	auipc	a2,0x4
ffffffffc0200b50:	28c60613          	addi	a2,a2,652 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200b54:	0d600593          	li	a1,214
ffffffffc0200b58:	00004517          	auipc	a0,0x4
ffffffffc0200b5c:	29850513          	addi	a0,a0,664 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200b60:	e62ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(!PageReserved(base) && (base->flags & BUDDY_MANAGED));
ffffffffc0200b64:	00004697          	auipc	a3,0x4
ffffffffc0200b68:	42c68693          	addi	a3,a3,1068 # ffffffffc0204f90 <etext+0x44a>
ffffffffc0200b6c:	00004617          	auipc	a2,0x4
ffffffffc0200b70:	26c60613          	addi	a2,a2,620 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200b74:	0c500593          	li	a1,197
ffffffffc0200b78:	00004517          	auipc	a0,0x4
ffffffffc0200b7c:	27850513          	addi	a0,a0,632 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200b80:	e42ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(size <= (size_t)~0U - nr_free);
ffffffffc0200b84:	00004697          	auipc	a3,0x4
ffffffffc0200b88:	52468693          	addi	a3,a3,1316 # ffffffffc02050a8 <etext+0x562>
ffffffffc0200b8c:	00004617          	auipc	a2,0x4
ffffffffc0200b90:	24c60613          	addi	a2,a2,588 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200b94:	0cf00593          	li	a1,207
ffffffffc0200b98:	00004517          	auipc	a0,0x4
ffffffffc0200b9c:	25850513          	addi	a0,a0,600 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200ba0:	e22ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((page2ppn(base) & (size - 1)) == 0);
ffffffffc0200ba4:	00004697          	auipc	a3,0x4
ffffffffc0200ba8:	4dc68693          	addi	a3,a3,1244 # ffffffffc0205080 <etext+0x53a>
ffffffffc0200bac:	00004617          	auipc	a2,0x4
ffffffffc0200bb0:	22c60613          	addi	a2,a2,556 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200bb4:	0ce00593          	li	a1,206
ffffffffc0200bb8:	00004517          	auipc	a0,0x4
ffffffffc0200bbc:	23850513          	addi	a0,a0,568 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200bc0:	e02ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(base->property == size && size <= npage - page2ppn(base));
ffffffffc0200bc4:	00004697          	auipc	a3,0x4
ffffffffc0200bc8:	47c68693          	addi	a3,a3,1148 # ffffffffc0205040 <etext+0x4fa>
ffffffffc0200bcc:	00004617          	auipc	a2,0x4
ffffffffc0200bd0:	20c60613          	addi	a2,a2,524 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200bd4:	0cd00593          	li	a1,205
ffffffffc0200bd8:	00004517          	auipc	a0,0x4
ffffffffc0200bdc:	21850513          	addi	a0,a0,536 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200be0:	de2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(base->u == u);
ffffffffc0200be4:	00004697          	auipc	a3,0x4
ffffffffc0200be8:	44c68693          	addi	a3,a3,1100 # ffffffffc0205030 <etext+0x4ea>
ffffffffc0200bec:	00004617          	auipc	a2,0x4
ffffffffc0200bf0:	1ec60613          	addi	a2,a2,492 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200bf4:	0cb00593          	li	a1,203
ffffffffc0200bf8:	00004517          	auipc	a0,0x4
ffffffffc0200bfc:	1f850513          	addi	a0,a0,504 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200c00:	dc2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(base->u >= 0 && base->u <= BUDDY_MAX_ORDER);
ffffffffc0200c04:	00004697          	auipc	a3,0x4
ffffffffc0200c08:	3fc68693          	addi	a3,a3,1020 # ffffffffc0205000 <etext+0x4ba>
ffffffffc0200c0c:	00004617          	auipc	a2,0x4
ffffffffc0200c10:	1cc60613          	addi	a2,a2,460 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200c14:	0c700593          	li	a1,199
ffffffffc0200c18:	00004517          	auipc	a0,0x4
ffffffffc0200c1c:	1d850513          	addi	a0,a0,472 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200c20:	da2ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((base->flags & BUDDY_ALLOCATED) && !PageProperty(base));
ffffffffc0200c24:	00004697          	auipc	a3,0x4
ffffffffc0200c28:	3a468693          	addi	a3,a3,932 # ffffffffc0204fc8 <etext+0x482>
ffffffffc0200c2c:	00004617          	auipc	a2,0x4
ffffffffc0200c30:	1ac60613          	addi	a2,a2,428 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200c34:	0c600593          	li	a1,198
ffffffffc0200c38:	00004517          	auipc	a0,0x4
ffffffffc0200c3c:	1b850513          	addi	a0,a0,440 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200c40:	d82ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200c44 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0200c44:	7159                	addi	sp,sp,-112
ffffffffc0200c46:	f0a2                	sd	s0,96(sp)
ffffffffc0200c48:	f486                	sd	ra,104(sp)
ffffffffc0200c4a:	eca6                	sd	s1,88(sp)
ffffffffc0200c4c:	e8ca                	sd	s2,80(sp)
ffffffffc0200c4e:	e4ce                	sd	s3,72(sp)
ffffffffc0200c50:	e0d2                	sd	s4,64(sp)
ffffffffc0200c52:	fc56                	sd	s5,56(sp)
ffffffffc0200c54:	f85a                	sd	s6,48(sp)
ffffffffc0200c56:	f45e                	sd	s7,40(sp)
ffffffffc0200c58:	f062                	sd	s8,32(sp)
ffffffffc0200c5a:	ec66                	sd	s9,24(sp)
ffffffffc0200c5c:	e86a                	sd	s10,16(sp)
ffffffffc0200c5e:	e46e                	sd	s11,8(sp)
    return npage > nbase && addr >= first &&
ffffffffc0200c60:	000ab797          	auipc	a5,0xab
ffffffffc0200c64:	cc07b783          	ld	a5,-832(a5) # ffffffffc02ab920 <npage>
ffffffffc0200c68:	00007417          	auipc	s0,0x7
ffffffffc0200c6c:	c5843403          	ld	s0,-936(s0) # ffffffffc02078c0 <nbase>
           (addr - first) % sizeof(struct Page) == 0 &&
ffffffffc0200c70:	02f46263          	bltu	s0,a5,ffffffffc0200c94 <default_init_memmap+0x50>
    assert(valid_page(base) && n > 0);
ffffffffc0200c74:	00004697          	auipc	a3,0x4
ffffffffc0200c78:	4ec68693          	addi	a3,a3,1260 # ffffffffc0205160 <etext+0x61a>
ffffffffc0200c7c:	00004617          	auipc	a2,0x4
ffffffffc0200c80:	15c60613          	addi	a2,a2,348 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200c84:	07c00593          	li	a1,124
ffffffffc0200c88:	00004517          	auipc	a0,0x4
ffffffffc0200c8c:	16850513          	addi	a0,a0,360 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200c90:	d32ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t addr = (uintptr_t)p, first = (uintptr_t)pages;
ffffffffc0200c94:	000ab917          	auipc	s2,0xab
ffffffffc0200c98:	c9490913          	addi	s2,s2,-876 # ffffffffc02ab928 <pages>
ffffffffc0200c9c:	00093683          	ld	a3,0(s2)
ffffffffc0200ca0:	8caa                	mv	s9,a0
    return npage > nbase && addr >= first &&
ffffffffc0200ca2:	fcd569e3          	bltu	a0,a3,ffffffffc0200c74 <default_init_memmap+0x30>
           (addr - first) % sizeof(struct Page) == 0 &&
ffffffffc0200ca6:	40d506b3          	sub	a3,a0,a3
ffffffffc0200caa:	02800713          	li	a4,40
ffffffffc0200cae:	02e6f633          	remu	a2,a3,a4
    return npage > nbase && addr >= first &&
ffffffffc0200cb2:	f269                	bnez	a2,ffffffffc0200c74 <default_init_memmap+0x30>
           (addr - first) / sizeof(struct Page) < npage - nbase;
ffffffffc0200cb4:	02e6d633          	divu	a2,a3,a4
ffffffffc0200cb8:	40878733          	sub	a4,a5,s0
           (addr - first) % sizeof(struct Page) == 0 &&
ffffffffc0200cbc:	fae67ce3          	bgeu	a2,a4,ffffffffc0200c74 <default_init_memmap+0x30>
ffffffffc0200cc0:	8b2e                	mv	s6,a1
    assert(valid_page(base) && n > 0);
ffffffffc0200cc2:	d9cd                	beqz	a1,ffffffffc0200c74 <default_init_memmap+0x30>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cc4:	4036d793          	srai	a5,a3,0x3
ffffffffc0200cc8:	00007497          	auipc	s1,0x7
ffffffffc0200ccc:	be84b483          	ld	s1,-1048(s1) # ffffffffc02078b0 <error_string+0x38>
ffffffffc0200cd0:	029787b3          	mul	a5,a5,s1
    assert(n <= npage - page2ppn(base));
ffffffffc0200cd4:	40f707b3          	sub	a5,a4,a5
ffffffffc0200cd8:	12b7e763          	bltu	a5,a1,ffffffffc0200e06 <default_init_memmap+0x1c2>
    assert(n <= (size_t)~0U - nr_free);
ffffffffc0200cdc:	0000a817          	auipc	a6,0xa
ffffffffc0200ce0:	33c80813          	addi	a6,a6,828 # ffffffffc020b018 <free_area>
ffffffffc0200ce4:	01082503          	lw	a0,16(a6)
ffffffffc0200ce8:	fff54793          	not	a5,a0
ffffffffc0200cec:	1782                	slli	a5,a5,0x20
ffffffffc0200cee:	9381                	srli	a5,a5,0x20
ffffffffc0200cf0:	0eb7eb63          	bltu	a5,a1,ffffffffc0200de6 <default_init_memmap+0x1a2>
ffffffffc0200cf4:	058a                	slli	a1,a1,0x2
ffffffffc0200cf6:	95da                	add	a1,a1,s6
ffffffffc0200cf8:	058e                	slli	a1,a1,0x3
ffffffffc0200cfa:	00bc8633          	add	a2,s9,a1
ffffffffc0200cfe:	87e6                	mv	a5,s9
        assert(PageReserved(base + i));
ffffffffc0200d00:	6798                	ld	a4,8(a5)
ffffffffc0200d02:	8b05                	andi	a4,a4,1
ffffffffc0200d04:	c369                	beqz	a4,ffffffffc0200dc6 <default_init_memmap+0x182>
    for (size_t i = 0; i < n; ++i) {
ffffffffc0200d06:	02878793          	addi	a5,a5,40
ffffffffc0200d0a:	fef61be3          	bne	a2,a5,ffffffffc0200d00 <default_init_memmap+0xbc>
ffffffffc0200d0e:	01858713          	addi	a4,a1,24
ffffffffc0200d12:	018c8793          	addi	a5,s9,24
ffffffffc0200d16:	9766                	add	a4,a4,s9
        p->flags = BUDDY_MANAGED;
ffffffffc0200d18:	4591                	li	a1,4
        p->u = BUDDY_NO_ORDER;
ffffffffc0200d1a:	567d                	li	a2,-1
        p->flags = BUDDY_MANAGED;
ffffffffc0200d1c:	feb7b823          	sd	a1,-16(a5)
        p->property = 0;
ffffffffc0200d20:	fe07ac23          	sw	zero,-8(a5)
        p->u = BUDDY_NO_ORDER;
ffffffffc0200d24:	fec7ae23          	sw	a2,-4(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d28:	fe07a423          	sw	zero,-24(a5)
    elm->prev = elm->next = elm;
ffffffffc0200d2c:	e79c                	sd	a5,8(a5)
ffffffffc0200d2e:	e39c                	sd	a5,0(a5)
    for (size_t i = 0; i < n; ++i) {
ffffffffc0200d30:	02878793          	addi	a5,a5,40
ffffffffc0200d34:	fef714e3          	bne	a4,a5,ffffffffc0200d1c <default_init_memmap+0xd8>
    nr_free += n;
ffffffffc0200d38:	00ab053b          	addw	a0,s6,a0
    return (size_t)1 << u;
ffffffffc0200d3c:	4b85                	li	s7,1
ffffffffc0200d3e:	4a15                	li	s4,5
    nr_free += n;
ffffffffc0200d40:	00a82823          	sw	a0,16(a6)
        while (u < BUDDY_MAX_ORDER && block_pages(u + 1) <= n &&
ffffffffc0200d44:	4c7d                	li	s8,31
        base += size;
ffffffffc0200d46:	02800993          	li	s3,40
ffffffffc0200d4a:	01fb9a93          	slli	s5,s7,0x1f
ffffffffc0200d4e:	1a0a                	slli	s4,s4,0x22
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d50:	868d                	srai	a3,a3,0x3
ffffffffc0200d52:	029686b3          	mul	a3,a3,s1
        int u = 0;
ffffffffc0200d56:	4701                	li	a4,0
ffffffffc0200d58:	96a2                	add	a3,a3,s0
        while (u < BUDDY_MAX_ORDER && block_pages(u + 1) <= n &&
ffffffffc0200d5a:	a031                	j	ffffffffc0200d66 <default_init_memmap+0x122>
               (ppn & (block_pages(u + 1) - 1)) == 0) {
ffffffffc0200d5c:	17fd                	addi	a5,a5,-1
ffffffffc0200d5e:	8ff5                	and	a5,a5,a3
        while (u < BUDDY_MAX_ORDER && block_pages(u + 1) <= n &&
ffffffffc0200d60:	eb89                	bnez	a5,ffffffffc0200d72 <default_init_memmap+0x12e>
ffffffffc0200d62:	03870f63          	beq	a4,s8,ffffffffc0200da0 <default_init_memmap+0x15c>
ffffffffc0200d66:	85ba                	mv	a1,a4
ffffffffc0200d68:	2705                	addiw	a4,a4,1
    return (size_t)1 << u;
ffffffffc0200d6a:	00eb97b3          	sll	a5,s7,a4
        while (u < BUDDY_MAX_ORDER && block_pages(u + 1) <= n &&
ffffffffc0200d6e:	fefb77e3          	bgeu	s6,a5,ffffffffc0200d5c <default_init_memmap+0x118>
        base += size;
ffffffffc0200d72:	00b99d33          	sll	s10,s3,a1
    return (size_t)1 << u;
ffffffffc0200d76:	00bb9db3          	sll	s11,s7,a1
        set_free_head(base, u);
ffffffffc0200d7a:	8566                	mv	a0,s9
ffffffffc0200d7c:	925ff0ef          	jal	ra,ffffffffc02006a0 <set_free_head>
        insert_free(base);
ffffffffc0200d80:	8566                	mv	a0,s9
ffffffffc0200d82:	86bff0ef          	jal	ra,ffffffffc02005ec <insert_free>
        merge_free(base);
ffffffffc0200d86:	8566                	mv	a0,s9
        n -= size;
ffffffffc0200d88:	41bb0b33          	sub	s6,s6,s11
        merge_free(base);
ffffffffc0200d8c:	a27ff0ef          	jal	ra,ffffffffc02007b2 <merge_free>
        base += size;
ffffffffc0200d90:	9cea                	add	s9,s9,s10
    while (n != 0) {
ffffffffc0200d92:	000b0b63          	beqz	s6,ffffffffc0200da8 <default_init_memmap+0x164>
ffffffffc0200d96:	00093683          	ld	a3,0(s2)
ffffffffc0200d9a:	40dc86b3          	sub	a3,s9,a3
ffffffffc0200d9e:	bf4d                	j	ffffffffc0200d50 <default_init_memmap+0x10c>
ffffffffc0200da0:	45fd                	li	a1,31
ffffffffc0200da2:	8dd6                	mv	s11,s5
ffffffffc0200da4:	8d52                	mv	s10,s4
ffffffffc0200da6:	bfd1                	j	ffffffffc0200d7a <default_init_memmap+0x136>
}
ffffffffc0200da8:	70a6                	ld	ra,104(sp)
ffffffffc0200daa:	7406                	ld	s0,96(sp)
ffffffffc0200dac:	64e6                	ld	s1,88(sp)
ffffffffc0200dae:	6946                	ld	s2,80(sp)
ffffffffc0200db0:	69a6                	ld	s3,72(sp)
ffffffffc0200db2:	6a06                	ld	s4,64(sp)
ffffffffc0200db4:	7ae2                	ld	s5,56(sp)
ffffffffc0200db6:	7b42                	ld	s6,48(sp)
ffffffffc0200db8:	7ba2                	ld	s7,40(sp)
ffffffffc0200dba:	7c02                	ld	s8,32(sp)
ffffffffc0200dbc:	6ce2                	ld	s9,24(sp)
ffffffffc0200dbe:	6d42                	ld	s10,16(sp)
ffffffffc0200dc0:	6da2                	ld	s11,8(sp)
ffffffffc0200dc2:	6165                	addi	sp,sp,112
ffffffffc0200dc4:	8082                	ret
        assert(PageReserved(base + i));
ffffffffc0200dc6:	00004697          	auipc	a3,0x4
ffffffffc0200dca:	3fa68693          	addi	a3,a3,1018 # ffffffffc02051c0 <etext+0x67a>
ffffffffc0200dce:	00004617          	auipc	a2,0x4
ffffffffc0200dd2:	00a60613          	addi	a2,a2,10 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200dd6:	08100593          	li	a1,129
ffffffffc0200dda:	00004517          	auipc	a0,0x4
ffffffffc0200dde:	01650513          	addi	a0,a0,22 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200de2:	be0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n <= (size_t)~0U - nr_free);
ffffffffc0200de6:	00004697          	auipc	a3,0x4
ffffffffc0200dea:	3ba68693          	addi	a3,a3,954 # ffffffffc02051a0 <etext+0x65a>
ffffffffc0200dee:	00004617          	auipc	a2,0x4
ffffffffc0200df2:	fea60613          	addi	a2,a2,-22 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200df6:	07e00593          	li	a1,126
ffffffffc0200dfa:	00004517          	auipc	a0,0x4
ffffffffc0200dfe:	ff650513          	addi	a0,a0,-10 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200e02:	bc0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n <= npage - page2ppn(base));
ffffffffc0200e06:	00004697          	auipc	a3,0x4
ffffffffc0200e0a:	37a68693          	addi	a3,a3,890 # ffffffffc0205180 <etext+0x63a>
ffffffffc0200e0e:	00004617          	auipc	a2,0x4
ffffffffc0200e12:	fca60613          	addi	a2,a2,-54 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200e16:	07d00593          	li	a1,125
ffffffffc0200e1a:	00004517          	auipc	a0,0x4
ffffffffc0200e1e:	fd650513          	addi	a0,a0,-42 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200e22:	ba0ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200e26 <default_alloc_pages>:
default_alloc_pages(size_t n) {
ffffffffc0200e26:	711d                	addi	sp,sp,-96
    if (!request_order(n, &u) || block_pages(u) > nr_free) {
ffffffffc0200e28:	006c                	addi	a1,sp,12
default_alloc_pages(size_t n) {
ffffffffc0200e2a:	ec86                	sd	ra,88(sp)
ffffffffc0200e2c:	e8a2                	sd	s0,80(sp)
ffffffffc0200e2e:	e4a6                	sd	s1,72(sp)
ffffffffc0200e30:	e0ca                	sd	s2,64(sp)
ffffffffc0200e32:	fc4e                	sd	s3,56(sp)
ffffffffc0200e34:	f852                	sd	s4,48(sp)
ffffffffc0200e36:	f456                	sd	s5,40(sp)
ffffffffc0200e38:	f05a                	sd	s6,32(sp)
ffffffffc0200e3a:	ec5e                	sd	s7,24(sp)
    if (!request_order(n, &u) || block_pages(u) > nr_free) {
ffffffffc0200e3c:	905ff0ef          	jal	ra,ffffffffc0200740 <request_order>
ffffffffc0200e40:	c175                	beqz	a0,ffffffffc0200f24 <default_alloc_pages+0xfe>
ffffffffc0200e42:	46b2                	lw	a3,12(sp)
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc0200e44:	47fd                	li	a5,31
ffffffffc0200e46:	14d7eb63          	bltu	a5,a3,ffffffffc0200f9c <default_alloc_pages+0x176>
    if (!request_order(n, &u) || block_pages(u) > nr_free) {
ffffffffc0200e4a:	0000aa17          	auipc	s4,0xa
ffffffffc0200e4e:	1cea0a13          	addi	s4,s4,462 # ffffffffc020b018 <free_area>
ffffffffc0200e52:	010a6783          	lwu	a5,16(s4)
    return (size_t)1 << u;
ffffffffc0200e56:	4805                	li	a6,1
ffffffffc0200e58:	00d81833          	sll	a6,a6,a3
    if (!request_order(n, &u) || block_pages(u) > nr_free) {
ffffffffc0200e5c:	0d07e463          	bltu	a5,a6,ffffffffc0200f24 <default_alloc_pages+0xfe>
    return listelm->next;
ffffffffc0200e60:	008a3783          	ld	a5,8(s4)
    while (le != &free_list) {
ffffffffc0200e64:	0d478063          	beq	a5,s4,ffffffffc0200f24 <default_alloc_pages+0xfe>
        if (p->u >= u) {
ffffffffc0200e68:	ffc7a483          	lw	s1,-4(a5)
ffffffffc0200e6c:	89be                	mv	s3,a5
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e6e:	679c                	ld	a5,8(a5)
ffffffffc0200e70:	fed4cae3          	blt	s1,a3,ffffffffc0200e64 <default_alloc_pages+0x3e>
ffffffffc0200e74:	0009b603          	ld	a2,0(s3)
    ClearPageProperty(p);
ffffffffc0200e78:	ff09b703          	ld	a4,-16(s3)
        struct Page *p = le2page(le, page_link);
ffffffffc0200e7c:	fe898413          	addi	s0,s3,-24
    prev->next = next;
ffffffffc0200e80:	e61c                	sd	a5,8(a2)
    next->prev = prev;
ffffffffc0200e82:	e390                	sd	a2,0(a5)
    ClearPageProperty(p);
ffffffffc0200e84:	ffd77793          	andi	a5,a4,-3
ffffffffc0200e88:	fef9b823          	sd	a5,-16(s3)
    p->u = BUDDY_NO_ORDER;
ffffffffc0200e8c:	57fd                	li	a5,-1
    elm->prev = elm->next = elm;
ffffffffc0200e8e:	0139b423          	sd	s3,8(s3)
ffffffffc0200e92:	0139b023          	sd	s3,0(s3)
    p->property = 0;
ffffffffc0200e96:	fe09ac23          	sw	zero,-8(s3)
    p->u = BUDDY_NO_ORDER;
ffffffffc0200e9a:	fef9ae23          	sw	a5,-4(s3)
        struct Page *p = le2page(le, page_link);
ffffffffc0200e9e:	8aa2                	mv	s5,s0
            while (i > u) {
ffffffffc0200ea0:	0496d063          	bge	a3,s1,ffffffffc0200ee0 <default_alloc_pages+0xba>
                --i;
ffffffffc0200ea4:	34fd                	addiw	s1,s1,-1
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc0200ea6:	47fd                	li	a5,31
                struct Page *right = p + block_pages(i);
ffffffffc0200ea8:	02800b13          	li	s6,40
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc0200eac:	4bfd                	li	s7,31
ffffffffc0200eae:	0097d663          	bge	a5,s1,ffffffffc0200eba <default_alloc_pages+0x94>
ffffffffc0200eb2:	a0f1                	j	ffffffffc0200f7e <default_alloc_pages+0x158>
                --i;
ffffffffc0200eb4:	34fd                	addiw	s1,s1,-1
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc0200eb6:	0c9be463          	bltu	s7,s1,ffffffffc0200f7e <default_alloc_pages+0x158>
                struct Page *right = p + block_pages(i);
ffffffffc0200eba:	009b1933          	sll	s2,s6,s1
ffffffffc0200ebe:	9922                	add	s2,s2,s0
                set_free_head(right, i);
ffffffffc0200ec0:	85a6                	mv	a1,s1
ffffffffc0200ec2:	854a                	mv	a0,s2
ffffffffc0200ec4:	fdcff0ef          	jal	ra,ffffffffc02006a0 <set_free_head>
                insert_free(right);
ffffffffc0200ec8:	854a                	mv	a0,s2
ffffffffc0200eca:	f22ff0ef          	jal	ra,ffffffffc02005ec <insert_free>
            while (i > u) {
ffffffffc0200ece:	46b2                	lw	a3,12(sp)
ffffffffc0200ed0:	fe96c2e3          	blt	a3,s1,ffffffffc0200eb4 <default_alloc_pages+0x8e>
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc0200ed4:	47fd                	li	a5,31
ffffffffc0200ed6:	0cd7c363          	blt	a5,a3,ffffffffc0200f9c <default_alloc_pages+0x176>
    return (size_t)1 << u;
ffffffffc0200eda:	4805                	li	a6,1
ffffffffc0200edc:	00d81833          	sll	a6,a6,a3
            for (size_t j = 0; j < size; ++j) {
ffffffffc0200ee0:	00281593          	slli	a1,a6,0x2
ffffffffc0200ee4:	95c2                	add	a1,a1,a6
ffffffffc0200ee6:	058e                	slli	a1,a1,0x3
ffffffffc0200ee8:	8722                	mv	a4,s0
ffffffffc0200eea:	95a2                	add	a1,a1,s0
                assert((p[j].flags & BUDDY_MANAGED) &&
ffffffffc0200eec:	4511                	li	a0,4
                assert(!PageReserved(p + j) && !PageProperty(p + j));
ffffffffc0200eee:	671c                	ld	a5,8(a4)
ffffffffc0200ef0:	0037f613          	andi	a2,a5,3
ffffffffc0200ef4:	e629                	bnez	a2,ffffffffc0200f3e <default_alloc_pages+0x118>
                assert((p[j].flags & BUDDY_MANAGED) &&
ffffffffc0200ef6:	00c7f613          	andi	a2,a5,12
ffffffffc0200efa:	06a61263          	bne	a2,a0,ffffffffc0200f5e <default_alloc_pages+0x138>
                p[j].flags |= BUDDY_ALLOCATED;
ffffffffc0200efe:	0087e793          	ori	a5,a5,8
ffffffffc0200f02:	e71c                	sd	a5,8(a4)
            for (size_t j = 0; j < size; ++j) {
ffffffffc0200f04:	02870713          	addi	a4,a4,40
ffffffffc0200f08:	feb713e3          	bne	a4,a1,ffffffffc0200eee <default_alloc_pages+0xc8>
            nr_free -= size;
ffffffffc0200f0c:	010a2783          	lw	a5,16(s4)
            p->property = size;
ffffffffc0200f10:	2801                	sext.w	a6,a6
ffffffffc0200f12:	ff09ac23          	sw	a6,-8(s3)
            p->u = u;
ffffffffc0200f16:	fed9ae23          	sw	a3,-4(s3)
            nr_free -= size;
ffffffffc0200f1a:	4107883b          	subw	a6,a5,a6
ffffffffc0200f1e:	010a2823          	sw	a6,16(s4)
            return p;
ffffffffc0200f22:	a011                	j	ffffffffc0200f26 <default_alloc_pages+0x100>
        return NULL;
ffffffffc0200f24:	4a81                	li	s5,0
}
ffffffffc0200f26:	60e6                	ld	ra,88(sp)
ffffffffc0200f28:	6446                	ld	s0,80(sp)
ffffffffc0200f2a:	64a6                	ld	s1,72(sp)
ffffffffc0200f2c:	6906                	ld	s2,64(sp)
ffffffffc0200f2e:	79e2                	ld	s3,56(sp)
ffffffffc0200f30:	7a42                	ld	s4,48(sp)
ffffffffc0200f32:	7b02                	ld	s6,32(sp)
ffffffffc0200f34:	6be2                	ld	s7,24(sp)
ffffffffc0200f36:	8556                	mv	a0,s5
ffffffffc0200f38:	7aa2                	ld	s5,40(sp)
ffffffffc0200f3a:	6125                	addi	sp,sp,96
ffffffffc0200f3c:	8082                	ret
                assert(!PageReserved(p + j) && !PageProperty(p + j));
ffffffffc0200f3e:	00004697          	auipc	a3,0x4
ffffffffc0200f42:	29a68693          	addi	a3,a3,666 # ffffffffc02051d8 <etext+0x692>
ffffffffc0200f46:	00004617          	auipc	a2,0x4
ffffffffc0200f4a:	e9260613          	addi	a2,a2,-366 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200f4e:	0b200593          	li	a1,178
ffffffffc0200f52:	00004517          	auipc	a0,0x4
ffffffffc0200f56:	e9e50513          	addi	a0,a0,-354 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200f5a:	a68ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert((p[j].flags & BUDDY_MANAGED) &&
ffffffffc0200f5e:	00004697          	auipc	a3,0x4
ffffffffc0200f62:	2aa68693          	addi	a3,a3,682 # ffffffffc0205208 <etext+0x6c2>
ffffffffc0200f66:	00004617          	auipc	a2,0x4
ffffffffc0200f6a:	e7260613          	addi	a2,a2,-398 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200f6e:	0b300593          	li	a1,179
ffffffffc0200f72:	00004517          	auipc	a0,0x4
ffffffffc0200f76:	e7e50513          	addi	a0,a0,-386 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200f7a:	a48ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc0200f7e:	00004697          	auipc	a3,0x4
ffffffffc0200f82:	e9268693          	addi	a3,a3,-366 # ffffffffc0204e10 <etext+0x2ca>
ffffffffc0200f86:	00004617          	auipc	a2,0x4
ffffffffc0200f8a:	e5260613          	addi	a2,a2,-430 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0200f8e:	45e9                	li	a1,26
ffffffffc0200f90:	00004517          	auipc	a0,0x4
ffffffffc0200f94:	e6050513          	addi	a0,a0,-416 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0200f98:	a2aff0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc0200f9c:	ee2ff0ef          	jal	ra,ffffffffc020067e <block_pages.part.0>

ffffffffc0200fa0 <buddy_check_invariants>:
    return listelm->next;
ffffffffc0200fa0:	0000a297          	auipc	t0,0xa
ffffffffc0200fa4:	07828293          	addi	t0,t0,120 # ffffffffc020b018 <free_area>
ffffffffc0200fa8:	0002b783          	ld	a5,0(t0)

/* Check free heads, physical alignment, ordering and maximal coalescing. */
static void
buddy_check_invariants(void) {
ffffffffc0200fac:	715d                	addi	sp,sp,-80
ffffffffc0200fae:	e486                	sd	ra,72(sp)
    size_t total = 0, count = 0;
    struct Page *previous = NULL;
    list_entry_t *le = list_next(&free_list);
    assert(list_next(list_prev(&free_list)) == &free_list);
ffffffffc0200fb0:	679c                	ld	a5,8(a5)
buddy_check_invariants(void) {
ffffffffc0200fb2:	e0a2                	sd	s0,64(sp)
ffffffffc0200fb4:	fc26                	sd	s1,56(sp)
ffffffffc0200fb6:	f84a                	sd	s2,48(sp)
ffffffffc0200fb8:	f44e                	sd	s3,40(sp)
ffffffffc0200fba:	f052                	sd	s4,32(sp)
ffffffffc0200fbc:	ec56                	sd	s5,24(sp)
ffffffffc0200fbe:	e85a                	sd	s6,16(sp)
ffffffffc0200fc0:	e45e                	sd	s7,8(sp)
ffffffffc0200fc2:	0082b703          	ld	a4,8(t0)
    assert(list_next(list_prev(&free_list)) == &free_list);
ffffffffc0200fc6:	28579263          	bne	a5,t0,ffffffffc020124a <buddy_check_invariants+0x2aa>
    return npage > nbase && addr >= first &&
ffffffffc0200fca:	000abf17          	auipc	t5,0xab
ffffffffc0200fce:	956f3f03          	ld	t5,-1706(t5) # ffffffffc02ab920 <npage>
ffffffffc0200fd2:	00007e97          	auipc	t4,0x7
ffffffffc0200fd6:	8eeebe83          	ld	t4,-1810(t4) # ffffffffc02078c0 <nbase>
        for (size_t i = 0; i < size; ++i) {
            struct Page *q = p + i;
            assert(!PageReserved(q) && (q->flags & BUDDY_MANAGED));
            assert(!(q->flags & BUDDY_ALLOCATED));
            if (i != 0) {
                assert(!PageProperty(q) && q->u == BUDDY_NO_ORDER &&
ffffffffc0200fda:	587d                	li	a6,-1
                       q->property == 0 && list_empty(&q->page_link));
            }
        }
        total += size;
        assert(total <= nr_free && ++count <= nr_free);
ffffffffc0200fdc:	0102ef83          	lwu	t6,16(t0)
    uintptr_t addr = (uintptr_t)p, first = (uintptr_t)pages;
ffffffffc0200fe0:	000ab917          	auipc	s2,0xab
ffffffffc0200fe4:	94893903          	ld	s2,-1720(s2) # ffffffffc02ab928 <pages>
           (addr - first) / sizeof(struct Page) < npage - nbase;
ffffffffc0200fe8:	41df0a33          	sub	s4,t5,t4
    struct Page *previous = NULL;
ffffffffc0200fec:	4a81                	li	s5,0
    size_t total = 0, count = 0;
ffffffffc0200fee:	4301                	li	t1,0
ffffffffc0200ff0:	4401                	li	s0,0
           (addr - first) % sizeof(struct Page) == 0 &&
ffffffffc0200ff2:	02800993          	li	s3,40
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc0200ff6:	44fd                	li	s1,31
    return (size_t)1 << u;
ffffffffc0200ff8:	4085                	li	ra,1
ffffffffc0200ffa:	00007397          	auipc	t2,0x7
ffffffffc0200ffe:	8b63b383          	ld	t2,-1866(t2) # ffffffffc02078b0 <error_string+0x38>
            assert(!PageReserved(q) && (q->flags & BUDDY_MANAGED));
ffffffffc0201002:	4511                	li	a0,4
                assert(!PageProperty(q) && q->u == BUDDY_NO_ORDER &&
ffffffffc0201004:	1802                	slli	a6,a6,0x20
    while (le != &free_list) {
ffffffffc0201006:	0e570a63          	beq	a4,t0,ffffffffc02010fa <buddy_check_invariants+0x15a>
           (addr - first) % sizeof(struct Page) == 0 &&
ffffffffc020100a:	03eee263          	bltu	t4,t5,ffffffffc020102e <buddy_check_invariants+0x8e>
        assert(valid_page(p) && PageProperty(p));
ffffffffc020100e:	00004697          	auipc	a3,0x4
ffffffffc0201012:	26a68693          	addi	a3,a3,618 # ffffffffc0205278 <etext+0x732>
ffffffffc0201016:	00004617          	auipc	a2,0x4
ffffffffc020101a:	dc260613          	addi	a2,a2,-574 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020101e:	0f100593          	li	a1,241
ffffffffc0201022:	00004517          	auipc	a0,0x4
ffffffffc0201026:	dce50513          	addi	a0,a0,-562 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc020102a:	998ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        struct Page *p = le2page(le, page_link);
ffffffffc020102e:	fe870893          	addi	a7,a4,-24
    uintptr_t addr = (uintptr_t)p, first = (uintptr_t)pages;
ffffffffc0201032:	87c6                	mv	a5,a7
    return npage > nbase && addr >= first &&
ffffffffc0201034:	fd28ede3          	bltu	a7,s2,ffffffffc020100e <buddy_check_invariants+0x6e>
           (addr - first) % sizeof(struct Page) == 0 &&
ffffffffc0201038:	41288633          	sub	a2,a7,s2
ffffffffc020103c:	033676b3          	remu	a3,a2,s3
    return npage > nbase && addr >= first &&
ffffffffc0201040:	f6f9                	bnez	a3,ffffffffc020100e <buddy_check_invariants+0x6e>
           (addr - first) / sizeof(struct Page) < npage - nbase;
ffffffffc0201042:	033656b3          	divu	a3,a2,s3
           (addr - first) % sizeof(struct Page) == 0 &&
ffffffffc0201046:	fd46f4e3          	bgeu	a3,s4,ffffffffc020100e <buddy_check_invariants+0x6e>
        assert(valid_page(p) && PageProperty(p));
ffffffffc020104a:	ff073683          	ld	a3,-16(a4)
ffffffffc020104e:	8a89                	andi	a3,a3,2
ffffffffc0201050:	dedd                	beqz	a3,ffffffffc020100e <buddy_check_invariants+0x6e>
        size_t size = block_pages(p->u);
ffffffffc0201052:	ffc72b03          	lw	s6,-4(a4)
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc0201056:	2364ea63          	bltu	s1,s6,ffffffffc020128a <buddy_check_invariants+0x2ea>
        assert(p->property == size && size <= npage - page2ppn(p));
ffffffffc020105a:	ff876683          	lwu	a3,-8(a4)
    return (size_t)1 << u;
ffffffffc020105e:	016095b3          	sll	a1,ra,s6
        assert(p->property == size && size <= npage - page2ppn(p));
ffffffffc0201062:	20b69463          	bne	a3,a1,ffffffffc020126a <buddy_check_invariants+0x2ca>
ffffffffc0201066:	860d                	srai	a2,a2,0x3
ffffffffc0201068:	02760633          	mul	a2,a2,t2
ffffffffc020106c:	9676                	add	a2,a2,t4
ffffffffc020106e:	40cf06b3          	sub	a3,t5,a2
ffffffffc0201072:	1eb6ec63          	bltu	a3,a1,ffffffffc020126a <buddy_check_invariants+0x2ca>
        assert((page2ppn(p) & (size - 1)) == 0);
ffffffffc0201076:	fff58693          	addi	a3,a1,-1
ffffffffc020107a:	8ef1                	and	a3,a3,a2
ffffffffc020107c:	18069763          	bnez	a3,ffffffffc020120a <buddy_check_invariants+0x26a>
ffffffffc0201080:	00873e03          	ld	t3,8(a4)
        assert(list_prev(list_next(le)) == le && list_next(list_prev(le)) == le);
ffffffffc0201084:	000e3b83          	ld	s7,0(t3)
ffffffffc0201088:	17771163          	bne	a4,s7,ffffffffc02011ea <buddy_check_invariants+0x24a>
ffffffffc020108c:	00073b83          	ld	s7,0(a4)
ffffffffc0201090:	008bbb83          	ld	s7,8(s7)
ffffffffc0201094:	15771b63          	bne	a4,s7,ffffffffc02011ea <buddy_check_invariants+0x24a>
        if (previous != NULL) {
ffffffffc0201098:	000a8f63          	beqz	s5,ffffffffc02010b6 <buddy_check_invariants+0x116>
            assert(previous + previous->property <= p);
ffffffffc020109c:	010aeb83          	lwu	s7,16(s5)
ffffffffc02010a0:	002b9713          	slli	a4,s7,0x2
ffffffffc02010a4:	975e                	add	a4,a4,s7
ffffffffc02010a6:	070e                	slli	a4,a4,0x3
ffffffffc02010a8:	9756                	add	a4,a4,s5
ffffffffc02010aa:	18e8e063          	bltu	a7,a4,ffffffffc020122a <buddy_check_invariants+0x28a>
            assert(previous->u != p->u ||
ffffffffc02010ae:	014aa703          	lw	a4,20(s5)
ffffffffc02010b2:	07670363          	beq	a4,s6,ffffffffc0201118 <buddy_check_invariants+0x178>
            assert(!PageReserved(q) && (q->flags & BUDDY_MANAGED));
ffffffffc02010b6:	6798                	ld	a4,8(a5)
ffffffffc02010b8:	00577613          	andi	a2,a4,5
ffffffffc02010bc:	0ca61763          	bne	a2,a0,ffffffffc020118a <buddy_check_invariants+0x1ea>
            assert(!(q->flags & BUDDY_ALLOCATED));
ffffffffc02010c0:	00877613          	andi	a2,a4,8
ffffffffc02010c4:	e25d                	bnez	a2,ffffffffc020116a <buddy_check_invariants+0x1ca>
            if (i != 0) {
ffffffffc02010c6:	ca99                	beqz	a3,ffffffffc02010dc <buddy_check_invariants+0x13c>
                assert(!PageProperty(q) && q->u == BUDDY_NO_ORDER &&
ffffffffc02010c8:	8b09                	andi	a4,a4,2
ffffffffc02010ca:	e341                	bnez	a4,ffffffffc020114a <buddy_check_invariants+0x1aa>
ffffffffc02010cc:	6b98                	ld	a4,16(a5)
ffffffffc02010ce:	07071e63          	bne	a4,a6,ffffffffc020114a <buddy_check_invariants+0x1aa>
ffffffffc02010d2:	7390                	ld	a2,32(a5)
ffffffffc02010d4:	01878713          	addi	a4,a5,24
ffffffffc02010d8:	06e61963          	bne	a2,a4,ffffffffc020114a <buddy_check_invariants+0x1aa>
        for (size_t i = 0; i < size; ++i) {
ffffffffc02010dc:	0685                	addi	a3,a3,1
ffffffffc02010de:	02878793          	addi	a5,a5,40
ffffffffc02010e2:	fcd59ae3          	bne	a1,a3,ffffffffc02010b6 <buddy_check_invariants+0x116>
        total += size;
ffffffffc02010e6:	942e                	add	s0,s0,a1
        assert(total <= nr_free && ++count <= nr_free);
ffffffffc02010e8:	0e8fe163          	bltu	t6,s0,ffffffffc02011ca <buddy_check_invariants+0x22a>
ffffffffc02010ec:	0305                	addi	t1,t1,1
ffffffffc02010ee:	0c6fee63          	bltu	t6,t1,ffffffffc02011ca <buddy_check_invariants+0x22a>
ffffffffc02010f2:	8772                	mv	a4,t3
        struct Page *p = le2page(le, page_link);
ffffffffc02010f4:	8ac6                	mv	s5,a7
    while (le != &free_list) {
ffffffffc02010f6:	f0571ae3          	bne	a4,t0,ffffffffc020100a <buddy_check_invariants+0x6a>
        previous = p;
        le = list_next(le);
    }
    assert(total == nr_free_pages());
ffffffffc02010fa:	7bf000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc02010fe:	0a851663          	bne	a0,s0,ffffffffc02011aa <buddy_check_invariants+0x20a>
}
ffffffffc0201102:	60a6                	ld	ra,72(sp)
ffffffffc0201104:	6406                	ld	s0,64(sp)
ffffffffc0201106:	74e2                	ld	s1,56(sp)
ffffffffc0201108:	7942                	ld	s2,48(sp)
ffffffffc020110a:	79a2                	ld	s3,40(sp)
ffffffffc020110c:	7a02                	ld	s4,32(sp)
ffffffffc020110e:	6ae2                	ld	s5,24(sp)
ffffffffc0201110:	6b42                	ld	s6,16(sp)
ffffffffc0201112:	6ba2                	ld	s7,8(sp)
ffffffffc0201114:	6161                	addi	sp,sp,80
ffffffffc0201116:	8082                	ret
ffffffffc0201118:	412a8733          	sub	a4,s5,s2
ffffffffc020111c:	870d                	srai	a4,a4,0x3
ffffffffc020111e:	02770733          	mul	a4,a4,t2
ffffffffc0201122:	9776                	add	a4,a4,t4
            assert(previous->u != p->u ||
ffffffffc0201124:	8f2d                	xor	a4,a4,a1
ffffffffc0201126:	f8c718e3          	bne	a4,a2,ffffffffc02010b6 <buddy_check_invariants+0x116>
ffffffffc020112a:	00004697          	auipc	a3,0x4
ffffffffc020112e:	23e68693          	addi	a3,a3,574 # ffffffffc0205368 <etext+0x822>
ffffffffc0201132:	00004617          	auipc	a2,0x4
ffffffffc0201136:	ca660613          	addi	a2,a2,-858 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020113a:	0f800593          	li	a1,248
ffffffffc020113e:	00004517          	auipc	a0,0x4
ffffffffc0201142:	cb250513          	addi	a0,a0,-846 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201146:	87cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(!PageProperty(q) && q->u == BUDDY_NO_ORDER &&
ffffffffc020114a:	00004697          	auipc	a3,0x4
ffffffffc020114e:	2b668693          	addi	a3,a3,694 # ffffffffc0205400 <etext+0x8ba>
ffffffffc0201152:	00004617          	auipc	a2,0x4
ffffffffc0201156:	c8660613          	addi	a2,a2,-890 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020115a:	10000593          	li	a1,256
ffffffffc020115e:	00004517          	auipc	a0,0x4
ffffffffc0201162:	c9250513          	addi	a0,a0,-878 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201166:	85cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(!(q->flags & BUDDY_ALLOCATED));
ffffffffc020116a:	00004697          	auipc	a3,0x4
ffffffffc020116e:	27668693          	addi	a3,a3,630 # ffffffffc02053e0 <etext+0x89a>
ffffffffc0201172:	00004617          	auipc	a2,0x4
ffffffffc0201176:	c6660613          	addi	a2,a2,-922 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020117a:	0fe00593          	li	a1,254
ffffffffc020117e:	00004517          	auipc	a0,0x4
ffffffffc0201182:	c7250513          	addi	a0,a0,-910 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201186:	83cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(!PageReserved(q) && (q->flags & BUDDY_MANAGED));
ffffffffc020118a:	00004697          	auipc	a3,0x4
ffffffffc020118e:	22668693          	addi	a3,a3,550 # ffffffffc02053b0 <etext+0x86a>
ffffffffc0201192:	00004617          	auipc	a2,0x4
ffffffffc0201196:	c4660613          	addi	a2,a2,-954 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020119a:	0fd00593          	li	a1,253
ffffffffc020119e:	00004517          	auipc	a0,0x4
ffffffffc02011a2:	c5250513          	addi	a0,a0,-942 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc02011a6:	81cff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(total == nr_free_pages());
ffffffffc02011aa:	00004697          	auipc	a3,0x4
ffffffffc02011ae:	2de68693          	addi	a3,a3,734 # ffffffffc0205488 <etext+0x942>
ffffffffc02011b2:	00004617          	auipc	a2,0x4
ffffffffc02011b6:	c2660613          	addi	a2,a2,-986 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02011ba:	10900593          	li	a1,265
ffffffffc02011be:	00004517          	auipc	a0,0x4
ffffffffc02011c2:	c3250513          	addi	a0,a0,-974 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc02011c6:	ffdfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(total <= nr_free && ++count <= nr_free);
ffffffffc02011ca:	00004697          	auipc	a3,0x4
ffffffffc02011ce:	29668693          	addi	a3,a3,662 # ffffffffc0205460 <etext+0x91a>
ffffffffc02011d2:	00004617          	auipc	a2,0x4
ffffffffc02011d6:	c0660613          	addi	a2,a2,-1018 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02011da:	10500593          	li	a1,261
ffffffffc02011de:	00004517          	auipc	a0,0x4
ffffffffc02011e2:	c1250513          	addi	a0,a0,-1006 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc02011e6:	fddfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(list_prev(list_next(le)) == le && list_next(list_prev(le)) == le);
ffffffffc02011ea:	00004697          	auipc	a3,0x4
ffffffffc02011ee:	10e68693          	addi	a3,a3,270 # ffffffffc02052f8 <etext+0x7b2>
ffffffffc02011f2:	00004617          	auipc	a2,0x4
ffffffffc02011f6:	be660613          	addi	a2,a2,-1050 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02011fa:	0f500593          	li	a1,245
ffffffffc02011fe:	00004517          	auipc	a0,0x4
ffffffffc0201202:	bf250513          	addi	a0,a0,-1038 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201206:	fbdfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert((page2ppn(p) & (size - 1)) == 0);
ffffffffc020120a:	00004697          	auipc	a3,0x4
ffffffffc020120e:	0ce68693          	addi	a3,a3,206 # ffffffffc02052d8 <etext+0x792>
ffffffffc0201212:	00004617          	auipc	a2,0x4
ffffffffc0201216:	bc660613          	addi	a2,a2,-1082 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020121a:	0f400593          	li	a1,244
ffffffffc020121e:	00004517          	auipc	a0,0x4
ffffffffc0201222:	bd250513          	addi	a0,a0,-1070 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201226:	f9dfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(previous + previous->property <= p);
ffffffffc020122a:	00004697          	auipc	a3,0x4
ffffffffc020122e:	11668693          	addi	a3,a3,278 # ffffffffc0205340 <etext+0x7fa>
ffffffffc0201232:	00004617          	auipc	a2,0x4
ffffffffc0201236:	ba660613          	addi	a2,a2,-1114 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020123a:	0f700593          	li	a1,247
ffffffffc020123e:	00004517          	auipc	a0,0x4
ffffffffc0201242:	bb250513          	addi	a0,a0,-1102 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201246:	f7dfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(list_next(list_prev(&free_list)) == &free_list);
ffffffffc020124a:	00004697          	auipc	a3,0x4
ffffffffc020124e:	ffe68693          	addi	a3,a3,-2 # ffffffffc0205248 <etext+0x702>
ffffffffc0201252:	00004617          	auipc	a2,0x4
ffffffffc0201256:	b8660613          	addi	a2,a2,-1146 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020125a:	0ee00593          	li	a1,238
ffffffffc020125e:	00004517          	auipc	a0,0x4
ffffffffc0201262:	b9250513          	addi	a0,a0,-1134 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201266:	f5dfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(p->property == size && size <= npage - page2ppn(p));
ffffffffc020126a:	00004697          	auipc	a3,0x4
ffffffffc020126e:	03668693          	addi	a3,a3,54 # ffffffffc02052a0 <etext+0x75a>
ffffffffc0201272:	00004617          	auipc	a2,0x4
ffffffffc0201276:	b6660613          	addi	a2,a2,-1178 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020127a:	0f300593          	li	a1,243
ffffffffc020127e:	00004517          	auipc	a0,0x4
ffffffffc0201282:	b7250513          	addi	a0,a0,-1166 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201286:	f3dfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(u >= 0 && u <= BUDDY_MAX_ORDER);
ffffffffc020128a:	00004697          	auipc	a3,0x4
ffffffffc020128e:	b8668693          	addi	a3,a3,-1146 # ffffffffc0204e10 <etext+0x2ca>
ffffffffc0201292:	00004617          	auipc	a2,0x4
ffffffffc0201296:	b4660613          	addi	a2,a2,-1210 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020129a:	45e9                	li	a1,26
ffffffffc020129c:	00004517          	auipc	a0,0x4
ffffffffc02012a0:	b5450513          	addi	a0,a0,-1196 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc02012a4:	f1ffe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02012a8 <default_check>:
 * original sentinel and descriptors are saved verbatim; other free blocks
 * stay unreachable and untouched throughout the test. No reserved page is
 * converted into test memory. Only these two functions are test helpers.
 */
static void
default_check(void) {
ffffffffc02012a8:	90010113          	addi	sp,sp,-1792
ffffffffc02012ac:	6e113c23          	sd	ra,1784(sp)
ffffffffc02012b0:	6e913423          	sd	s1,1768(sp)
ffffffffc02012b4:	6e813823          	sd	s0,1776(sp)
ffffffffc02012b8:	6f213023          	sd	s2,1760(sp)
ffffffffc02012bc:	6d313c23          	sd	s3,1752(sp)
ffffffffc02012c0:	6d413823          	sd	s4,1744(sp)
ffffffffc02012c4:	6d513423          	sd	s5,1736(sp)
ffffffffc02012c8:	6d613023          	sd	s6,1728(sp)
ffffffffc02012cc:	6b713c23          	sd	s7,1720(sp)
ffffffffc02012d0:	6b813823          	sd	s8,1712(sp)
ffffffffc02012d4:	6b913423          	sd	s9,1704(sp)
ffffffffc02012d8:	6ba13023          	sd	s10,1696(sp)
ffffffffc02012dc:	69b13c23          	sd	s11,1688(sp)
    buddy_check_invariants();
ffffffffc02012e0:	cc1ff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
    size_t original_free = nr_free_pages();
ffffffffc02012e4:	5d5000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc02012e8:	0000a497          	auipc	s1,0xa
ffffffffc02012ec:	d3048493          	addi	s1,s1,-720 # ffffffffc020b018 <free_area>
ffffffffc02012f0:	649c                	ld	a5,8(s1)
ffffffffc02012f2:	ecaa                	sd	a0,88(sp)
ffffffffc02012f4:	f83e                	sd	a5,48(sp)
    struct Page *arena = NULL;
    for (list_entry_t *le = list_next(&free_list); le != &free_list;
ffffffffc02012f6:	04978163          	beq	a5,s1,ffffffffc0201338 <default_check+0x90>
ffffffffc02012fa:	893e                	mv	s2,a5
         le = list_next(le)) {
        struct Page *p = le2page(le, page_link);
        if (p->u >= 4) {
ffffffffc02012fc:	470d                	li	a4,3
ffffffffc02012fe:	a029                	j	ffffffffc0201308 <default_check+0x60>
ffffffffc0201300:	00893903          	ld	s2,8(s2)
    for (list_entry_t *le = list_next(&free_list); le != &free_list;
ffffffffc0201304:	02990a63          	beq	s2,s1,ffffffffc0201338 <default_check+0x90>
        if (p->u >= 4) {
ffffffffc0201308:	ffc92783          	lw	a5,-4(s2)
ffffffffc020130c:	fef75ae3          	bge	a4,a5,ffffffffc0201300 <default_check+0x58>
    return npage > nbase && addr >= first &&
ffffffffc0201310:	00006797          	auipc	a5,0x6
ffffffffc0201314:	5b07b783          	ld	a5,1456(a5) # ffffffffc02078c0 <nbase>
ffffffffc0201318:	000aa717          	auipc	a4,0xaa
ffffffffc020131c:	60873703          	ld	a4,1544(a4) # ffffffffc02ab920 <npage>
ffffffffc0201320:	f03e                	sd	a5,32(sp)
           (addr - first) % sizeof(struct Page) == 0 &&
ffffffffc0201322:	00e7fb63          	bgeu	a5,a4,ffffffffc0201338 <default_check+0x90>
    uintptr_t addr = (uintptr_t)p, first = (uintptr_t)pages;
ffffffffc0201326:	000aa797          	auipc	a5,0xaa
ffffffffc020132a:	60278793          	addi	a5,a5,1538 # ffffffffc02ab928 <pages>
ffffffffc020132e:	639c                	ld	a5,0(a5)
            arena = p;
            break;
        }
    }
    assert(arena != NULL && valid_page(arena + 15));
ffffffffc0201330:	24090693          	addi	a3,s2,576
    return npage > nbase && addr >= first &&
ffffffffc0201334:	02f6f263          	bgeu	a3,a5,ffffffffc0201358 <default_check+0xb0>
    assert(arena != NULL && valid_page(arena + 15));
ffffffffc0201338:	00004697          	auipc	a3,0x4
ffffffffc020133c:	17068693          	addi	a3,a3,368 # ffffffffc02054a8 <etext+0x962>
ffffffffc0201340:	00004617          	auipc	a2,0x4
ffffffffc0201344:	a9860613          	addi	a2,a2,-1384 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201348:	11e00593          	li	a1,286
ffffffffc020134c:	00004517          	auipc	a0,0x4
ffffffffc0201350:	aa450513          	addi	a0,a0,-1372 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201354:	e6ffe0ef          	jal	ra,ffffffffc02001c2 <__panic>
           (addr - first) % sizeof(struct Page) == 0 &&
ffffffffc0201358:	8e9d                	sub	a3,a3,a5
ffffffffc020135a:	02800613          	li	a2,40
ffffffffc020135e:	02c6f5b3          	remu	a1,a3,a2
    return npage > nbase && addr >= first &&
ffffffffc0201362:	f9f9                	bnez	a1,ffffffffc0201338 <default_check+0x90>
           (addr - first) / sizeof(struct Page) < npage - nbase;
ffffffffc0201364:	02c6d6b3          	divu	a3,a3,a2
ffffffffc0201368:	7602                	ld	a2,32(sp)
ffffffffc020136a:	8f11                	sub	a4,a4,a2
           (addr - first) % sizeof(struct Page) == 0 &&
ffffffffc020136c:	fce6f6e3          	bgeu	a3,a4,ffffffffc0201338 <default_check+0x90>
ffffffffc0201370:	00006717          	auipc	a4,0x6
ffffffffc0201374:	54070713          	addi	a4,a4,1344 # ffffffffc02078b0 <error_string+0x38>
ffffffffc0201378:	6318                	ld	a4,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc020137a:	fe890c93          	addi	s9,s2,-24
ffffffffc020137e:	40fc87b3          	sub	a5,s9,a5
ffffffffc0201382:	878d                	srai	a5,a5,0x3
ffffffffc0201384:	02e787b3          	mul	a5,a5,a4
ffffffffc0201388:	97b2                	add	a5,a5,a2
    assert((page2ppn(arena) & 15) == 0);
ffffffffc020138a:	8bbd                	andi	a5,a5,15
ffffffffc020138c:	08079ae3          	bnez	a5,ffffffffc0201c20 <default_check+0x978>
    free_area_t saved_area = free_area;
ffffffffc0201390:	609c                	ld	a5,0(s1)
ffffffffc0201392:	0b00                	addi	s0,sp,400
ffffffffc0201394:	ff090713          	addi	a4,s2,-16
ffffffffc0201398:	fc3e                	sd	a5,56(sp)
ffffffffc020139a:	489c                	lw	a5,16(s1)
ffffffffc020139c:	41010a93          	addi	s5,sp,1040
ffffffffc02013a0:	e8be                	sd	a5,80(sp)
ffffffffc02013a2:	87a2                	mv	a5,s0
    list_entry_t saved_sentinel = free_list;
    struct Page saved_pages[16];
    for (size_t i = 0; i < 16; ++i) {
        assert(!PageReserved(arena + i));
ffffffffc02013a4:	6314                	ld	a3,0(a4)
ffffffffc02013a6:	0016fc13          	andi	s8,a3,1
ffffffffc02013aa:	040c1be3          	bnez	s8,ffffffffc0201c00 <default_check+0x958>
        saved_pages[i] = arena[i];
ffffffffc02013ae:	ff873803          	ld	a6,-8(a4)
ffffffffc02013b2:	6708                	ld	a0,8(a4)
ffffffffc02013b4:	6b0c                	ld	a1,16(a4)
ffffffffc02013b6:	6f10                	ld	a2,24(a4)
ffffffffc02013b8:	0107b023          	sd	a6,0(a5)
ffffffffc02013bc:	e794                	sd	a3,8(a5)
ffffffffc02013be:	eb88                	sd	a0,16(a5)
ffffffffc02013c0:	ef8c                	sd	a1,24(a5)
ffffffffc02013c2:	f390                	sd	a2,32(a5)
    for (size_t i = 0; i < 16; ++i) {
ffffffffc02013c4:	02878793          	addi	a5,a5,40
ffffffffc02013c8:	02870713          	addi	a4,a4,40
ffffffffc02013cc:	fd579ce3          	bne	a5,s5,ffffffffc02013a4 <default_check+0xfc>
    elm->prev = elm->next = elm;
ffffffffc02013d0:	e484                	sd	s1,8(s1)
ffffffffc02013d2:	e084                	sd	s1,0(s1)
     * identical. The saved arena head and sentinel complete that list again
     * at the end. While isolated, only the new sentinel is traversed.
     */
    list_init(&free_list);
    list_init(&arena->page_link);
    set_free_head(arena, 4);
ffffffffc02013d4:	4591                	li	a1,4
ffffffffc02013d6:	01293423          	sd	s2,8(s2)
ffffffffc02013da:	01293023          	sd	s2,0(s2)
ffffffffc02013de:	8566                	mv	a0,s9
ffffffffc02013e0:	ac0ff0ef          	jal	ra,ffffffffc02006a0 <set_free_head>
    insert_free(arena);
ffffffffc02013e4:	8566                	mv	a0,s9
ffffffffc02013e6:	a06ff0ef          	jal	ra,ffffffffc02005ec <insert_free>
    nr_free = 16;
ffffffffc02013ea:	47c1                	li	a5,16
ffffffffc02013ec:	c89c                	sw	a5,16(s1)
    buddy_check_invariants();
ffffffffc02013ee:	bb3ff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>

    /* Basic requests: exact first-fit addresses, rounding, all live pages,
     * non-overlap, and freeing by the ORIGINAL request (especially 3 and 5).
     */
    const size_t requests[] = {1, 2, 3, 5};
ffffffffc02013f2:	458d                	li	a1,3
ffffffffc02013f4:	4789                	li	a5,2
    const size_t sizes[] = {1, 2, 4, 8};
ffffffffc02013f6:	4721                	li	a4,8
    const size_t requests[] = {1, 2, 3, 5};
ffffffffc02013f8:	fcae                	sd	a1,120(sp)
ffffffffc02013fa:	4595                	li	a1,5
ffffffffc02013fc:	4605                	li	a2,1
    const size_t sizes[] = {1, 2, 4, 8};
ffffffffc02013fe:	4691                	li	a3,4
ffffffffc0201400:	0c810a13          	addi	s4,sp,200
    const size_t requests[] = {1, 2, 3, 5};
ffffffffc0201404:	f8be                	sd	a5,112(sp)
ffffffffc0201406:	e12e                	sd	a1,128(sp)
    const size_t sizes[] = {1, 2, 4, 8};
ffffffffc0201408:	e93e                	sd	a5,144(sp)
ffffffffc020140a:	f13a                	sd	a4,160(sp)
    const size_t offsets[] = {0, 2, 4, 8};
ffffffffc020140c:	f93e                	sd	a5,176(sp)
ffffffffc020140e:	e1ba                	sd	a4,192(sp)
    struct Page *blocks[4];
    for (size_t i = 0; i < 4; ++i) {
ffffffffc0201410:	10bc                	addi	a5,sp,104
    const size_t offsets[] = {0, 2, 4, 8};
ffffffffc0201412:	4705                	li	a4,1
            struct Page *p = blocks[i] + j;
            assert(!PageReserved(p) && !PageProperty(p));
            assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
            assert(list_empty(&p->page_link));
            if (j != 0) {
                assert(p->u == BUDDY_NO_ORDER && p->property == 0);
ffffffffc0201414:	55fd                	li	a1,-1
    for (size_t i = 0; i < 4; ++i) {
ffffffffc0201416:	e4ca                	sd	s2,72(sp)
    const size_t requests[] = {1, 2, 3, 5};
ffffffffc0201418:	f4b2                	sd	a2,104(sp)
    const size_t sizes[] = {1, 2, 4, 8};
ffffffffc020141a:	e532                	sd	a2,136(sp)
ffffffffc020141c:	ed36                	sd	a3,152(sp)
    const size_t offsets[] = {0, 2, 4, 8};
ffffffffc020141e:	f502                	sd	zero,168(sp)
ffffffffc0201420:	fd36                	sd	a3,184(sp)
ffffffffc0201422:	0a810b93          	addi	s7,sp,168
ffffffffc0201426:	08810993          	addi	s3,sp,136
ffffffffc020142a:	e43a                	sd	a4,8(sp)
            assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
ffffffffc020142c:	4d31                	li	s10,12
                assert(p->u == BUDDY_NO_ORDER && p->property == 0);
ffffffffc020142e:	02059d93          	slli	s11,a1,0x20
    for (size_t i = 0; i < 4; ++i) {
ffffffffc0201432:	e0a2                	sd	s0,64(sp)
ffffffffc0201434:	ec66                	sd	s9,24(sp)
ffffffffc0201436:	f452                	sd	s4,40(sp)
ffffffffc0201438:	893e                	mv	s2,a5
        size_t before = nr_free_pages();
ffffffffc020143a:	47f000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc020143e:	842a                	mv	s0,a0
        blocks[i] = alloc_pages(requests[i]);
ffffffffc0201440:	00093503          	ld	a0,0(s2)
ffffffffc0201444:	45d000ef          	jal	ra,ffffffffc02020a0 <alloc_pages>
        assert(blocks[i] == arena + offsets[i]);
ffffffffc0201448:	000bb703          	ld	a4,0(s7)
        blocks[i] = alloc_pages(requests[i]);
ffffffffc020144c:	00aa3023          	sd	a0,0(s4)
ffffffffc0201450:	8caa                	mv	s9,a0
        assert(blocks[i] == arena + offsets[i]);
ffffffffc0201452:	00271793          	slli	a5,a4,0x2
ffffffffc0201456:	97ba                	add	a5,a5,a4
ffffffffc0201458:	6762                	ld	a4,24(sp)
ffffffffc020145a:	078e                	slli	a5,a5,0x3
ffffffffc020145c:	97ba                	add	a5,a5,a4
ffffffffc020145e:	78f51163          	bne	a0,a5,ffffffffc0201be0 <default_check+0x938>
        assert(blocks[i]->u == (int)i && blocks[i]->property == sizes[i]);
ffffffffc0201462:	4958                	lw	a4,20(a0)
ffffffffc0201464:	000c079b          	sext.w	a5,s8
ffffffffc0201468:	16f71ce3          	bne	a4,a5,ffffffffc0201de0 <default_check+0xb38>
ffffffffc020146c:	0009bb03          	ld	s6,0(s3)
ffffffffc0201470:	01056783          	lwu	a5,16(a0)
ffffffffc0201474:	176796e3          	bne	a5,s6,ffffffffc0201de0 <default_check+0xb38>
        assert(before - nr_free_pages() == sizes[i]);
ffffffffc0201478:	e83e                	sd	a5,16(sp)
ffffffffc020147a:	43f000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc020147e:	67c2                	ld	a5,16(sp)
ffffffffc0201480:	8c09                	sub	s0,s0,a0
ffffffffc0201482:	12879fe3          	bne	a5,s0,ffffffffc0201dc0 <default_check+0xb18>
ffffffffc0201486:	000aa797          	auipc	a5,0xaa
ffffffffc020148a:	4a278793          	addi	a5,a5,1186 # ffffffffc02ab928 <pages>
ffffffffc020148e:	6398                	ld	a4,0(a5)
ffffffffc0201490:	00006697          	auipc	a3,0x6
ffffffffc0201494:	42068693          	addi	a3,a3,1056 # ffffffffc02078b0 <error_string+0x38>
ffffffffc0201498:	6294                	ld	a3,0(a3)
ffffffffc020149a:	40ec8733          	sub	a4,s9,a4
ffffffffc020149e:	870d                	srai	a4,a4,0x3
ffffffffc02014a0:	02d70733          	mul	a4,a4,a3
ffffffffc02014a4:	7682                	ld	a3,32(sp)
        assert((page2ppn(blocks[i]) & (sizes[i] - 1)) == 0);
ffffffffc02014a6:	fffb0793          	addi	a5,s6,-1 # ffff <kern_entry-0xffffffffc01f0001>
ffffffffc02014aa:	9736                	add	a4,a4,a3
ffffffffc02014ac:	8ff9                	and	a5,a5,a4
ffffffffc02014ae:	200799e3          	bnez	a5,ffffffffc0201ec0 <default_check+0xc18>
        for (size_t j = 0; j < sizes[i]; ++j) {
ffffffffc02014b2:	87e6                	mv	a5,s9
ffffffffc02014b4:	4681                	li	a3,0
ffffffffc02014b6:	020b0863          	beqz	s6,ffffffffc02014e6 <default_check+0x23e>
            assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02014ba:	6798                	ld	a4,8(a5)
ffffffffc02014bc:	00377613          	andi	a2,a4,3
ffffffffc02014c0:	64061063          	bnez	a2,ffffffffc0201b00 <default_check+0x858>
            assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
ffffffffc02014c4:	8b31                	andi	a4,a4,12
ffffffffc02014c6:	67a71d63          	bne	a4,s10,ffffffffc0201b40 <default_check+0x898>
            assert(list_empty(&p->page_link));
ffffffffc02014ca:	7390                	ld	a2,32(a5)
ffffffffc02014cc:	01878713          	addi	a4,a5,24
ffffffffc02014d0:	64e61863          	bne	a2,a4,ffffffffc0201b20 <default_check+0x878>
            if (j != 0) {
ffffffffc02014d4:	c681                	beqz	a3,ffffffffc02014dc <default_check+0x234>
                assert(p->u == BUDDY_NO_ORDER && p->property == 0);
ffffffffc02014d6:	6b98                	ld	a4,16(a5)
ffffffffc02014d8:	69b71463          	bne	a4,s11,ffffffffc0201b60 <default_check+0x8b8>
        for (size_t j = 0; j < sizes[i]; ++j) {
ffffffffc02014dc:	0685                	addi	a3,a3,1
ffffffffc02014de:	02878793          	addi	a5,a5,40
ffffffffc02014e2:	fcdb1ce3          	bne	s6,a3,ffffffffc02014ba <default_check+0x212>
            }
        }
        for (size_t j = 0; j < i; ++j) {
ffffffffc02014e6:	600c0a63          	beqz	s8,ffffffffc0201afa <default_check+0x852>
            assert(blocks[j] + sizes[j] <= blocks[i] ||
ffffffffc02014ea:	002b1793          	slli	a5,s6,0x2
ffffffffc02014ee:	016788b3          	add	a7,a5,s6
ffffffffc02014f2:	088e                	slli	a7,a7,0x3
ffffffffc02014f4:	4785                	li	a5,1
ffffffffc02014f6:	76a2                	ld	a3,40(sp)
ffffffffc02014f8:	98e6                	add	a7,a7,s9
ffffffffc02014fa:	0130                	addi	a2,sp,136
ffffffffc02014fc:	873e                	mv	a4,a5
ffffffffc02014fe:	a011                	j	ffffffffc0201502 <default_check+0x25a>
ffffffffc0201500:	6218                	ld	a4,0(a2)
ffffffffc0201502:	628c                	ld	a1,0(a3)
ffffffffc0201504:	00271793          	slli	a5,a4,0x2
ffffffffc0201508:	97ba                	add	a5,a5,a4
ffffffffc020150a:	078e                	slli	a5,a5,0x3
ffffffffc020150c:	97ae                	add	a5,a5,a1
ffffffffc020150e:	00fcf463          	bgeu	s9,a5,ffffffffc0201516 <default_check+0x26e>
ffffffffc0201512:	6b15e763          	bltu	a1,a7,ffffffffc0201bc0 <default_check+0x918>
        for (size_t j = 0; j < i; ++j) {
ffffffffc0201516:	06a1                	addi	a3,a3,8
ffffffffc0201518:	0621                	addi	a2,a2,8
ffffffffc020151a:	ff4693e3          	bne	a3,s4,ffffffffc0201500 <default_check+0x258>
                   blocks[i] + sizes[i] <= blocks[j]);
        }
        buddy_check_invariants();
ffffffffc020151e:	a83ff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
    for (size_t i = 0; i < 4; ++i) {
ffffffffc0201522:	67a2                	ld	a5,8(sp)
ffffffffc0201524:	4711                	li	a4,4
ffffffffc0201526:	00e78b63          	beq	a5,a4,ffffffffc020153c <default_check+0x294>
ffffffffc020152a:	67a2                	ld	a5,8(sp)
ffffffffc020152c:	0c05                	addi	s8,s8,1
ffffffffc020152e:	0921                	addi	s2,s2,8
ffffffffc0201530:	0785                	addi	a5,a5,1
ffffffffc0201532:	0a21                	addi	s4,s4,8
ffffffffc0201534:	0ba1                	addi	s7,s7,8
ffffffffc0201536:	e43e                	sd	a5,8(sp)
ffffffffc0201538:	09a1                	addi	s3,s3,8
ffffffffc020153a:	b701                	j	ffffffffc020143a <default_check+0x192>
    }
    assert(nr_free_pages() == 1);
ffffffffc020153c:	6406                	ld	s0,64(sp)
ffffffffc020153e:	6ce2                	ld	s9,24(sp)
ffffffffc0201540:	6926                	ld	s2,72(sp)
ffffffffc0201542:	7a22                	ld	s4,40(sp)
ffffffffc0201544:	375000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0201548:	4785                	li	a5,1
ffffffffc020154a:	78f51b63          	bne	a0,a5,ffffffffc0201ce0 <default_check+0xa38>
    assert(free_list.next == &arena[1].page_link &&
ffffffffc020154e:	649c                	ld	a5,8(s1)
ffffffffc0201550:	02890713          	addi	a4,s2,40
ffffffffc0201554:	7ce79663          	bne	a5,a4,ffffffffc0201d20 <default_check+0xa78>
ffffffffc0201558:	6098                	ld	a4,0(s1)
ffffffffc020155a:	7ce79363          	bne	a5,a4,ffffffffc0201d20 <default_check+0xa78>
ffffffffc020155e:	02492783          	lw	a5,36(s2)
ffffffffc0201562:	7a079f63          	bnez	a5,ffffffffc0201d20 <default_check+0xa78>
ffffffffc0201566:	08010993          	addi	s3,sp,128
ffffffffc020156a:	0a010c13          	addi	s8,sp,160
ffffffffc020156e:	fe0a0b13          	addi	s6,s4,-32
           free_list.prev == &arena[1].page_link && arena[1].u == 0);
    for (size_t i = 4; i-- > 0;) {
        size_t before = nr_free_pages();
ffffffffc0201572:	347000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
        free_pages(blocks[i], requests[i]);
ffffffffc0201576:	0009b583          	ld	a1,0(s3)
        size_t before = nr_free_pages();
ffffffffc020157a:	8baa                	mv	s7,a0
        free_pages(blocks[i], requests[i]);
ffffffffc020157c:	018a3503          	ld	a0,24(s4)
ffffffffc0201580:	32d000ef          	jal	ra,ffffffffc02020ac <free_pages>
        assert(nr_free_pages() == before + sizes[i]);
ffffffffc0201584:	335000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0201588:	000c3783          	ld	a5,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc020158c:	9bbe                	add	s7,s7,a5
ffffffffc020158e:	77751963          	bne	a0,s7,ffffffffc0201d00 <default_check+0xa58>
    for (size_t i = 4; i-- > 0;) {
ffffffffc0201592:	1a61                	addi	s4,s4,-8
        buddy_check_invariants();
ffffffffc0201594:	a0dff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
    for (size_t i = 4; i-- > 0;) {
ffffffffc0201598:	19e1                	addi	s3,s3,-8
ffffffffc020159a:	1c61                	addi	s8,s8,-8
ffffffffc020159c:	fd6a1be3          	bne	s4,s6,ffffffffc0201572 <default_check+0x2ca>
    }
    assert(nr_free_pages() == 16 && arena->u == 4);
ffffffffc02015a0:	319000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc02015a4:	47c1                	li	a5,16
ffffffffc02015a6:	7ef51d63          	bne	a0,a5,ffffffffc0201da0 <default_check+0xaf8>
ffffffffc02015aa:	ffc92703          	lw	a4,-4(s2)
ffffffffc02015ae:	4791                	li	a5,4
ffffffffc02015b0:	7ef71863          	bne	a4,a5,ffffffffc0201da0 <default_check+0xaf8>
    assert(free_list.next == &arena->page_link && free_list.prev == &arena->page_link);
ffffffffc02015b4:	649c                	ld	a5,8(s1)
ffffffffc02015b6:	7cf91563          	bne	s2,a5,ffffffffc0201d80 <default_check+0xad8>
ffffffffc02015ba:	609c                	ld	a5,0(s1)
ffffffffc02015bc:	e856                	sd	s5,16(sp)

    /* Split an isolated aligned eight-page block, then restore it in two
     * different orders. Holding the lower eight pages prevents cross merges.
     */
    for (size_t round = 0; round < 2; ++round) {
ffffffffc02015be:	4b81                	li	s7,0
    assert(free_list.next == &arena->page_link && free_list.prev == &arena->page_link);
ffffffffc02015c0:	7cf91063          	bne	s2,a5,ffffffffc0201d80 <default_check+0xad8>
        struct Page *held = alloc_pages(8), *slots[8];
        assert(held == arena && held->u == 3 && held->property == 8);
ffffffffc02015c4:	478d                	li	a5,3
ffffffffc02015c6:	1782                	slli	a5,a5,0x20
ffffffffc02015c8:	07a1                	addi	a5,a5,8
ffffffffc02015ca:	e43e                	sd	a5,8(sp)
        struct Page *base = arena + 8;
ffffffffc02015cc:	140c8793          	addi	a5,s9,320
ffffffffc02015d0:	ec3e                	sd	a5,24(sp)
        assert(nr_free_pages() == 8 && base->u == 3 && base->property == 8);
        assert(free_list.next == &base->page_link && free_list.prev == &base->page_link);
ffffffffc02015d2:	158c8793          	addi	a5,s9,344
ffffffffc02015d6:	f43e                	sd	a5,40(sp)
ffffffffc02015d8:	e0a2                	sd	s0,64(sp)
ffffffffc02015da:	e4ca                	sd	s2,72(sp)
        struct Page *held = alloc_pages(8), *slots[8];
ffffffffc02015dc:	4521                	li	a0,8
ffffffffc02015de:	2c3000ef          	jal	ra,ffffffffc02020a0 <alloc_pages>
ffffffffc02015e2:	8a2a                	mv	s4,a0
        assert(held == arena && held->u == 3 && held->property == 8);
ffffffffc02015e4:	76ac9e63          	bne	s9,a0,ffffffffc0201d60 <default_check+0xab8>
ffffffffc02015e8:	010cb783          	ld	a5,16(s9)
ffffffffc02015ec:	6722                	ld	a4,8(sp)
ffffffffc02015ee:	76e79963          	bne	a5,a4,ffffffffc0201d60 <default_check+0xab8>
        assert(nr_free_pages() == 8 && base->u == 3 && base->property == 8);
ffffffffc02015f2:	2c7000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc02015f6:	47a1                	li	a5,8
ffffffffc02015f8:	74f51463          	bne	a0,a5,ffffffffc0201d40 <default_check+0xa98>
ffffffffc02015fc:	150cb783          	ld	a5,336(s9)
ffffffffc0201600:	6722                	ld	a4,8(sp)
ffffffffc0201602:	72e79f63          	bne	a5,a4,ffffffffc0201d40 <default_check+0xa98>
        assert(free_list.next == &base->page_link && free_list.prev == &base->page_link);
ffffffffc0201606:	649c                	ld	a5,8(s1)
ffffffffc0201608:	7722                	ld	a4,40(sp)
ffffffffc020160a:	08e79be3          	bne	a5,a4,ffffffffc0201ea0 <default_check+0xbf8>
ffffffffc020160e:	609c                	ld	a5,0(s1)
ffffffffc0201610:	08f718e3          	bne	a4,a5,ffffffffc0201ea0 <default_check+0xbf8>
        buddy_check_invariants();
ffffffffc0201614:	98dff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
        slots[0] = alloc_page();
ffffffffc0201618:	4505                	li	a0,1
ffffffffc020161a:	287000ef          	jal	ra,ffffffffc02020a0 <alloc_pages>
        assert(slots[0] == base && base->u == 0 && base->property == 1);
ffffffffc020161e:	67e2                	ld	a5,24(sp)
        slots[0] = alloc_page();
ffffffffc0201620:	ea2a                	sd	a0,272(sp)
        assert(slots[0] == base && base->u == 0 && base->property == 1);
ffffffffc0201622:	04f51fe3          	bne	a0,a5,ffffffffc0201e80 <default_check+0xbd8>
ffffffffc0201626:	150cb703          	ld	a4,336(s9)
ffffffffc020162a:	4785                	li	a5,1
ffffffffc020162c:	04f71ae3          	bne	a4,a5,ffffffffc0201e80 <default_check+0xbd8>
        assert(nr_free_pages() == 7);
ffffffffc0201630:	289000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0201634:	479d                	li	a5,7
ffffffffc0201636:	02f515e3          	bne	a0,a5,ffffffffc0201e60 <default_check+0xbb8>
    return listelm->next;
ffffffffc020163a:	6494                	ld	a3,8(s1)
        list_entry_t *le = list_next(&free_list);
        for (int u = 0; u < 3; ++u) {
            struct Page *p = base + block_pages(u);
ffffffffc020163c:	6862                	ld	a6,24(sp)
        for (int u = 0; u < 3; ++u) {
ffffffffc020163e:	4401                	li	s0,0
    return (size_t)1 << u;
ffffffffc0201640:	4505                	li	a0,1
            struct Page *p = base + block_pages(u);
ffffffffc0201642:	02800593          	li	a1,40
ffffffffc0201646:	008597b3          	sll	a5,a1,s0
ffffffffc020164a:	97c2                	add	a5,a5,a6
            assert(le == &p->page_link && PageProperty(p));
ffffffffc020164c:	01878713          	addi	a4,a5,24
    return (size_t)1 << u;
ffffffffc0201650:	00851633          	sll	a2,a0,s0
            assert(le == &p->page_link && PageProperty(p));
ffffffffc0201654:	7ee69663          	bne	a3,a4,ffffffffc0201e40 <default_check+0xb98>
ffffffffc0201658:	6798                	ld	a4,8(a5)
ffffffffc020165a:	8b09                	andi	a4,a4,2
ffffffffc020165c:	7e070263          	beqz	a4,ffffffffc0201e40 <default_check+0xb98>
            assert(p->u == u && p->property == block_pages(u));
ffffffffc0201660:	4bd8                	lw	a4,20(a5)
ffffffffc0201662:	7a871f63          	bne	a4,s0,ffffffffc0201e20 <default_check+0xb78>
ffffffffc0201666:	0107e783          	lwu	a5,16(a5)
ffffffffc020166a:	7ac79b63          	bne	a5,a2,ffffffffc0201e20 <default_check+0xb78>
        for (int u = 0; u < 3; ++u) {
ffffffffc020166e:	2405                	addiw	s0,s0,1
ffffffffc0201670:	478d                	li	a5,3
ffffffffc0201672:	6694                	ld	a3,8(a3)
ffffffffc0201674:	fcf419e3          	bne	s0,a5,ffffffffc0201646 <default_check+0x39e>
            le = list_next(le);
        }
        assert(le == &free_list);
ffffffffc0201678:	78969463          	bne	a3,s1,ffffffffc0201e00 <default_check+0xb58>
        buddy_check_invariants();
ffffffffc020167c:	925ff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
        for (size_t i = 1; i < 8; ++i) {
ffffffffc0201680:	11010c13          	addi	s8,sp,272
ffffffffc0201684:	168a0913          	addi	s2,s4,360
        buddy_check_invariants();
ffffffffc0201688:	4999                	li	s3,6
            slots[i] = alloc_page();
ffffffffc020168a:	4505                	li	a0,1
ffffffffc020168c:	215000ef          	jal	ra,ffffffffc02020a0 <alloc_pages>
ffffffffc0201690:	00ac3423          	sd	a0,8(s8)
            assert(slots[i] == base + i && slots[i]->u == 0 && slots[i]->property == 1);
ffffffffc0201694:	51251663          	bne	a0,s2,ffffffffc0201ba0 <default_check+0x8f8>
ffffffffc0201698:	01093b03          	ld	s6,16(s2)
ffffffffc020169c:	4785                	li	a5,1
ffffffffc020169e:	50fb1163          	bne	s6,a5,ffffffffc0201ba0 <default_check+0x8f8>
            assert(nr_free_pages() == 7 - i);
ffffffffc02016a2:	217000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc02016a6:	61351d63          	bne	a0,s3,ffffffffc0201cc0 <default_check+0xa18>
            buddy_check_invariants();
ffffffffc02016aa:	8f7ff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
        for (size_t i = 1; i < 8; ++i) {
ffffffffc02016ae:	19fd                	addi	s3,s3,-1
ffffffffc02016b0:	57fd                	li	a5,-1
ffffffffc02016b2:	0c21                	addi	s8,s8,8
ffffffffc02016b4:	02890913          	addi	s2,s2,40
ffffffffc02016b8:	fcf999e3          	bne	s3,a5,ffffffffc020168a <default_check+0x3e2>
        }
        const size_t orders[2][8] = {{0, 1, 2, 3, 4, 5, 6, 7},
ffffffffc02016bc:	00005797          	auipc	a5,0x5
ffffffffc02016c0:	81478793          	addi	a5,a5,-2028 # ffffffffc0205ed0 <etext+0x138a>
ffffffffc02016c4:	8756                	mv	a4,s5
ffffffffc02016c6:	00005817          	auipc	a6,0x5
ffffffffc02016ca:	88a80813          	addi	a6,a6,-1910 # ffffffffc0205f50 <buddy_system_pmm_manager>
ffffffffc02016ce:	6388                	ld	a0,0(a5)
ffffffffc02016d0:	678c                	ld	a1,8(a5)
ffffffffc02016d2:	6b90                	ld	a2,16(a5)
ffffffffc02016d4:	6f94                	ld	a3,24(a5)
ffffffffc02016d6:	e308                	sd	a0,0(a4)
ffffffffc02016d8:	e70c                	sd	a1,8(a4)
ffffffffc02016da:	eb10                	sd	a2,16(a4)
ffffffffc02016dc:	ef14                	sd	a3,24(a4)
ffffffffc02016de:	02078793          	addi	a5,a5,32
ffffffffc02016e2:	02070713          	addi	a4,a4,32
ffffffffc02016e6:	ff0794e3          	bne	a5,a6,ffffffffc02016ce <default_check+0x426>
ffffffffc02016ea:	6d42                	ld	s10,16(sp)
ffffffffc02016ec:	4d81                	li	s11,0
                                     {3, 6, 1, 4, 7, 0, 5, 2}};
        for (size_t i = 0; i < 8; ++i) {
ffffffffc02016ee:	4c21                	li	s8,8
ffffffffc02016f0:	a021                	j	ffffffffc02016f8 <default_check+0x450>
ffffffffc02016f2:	0d21                	addi	s10,s10,8
ffffffffc02016f4:	098d8063          	beq	s11,s8,ffffffffc0201774 <default_check+0x4cc>
            free_page(slots[orders[round][i]]);
ffffffffc02016f8:	000d3783          	ld	a5,0(s10)
ffffffffc02016fc:	69010713          	addi	a4,sp,1680
ffffffffc0201700:	4585                	li	a1,1
ffffffffc0201702:	078e                	slli	a5,a5,0x3
ffffffffc0201704:	97ba                	add	a5,a5,a4
ffffffffc0201706:	a807b503          	ld	a0,-1408(a5)
ffffffffc020170a:	896e                	mv	s2,s11
ffffffffc020170c:	0d85                	addi	s11,s11,1
ffffffffc020170e:	19f000ef          	jal	ra,ffffffffc02020ac <free_pages>
            assert(nr_free_pages() == i + 1);
ffffffffc0201712:	1a7000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0201716:	17b515e3          	bne	a0,s11,ffffffffc0202080 <default_check+0xdd8>
            buddy_check_invariants();
ffffffffc020171a:	887ff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
            if (round == 0 && (i == 1 || i == 3 || i == 7)) {
ffffffffc020171e:	fc0b9ae3          	bnez	s7,ffffffffc02016f2 <default_check+0x44a>
ffffffffc0201722:	4785                	li	a5,1
ffffffffc0201724:	26f90a63          	beq	s2,a5,ffffffffc0201998 <default_check+0x6f0>
ffffffffc0201728:	478d                	li	a5,3
ffffffffc020172a:	26f90963          	beq	s2,a5,ffffffffc020199c <default_check+0x6f4>
ffffffffc020172e:	479d                	li	a5,7
                int u = i == 1 ? 1 : i == 3 ? 2 : 3;
ffffffffc0201730:	86a2                	mv	a3,s0
            if (round == 0 && (i == 1 || i == 3 || i == 7)) {
ffffffffc0201732:	fcf910e3          	bne	s2,a5,ffffffffc02016f2 <default_check+0x44a>
                assert(PageProperty(base) && base->u == u &&
ffffffffc0201736:	148a3703          	ld	a4,328(s4)
ffffffffc020173a:	8b09                	andi	a4,a4,2
ffffffffc020173c:	cf01                	beqz	a4,ffffffffc0201754 <default_check+0x4ac>
ffffffffc020173e:	154a2783          	lw	a5,340(s4)
ffffffffc0201742:	00d79963          	bne	a5,a3,ffffffffc0201754 <default_check+0x4ac>
ffffffffc0201746:	150a6703          	lwu	a4,336(s4)
    return (size_t)1 << u;
ffffffffc020174a:	4785                	li	a5,1
ffffffffc020174c:	00d797b3          	sll	a5,a5,a3
                assert(PageProperty(base) && base->u == u &&
ffffffffc0201750:	faf701e3          	beq	a4,a5,ffffffffc02016f2 <default_check+0x44a>
ffffffffc0201754:	00004697          	auipc	a3,0x4
ffffffffc0201758:	1ec68693          	addi	a3,a3,492 # ffffffffc0205940 <etext+0xdfa>
ffffffffc020175c:	00003617          	auipc	a2,0x3
ffffffffc0201760:	67c60613          	addi	a2,a2,1660 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201764:	17f00593          	li	a1,383
ffffffffc0201768:	00003517          	auipc	a0,0x3
ffffffffc020176c:	68850513          	addi	a0,a0,1672 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201770:	a53fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
                       base->property == block_pages(u));
            }
        }
        assert(base->u == 3 && base->property == 8);
ffffffffc0201774:	150a3783          	ld	a5,336(s4)
ffffffffc0201778:	6722                	ld	a4,8(sp)
ffffffffc020177a:	0ee793e3          	bne	a5,a4,ffffffffc0202060 <default_check+0xdb8>
        assert(free_list.next == &base->page_link && free_list.prev == &base->page_link);
ffffffffc020177e:	649c                	ld	a5,8(s1)
ffffffffc0201780:	7722                	ld	a4,40(sp)
ffffffffc0201782:	0af71fe3          	bne	a4,a5,ffffffffc0202040 <default_check+0xd98>
ffffffffc0201786:	609c                	ld	a5,0(s1)
ffffffffc0201788:	0af71ce3          	bne	a4,a5,ffffffffc0202040 <default_check+0xd98>
        free_pages(held, 8);
ffffffffc020178c:	45a1                	li	a1,8
ffffffffc020178e:	8552                	mv	a0,s4
ffffffffc0201790:	11d000ef          	jal	ra,ffffffffc02020ac <free_pages>
        buddy_check_invariants();
ffffffffc0201794:	80dff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
        assert(nr_free_pages() == 16 && arena->u == 4);
ffffffffc0201798:	121000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc020179c:	47c1                	li	a5,16
ffffffffc020179e:	08f511e3          	bne	a0,a5,ffffffffc0202020 <default_check+0xd78>
ffffffffc02017a2:	014a2703          	lw	a4,20(s4)
ffffffffc02017a6:	4791                	li	a5,4
ffffffffc02017a8:	06f71ce3          	bne	a4,a5,ffffffffc0202020 <default_check+0xd78>
    for (size_t round = 0; round < 2; ++round) {
ffffffffc02017ac:	6742                	ld	a4,16(sp)
ffffffffc02017ae:	4785                	li	a5,1
ffffffffc02017b0:	04070713          	addi	a4,a4,64
ffffffffc02017b4:	e83a                	sd	a4,16(sp)
ffffffffc02017b6:	1efb9563          	bne	s7,a5,ffffffffc02019a0 <default_check+0x6f8>
            assert(free_list.next == &slots[1]->page_link &&
                   slots[1]->page_link.next == &slots[2]->page_link &&
                   free_list.prev == &slots[2]->page_link);
            assert((page2ppn(slots[1]) ^ 1) != page2ppn(slots[2]));
        }
        const size_t failures[] = {0, (size_t)-1,
ffffffffc02017ba:	6926                	ld	s2,72(sp)
ffffffffc02017bc:	4c85                	li	s9,1
ffffffffc02017be:	01fc9713          	slli	a4,s9,0x1f
                free_page(slots[i]);
                buddy_check_invariants();
            }
        }
        /* Verify actual allocator restoration BEFORE restoring the fixture. */
        assert(nr_free_pages() == 16 && arena->u == 4 && arena->property == 16);
ffffffffc02017c2:	022c9793          	slli	a5,s9,0x22
        const size_t failures[] = {0, (size_t)-1,
ffffffffc02017c6:	0705                	addi	a4,a4,1
        assert(nr_free_pages() == 16 && arena->u == 4 && arena->property == 16);
ffffffffc02017c8:	07c1                	addi	a5,a5,16
    for (size_t scenario = 0; scenario < 3; ++scenario) {
ffffffffc02017ca:	4c01                	li	s8,0
        const size_t failures[] = {0, (size_t)-1,
ffffffffc02017cc:	f43a                	sd	a4,40(sp)
        assert(nr_free_pages() == 16 && arena->u == 4 && arena->property == 16);
ffffffffc02017ce:	ec3e                	sd	a5,24(sp)
ffffffffc02017d0:	e84a                	sd	s2,16(sp)
ffffffffc02017d2:	e4ce                	sd	s3,72(sp)
        if (scenario != 0) {
ffffffffc02017d4:	1c0c1863          	bnez	s8,ffffffffc02019a4 <default_check+0x6fc>
        const size_t failures[] = {0, (size_t)-1,
ffffffffc02017d8:	57fd                	li	a5,-1
ffffffffc02017da:	f9be                	sd	a5,240(sp)
ffffffffc02017dc:	77a2                	ld	a5,40(sp)
            scenario == 0 ? 17 : scenario == 1 ? 1 : 2};
ffffffffc02017de:	4bc5                	li	s7,17
        const size_t failures[] = {0, (size_t)-1,
ffffffffc02017e0:	fdbe                	sd	a5,248(sp)
ffffffffc02017e2:	47c5                	li	a5,17
ffffffffc02017e4:	e23e                	sd	a5,256(sp)
ffffffffc02017e6:	4901                	li	s2,0
ffffffffc02017e8:	e462                	sd	s8,8(sp)
ffffffffc02017ea:	e65e                	sd	s7,264(sp)
        for (size_t f = 0; f < sizeof(failures) / sizeof(failures[0]); ++f) {
ffffffffc02017ec:	0f010b13          	addi	s6,sp,240
ffffffffc02017f0:	69010413          	addi	s0,sp,1680
ffffffffc02017f4:	8c4a                	mv	s8,s2
            size_t before_count = nr_free_pages();
ffffffffc02017f6:	0c3000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
            list_entry_t before_list = free_list;
ffffffffc02017fa:	0004bd03          	ld	s10,0(s1)
ffffffffc02017fe:	0084bd83          	ld	s11,8(s1)
            size_t before_count = nr_free_pages();
ffffffffc0201802:	8baa                	mv	s7,a0
            for (size_t i = 0; i < 16; ++i) {
ffffffffc0201804:	8952                	mv	s2,s4
ffffffffc0201806:	89d6                	mv	s3,s5
            list_entry_t before_list = free_list;
ffffffffc0201808:	87d6                	mv	a5,s5
ffffffffc020180a:	8752                	mv	a4,s4
                before[i] = arena[i];
ffffffffc020180c:	00073803          	ld	a6,0(a4)
ffffffffc0201810:	6708                	ld	a0,8(a4)
ffffffffc0201812:	6b0c                	ld	a1,16(a4)
ffffffffc0201814:	6f10                	ld	a2,24(a4)
ffffffffc0201816:	7314                	ld	a3,32(a4)
ffffffffc0201818:	0107b023          	sd	a6,0(a5)
ffffffffc020181c:	e788                	sd	a0,8(a5)
ffffffffc020181e:	eb8c                	sd	a1,16(a5)
ffffffffc0201820:	ef90                	sd	a2,24(a5)
ffffffffc0201822:	f394                	sd	a3,32(a5)
            for (size_t i = 0; i < 16; ++i) {
ffffffffc0201824:	02878793          	addi	a5,a5,40
ffffffffc0201828:	02870713          	addi	a4,a4,40
ffffffffc020182c:	fe8790e3          	bne	a5,s0,ffffffffc020180c <default_check+0x564>
            assert(alloc_pages(failures[f]) == NULL);
ffffffffc0201830:	8562                	mv	a0,s8
ffffffffc0201832:	06f000ef          	jal	ra,ffffffffc02020a0 <alloc_pages>
ffffffffc0201836:	7c051563          	bnez	a0,ffffffffc0202000 <default_check+0xd58>
            assert(nr_free_pages() == before_count);
ffffffffc020183a:	07f000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc020183e:	7b751163          	bne	a0,s7,ffffffffc0201fe0 <default_check+0xd38>
            assert(free_list.next == before_list.next &&
ffffffffc0201842:	649c                	ld	a5,8(s1)
ffffffffc0201844:	77b79e63          	bne	a5,s11,ffffffffc0201fc0 <default_check+0xd18>
ffffffffc0201848:	609c                	ld	a5,0(s1)
ffffffffc020184a:	77a79b63          	bne	a5,s10,ffffffffc0201fc0 <default_check+0xd18>
ffffffffc020184e:	87d2                	mv	a5,s4
                assert(arena[i].flags == before[i].flags &&
ffffffffc0201850:	6794                	ld	a3,8(a5)
ffffffffc0201852:	0089b703          	ld	a4,8(s3)
ffffffffc0201856:	1ce69663          	bne	a3,a4,ffffffffc0201a22 <default_check+0x77a>
ffffffffc020185a:	4394                	lw	a3,0(a5)
ffffffffc020185c:	0009a703          	lw	a4,0(s3)
ffffffffc0201860:	1ce69163          	bne	a3,a4,ffffffffc0201a22 <default_check+0x77a>
ffffffffc0201864:	4bd4                	lw	a3,20(a5)
ffffffffc0201866:	0149a703          	lw	a4,20(s3)
ffffffffc020186a:	1ae69c63          	bne	a3,a4,ffffffffc0201a22 <default_check+0x77a>
ffffffffc020186e:	4b94                	lw	a3,16(a5)
ffffffffc0201870:	0109a703          	lw	a4,16(s3)
ffffffffc0201874:	1ae69763          	bne	a3,a4,ffffffffc0201a22 <default_check+0x77a>
ffffffffc0201878:	7394                	ld	a3,32(a5)
ffffffffc020187a:	0209b703          	ld	a4,32(s3)
ffffffffc020187e:	1ae69263          	bne	a3,a4,ffffffffc0201a22 <default_check+0x77a>
ffffffffc0201882:	6f94                	ld	a3,24(a5)
ffffffffc0201884:	0189b703          	ld	a4,24(s3)
ffffffffc0201888:	18e69d63          	bne	a3,a4,ffffffffc0201a22 <default_check+0x77a>
            for (size_t i = 0; i < 16; ++i) {
ffffffffc020188c:	02898993          	addi	s3,s3,40
ffffffffc0201890:	02878793          	addi	a5,a5,40
ffffffffc0201894:	fa899ee3          	bne	s3,s0,ffffffffc0201850 <default_check+0x5a8>
            buddy_check_invariants();
ffffffffc0201898:	f08ff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
        for (size_t f = 0; f < sizeof(failures) / sizeof(failures[0]); ++f) {
ffffffffc020189c:	0a1c                	addi	a5,sp,272
ffffffffc020189e:	01678663          	beq	a5,s6,ffffffffc02018aa <default_check+0x602>
            assert(alloc_pages(failures[f]) == NULL);
ffffffffc02018a2:	000b3c03          	ld	s8,0(s6)
ffffffffc02018a6:	0b21                	addi	s6,s6,8
ffffffffc02018a8:	b7b9                	j	ffffffffc02017f6 <default_check+0x54e>
        if (scenario != 0) {
ffffffffc02018aa:	6c22                	ld	s8,8(sp)
ffffffffc02018ac:	844a                	mv	s0,s2
ffffffffc02018ae:	140c1463          	bnez	s8,ffffffffc02019f6 <default_check+0x74e>
        assert(nr_free_pages() == 16 && arena->u == 4 && arena->property == 16);
ffffffffc02018b2:	007000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc02018b6:	47c1                	li	a5,16
ffffffffc02018b8:	6ef51463          	bne	a0,a5,ffffffffc0201fa0 <default_check+0xcf8>
ffffffffc02018bc:	010a3783          	ld	a5,16(s4)
ffffffffc02018c0:	6762                	ld	a4,24(sp)
ffffffffc02018c2:	6ce79f63          	bne	a5,a4,ffffffffc0201fa0 <default_check+0xcf8>
        assert(free_list.next == &arena->page_link && free_list.prev == &arena->page_link);
ffffffffc02018c6:	649c                	ld	a5,8(s1)
ffffffffc02018c8:	6742                	ld	a4,16(sp)
ffffffffc02018ca:	6af71b63          	bne	a4,a5,ffffffffc0201f80 <default_check+0xcd8>
ffffffffc02018ce:	609c                	ld	a5,0(s1)
ffffffffc02018d0:	6af71863          	bne	a4,a5,ffffffffc0201f80 <default_check+0xcd8>
    for (size_t scenario = 0; scenario < 3; ++scenario) {
ffffffffc02018d4:	0c05                	addi	s8,s8,1
ffffffffc02018d6:	478d                	li	a5,3
ffffffffc02018d8:	eefc1ee3          	bne	s8,a5,ffffffffc02017d4 <default_check+0x52c>
ffffffffc02018dc:	8d22                	mv	s10,s0
ffffffffc02018de:	6942                	ld	s2,16(sp)
ffffffffc02018e0:	6406                	ld	s0,64(sp)
     * flags and both links. Every other original block was never modified;
     * restoring the original head and sentinel recovers the EXACT block set,
     * rather than merely its count or a hash.
     */
    for (size_t i = 0; i < 16; ++i) {
        arena[i] = saved_pages[i];
ffffffffc02018e2:	600c                	ld	a1,0(s0)
ffffffffc02018e4:	6410                	ld	a2,8(s0)
ffffffffc02018e6:	6814                	ld	a3,16(s0)
ffffffffc02018e8:	6c18                	ld	a4,24(s0)
ffffffffc02018ea:	701c                	ld	a5,32(s0)
ffffffffc02018ec:	00bd3023          	sd	a1,0(s10)
ffffffffc02018f0:	00cd3423          	sd	a2,8(s10)
ffffffffc02018f4:	00dd3823          	sd	a3,16(s10)
ffffffffc02018f8:	00ed3c23          	sd	a4,24(s10)
ffffffffc02018fc:	02fd3023          	sd	a5,32(s10)
    for (size_t i = 0; i < 16; ++i) {
ffffffffc0201900:	02840413          	addi	s0,s0,40
ffffffffc0201904:	028d0d13          	addi	s10,s10,40
ffffffffc0201908:	fd541de3          	bne	s0,s5,ffffffffc02018e2 <default_check+0x63a>
    }
    free_area = saved_area;
ffffffffc020190c:	77e2                	ld	a5,56(sp)
ffffffffc020190e:	e09c                	sd	a5,0(s1)
ffffffffc0201910:	77c2                	ld	a5,48(sp)
ffffffffc0201912:	e49c                	sd	a5,8(s1)
ffffffffc0201914:	67c6                	ld	a5,80(sp)
ffffffffc0201916:	c89c                	sw	a5,16(s1)
    assert(nr_free_pages() == original_free);
ffffffffc0201918:	7a0000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc020191c:	67e6                	ld	a5,88(sp)
ffffffffc020191e:	64f51163          	bne	a0,a5,ffffffffc0201f60 <default_check+0xcb8>
    assert(arena->u == saved_pages[0].u && arena->property == saved_pages[0].property);
ffffffffc0201922:	010a3703          	ld	a4,16(s4)
ffffffffc0201926:	779a                	ld	a5,416(sp)
ffffffffc0201928:	60f71c63          	bne	a4,a5,ffffffffc0201f40 <default_check+0xc98>
ffffffffc020192c:	018a3783          	ld	a5,24(s4)
    assert(list_next(list_prev(&arena->page_link)) == &arena->page_link &&
ffffffffc0201930:	679c                	ld	a5,8(a5)
ffffffffc0201932:	5ef91763          	bne	s2,a5,ffffffffc0201f20 <default_check+0xc78>
    return listelm->prev;
ffffffffc0201936:	020a3783          	ld	a5,32(s4)
ffffffffc020193a:	639c                	ld	a5,0(a5)
ffffffffc020193c:	5ef91263          	bne	s2,a5,ffffffffc0201f20 <default_check+0xc78>
           list_prev(list_next(&arena->page_link)) == &arena->page_link);
    assert(free_list.next == saved_sentinel.next &&
ffffffffc0201940:	649c                	ld	a5,8(s1)
ffffffffc0201942:	7742                	ld	a4,48(sp)
ffffffffc0201944:	5ae79e63          	bne	a5,a4,ffffffffc0201f00 <default_check+0xc58>
ffffffffc0201948:	609c                	ld	a5,0(s1)
ffffffffc020194a:	7762                	ld	a4,56(sp)
ffffffffc020194c:	5ae79a63          	bne	a5,a4,ffffffffc0201f00 <default_check+0xc58>
           free_list.prev == saved_sentinel.prev);
    buddy_check_invariants();
ffffffffc0201950:	e50ff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
    cprintf("buddy_system_pmm check passed: rounding, split/merge, boundaries, failures, restoration\n");
}
ffffffffc0201954:	6f013403          	ld	s0,1776(sp)
ffffffffc0201958:	6f813083          	ld	ra,1784(sp)
ffffffffc020195c:	6e813483          	ld	s1,1768(sp)
ffffffffc0201960:	6e013903          	ld	s2,1760(sp)
ffffffffc0201964:	6d813983          	ld	s3,1752(sp)
ffffffffc0201968:	6d013a03          	ld	s4,1744(sp)
ffffffffc020196c:	6c813a83          	ld	s5,1736(sp)
ffffffffc0201970:	6c013b03          	ld	s6,1728(sp)
ffffffffc0201974:	6b813b83          	ld	s7,1720(sp)
ffffffffc0201978:	6b013c03          	ld	s8,1712(sp)
ffffffffc020197c:	6a813c83          	ld	s9,1704(sp)
ffffffffc0201980:	6a013d03          	ld	s10,1696(sp)
ffffffffc0201984:	69813d83          	ld	s11,1688(sp)
    cprintf("buddy_system_pmm check passed: rounding, split/merge, boundaries, failures, restoration\n");
ffffffffc0201988:	00004517          	auipc	a0,0x4
ffffffffc020198c:	4c850513          	addi	a0,a0,1224 # ffffffffc0205e50 <etext+0x130a>
}
ffffffffc0201990:	70010113          	addi	sp,sp,1792
    cprintf("buddy_system_pmm check passed: rounding, split/merge, boundaries, failures, restoration\n");
ffffffffc0201994:	fb8fe06f          	j	ffffffffc020014c <cprintf>
                int u = i == 1 ? 1 : i == 3 ? 2 : 3;
ffffffffc0201998:	4685                	li	a3,1
ffffffffc020199a:	bb71                	j	ffffffffc0201736 <default_check+0x48e>
ffffffffc020199c:	4689                	li	a3,2
ffffffffc020199e:	bb61                	j	ffffffffc0201736 <default_check+0x48e>
ffffffffc02019a0:	8bda                	mv	s7,s6
ffffffffc02019a2:	b92d                	j	ffffffffc02015dc <default_check+0x334>
ffffffffc02019a4:	11010b13          	addi	s6,sp,272
ffffffffc02019a8:	89d2                	mv	s3,s4
                slots[i] = alloc_page();
ffffffffc02019aa:	4505                	li	a0,1
ffffffffc02019ac:	6f4000ef          	jal	ra,ffffffffc02020a0 <alloc_pages>
ffffffffc02019b0:	00ab3023          	sd	a0,0(s6)
                assert(slots[i] == arena + i && slots[i]->u == 0 &&
ffffffffc02019b4:	1d351663          	bne	a0,s3,ffffffffc0201b80 <default_check+0x8d8>
ffffffffc02019b8:	0109bb83          	ld	s7,16(s3)
ffffffffc02019bc:	1d9b9263          	bne	s7,s9,ffffffffc0201b80 <default_check+0x8d8>
                buddy_check_invariants();
ffffffffc02019c0:	de0ff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
            for (size_t i = 0; i < 16; ++i) {
ffffffffc02019c4:	0b21                	addi	s6,s6,8
ffffffffc02019c6:	0b1c                	addi	a5,sp,400
ffffffffc02019c8:	02898993          	addi	s3,s3,40
ffffffffc02019cc:	fcfb1fe3          	bne	s6,a5,ffffffffc02019aa <default_check+0x702>
            assert(nr_free_pages() == 0 && list_empty(&free_list));
ffffffffc02019d0:	6e8000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc02019d4:	50051663          	bnez	a0,ffffffffc0201ee0 <default_check+0xc38>
ffffffffc02019d8:	649c                	ld	a5,8(s1)
ffffffffc02019da:	50979363          	bne	a5,s1,ffffffffc0201ee0 <default_check+0xc38>
        if (scenario == 2) {
ffffffffc02019de:	4789                	li	a5,2
ffffffffc02019e0:	06fc0163          	beq	s8,a5,ffffffffc0201a42 <default_check+0x79a>
        const size_t failures[] = {0, (size_t)-1,
ffffffffc02019e4:	01fc9793          	slli	a5,s9,0x1f
ffffffffc02019e8:	0785                	addi	a5,a5,1
ffffffffc02019ea:	577d                	li	a4,-1
ffffffffc02019ec:	fdbe                	sd	a5,248(sp)
ffffffffc02019ee:	47c5                	li	a5,17
ffffffffc02019f0:	f9ba                	sd	a4,240(sp)
ffffffffc02019f2:	e23e                	sd	a5,256(sp)
ffffffffc02019f4:	bbcd                	j	ffffffffc02017e6 <default_check+0x53e>
        if (scenario != 0) {
ffffffffc02019f6:	6b26                	ld	s6,72(sp)
ffffffffc02019f8:	11010993          	addi	s3,sp,272
ffffffffc02019fc:	a829                	j	ffffffffc0201a16 <default_check+0x76e>
                free_page(slots[i]);
ffffffffc02019fe:	0009b503          	ld	a0,0(s3)
ffffffffc0201a02:	4585                	li	a1,1
ffffffffc0201a04:	6a8000ef          	jal	ra,ffffffffc02020ac <free_pages>
                buddy_check_invariants();
ffffffffc0201a08:	d98ff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
            for (size_t i = 0; i < 16; ++i) {
ffffffffc0201a0c:	09a1                	addi	s3,s3,8
ffffffffc0201a0e:	0b1c                	addi	a5,sp,400
ffffffffc0201a10:	0b05                	addi	s6,s6,1
ffffffffc0201a12:	eaf980e3          	beq	s3,a5,ffffffffc02018b2 <default_check+0x60a>
                if (scenario == 2 && (i == 1 || i == 2)) {
ffffffffc0201a16:	4789                	li	a5,2
ffffffffc0201a18:	fefc13e3          	bne	s8,a5,ffffffffc02019fe <default_check+0x756>
ffffffffc0201a1c:	ff6ce1e3          	bltu	s9,s6,ffffffffc02019fe <default_check+0x756>
ffffffffc0201a20:	b7f5                	j	ffffffffc0201a0c <default_check+0x764>
                assert(arena[i].flags == before[i].flags &&
ffffffffc0201a22:	00004697          	auipc	a3,0x4
ffffffffc0201a26:	1a668693          	addi	a3,a3,422 # ffffffffc0205bc8 <etext+0x1082>
ffffffffc0201a2a:	00003617          	auipc	a2,0x3
ffffffffc0201a2e:	3ae60613          	addi	a2,a2,942 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201a32:	1b500593          	li	a1,437
ffffffffc0201a36:	00003517          	auipc	a0,0x3
ffffffffc0201a3a:	3ba50513          	addi	a0,a0,954 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201a3e:	f84fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            free_page(slots[1]);
ffffffffc0201a42:	69f2                	ld	s3,280(sp)
ffffffffc0201a44:	4585                	li	a1,1
ffffffffc0201a46:	854e                	mv	a0,s3
ffffffffc0201a48:	664000ef          	jal	ra,ffffffffc02020ac <free_pages>
            buddy_check_invariants();
ffffffffc0201a4c:	d54ff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
            free_page(slots[2]);
ffffffffc0201a50:	7b12                	ld	s6,288(sp)
ffffffffc0201a52:	4585                	li	a1,1
ffffffffc0201a54:	855a                	mv	a0,s6
ffffffffc0201a56:	656000ef          	jal	ra,ffffffffc02020ac <free_pages>
            buddy_check_invariants();
ffffffffc0201a5a:	d46ff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
            assert(nr_free_pages() == 2);
ffffffffc0201a5e:	65a000ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0201a62:	8baa                	mv	s7,a0
ffffffffc0201a64:	23851e63          	bne	a0,s8,ffffffffc0201ca0 <default_check+0x9f8>
            assert(slots[1]->u == 0 && slots[2]->u == 0);
ffffffffc0201a68:	0149a783          	lw	a5,20(s3)
ffffffffc0201a6c:	20079a63          	bnez	a5,ffffffffc0201c80 <default_check+0x9d8>
ffffffffc0201a70:	014b2783          	lw	a5,20(s6)
ffffffffc0201a74:	20079663          	bnez	a5,ffffffffc0201c80 <default_check+0x9d8>
            assert(slots[1]->property == 1 && slots[2]->property == 1);
ffffffffc0201a78:	0109a783          	lw	a5,16(s3)
ffffffffc0201a7c:	1f979263          	bne	a5,s9,ffffffffc0201c60 <default_check+0x9b8>
ffffffffc0201a80:	010b2783          	lw	a5,16(s6)
ffffffffc0201a84:	1d979e63          	bne	a5,s9,ffffffffc0201c60 <default_check+0x9b8>
            assert(free_list.next == &slots[1]->page_link &&
ffffffffc0201a88:	6498                	ld	a4,8(s1)
ffffffffc0201a8a:	01898793          	addi	a5,s3,24
ffffffffc0201a8e:	1af71963          	bne	a4,a5,ffffffffc0201c40 <default_check+0x998>
ffffffffc0201a92:	0209b783          	ld	a5,32(s3)
ffffffffc0201a96:	018b0713          	addi	a4,s6,24
ffffffffc0201a9a:	1ae79363          	bne	a5,a4,ffffffffc0201c40 <default_check+0x998>
ffffffffc0201a9e:	6098                	ld	a4,0(s1)
ffffffffc0201aa0:	1ae79063          	bne	a5,a4,ffffffffc0201c40 <default_check+0x998>
ffffffffc0201aa4:	000aa797          	auipc	a5,0xaa
ffffffffc0201aa8:	e8478793          	addi	a5,a5,-380 # ffffffffc02ab928 <pages>
ffffffffc0201aac:	6398                	ld	a4,0(a5)
ffffffffc0201aae:	00006697          	auipc	a3,0x6
ffffffffc0201ab2:	e0268693          	addi	a3,a3,-510 # ffffffffc02078b0 <error_string+0x38>
ffffffffc0201ab6:	6290                	ld	a2,0(a3)
ffffffffc0201ab8:	40e987b3          	sub	a5,s3,a4
ffffffffc0201abc:	878d                	srai	a5,a5,0x3
ffffffffc0201abe:	40eb0733          	sub	a4,s6,a4
ffffffffc0201ac2:	02c787b3          	mul	a5,a5,a2
ffffffffc0201ac6:	870d                	srai	a4,a4,0x3
ffffffffc0201ac8:	7682                	ld	a3,32(sp)
ffffffffc0201aca:	02c70733          	mul	a4,a4,a2
ffffffffc0201ace:	97b6                	add	a5,a5,a3
            assert((page2ppn(slots[1]) ^ 1) != page2ppn(slots[2]));
ffffffffc0201ad0:	0017c793          	xori	a5,a5,1
ffffffffc0201ad4:	9736                	add	a4,a4,a3
ffffffffc0201ad6:	f0e797e3          	bne	a5,a4,ffffffffc02019e4 <default_check+0x73c>
ffffffffc0201ada:	00004697          	auipc	a3,0x4
ffffffffc0201ade:	02668693          	addi	a3,a3,38 # ffffffffc0205b00 <etext+0xfba>
ffffffffc0201ae2:	00003617          	auipc	a2,0x3
ffffffffc0201ae6:	2f660613          	addi	a2,a2,758 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201aea:	1a400593          	li	a1,420
ffffffffc0201aee:	00003517          	auipc	a0,0x3
ffffffffc0201af2:	30250513          	addi	a0,a0,770 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201af6:	eccfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        buddy_check_invariants();
ffffffffc0201afa:	ca6ff0ef          	jal	ra,ffffffffc0200fa0 <buddy_check_invariants>
    for (size_t i = 0; i < 4; ++i) {
ffffffffc0201afe:	b435                	j	ffffffffc020152a <default_check+0x282>
            assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201b00:	00003697          	auipc	a3,0x3
ffffffffc0201b04:	5c868693          	addi	a3,a3,1480 # ffffffffc02050c8 <etext+0x582>
ffffffffc0201b08:	00003617          	auipc	a2,0x3
ffffffffc0201b0c:	2d060613          	addi	a2,a2,720 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201b10:	14200593          	li	a1,322
ffffffffc0201b14:	00003517          	auipc	a0,0x3
ffffffffc0201b18:	2dc50513          	addi	a0,a0,732 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201b1c:	ea6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(list_empty(&p->page_link));
ffffffffc0201b20:	00003697          	auipc	a3,0x3
ffffffffc0201b24:	36068693          	addi	a3,a3,864 # ffffffffc0204e80 <etext+0x33a>
ffffffffc0201b28:	00003617          	auipc	a2,0x3
ffffffffc0201b2c:	2b060613          	addi	a2,a2,688 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201b30:	14400593          	li	a1,324
ffffffffc0201b34:	00003517          	auipc	a0,0x3
ffffffffc0201b38:	2bc50513          	addi	a0,a0,700 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201b3c:	e86fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert((p->flags & BUDDY_MANAGED) && (p->flags & BUDDY_ALLOCATED));
ffffffffc0201b40:	00003697          	auipc	a3,0x3
ffffffffc0201b44:	5b068693          	addi	a3,a3,1456 # ffffffffc02050f0 <etext+0x5aa>
ffffffffc0201b48:	00003617          	auipc	a2,0x3
ffffffffc0201b4c:	29060613          	addi	a2,a2,656 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201b50:	14300593          	li	a1,323
ffffffffc0201b54:	00003517          	auipc	a0,0x3
ffffffffc0201b58:	29c50513          	addi	a0,a0,668 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201b5c:	e66fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(p->u == BUDDY_NO_ORDER && p->property == 0);
ffffffffc0201b60:	00003697          	auipc	a3,0x3
ffffffffc0201b64:	5d068693          	addi	a3,a3,1488 # ffffffffc0205130 <etext+0x5ea>
ffffffffc0201b68:	00003617          	auipc	a2,0x3
ffffffffc0201b6c:	27060613          	addi	a2,a2,624 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201b70:	14600593          	li	a1,326
ffffffffc0201b74:	00003517          	auipc	a0,0x3
ffffffffc0201b78:	27c50513          	addi	a0,a0,636 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201b7c:	e46fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(slots[i] == arena + i && slots[i]->u == 0 &&
ffffffffc0201b80:	00004697          	auipc	a3,0x4
ffffffffc0201b84:	e0868693          	addi	a3,a3,-504 # ffffffffc0205988 <etext+0xe42>
ffffffffc0201b88:	00003617          	auipc	a2,0x3
ffffffffc0201b8c:	25060613          	addi	a2,a2,592 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201b90:	19300593          	li	a1,403
ffffffffc0201b94:	00003517          	auipc	a0,0x3
ffffffffc0201b98:	25c50513          	addi	a0,a0,604 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201b9c:	e26fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(slots[i] == base + i && slots[i]->u == 0 && slots[i]->property == 1);
ffffffffc0201ba0:	00004697          	auipc	a3,0x4
ffffffffc0201ba4:	d1868693          	addi	a3,a3,-744 # ffffffffc02058b8 <etext+0xd72>
ffffffffc0201ba8:	00003617          	auipc	a2,0x3
ffffffffc0201bac:	23060613          	addi	a2,a2,560 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201bb0:	17300593          	li	a1,371
ffffffffc0201bb4:	00003517          	auipc	a0,0x3
ffffffffc0201bb8:	23c50513          	addi	a0,a0,572 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201bbc:	e06fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(blocks[j] + sizes[j] <= blocks[i] ||
ffffffffc0201bc0:	00004697          	auipc	a3,0x4
ffffffffc0201bc4:	a0868693          	addi	a3,a3,-1528 # ffffffffc02055c8 <etext+0xa82>
ffffffffc0201bc8:	00003617          	auipc	a2,0x3
ffffffffc0201bcc:	21060613          	addi	a2,a2,528 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201bd0:	14a00593          	li	a1,330
ffffffffc0201bd4:	00003517          	auipc	a0,0x3
ffffffffc0201bd8:	21c50513          	addi	a0,a0,540 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201bdc:	de6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(blocks[i] == arena + offsets[i]);
ffffffffc0201be0:	00004697          	auipc	a3,0x4
ffffffffc0201be4:	93068693          	addi	a3,a3,-1744 # ffffffffc0205510 <etext+0x9ca>
ffffffffc0201be8:	00003617          	auipc	a2,0x3
ffffffffc0201bec:	1f060613          	addi	a2,a2,496 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201bf0:	13c00593          	li	a1,316
ffffffffc0201bf4:	00003517          	auipc	a0,0x3
ffffffffc0201bf8:	1fc50513          	addi	a0,a0,508 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201bfc:	dc6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(!PageReserved(arena + i));
ffffffffc0201c00:	00004697          	auipc	a3,0x4
ffffffffc0201c04:	8f068693          	addi	a3,a3,-1808 # ffffffffc02054f0 <etext+0x9aa>
ffffffffc0201c08:	00003617          	auipc	a2,0x3
ffffffffc0201c0c:	1d060613          	addi	a2,a2,464 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201c10:	12400593          	li	a1,292
ffffffffc0201c14:	00003517          	auipc	a0,0x3
ffffffffc0201c18:	1dc50513          	addi	a0,a0,476 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201c1c:	da6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert((page2ppn(arena) & 15) == 0);
ffffffffc0201c20:	00004697          	auipc	a3,0x4
ffffffffc0201c24:	8b068693          	addi	a3,a3,-1872 # ffffffffc02054d0 <etext+0x98a>
ffffffffc0201c28:	00003617          	auipc	a2,0x3
ffffffffc0201c2c:	1b060613          	addi	a2,a2,432 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201c30:	11f00593          	li	a1,287
ffffffffc0201c34:	00003517          	auipc	a0,0x3
ffffffffc0201c38:	1bc50513          	addi	a0,a0,444 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201c3c:	d86fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(free_list.next == &slots[1]->page_link &&
ffffffffc0201c40:	00004697          	auipc	a3,0x4
ffffffffc0201c44:	e3868693          	addi	a3,a3,-456 # ffffffffc0205a78 <etext+0xf32>
ffffffffc0201c48:	00003617          	auipc	a2,0x3
ffffffffc0201c4c:	19060613          	addi	a2,a2,400 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201c50:	1a100593          	li	a1,417
ffffffffc0201c54:	00003517          	auipc	a0,0x3
ffffffffc0201c58:	19c50513          	addi	a0,a0,412 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201c5c:	d66fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(slots[1]->property == 1 && slots[2]->property == 1);
ffffffffc0201c60:	00004697          	auipc	a3,0x4
ffffffffc0201c64:	de068693          	addi	a3,a3,-544 # ffffffffc0205a40 <etext+0xefa>
ffffffffc0201c68:	00003617          	auipc	a2,0x3
ffffffffc0201c6c:	17060613          	addi	a2,a2,368 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201c70:	1a000593          	li	a1,416
ffffffffc0201c74:	00003517          	auipc	a0,0x3
ffffffffc0201c78:	17c50513          	addi	a0,a0,380 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201c7c:	d46fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(slots[1]->u == 0 && slots[2]->u == 0);
ffffffffc0201c80:	00004697          	auipc	a3,0x4
ffffffffc0201c84:	d9868693          	addi	a3,a3,-616 # ffffffffc0205a18 <etext+0xed2>
ffffffffc0201c88:	00003617          	auipc	a2,0x3
ffffffffc0201c8c:	15060613          	addi	a2,a2,336 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201c90:	19f00593          	li	a1,415
ffffffffc0201c94:	00003517          	auipc	a0,0x3
ffffffffc0201c98:	15c50513          	addi	a0,a0,348 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201c9c:	d26fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(nr_free_pages() == 2);
ffffffffc0201ca0:	00004697          	auipc	a3,0x4
ffffffffc0201ca4:	d6068693          	addi	a3,a3,-672 # ffffffffc0205a00 <etext+0xeba>
ffffffffc0201ca8:	00003617          	auipc	a2,0x3
ffffffffc0201cac:	13060613          	addi	a2,a2,304 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201cb0:	19e00593          	li	a1,414
ffffffffc0201cb4:	00003517          	auipc	a0,0x3
ffffffffc0201cb8:	13c50513          	addi	a0,a0,316 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201cbc:	d06fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(nr_free_pages() == 7 - i);
ffffffffc0201cc0:	00004697          	auipc	a3,0x4
ffffffffc0201cc4:	c4068693          	addi	a3,a3,-960 # ffffffffc0205900 <etext+0xdba>
ffffffffc0201cc8:	00003617          	auipc	a2,0x3
ffffffffc0201ccc:	11060613          	addi	a2,a2,272 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201cd0:	17400593          	li	a1,372
ffffffffc0201cd4:	00003517          	auipc	a0,0x3
ffffffffc0201cd8:	11c50513          	addi	a0,a0,284 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201cdc:	ce6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == 1);
ffffffffc0201ce0:	00004697          	auipc	a3,0x4
ffffffffc0201ce4:	93068693          	addi	a3,a3,-1744 # ffffffffc0205610 <etext+0xaca>
ffffffffc0201ce8:	00003617          	auipc	a2,0x3
ffffffffc0201cec:	0f060613          	addi	a2,a2,240 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201cf0:	14f00593          	li	a1,335
ffffffffc0201cf4:	00003517          	auipc	a0,0x3
ffffffffc0201cf8:	0fc50513          	addi	a0,a0,252 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201cfc:	cc6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(nr_free_pages() == before + sizes[i]);
ffffffffc0201d00:	00004697          	auipc	a3,0x4
ffffffffc0201d04:	99068693          	addi	a3,a3,-1648 # ffffffffc0205690 <etext+0xb4a>
ffffffffc0201d08:	00003617          	auipc	a2,0x3
ffffffffc0201d0c:	0d060613          	addi	a2,a2,208 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201d10:	15500593          	li	a1,341
ffffffffc0201d14:	00003517          	auipc	a0,0x3
ffffffffc0201d18:	0dc50513          	addi	a0,a0,220 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201d1c:	ca6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(free_list.next == &arena[1].page_link &&
ffffffffc0201d20:	00004697          	auipc	a3,0x4
ffffffffc0201d24:	90868693          	addi	a3,a3,-1784 # ffffffffc0205628 <etext+0xae2>
ffffffffc0201d28:	00003617          	auipc	a2,0x3
ffffffffc0201d2c:	0b060613          	addi	a2,a2,176 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201d30:	15000593          	li	a1,336
ffffffffc0201d34:	00003517          	auipc	a0,0x3
ffffffffc0201d38:	0bc50513          	addi	a0,a0,188 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201d3c:	c86fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(nr_free_pages() == 8 && base->u == 3 && base->property == 8);
ffffffffc0201d40:	00004697          	auipc	a3,0x4
ffffffffc0201d44:	a2868693          	addi	a3,a3,-1496 # ffffffffc0205768 <etext+0xc22>
ffffffffc0201d48:	00003617          	auipc	a2,0x3
ffffffffc0201d4c:	09060613          	addi	a2,a2,144 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201d50:	16200593          	li	a1,354
ffffffffc0201d54:	00003517          	auipc	a0,0x3
ffffffffc0201d58:	09c50513          	addi	a0,a0,156 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201d5c:	c66fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(held == arena && held->u == 3 && held->property == 8);
ffffffffc0201d60:	00004697          	auipc	a3,0x4
ffffffffc0201d64:	9d068693          	addi	a3,a3,-1584 # ffffffffc0205730 <etext+0xbea>
ffffffffc0201d68:	00003617          	auipc	a2,0x3
ffffffffc0201d6c:	07060613          	addi	a2,a2,112 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201d70:	16000593          	li	a1,352
ffffffffc0201d74:	00003517          	auipc	a0,0x3
ffffffffc0201d78:	07c50513          	addi	a0,a0,124 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201d7c:	c46fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(free_list.next == &arena->page_link && free_list.prev == &arena->page_link);
ffffffffc0201d80:	00004697          	auipc	a3,0x4
ffffffffc0201d84:	96068693          	addi	a3,a3,-1696 # ffffffffc02056e0 <etext+0xb9a>
ffffffffc0201d88:	00003617          	auipc	a2,0x3
ffffffffc0201d8c:	05060613          	addi	a2,a2,80 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201d90:	15900593          	li	a1,345
ffffffffc0201d94:	00003517          	auipc	a0,0x3
ffffffffc0201d98:	05c50513          	addi	a0,a0,92 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201d9c:	c26fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == 16 && arena->u == 4);
ffffffffc0201da0:	00004697          	auipc	a3,0x4
ffffffffc0201da4:	91868693          	addi	a3,a3,-1768 # ffffffffc02056b8 <etext+0xb72>
ffffffffc0201da8:	00003617          	auipc	a2,0x3
ffffffffc0201dac:	03060613          	addi	a2,a2,48 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201db0:	15800593          	li	a1,344
ffffffffc0201db4:	00003517          	auipc	a0,0x3
ffffffffc0201db8:	03c50513          	addi	a0,a0,60 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201dbc:	c06fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(before - nr_free_pages() == sizes[i]);
ffffffffc0201dc0:	00003697          	auipc	a3,0x3
ffffffffc0201dc4:	7b068693          	addi	a3,a3,1968 # ffffffffc0205570 <etext+0xa2a>
ffffffffc0201dc8:	00003617          	auipc	a2,0x3
ffffffffc0201dcc:	01060613          	addi	a2,a2,16 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201dd0:	13e00593          	li	a1,318
ffffffffc0201dd4:	00003517          	auipc	a0,0x3
ffffffffc0201dd8:	01c50513          	addi	a0,a0,28 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201ddc:	be6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(blocks[i]->u == (int)i && blocks[i]->property == sizes[i]);
ffffffffc0201de0:	00003697          	auipc	a3,0x3
ffffffffc0201de4:	75068693          	addi	a3,a3,1872 # ffffffffc0205530 <etext+0x9ea>
ffffffffc0201de8:	00003617          	auipc	a2,0x3
ffffffffc0201dec:	ff060613          	addi	a2,a2,-16 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201df0:	13d00593          	li	a1,317
ffffffffc0201df4:	00003517          	auipc	a0,0x3
ffffffffc0201df8:	ffc50513          	addi	a0,a0,-4 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201dfc:	bc6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(le == &free_list);
ffffffffc0201e00:	00004697          	auipc	a3,0x4
ffffffffc0201e04:	aa068693          	addi	a3,a3,-1376 # ffffffffc02058a0 <etext+0xd5a>
ffffffffc0201e08:	00003617          	auipc	a2,0x3
ffffffffc0201e0c:	fd060613          	addi	a2,a2,-48 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201e10:	16f00593          	li	a1,367
ffffffffc0201e14:	00003517          	auipc	a0,0x3
ffffffffc0201e18:	fdc50513          	addi	a0,a0,-36 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201e1c:	ba6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(p->u == u && p->property == block_pages(u));
ffffffffc0201e20:	00004697          	auipc	a3,0x4
ffffffffc0201e24:	a5068693          	addi	a3,a3,-1456 # ffffffffc0205870 <etext+0xd2a>
ffffffffc0201e28:	00003617          	auipc	a2,0x3
ffffffffc0201e2c:	fb060613          	addi	a2,a2,-80 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201e30:	16c00593          	li	a1,364
ffffffffc0201e34:	00003517          	auipc	a0,0x3
ffffffffc0201e38:	fbc50513          	addi	a0,a0,-68 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201e3c:	b86fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(le == &p->page_link && PageProperty(p));
ffffffffc0201e40:	00004697          	auipc	a3,0x4
ffffffffc0201e44:	a0868693          	addi	a3,a3,-1528 # ffffffffc0205848 <etext+0xd02>
ffffffffc0201e48:	00003617          	auipc	a2,0x3
ffffffffc0201e4c:	f9060613          	addi	a2,a2,-112 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201e50:	16b00593          	li	a1,363
ffffffffc0201e54:	00003517          	auipc	a0,0x3
ffffffffc0201e58:	f9c50513          	addi	a0,a0,-100 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201e5c:	b66fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(nr_free_pages() == 7);
ffffffffc0201e60:	00004697          	auipc	a3,0x4
ffffffffc0201e64:	9d068693          	addi	a3,a3,-1584 # ffffffffc0205830 <etext+0xcea>
ffffffffc0201e68:	00003617          	auipc	a2,0x3
ffffffffc0201e6c:	f7060613          	addi	a2,a2,-144 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201e70:	16700593          	li	a1,359
ffffffffc0201e74:	00003517          	auipc	a0,0x3
ffffffffc0201e78:	f7c50513          	addi	a0,a0,-132 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201e7c:	b46fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(slots[0] == base && base->u == 0 && base->property == 1);
ffffffffc0201e80:	00004697          	auipc	a3,0x4
ffffffffc0201e84:	97868693          	addi	a3,a3,-1672 # ffffffffc02057f8 <etext+0xcb2>
ffffffffc0201e88:	00003617          	auipc	a2,0x3
ffffffffc0201e8c:	f5060613          	addi	a2,a2,-176 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201e90:	16600593          	li	a1,358
ffffffffc0201e94:	00003517          	auipc	a0,0x3
ffffffffc0201e98:	f5c50513          	addi	a0,a0,-164 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201e9c:	b26fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(free_list.next == &base->page_link && free_list.prev == &base->page_link);
ffffffffc0201ea0:	00004697          	auipc	a3,0x4
ffffffffc0201ea4:	90868693          	addi	a3,a3,-1784 # ffffffffc02057a8 <etext+0xc62>
ffffffffc0201ea8:	00003617          	auipc	a2,0x3
ffffffffc0201eac:	f3060613          	addi	a2,a2,-208 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201eb0:	16300593          	li	a1,355
ffffffffc0201eb4:	00003517          	auipc	a0,0x3
ffffffffc0201eb8:	f3c50513          	addi	a0,a0,-196 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201ebc:	b06fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert((page2ppn(blocks[i]) & (sizes[i] - 1)) == 0);
ffffffffc0201ec0:	00003697          	auipc	a3,0x3
ffffffffc0201ec4:	6d868693          	addi	a3,a3,1752 # ffffffffc0205598 <etext+0xa52>
ffffffffc0201ec8:	00003617          	auipc	a2,0x3
ffffffffc0201ecc:	f1060613          	addi	a2,a2,-240 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201ed0:	13f00593          	li	a1,319
ffffffffc0201ed4:	00003517          	auipc	a0,0x3
ffffffffc0201ed8:	f1c50513          	addi	a0,a0,-228 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201edc:	ae6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(nr_free_pages() == 0 && list_empty(&free_list));
ffffffffc0201ee0:	00004697          	auipc	a3,0x4
ffffffffc0201ee4:	af068693          	addi	a3,a3,-1296 # ffffffffc02059d0 <etext+0xe8a>
ffffffffc0201ee8:	00003617          	auipc	a2,0x3
ffffffffc0201eec:	ef060613          	addi	a2,a2,-272 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201ef0:	19700593          	li	a1,407
ffffffffc0201ef4:	00003517          	auipc	a0,0x3
ffffffffc0201ef8:	efc50513          	addi	a0,a0,-260 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201efc:	ac6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(free_list.next == saved_sentinel.next &&
ffffffffc0201f00:	00004697          	auipc	a3,0x4
ffffffffc0201f04:	f0068693          	addi	a3,a3,-256 # ffffffffc0205e00 <etext+0x12ba>
ffffffffc0201f08:	00003617          	auipc	a2,0x3
ffffffffc0201f0c:	ed060613          	addi	a2,a2,-304 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201f10:	1d900593          	li	a1,473
ffffffffc0201f14:	00003517          	auipc	a0,0x3
ffffffffc0201f18:	edc50513          	addi	a0,a0,-292 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201f1c:	aa6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(list_next(list_prev(&arena->page_link)) == &arena->page_link &&
ffffffffc0201f20:	00004697          	auipc	a3,0x4
ffffffffc0201f24:	e6068693          	addi	a3,a3,-416 # ffffffffc0205d80 <etext+0x123a>
ffffffffc0201f28:	00003617          	auipc	a2,0x3
ffffffffc0201f2c:	eb060613          	addi	a2,a2,-336 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201f30:	1d700593          	li	a1,471
ffffffffc0201f34:	00003517          	auipc	a0,0x3
ffffffffc0201f38:	ebc50513          	addi	a0,a0,-324 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201f3c:	a86fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(arena->u == saved_pages[0].u && arena->property == saved_pages[0].property);
ffffffffc0201f40:	00004697          	auipc	a3,0x4
ffffffffc0201f44:	df068693          	addi	a3,a3,-528 # ffffffffc0205d30 <etext+0x11ea>
ffffffffc0201f48:	00003617          	auipc	a2,0x3
ffffffffc0201f4c:	e9060613          	addi	a2,a2,-368 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201f50:	1d600593          	li	a1,470
ffffffffc0201f54:	00003517          	auipc	a0,0x3
ffffffffc0201f58:	e9c50513          	addi	a0,a0,-356 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201f5c:	a66fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(nr_free_pages() == original_free);
ffffffffc0201f60:	00004697          	auipc	a3,0x4
ffffffffc0201f64:	da868693          	addi	a3,a3,-600 # ffffffffc0205d08 <etext+0x11c2>
ffffffffc0201f68:	00003617          	auipc	a2,0x3
ffffffffc0201f6c:	e7060613          	addi	a2,a2,-400 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201f70:	1d500593          	li	a1,469
ffffffffc0201f74:	00003517          	auipc	a0,0x3
ffffffffc0201f78:	e7c50513          	addi	a0,a0,-388 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201f7c:	a46fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(free_list.next == &arena->page_link && free_list.prev == &arena->page_link);
ffffffffc0201f80:	00003697          	auipc	a3,0x3
ffffffffc0201f84:	76068693          	addi	a3,a3,1888 # ffffffffc02056e0 <etext+0xb9a>
ffffffffc0201f88:	00003617          	auipc	a2,0x3
ffffffffc0201f8c:	e5060613          	addi	a2,a2,-432 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201f90:	1c900593          	li	a1,457
ffffffffc0201f94:	00003517          	auipc	a0,0x3
ffffffffc0201f98:	e5c50513          	addi	a0,a0,-420 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201f9c:	a26fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(nr_free_pages() == 16 && arena->u == 4 && arena->property == 16);
ffffffffc0201fa0:	00004697          	auipc	a3,0x4
ffffffffc0201fa4:	d2868693          	addi	a3,a3,-728 # ffffffffc0205cc8 <etext+0x1182>
ffffffffc0201fa8:	00003617          	auipc	a2,0x3
ffffffffc0201fac:	e3060613          	addi	a2,a2,-464 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201fb0:	1c800593          	li	a1,456
ffffffffc0201fb4:	00003517          	auipc	a0,0x3
ffffffffc0201fb8:	e3c50513          	addi	a0,a0,-452 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201fbc:	a06fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(free_list.next == before_list.next &&
ffffffffc0201fc0:	00004697          	auipc	a3,0x4
ffffffffc0201fc4:	bb868693          	addi	a3,a3,-1096 # ffffffffc0205b78 <etext+0x1032>
ffffffffc0201fc8:	00003617          	auipc	a2,0x3
ffffffffc0201fcc:	e1060613          	addi	a2,a2,-496 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201fd0:	1b200593          	li	a1,434
ffffffffc0201fd4:	00003517          	auipc	a0,0x3
ffffffffc0201fd8:	e1c50513          	addi	a0,a0,-484 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201fdc:	9e6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(nr_free_pages() == before_count);
ffffffffc0201fe0:	00004697          	auipc	a3,0x4
ffffffffc0201fe4:	b7868693          	addi	a3,a3,-1160 # ffffffffc0205b58 <etext+0x1012>
ffffffffc0201fe8:	00003617          	auipc	a2,0x3
ffffffffc0201fec:	df060613          	addi	a2,a2,-528 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0201ff0:	1b100593          	li	a1,433
ffffffffc0201ff4:	00003517          	auipc	a0,0x3
ffffffffc0201ff8:	dfc50513          	addi	a0,a0,-516 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc0201ffc:	9c6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(alloc_pages(failures[f]) == NULL);
ffffffffc0202000:	00004697          	auipc	a3,0x4
ffffffffc0202004:	b3068693          	addi	a3,a3,-1232 # ffffffffc0205b30 <etext+0xfea>
ffffffffc0202008:	00003617          	auipc	a2,0x3
ffffffffc020200c:	dd060613          	addi	a2,a2,-560 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202010:	1b000593          	li	a1,432
ffffffffc0202014:	00003517          	auipc	a0,0x3
ffffffffc0202018:	ddc50513          	addi	a0,a0,-548 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc020201c:	9a6fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(nr_free_pages() == 16 && arena->u == 4);
ffffffffc0202020:	00003697          	auipc	a3,0x3
ffffffffc0202024:	69868693          	addi	a3,a3,1688 # ffffffffc02056b8 <etext+0xb72>
ffffffffc0202028:	00003617          	auipc	a2,0x3
ffffffffc020202c:	db060613          	addi	a2,a2,-592 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202030:	18700593          	li	a1,391
ffffffffc0202034:	00003517          	auipc	a0,0x3
ffffffffc0202038:	dbc50513          	addi	a0,a0,-580 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc020203c:	986fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(free_list.next == &base->page_link && free_list.prev == &base->page_link);
ffffffffc0202040:	00003697          	auipc	a3,0x3
ffffffffc0202044:	76868693          	addi	a3,a3,1896 # ffffffffc02057a8 <etext+0xc62>
ffffffffc0202048:	00003617          	auipc	a2,0x3
ffffffffc020204c:	d9060613          	addi	a2,a2,-624 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202050:	18400593          	li	a1,388
ffffffffc0202054:	00003517          	auipc	a0,0x3
ffffffffc0202058:	d9c50513          	addi	a0,a0,-612 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc020205c:	966fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(base->u == 3 && base->property == 8);
ffffffffc0202060:	00003697          	auipc	a3,0x3
ffffffffc0202064:	72068693          	addi	a3,a3,1824 # ffffffffc0205780 <etext+0xc3a>
ffffffffc0202068:	00003617          	auipc	a2,0x3
ffffffffc020206c:	d7060613          	addi	a2,a2,-656 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202070:	18300593          	li	a1,387
ffffffffc0202074:	00003517          	auipc	a0,0x3
ffffffffc0202078:	d7c50513          	addi	a0,a0,-644 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc020207c:	946fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(nr_free_pages() == i + 1);
ffffffffc0202080:	00004697          	auipc	a3,0x4
ffffffffc0202084:	8a068693          	addi	a3,a3,-1888 # ffffffffc0205920 <etext+0xdda>
ffffffffc0202088:	00003617          	auipc	a2,0x3
ffffffffc020208c:	d5060613          	addi	a2,a2,-688 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202090:	17b00593          	li	a1,379
ffffffffc0202094:	00003517          	auipc	a0,0x3
ffffffffc0202098:	d5c50513          	addi	a0,a0,-676 # ffffffffc0204df0 <etext+0x2aa>
ffffffffc020209c:	926fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02020a0 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc02020a0:	000aa797          	auipc	a5,0xaa
ffffffffc02020a4:	8907b783          	ld	a5,-1904(a5) # ffffffffc02ab930 <pmm_manager>
ffffffffc02020a8:	6f9c                	ld	a5,24(a5)
ffffffffc02020aa:	8782                	jr	a5

ffffffffc02020ac <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc02020ac:	000aa797          	auipc	a5,0xaa
ffffffffc02020b0:	8847b783          	ld	a5,-1916(a5) # ffffffffc02ab930 <pmm_manager>
ffffffffc02020b4:	739c                	ld	a5,32(a5)
ffffffffc02020b6:	8782                	jr	a5

ffffffffc02020b8 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc02020b8:	000aa797          	auipc	a5,0xaa
ffffffffc02020bc:	8787b783          	ld	a5,-1928(a5) # ffffffffc02ab930 <pmm_manager>
ffffffffc02020c0:	779c                	ld	a5,40(a5)
ffffffffc02020c2:	8782                	jr	a5

ffffffffc02020c4 <pmm_init>:
    pmm_manager = &slub_pmm_manager;
ffffffffc02020c4:	00005797          	auipc	a5,0x5
ffffffffc02020c8:	56c78793          	addi	a5,a5,1388 # ffffffffc0207630 <slub_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02020cc:	638c                	ld	a1,0(a5)
    cprintf("page_init: npage=0x%lx pages=0x%016lx freemem=0x%lx\n",
            (unsigned long)npage, (uintptr_t)pages, (unsigned long)freemem);
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02020ce:	7139                	addi	sp,sp,-64
ffffffffc02020d0:	f426                	sd	s1,40(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02020d2:	00004517          	auipc	a0,0x4
ffffffffc02020d6:	eb650513          	addi	a0,a0,-330 # ffffffffc0205f88 <buddy_system_pmm_manager+0x38>
    pmm_manager = &slub_pmm_manager;
ffffffffc02020da:	000aa497          	auipc	s1,0xaa
ffffffffc02020de:	85648493          	addi	s1,s1,-1962 # ffffffffc02ab930 <pmm_manager>
void pmm_init(void) {
ffffffffc02020e2:	fc06                	sd	ra,56(sp)
ffffffffc02020e4:	f04a                	sd	s2,32(sp)
ffffffffc02020e6:	ec4e                	sd	s3,24(sp)
ffffffffc02020e8:	e852                	sd	s4,16(sp)
    pmm_manager = &slub_pmm_manager;
ffffffffc02020ea:	e09c                	sd	a5,0(s1)
void pmm_init(void) {
ffffffffc02020ec:	f822                	sd	s0,48(sp)
ffffffffc02020ee:	e456                	sd	s5,8(sp)
ffffffffc02020f0:	e05a                	sd	s6,0(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02020f2:	85afe0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc02020f6:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02020f8:	000aa917          	auipc	s2,0xaa
ffffffffc02020fc:	85090913          	addi	s2,s2,-1968 # ffffffffc02ab948 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202100:	679c                	ld	a5,8(a5)
ffffffffc0202102:	9782                	jalr	a5
    uint64_t mem_base = get_memory_base();
ffffffffc0202104:	cb8fe0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0202108:	89aa                	mv	s3,a0
    uint64_t mem_size = get_memory_size();
ffffffffc020210a:	cbcfe0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020210e:	57f5                	li	a5,-3
ffffffffc0202110:	07fa                	slli	a5,a5,0x1e
ffffffffc0202112:	00f93023          	sd	a5,0(s2)
    if (mem_base != DRAM_BASE || mem_size == 0) {
ffffffffc0202116:	4785                	li	a5,1
ffffffffc0202118:	07fe                	slli	a5,a5,0x1f
    uint64_t mem_size = get_memory_size();
ffffffffc020211a:	8a2a                	mv	s4,a0
    if (mem_base != DRAM_BASE || mem_size == 0) {
ffffffffc020211c:	16f99163          	bne	s3,a5,ffffffffc020227e <pmm_init+0x1ba>
ffffffffc0202120:	14050f63          	beqz	a0,ffffffffc020227e <pmm_init+0x1ba>
    if (mem_end < mem_base) {  // address overflow
ffffffffc0202124:	800007b7          	lui	a5,0x80000
    uint64_t mem_end = mem_base + mem_size;
ffffffffc0202128:	99aa                	add	s3,s3,a0
    if (mem_end < mem_base) {  // address overflow
ffffffffc020212a:	fff7c793          	not	a5,a5
ffffffffc020212e:	1d37f963          	bgeu	a5,s3,ffffffffc0202300 <pmm_init+0x23c>
    if (mem_end > PHYSICAL_MEMORY_END) {
ffffffffc0202132:	4445                	li	s0,17
ffffffffc0202134:	046e                	slli	s0,s0,0x1b
ffffffffc0202136:	13346763          	bltu	s0,s3,ffffffffc0202264 <pmm_init+0x1a0>
    if (mem_end <= KERNEL_BEGIN_PADDR) {
ffffffffc020213a:	40100793          	li	a5,1025
ffffffffc020213e:	07d6                	slli	a5,a5,0x15
ffffffffc0202140:	1937f763          	bgeu	a5,s3,ffffffffc02022ce <pmm_init+0x20a>
    npage = mem_end / PGSIZE;
ffffffffc0202144:	00c9d593          	srli	a1,s3,0xc
        PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202148:	00259413          	slli	s0,a1,0x2
ffffffffc020214c:	942e                	add	s0,s0,a1
ffffffffc020214e:	040e                	slli	s0,s0,0x3
    npage = mem_end / PGSIZE;
ffffffffc0202150:	777d                	lui	a4,0xfffff
ffffffffc0202152:	000aa797          	auipc	a5,0xaa
ffffffffc0202156:	7fd78793          	addi	a5,a5,2045 # ffffffffc02ac94f <end+0xfff>
ffffffffc020215a:	8ff9                	and	a5,a5,a4
ffffffffc020215c:	fec00837          	lui	a6,0xfec00
ffffffffc0202160:	000a9b17          	auipc	s6,0xa9
ffffffffc0202164:	7c0b0b13          	addi	s6,s6,1984 # ffffffffc02ab920 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202168:	000a9a97          	auipc	s5,0xa9
ffffffffc020216c:	7c0a8a93          	addi	s5,s5,1984 # ffffffffc02ab928 <pages>
ffffffffc0202170:	01078733          	add	a4,a5,a6
    npage = mem_end / PGSIZE;
ffffffffc0202174:	00bb3023          	sd	a1,0(s6)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202178:	00fab023          	sd	a5,0(s5)
        PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020217c:	943a                	add	s0,s0,a4
ffffffffc020217e:	c02006b7          	lui	a3,0xc0200
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202182:	853e                	mv	a0,a5
        PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202184:	12d46863          	bltu	s0,a3,ffffffffc02022b4 <pmm_init+0x1f0>
ffffffffc0202188:	00093683          	ld	a3,0(s2)
ffffffffc020218c:	8c15                	sub	s0,s0,a3
    if (descriptor_end > mem_end) {
ffffffffc020218e:	1489ed63          	bltu	s3,s0,ffffffffc02022e8 <pmm_init+0x224>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0202192:	00259813          	slli	a6,a1,0x2
ffffffffc0202196:	982e                	add	a6,a6,a1
ffffffffc0202198:	080e                	slli	a6,a6,0x3
ffffffffc020219a:	983a                	add	a6,a6,a4
        SetPageReserved(p);
ffffffffc020219c:	4685                	li	a3,1
        p->ref = 0;
ffffffffc020219e:	0007a023          	sw	zero,0(a5)
        p->property = 0;
ffffffffc02021a2:	0007a823          	sw	zero,16(a5)
        SetPageReserved(p);
ffffffffc02021a6:	e794                	sd	a3,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02021a8:	02878793          	addi	a5,a5,40
ffffffffc02021ac:	ff0799e3          	bne	a5,a6,ffffffffc020219e <pmm_init+0xda>
    uintptr_t freemem = ROUNDUP(descriptor_end, PGSIZE);
ffffffffc02021b0:	6685                	lui	a3,0x1
ffffffffc02021b2:	16fd                	addi	a3,a3,-1
ffffffffc02021b4:	77fd                	lui	a5,0xfffff
ffffffffc02021b6:	9436                	add	s0,s0,a3
ffffffffc02021b8:	8c7d                	and	s0,s0,a5
    uintptr_t managed_end = (uintptr_t)npage * PGSIZE;
ffffffffc02021ba:	00c59793          	slli	a5,a1,0xc
    if (freemem < managed_end) {
ffffffffc02021be:	08f46363          	bltu	s0,a5,ffffffffc0202244 <pmm_init+0x180>
    cprintf("physical memory: base=0x%lx size=0x%lx end=0x%lx\n",
ffffffffc02021c2:	4585                	li	a1,1
ffffffffc02021c4:	8652                	mv	a2,s4
ffffffffc02021c6:	05fe                	slli	a1,a1,0x1f
ffffffffc02021c8:	86ce                	mv	a3,s3
ffffffffc02021ca:	00004517          	auipc	a0,0x4
ffffffffc02021ce:	f3650513          	addi	a0,a0,-202 # ffffffffc0206100 <buddy_system_pmm_manager+0x1b0>
ffffffffc02021d2:	f7bfd0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("page_init: npage=0x%lx pages=0x%016lx freemem=0x%lx\n",
ffffffffc02021d6:	000b3583          	ld	a1,0(s6)
ffffffffc02021da:	000ab603          	ld	a2,0(s5)
ffffffffc02021de:	86a2                	mv	a3,s0
ffffffffc02021e0:	00004517          	auipc	a0,0x4
ffffffffc02021e4:	f5850513          	addi	a0,a0,-168 # ffffffffc0206138 <buddy_system_pmm_manager+0x1e8>
ffffffffc02021e8:	f65fd0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02021ec:	609c                	ld	a5,0(s1)
ffffffffc02021ee:	7b9c                	ld	a5,48(a5)
ffffffffc02021f0:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02021f2:	00004517          	auipc	a0,0x4
ffffffffc02021f6:	f7e50513          	addi	a0,a0,-130 # ffffffffc0206170 <buddy_system_pmm_manager+0x220>
ffffffffc02021fa:	f53fd0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02021fe:	00008597          	auipc	a1,0x8
ffffffffc0202202:	e0258593          	addi	a1,a1,-510 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202206:	000a9797          	auipc	a5,0xa9
ffffffffc020220a:	72b7bd23          	sd	a1,1850(a5) # ffffffffc02ab940 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020220e:	c02007b7          	lui	a5,0xc0200
ffffffffc0202212:	08f5e463          	bltu	a1,a5,ffffffffc020229a <pmm_init+0x1d6>
ffffffffc0202216:	00093603          	ld	a2,0(s2)
}
ffffffffc020221a:	7442                	ld	s0,48(sp)
ffffffffc020221c:	70e2                	ld	ra,56(sp)
ffffffffc020221e:	74a2                	ld	s1,40(sp)
ffffffffc0202220:	7902                	ld	s2,32(sp)
ffffffffc0202222:	69e2                	ld	s3,24(sp)
ffffffffc0202224:	6a42                	ld	s4,16(sp)
ffffffffc0202226:	6aa2                	ld	s5,8(sp)
ffffffffc0202228:	6b02                	ld	s6,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020222a:	40c58633          	sub	a2,a1,a2
ffffffffc020222e:	000a9797          	auipc	a5,0xa9
ffffffffc0202232:	70c7b523          	sd	a2,1802(a5) # ffffffffc02ab938 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0202236:	00004517          	auipc	a0,0x4
ffffffffc020223a:	f5a50513          	addi	a0,a0,-166 # ffffffffc0206190 <buddy_system_pmm_manager+0x240>
}
ffffffffc020223e:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0202240:	f0dfd06f          	j	ffffffffc020014c <cprintf>
        size_t free_base = PPN(freemem) - nbase;
ffffffffc0202244:	00c45693          	srli	a3,s0,0xc
    pmm_manager->init_memmap(base, n);
ffffffffc0202248:	6090                	ld	a2,0(s1)
        size_t free_base = PPN(freemem) - nbase;
ffffffffc020224a:	fff807b7          	lui	a5,0xfff80
ffffffffc020224e:	00f68733          	add	a4,a3,a5
        init_memmap(pages + free_base, npage - nbase - free_base);
ffffffffc0202252:	00271793          	slli	a5,a4,0x2
ffffffffc0202256:	97ba                	add	a5,a5,a4
    pmm_manager->init_memmap(base, n);
ffffffffc0202258:	6a18                	ld	a4,16(a2)
        init_memmap(pages + free_base, npage - nbase - free_base);
ffffffffc020225a:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020225c:	8d95                	sub	a1,a1,a3
ffffffffc020225e:	953e                	add	a0,a0,a5
ffffffffc0202260:	9702                	jalr	a4
}
ffffffffc0202262:	b785                	j	ffffffffc02021c2 <pmm_init+0xfe>
        cprintf("page_init: memory end 0x%lx exceeds PHYSICAL_MEMORY_END, clamping\n",
ffffffffc0202264:	85ce                	mv	a1,s3
ffffffffc0202266:	00004517          	auipc	a0,0x4
ffffffffc020226a:	db250513          	addi	a0,a0,-590 # ffffffffc0206018 <buddy_system_pmm_manager+0xc8>
ffffffffc020226e:	edffd0ef          	jal	ra,ffffffffc020014c <cprintf>
        mem_end = PHYSICAL_MEMORY_END;
ffffffffc0202272:	89a2                	mv	s3,s0
        cprintf("page_init: memory end 0x%lx exceeds PHYSICAL_MEMORY_END, clamping\n",
ffffffffc0202274:	000885b7          	lui	a1,0x88
ffffffffc0202278:	01540437          	lui	s0,0x1540
ffffffffc020227c:	bdd1                	j	ffffffffc0202150 <pmm_init+0x8c>
        panic("page_init: incompatible memory layout (base=0x%lx, size=0x%lx)",
ffffffffc020227e:	8752                	mv	a4,s4
ffffffffc0202280:	86ce                	mv	a3,s3
ffffffffc0202282:	00004617          	auipc	a2,0x4
ffffffffc0202286:	d1e60613          	addi	a2,a2,-738 # ffffffffc0205fa0 <buddy_system_pmm_manager+0x50>
ffffffffc020228a:	05e00593          	li	a1,94
ffffffffc020228e:	00004517          	auipc	a0,0x4
ffffffffc0202292:	d5250513          	addi	a0,a0,-686 # ffffffffc0205fe0 <buddy_system_pmm_manager+0x90>
ffffffffc0202296:	f2dfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020229a:	86ae                	mv	a3,a1
ffffffffc020229c:	00004617          	auipc	a2,0x4
ffffffffc02022a0:	e0460613          	addi	a2,a2,-508 # ffffffffc02060a0 <buddy_system_pmm_manager+0x150>
ffffffffc02022a4:	0b700593          	li	a1,183
ffffffffc02022a8:	00004517          	auipc	a0,0x4
ffffffffc02022ac:	d3850513          	addi	a0,a0,-712 # ffffffffc0205fe0 <buddy_system_pmm_manager+0x90>
ffffffffc02022b0:	f13fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02022b4:	86a2                	mv	a3,s0
ffffffffc02022b6:	00004617          	auipc	a2,0x4
ffffffffc02022ba:	dea60613          	addi	a2,a2,-534 # ffffffffc02060a0 <buddy_system_pmm_manager+0x150>
ffffffffc02022be:	08100593          	li	a1,129
ffffffffc02022c2:	00004517          	auipc	a0,0x4
ffffffffc02022c6:	d1e50513          	addi	a0,a0,-738 # ffffffffc0205fe0 <buddy_system_pmm_manager+0x90>
ffffffffc02022ca:	ef9fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("page_init: memory does not cover the kernel image (end=0x%lx)",
ffffffffc02022ce:	86ce                	mv	a3,s3
ffffffffc02022d0:	00004617          	auipc	a2,0x4
ffffffffc02022d4:	d9060613          	addi	a2,a2,-624 # ffffffffc0206060 <buddy_system_pmm_manager+0x110>
ffffffffc02022d8:	07000593          	li	a1,112
ffffffffc02022dc:	00004517          	auipc	a0,0x4
ffffffffc02022e0:	d0450513          	addi	a0,a0,-764 # ffffffffc0205fe0 <buddy_system_pmm_manager+0x90>
ffffffffc02022e4:	edffd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("page_init: not enough memory for page descriptors");
ffffffffc02022e8:	00004617          	auipc	a2,0x4
ffffffffc02022ec:	de060613          	addi	a2,a2,-544 # ffffffffc02060c8 <buddy_system_pmm_manager+0x178>
ffffffffc02022f0:	08300593          	li	a1,131
ffffffffc02022f4:	00004517          	auipc	a0,0x4
ffffffffc02022f8:	cec50513          	addi	a0,a0,-788 # ffffffffc0205fe0 <buddy_system_pmm_manager+0x90>
ffffffffc02022fc:	ec7fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("page_init: memory range overflow");
ffffffffc0202300:	00004617          	auipc	a2,0x4
ffffffffc0202304:	cf060613          	addi	a2,a2,-784 # ffffffffc0205ff0 <buddy_system_pmm_manager+0xa0>
ffffffffc0202308:	06300593          	li	a1,99
ffffffffc020230c:	00004517          	auipc	a0,0x4
ffffffffc0202310:	cd450513          	addi	a0,a0,-812 # ffffffffc0205fe0 <buddy_system_pmm_manager+0x90>
ffffffffc0202314:	eaffd0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0202318 <combined_init_memmap>:
static void combined_init(void) {
    buddy_system_pmm_manager.init();
    slub_init();
}
static void combined_init_memmap(struct Page *base, size_t n) {
    buddy_system_pmm_manager.init_memmap(base, n);
ffffffffc0202318:	00004797          	auipc	a5,0x4
ffffffffc020231c:	c487b783          	ld	a5,-952(a5) # ffffffffc0205f60 <buddy_system_pmm_manager+0x10>
ffffffffc0202320:	8782                	jr	a5

ffffffffc0202322 <combined_alloc_pages>:
}
static struct Page *combined_alloc_pages(size_t n) {
    return buddy_system_pmm_manager.alloc_pages(n);
ffffffffc0202322:	00004797          	auipc	a5,0x4
ffffffffc0202326:	c467b783          	ld	a5,-954(a5) # ffffffffc0205f68 <buddy_system_pmm_manager+0x18>
ffffffffc020232a:	8782                	jr	a5

ffffffffc020232c <combined_free_pages>:
}
static void combined_free_pages(struct Page *base, size_t n) {
    buddy_system_pmm_manager.free_pages(base, n);
ffffffffc020232c:	00004797          	auipc	a5,0x4
ffffffffc0202330:	c447b783          	ld	a5,-956(a5) # ffffffffc0205f70 <buddy_system_pmm_manager+0x20>
ffffffffc0202334:	8782                	jr	a5

ffffffffc0202336 <combined_nr_free_pages>:
}
static size_t combined_nr_free_pages(void) {
    return buddy_system_pmm_manager.nr_free_pages();
ffffffffc0202336:	00004797          	auipc	a5,0x4
ffffffffc020233a:	c427b783          	ld	a5,-958(a5) # ffffffffc0205f78 <buddy_system_pmm_manager+0x28>
ffffffffc020233e:	8782                	jr	a5

ffffffffc0202340 <new_slab>:
static struct slab *new_slab(size_t npages, struct cache *cache) {
ffffffffc0202340:	7179                	addi	sp,sp,-48
ffffffffc0202342:	ec26                	sd	s1,24(sp)
ffffffffc0202344:	e44e                	sd	s3,8(sp)
ffffffffc0202346:	f406                	sd	ra,40(sp)
ffffffffc0202348:	f022                	sd	s0,32(sp)
ffffffffc020234a:	e84a                	sd	s2,16(sp)
ffffffffc020234c:	89aa                	mv	s3,a0
ffffffffc020234e:	84ae                	mv	s1,a1
    struct Page *page = alloc_pages(npages);
ffffffffc0202350:	d51ff0ef          	jal	ra,ffffffffc02020a0 <alloc_pages>
    if (page == NULL) {
ffffffffc0202354:	10050463          	beqz	a0,ffffffffc020245c <new_slab+0x11c>
ffffffffc0202358:	000a9417          	auipc	s0,0xa9
ffffffffc020235c:	5d043403          	ld	s0,1488(s0) # ffffffffc02ab928 <pages>
ffffffffc0202360:	40850433          	sub	s0,a0,s0
ffffffffc0202364:	00005797          	auipc	a5,0x5
ffffffffc0202368:	54c7b783          	ld	a5,1356(a5) # ffffffffc02078b0 <error_string+0x38>
ffffffffc020236c:	840d                	srai	s0,s0,0x3
ffffffffc020236e:	02f40433          	mul	s0,s0,a5
ffffffffc0202372:	00005797          	auipc	a5,0x5
ffffffffc0202376:	54e7b783          	ld	a5,1358(a5) # ffffffffc02078c0 <nbase>
    memset(s, 0, HEADER_SIZE);
ffffffffc020237a:	4581                	li	a1,0
ffffffffc020237c:	892a                	mv	s2,a0
ffffffffc020237e:	08000613          	li	a2,128
ffffffffc0202382:	943e                	add	s0,s0,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0202384:	0432                	slli	s0,s0,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc0202386:	000a9797          	auipc	a5,0xa9
ffffffffc020238a:	5c27b783          	ld	a5,1474(a5) # ffffffffc02ab948 <va_pa_offset>
ffffffffc020238e:	943e                	add	s0,s0,a5
    memset(s, 0, HEADER_SIZE);
ffffffffc0202390:	8522                	mv	a0,s0
ffffffffc0202392:	766020ef          	jal	ra,ffffffffc0204af8 <memset>
    s->magic = SLUB_MAGIC;
ffffffffc0202396:	00005797          	auipc	a5,0x5
ffffffffc020239a:	5227b783          	ld	a5,1314(a5) # ffffffffc02078b8 <error_string+0x40>
ffffffffc020239e:	e01c                	sd	a5,0(s0)
    list_init(&s->available);
ffffffffc02023a0:	04040593          	addi	a1,s0,64
    list_add(&live, &s->live);
ffffffffc02023a4:	05040713          	addi	a4,s0,80
    s->kind = cache == NULL ? LARGE : SMALL;
ffffffffc02023a8:	ccbd                	beqz	s1,ffffffffc0202426 <new_slab+0xe6>
        s->total = (PGSIZE - HEADER_SIZE) / cache->size;
ffffffffc02023aa:	6090                	ld	a2,0(s1)
ffffffffc02023ac:	6785                	lui	a5,0x1
ffffffffc02023ae:	f8078793          	addi	a5,a5,-128 # f80 <kern_entry-0xffffffffc01ff080>
ffffffffc02023b2:	02c7d6b3          	divu	a3,a5,a2
    __list_add(elm, listelm, listelm->next);
ffffffffc02023b6:	000a9517          	auipc	a0,0xa9
ffffffffc02023ba:	d3a50513          	addi	a0,a0,-710 # ffffffffc02ab0f0 <live>
ffffffffc02023be:	00853803          	ld	a6,8(a0)
    s->kind = cache == NULL ? LARGE : SMALL;
ffffffffc02023c2:	4885                	li	a7,1
ffffffffc02023c4:	01142423          	sw	a7,8(s0)
    s->cache = cache;
ffffffffc02023c8:	e804                	sd	s1,16(s0)
    s->page = page;
ffffffffc02023ca:	01243c23          	sd	s2,24(s0)
    s->npages = npages; /* caller already rounded to Buddy's actual block size */
ffffffffc02023ce:	03343023          	sd	s3,32(s0)
    elm->prev = elm->next = elm;
ffffffffc02023d2:	e42c                	sd	a1,72(s0)
ffffffffc02023d4:	e02c                	sd	a1,64(s0)
    prev->next = next->prev = elm;
ffffffffc02023d6:	00e83023          	sd	a4,0(a6) # fffffffffec00000 <end+0x3e9546b0>
ffffffffc02023da:	e518                	sd	a4,8(a0)
    elm->next = next;
ffffffffc02023dc:	05043c23          	sd	a6,88(s0)
    elm->prev = prev;
ffffffffc02023e0:	e828                	sd	a0,80(s0)
        s->total = (PGSIZE - HEADER_SIZE) / cache->size;
ffffffffc02023e2:	f414                	sd	a3,40(s0)
        for (size_t i = s->total; i != 0; --i) {
ffffffffc02023e4:	02c7e263          	bltu	a5,a2,ffffffffc0202408 <new_slab+0xc8>
ffffffffc02023e8:	16fd                	addi	a3,a3,-1
ffffffffc02023ea:	02c687b3          	mul	a5,a3,a2
ffffffffc02023ee:	7c18                	ld	a4,56(s0)
ffffffffc02023f0:	08078793          	addi	a5,a5,128
ffffffffc02023f4:	97a2                	add	a5,a5,s0
ffffffffc02023f6:	a011                	j	ffffffffc02023fa <new_slab+0xba>
ffffffffc02023f8:	16fd                	addi	a3,a3,-1
            slot->next = s->freelist;
ffffffffc02023fa:	e398                	sd	a4,0(a5)
            struct slot *slot = (void *)((char *)objects(s) + (i - 1) * cache->size);
ffffffffc02023fc:	873e                	mv	a4,a5
        for (size_t i = s->total; i != 0; --i) {
ffffffffc02023fe:	8f91                	sub	a5,a5,a2
ffffffffc0202400:	fee5                	bnez	a3,ffffffffc02023f8 <new_slab+0xb8>
            struct slot *slot = (void *)((char *)objects(s) + (i - 1) * cache->size);
ffffffffc0202402:	08040793          	addi	a5,s0,128
ffffffffc0202406:	fc1c                	sd	a5,56(s0)
    __list_add(elm, listelm, listelm->next);
ffffffffc0202408:	689c                	ld	a5,16(s1)
        list_add(&cache->available, &s->available);
ffffffffc020240a:	00848713          	addi	a4,s1,8
}
ffffffffc020240e:	70a2                	ld	ra,40(sp)
    prev->next = next->prev = elm;
ffffffffc0202410:	e38c                	sd	a1,0(a5)
ffffffffc0202412:	e88c                	sd	a1,16(s1)
    elm->next = next;
ffffffffc0202414:	e43c                	sd	a5,72(s0)
    elm->prev = prev;
ffffffffc0202416:	e038                	sd	a4,64(s0)
ffffffffc0202418:	8522                	mv	a0,s0
ffffffffc020241a:	7402                	ld	s0,32(sp)
ffffffffc020241c:	64e2                	ld	s1,24(sp)
ffffffffc020241e:	6942                	ld	s2,16(sp)
ffffffffc0202420:	69a2                	ld	s3,8(sp)
ffffffffc0202422:	6145                	addi	sp,sp,48
ffffffffc0202424:	8082                	ret
    __list_add(elm, listelm, listelm->next);
ffffffffc0202426:	000a9797          	auipc	a5,0xa9
ffffffffc020242a:	cca78793          	addi	a5,a5,-822 # ffffffffc02ab0f0 <live>
ffffffffc020242e:	6794                	ld	a3,8(a5)
    s->kind = cache == NULL ? LARGE : SMALL;
ffffffffc0202430:	4609                	li	a2,2
ffffffffc0202432:	c410                	sw	a2,8(s0)
    s->page = page;
ffffffffc0202434:	01243c23          	sd	s2,24(s0)
    s->npages = npages; /* caller already rounded to Buddy's actual block size */
ffffffffc0202438:	03343023          	sd	s3,32(s0)
    s->cache = cache;
ffffffffc020243c:	00043823          	sd	zero,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0202440:	e42c                	sd	a1,72(s0)
ffffffffc0202442:	e02c                	sd	a1,64(s0)
    prev->next = next->prev = elm;
ffffffffc0202444:	e298                	sd	a4,0(a3)
}
ffffffffc0202446:	70a2                	ld	ra,40(sp)
    elm->next = next;
ffffffffc0202448:	ec34                	sd	a3,88(s0)
    elm->prev = prev;
ffffffffc020244a:	e83c                	sd	a5,80(s0)
ffffffffc020244c:	8522                	mv	a0,s0
ffffffffc020244e:	7402                	ld	s0,32(sp)
    prev->next = next->prev = elm;
ffffffffc0202450:	e798                	sd	a4,8(a5)
ffffffffc0202452:	64e2                	ld	s1,24(sp)
ffffffffc0202454:	6942                	ld	s2,16(sp)
ffffffffc0202456:	69a2                	ld	s3,8(sp)
ffffffffc0202458:	6145                	addi	sp,sp,48
ffffffffc020245a:	8082                	ret
        return NULL;
ffffffffc020245c:	4401                	li	s0,0
}
ffffffffc020245e:	70a2                	ld	ra,40(sp)
ffffffffc0202460:	8522                	mv	a0,s0
ffffffffc0202462:	7402                	ld	s0,32(sp)
ffffffffc0202464:	64e2                	ld	s1,24(sp)
ffffffffc0202466:	6942                	ld	s2,16(sp)
ffffffffc0202468:	69a2                	ld	s3,8(sp)
ffffffffc020246a:	6145                	addi	sp,sp,48
ffffffffc020246c:	8082                	ret

ffffffffc020246e <slub_check_invariants>:
static void slub_check_invariants(void) {
ffffffffc020246e:	7115                	addi	sp,sp,-224
ffffffffc0202470:	f952                	sd	s4,176(sp)
ffffffffc0202472:	f556                	sd	s5,168(sp)
ffffffffc0202474:	ed86                	sd	ra,216(sp)
ffffffffc0202476:	e9a2                	sd	s0,208(sp)
ffffffffc0202478:	e5a6                	sd	s1,200(sp)
ffffffffc020247a:	e1ca                	sd	s2,192(sp)
ffffffffc020247c:	fd4e                	sd	s3,184(sp)
ffffffffc020247e:	f15a                	sd	s6,160(sp)
ffffffffc0202480:	ed5e                	sd	s7,152(sp)
ffffffffc0202482:	e962                	sd	s8,144(sp)
ffffffffc0202484:	e566                	sd	s9,136(sp)
ffffffffc0202486:	e16a                	sd	s10,128(sp)
ffffffffc0202488:	fcee                	sd	s11,120(sp)
    size_t available_count[CACHE_COUNT] = {0}, live_count = 0;
ffffffffc020248a:	f802                	sd	zero,48(sp)
ffffffffc020248c:	fc02                	sd	zero,56(sp)
ffffffffc020248e:	e082                	sd	zero,64(sp)
ffffffffc0202490:	e482                	sd	zero,72(sp)
ffffffffc0202492:	e882                	sd	zero,80(sp)
ffffffffc0202494:	ec82                	sd	zero,88(sp)
ffffffffc0202496:	f082                	sd	zero,96(sp)
ffffffffc0202498:	f482                	sd	zero,104(sp)
    assert(npage > nbase);
ffffffffc020249a:	000a9a97          	auipc	s5,0xa9
ffffffffc020249e:	486aba83          	ld	s5,1158(s5) # ffffffffc02ab920 <npage>
ffffffffc02024a2:	00005a17          	auipc	s4,0x5
ffffffffc02024a6:	41ea3a03          	ld	s4,1054(s4) # ffffffffc02078c0 <nbase>
ffffffffc02024aa:	795a7963          	bgeu	s4,s5,ffffffffc0202c3c <slub_check_invariants+0x7ce>
    return listelm->prev;
ffffffffc02024ae:	000a9e97          	auipc	t4,0xa9
ffffffffc02024b2:	c42e8e93          	addi	t4,t4,-958 # ffffffffc02ab0f0 <live>
    return listelm->next;
ffffffffc02024b6:	000eb783          	ld	a5,0(t4)
    assert(list_next(list_prev(&live)) == &live &&
ffffffffc02024ba:	679c                	ld	a5,8(a5)
ffffffffc02024bc:	7dd79063          	bne	a5,t4,ffffffffc0202c7c <slub_check_invariants+0x80e>
ffffffffc02024c0:	008eb283          	ld	t0,8(t4)
ffffffffc02024c4:	0002b783          	ld	a5,0(t0)
ffffffffc02024c8:	7bd79a63          	bne	a5,t4,ffffffffc0202c7c <slub_check_invariants+0x80e>
ffffffffc02024cc:	00009417          	auipc	s0,0x9
ffffffffc02024d0:	b6440413          	addi	s0,s0,-1180 # ffffffffc020b030 <caches>
ffffffffc02024d4:	8722                	mv	a4,s0
    for (size_t ci = 0; ci < CACHE_COUNT; ++ci) {
ffffffffc02024d6:	4781                	li	a5,0
        assert(caches[ci].size == ((size_t)ALIGNMENT << ci));
ffffffffc02024d8:	4541                	li	a0,16
    for (size_t ci = 0; ci < CACHE_COUNT; ++ci) {
ffffffffc02024da:	45a1                	li	a1,8
        assert(caches[ci].size == ((size_t)ALIGNMENT << ci));
ffffffffc02024dc:	6310                	ld	a2,0(a4)
ffffffffc02024de:	00f516b3          	sll	a3,a0,a5
ffffffffc02024e2:	0cd61de3          	bne	a2,a3,ffffffffc0202dbc <slub_check_invariants+0x94e>
    for (size_t ci = 0; ci < CACHE_COUNT; ++ci) {
ffffffffc02024e6:	0785                	addi	a5,a5,1
ffffffffc02024e8:	0761                	addi	a4,a4,24
ffffffffc02024ea:	feb799e3          	bne	a5,a1,ffffffffc02024dc <slub_check_invariants+0x6e>
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc02024ee:	39d28263          	beq	t0,t4,ffffffffc0202872 <slub_check_invariants+0x404>
        assert(++live_count <= npage - nbase); /* bounds cycles in live */
ffffffffc02024f2:	414a87b3          	sub	a5,s5,s4
ffffffffc02024f6:	e422                	sd	s0,8(sp)
ffffffffc02024f8:	8596                	mv	a1,t0
ffffffffc02024fa:	4985                	li	s3,1
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02024fc:	000a9c97          	auipc	s9,0xa9
ffffffffc0202500:	42cc8c93          	addi	s9,s9,1068 # ffffffffc02ab928 <pages>
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc0202504:	000a9c17          	auipc	s8,0xa9
ffffffffc0202508:	444c0c13          	addi	s8,s8,1092 # ffffffffc02ab948 <va_pa_offset>
        assert(((size_t)1 << s->page->u) == s->npages);
ffffffffc020250c:	4b85                	li	s7,1
        while (ci < CACHE_COUNT && s->cache != &caches[ci]) { ++ci; }
ffffffffc020250e:	4b21                	li	s6,8
        for (size_t i = s->total; i < MAX_SLOTS; ++i) { assert(!bit_set(s, i)); }
ffffffffc0202510:	10000393          	li	t2,256
            seen[index / 8] |= 1U << (index % 8);
ffffffffc0202514:	4f05                	li	t5,1
ffffffffc0202516:	843e                	mv	s0,a5
        assert(s->magic == SLUB_MAGIC && page_address(s->page) == s);
ffffffffc0202518:	00005717          	auipc	a4,0x5
ffffffffc020251c:	3a070713          	addi	a4,a4,928 # ffffffffc02078b8 <error_string+0x40>
ffffffffc0202520:	fb05b783          	ld	a5,-80(a1) # 87fb0 <kern_entry-0xffffffffc0178050>
ffffffffc0202524:	6318                	ld	a4,0(a4)
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0202526:	fb058d93          	addi	s11,a1,-80
        assert(s->magic == SLUB_MAGIC && page_address(s->page) == s);
ffffffffc020252a:	7ee79963          	bne	a5,a4,ffffffffc0202d1c <slub_check_invariants+0x8ae>
ffffffffc020252e:	fc85b883          	ld	a7,-56(a1)
ffffffffc0202532:	000cb783          	ld	a5,0(s9)
ffffffffc0202536:	00005717          	auipc	a4,0x5
ffffffffc020253a:	37a70713          	addi	a4,a4,890 # ffffffffc02078b0 <error_string+0x38>
ffffffffc020253e:	6318                	ld	a4,0(a4)
ffffffffc0202540:	40f887b3          	sub	a5,a7,a5
ffffffffc0202544:	878d                	srai	a5,a5,0x3
ffffffffc0202546:	02e787b3          	mul	a5,a5,a4
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc020254a:	000c3683          	ld	a3,0(s8)
ffffffffc020254e:	97d2                	add	a5,a5,s4
    return page2ppn(page) << PGSHIFT;
ffffffffc0202550:	00c79713          	slli	a4,a5,0xc
ffffffffc0202554:	9736                	add	a4,a4,a3
        assert(s->magic == SLUB_MAGIC && page_address(s->page) == s);
ffffffffc0202556:	7ced9363          	bne	s11,a4,ffffffffc0202d1c <slub_check_invariants+0x8ae>
ffffffffc020255a:	6584                	ld	s1,8(a1)
        assert(list_prev(list_next(le)) == le && list_next(list_prev(le)) == le);
ffffffffc020255c:	6098                	ld	a4,0(s1)
ffffffffc020255e:	7eb71f63          	bne	a4,a1,ffffffffc0202d5c <slub_check_invariants+0x8ee>
ffffffffc0202562:	6198                	ld	a4,0(a1)
ffffffffc0202564:	6718                	ld	a4,8(a4)
ffffffffc0202566:	7eb71b63          	bne	a4,a1,ffffffffc0202d5c <slub_check_invariants+0x8ee>
        assert((uintptr_t)s % PGSIZE == 0 && (uintptr_t)s % ALIGNMENT == 0);
ffffffffc020256a:	6705                	lui	a4,0x1
ffffffffc020256c:	177d                	addi	a4,a4,-1
ffffffffc020256e:	00edf733          	and	a4,s11,a4
ffffffffc0202572:	7c071563          	bnez	a4,ffffffffc0202d3c <slub_check_invariants+0x8ce>
        assert((uintptr_t)objects(s) % ALIGNMENT == 0);
ffffffffc0202576:	00f5f713          	andi	a4,a1,15
        assert((uintptr_t)objects(s) == (uintptr_t)s + HEADER_SIZE);
ffffffffc020257a:	03058813          	addi	a6,a1,48
        assert((uintptr_t)objects(s) % ALIGNMENT == 0);
ffffffffc020257e:	72071f63          	bnez	a4,ffffffffc0202cbc <slub_check_invariants+0x84e>
        assert(page2ppn(s->page) >= nbase && page2ppn(s->page) < npage);
ffffffffc0202582:	7147ed63          	bltu	a5,s4,ffffffffc0202c9c <slub_check_invariants+0x82e>
ffffffffc0202586:	7157fb63          	bgeu	a5,s5,ffffffffc0202c9c <slub_check_invariants+0x82e>
        assert(s->npages > 0 && s->npages <= npage - page2ppn(s->page));
ffffffffc020258a:	fd05b503          	ld	a0,-48(a1)
ffffffffc020258e:	74050763          	beqz	a0,ffffffffc0202cdc <slub_check_invariants+0x86e>
ffffffffc0202592:	40fa87b3          	sub	a5,s5,a5
ffffffffc0202596:	74a7e363          	bltu	a5,a0,ffffffffc0202cdc <slub_check_invariants+0x86e>
        assert((s->npages & (s->npages - 1)) == 0);
ffffffffc020259a:	fff50793          	addi	a5,a0,-1
ffffffffc020259e:	8fe9                	and	a5,a5,a0
ffffffffc02025a0:	7c079e63          	bnez	a5,ffffffffc0202d7c <slub_check_invariants+0x90e>
        assert(s->page->property == s->npages && !PageProperty(s->page));
ffffffffc02025a4:	0108e783          	lwu	a5,16(a7)
ffffffffc02025a8:	62f51a63          	bne	a0,a5,ffffffffc0202bdc <slub_check_invariants+0x76e>
ffffffffc02025ac:	0088b703          	ld	a4,8(a7)
ffffffffc02025b0:	00277693          	andi	a3,a4,2
ffffffffc02025b4:	62069463          	bnez	a3,ffffffffc0202bdc <slub_check_invariants+0x76e>
        assert(s->page->u >= 0 && s->page->u < sizeof(size_t) * 8);
ffffffffc02025b8:	0148a783          	lw	a5,20(a7)
ffffffffc02025bc:	03f00613          	li	a2,63
ffffffffc02025c0:	5ef66e63          	bltu	a2,a5,ffffffffc0202bbc <slub_check_invariants+0x74e>
        assert(((size_t)1 << s->page->u) == s->npages);
ffffffffc02025c4:	00fb97b3          	sll	a5,s7,a5
ffffffffc02025c8:	00f51ae3          	bne	a0,a5,ffffffffc0202ddc <slub_check_invariants+0x96e>
ffffffffc02025cc:	02888793          	addi	a5,a7,40
ffffffffc02025d0:	a021                	j	ffffffffc02025d8 <slub_check_invariants+0x16a>
            assert(!PageReserved(s->page + p) && !PageProperty(s->page + p));
ffffffffc02025d2:	6798                	ld	a4,8(a5)
ffffffffc02025d4:	02878793          	addi	a5,a5,40
ffffffffc02025d8:	8b0d                	andi	a4,a4,3
ffffffffc02025da:	3a071163          	bnez	a4,ffffffffc020297c <slub_check_invariants+0x50e>
            assert(list_empty(&s->page[p].page_link));
ffffffffc02025de:	ff87b303          	ld	t1,-8(a5)
ffffffffc02025e2:	ff078613          	addi	a2,a5,-16
ffffffffc02025e6:	3ac31b63          	bne	t1,a2,ffffffffc020299c <slub_check_invariants+0x52e>
        for (size_t p = 0; p < s->npages; ++p) {
ffffffffc02025ea:	0685                	addi	a3,a3,1
ffffffffc02025ec:	fed513e3          	bne	a0,a3,ffffffffc02025d2 <slub_check_invariants+0x164>
        for (list_entry_t *qle = list_next(&live); qle != le; qle = list_next(qle)) {
ffffffffc02025f0:	02b28863          	beq	t0,a1,ffffffffc0202620 <slub_check_invariants+0x1b2>
            assert(s->page + s->npages <= q->page ||
ffffffffc02025f4:	00251313          	slli	t1,a0,0x2
ffffffffc02025f8:	932a                	add	t1,t1,a0
ffffffffc02025fa:	030e                	slli	t1,t1,0x3
ffffffffc02025fc:	9346                	add	t1,t1,a7
ffffffffc02025fe:	8796                	mv	a5,t0
ffffffffc0202600:	fc87b683          	ld	a3,-56(a5)
ffffffffc0202604:	0066fb63          	bgeu	a3,t1,ffffffffc020261a <slub_check_invariants+0x1ac>
ffffffffc0202608:	fd07be03          	ld	t3,-48(a5)
ffffffffc020260c:	002e1613          	slli	a2,t3,0x2
ffffffffc0202610:	9672                	add	a2,a2,t3
ffffffffc0202612:	060e                	slli	a2,a2,0x3
ffffffffc0202614:	96b2                	add	a3,a3,a2
ffffffffc0202616:	44d8e363          	bltu	a7,a3,ffffffffc0202a5c <slub_check_invariants+0x5ee>
ffffffffc020261a:	679c                	ld	a5,8(a5)
        for (list_entry_t *qle = list_next(&live); qle != le; qle = list_next(qle)) {
ffffffffc020261c:	feb792e3          	bne	a5,a1,ffffffffc0202600 <slub_check_invariants+0x192>
        if (s->kind == LARGE) {
ffffffffc0202620:	fb85a783          	lw	a5,-72(a1)
ffffffffc0202624:	4689                	li	a3,2
ffffffffc0202626:	02d79f63          	bne	a5,a3,ffffffffc0202664 <slub_check_invariants+0x1f6>
            assert(s->cache == NULL && list_empty(&s->available));
ffffffffc020262a:	fc05b783          	ld	a5,-64(a1)
ffffffffc020262e:	52079763          	bnez	a5,ffffffffc0202b5c <slub_check_invariants+0x6ee>
ffffffffc0202632:	ff85b703          	ld	a4,-8(a1)
ffffffffc0202636:	ff058793          	addi	a5,a1,-16
ffffffffc020263a:	52f71163          	bne	a4,a5,ffffffffc0202b5c <slub_check_invariants+0x6ee>
            assert(s->freelist == NULL && s->total == 0 && s->used == 0);
ffffffffc020263e:	fe85b783          	ld	a5,-24(a1)
ffffffffc0202642:	4e079d63          	bnez	a5,ffffffffc0202b3c <slub_check_invariants+0x6ce>
ffffffffc0202646:	fd85b783          	ld	a5,-40(a1)
ffffffffc020264a:	4e079963          	bnez	a5,ffffffffc0202b3c <slub_check_invariants+0x6ce>
ffffffffc020264e:	fe05b783          	ld	a5,-32(a1)
ffffffffc0202652:	4e079563          	bnez	a5,ffffffffc0202b3c <slub_check_invariants+0x6ce>
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0202656:	21d48d63          	beq	s1,t4,ffffffffc0202870 <slub_check_invariants+0x402>
        assert(++live_count <= npage - nbase); /* bounds cycles in live */
ffffffffc020265a:	0985                	addi	s3,s3,1
ffffffffc020265c:	75346063          	bltu	s0,s3,ffffffffc0202d9c <slub_check_invariants+0x92e>
ffffffffc0202660:	85a6                	mv	a1,s1
ffffffffc0202662:	bd5d                	j	ffffffffc0202518 <slub_check_invariants+0xaa>
        assert(s->kind == SMALL && s->npages == 1);
ffffffffc0202664:	69779c63          	bne	a5,s7,ffffffffc0202cfc <slub_check_invariants+0x88e>
ffffffffc0202668:	69751a63          	bne	a0,s7,ffffffffc0202cfc <slub_check_invariants+0x88e>
        while (ci < CACHE_COUNT && s->cache != &caches[ci]) { ++ci; }
ffffffffc020266c:	fc05b683          	ld	a3,-64(a1)
ffffffffc0202670:	67a2                	ld	a5,8(sp)
        size_t ci = 0;
ffffffffc0202672:	4f81                	li	t6,0
        while (ci < CACHE_COUNT && s->cache != &caches[ci]) { ++ci; }
ffffffffc0202674:	02f68663          	beq	a3,a5,ffffffffc02026a0 <slub_check_invariants+0x232>
ffffffffc0202678:	0f85                	addi	t6,t6,1
ffffffffc020267a:	07e1                	addi	a5,a5,24
ffffffffc020267c:	ff6f9ce3          	bne	t6,s6,ffffffffc0202674 <slub_check_invariants+0x206>
        assert(ci < CACHE_COUNT);
ffffffffc0202680:	00004697          	auipc	a3,0x4
ffffffffc0202684:	28068693          	addi	a3,a3,640 # ffffffffc0206900 <buddy_system_pmm_manager+0x9b0>
ffffffffc0202688:	00002617          	auipc	a2,0x2
ffffffffc020268c:	75060613          	addi	a2,a2,1872 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202690:	0f500593          	li	a1,245
ffffffffc0202694:	00004517          	auipc	a0,0x4
ffffffffc0202698:	b4c50513          	addi	a0,a0,-1204 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc020269c:	b27fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(s->total == (PGSIZE - HEADER_SIZE) / s->cache->size);
ffffffffc02026a0:	001f9793          	slli	a5,t6,0x1
ffffffffc02026a4:	97fe                	add	a5,a5,t6
ffffffffc02026a6:	078e                	slli	a5,a5,0x3
ffffffffc02026a8:	00009697          	auipc	a3,0x9
ffffffffc02026ac:	98868693          	addi	a3,a3,-1656 # ffffffffc020b030 <caches>
ffffffffc02026b0:	97b6                	add	a5,a5,a3
ffffffffc02026b2:	0007be03          	ld	t3,0(a5)
ffffffffc02026b6:	6785                	lui	a5,0x1
ffffffffc02026b8:	f8078793          	addi	a5,a5,-128 # f80 <kern_entry-0xffffffffc01ff080>
ffffffffc02026bc:	03c7d7b3          	divu	a5,a5,t3
ffffffffc02026c0:	fd85b883          	ld	a7,-40(a1)
ffffffffc02026c4:	4cf89c63          	bne	a7,a5,ffffffffc0202b9c <slub_check_invariants+0x72e>
        assert(s->total > 0 && s->total <= MAX_SLOTS);
ffffffffc02026c8:	fff88793          	addi	a5,a7,-1
ffffffffc02026cc:	0ff00693          	li	a3,255
ffffffffc02026d0:	4af6e663          	bltu	a3,a5,ffffffffc0202b7c <slub_check_invariants+0x70e>
        assert(s->used > 0 && s->used <= s->total);
ffffffffc02026d4:	fe05b903          	ld	s2,-32(a1)
ffffffffc02026d8:	44090263          	beqz	s2,ffffffffc0202b1c <slub_check_invariants+0x6ae>
ffffffffc02026dc:	4528e063          	bltu	a7,s2,ffffffffc0202b1c <slub_check_invariants+0x6ae>
        for (struct slot *slot = s->freelist; slot != NULL; slot = slot->next) {
ffffffffc02026e0:	fe85b603          	ld	a2,-24(a1)
        uint8_t seen[MAX_SLOTS / 8] = {0};
ffffffffc02026e4:	e802                	sd	zero,16(sp)
ffffffffc02026e6:	ec02                	sd	zero,24(sp)
ffffffffc02026e8:	f002                	sd	zero,32(sp)
ffffffffc02026ea:	f402                	sd	zero,40(sp)
        for (struct slot *slot = s->freelist; slot != NULL; slot = slot->next) {
ffffffffc02026ec:	ca4d                	beqz	a2,ffffffffc020279e <slub_check_invariants+0x330>
    if (addr < start || (addr - start) % s->cache->size != 0) {
ffffffffc02026ee:	09066863          	bltu	a2,a6,ffffffffc020277e <slub_check_invariants+0x310>
ffffffffc02026f2:	410607b3          	sub	a5,a2,a6
ffffffffc02026f6:	03c7fd33          	remu	s10,a5,t3
ffffffffc02026fa:	080d1263          	bnez	s10,ffffffffc020277e <slub_check_invariants+0x310>
    *index = (addr - start) / s->cache->size;
ffffffffc02026fe:	03c7d7b3          	divu	a5,a5,t3
            assert(slot_index(s, slot, &index) && !bit_set(s, index));
ffffffffc0202702:	0717fe63          	bgeu	a5,a7,ffffffffc020277e <slub_check_invariants+0x310>
    return (s->allocated[i / 8] >> (i % 8)) & 1;
ffffffffc0202706:	0037d693          	srli	a3,a5,0x3
ffffffffc020270a:	00d58533          	add	a0,a1,a3
ffffffffc020270e:	01054503          	lbu	a0,16(a0)
ffffffffc0202712:	8b9d                	andi	a5,a5,7
ffffffffc0202714:	40f5553b          	sraw	a0,a0,a5
            assert(slot_index(s, slot, &index) && !bit_set(s, index));
ffffffffc0202718:	8905                	andi	a0,a0,1
ffffffffc020271a:	c51d                	beqz	a0,ffffffffc0202748 <slub_check_invariants+0x2da>
ffffffffc020271c:	a08d                	j	ffffffffc020277e <slub_check_invariants+0x310>
    if (addr < start || (addr - start) % s->cache->size != 0) {
ffffffffc020271e:	410607b3          	sub	a5,a2,a6
ffffffffc0202722:	03c7f6b3          	remu	a3,a5,t3
ffffffffc0202726:	eea1                	bnez	a3,ffffffffc020277e <slub_check_invariants+0x310>
    *index = (addr - start) / s->cache->size;
ffffffffc0202728:	03c7d7b3          	divu	a5,a5,t3
            assert(slot_index(s, slot, &index) && !bit_set(s, index));
ffffffffc020272c:	0517f963          	bgeu	a5,a7,ffffffffc020277e <slub_check_invariants+0x310>
    return (s->allocated[i / 8] >> (i % 8)) & 1;
ffffffffc0202730:	0037d693          	srli	a3,a5,0x3
ffffffffc0202734:	00d58533          	add	a0,a1,a3
ffffffffc0202738:	01054503          	lbu	a0,16(a0)
ffffffffc020273c:	8b9d                	andi	a5,a5,7
ffffffffc020273e:	40f5553b          	sraw	a0,a0,a5
            assert(slot_index(s, slot, &index) && !bit_set(s, index));
ffffffffc0202742:	8905                	andi	a0,a0,1
ffffffffc0202744:	ed0d                	bnez	a0,ffffffffc020277e <slub_check_invariants+0x310>
ffffffffc0202746:	8d1a                	mv	s10,t1
            assert((uintptr_t)slot % ALIGNMENT == 0);
ffffffffc0202748:	00f67513          	andi	a0,a2,15
ffffffffc020274c:	2c051863          	bnez	a0,ffffffffc0202a1c <slub_check_invariants+0x5ae>
            assert(!(seen[index / 8] & (1U << (index % 8))));
ffffffffc0202750:	1888                	addi	a0,sp,112
ffffffffc0202752:	96aa                	add	a3,a3,a0
ffffffffc0202754:	fa06c503          	lbu	a0,-96(a3)
ffffffffc0202758:	00f5533b          	srlw	t1,a0,a5
ffffffffc020275c:	00137313          	andi	t1,t1,1
ffffffffc0202760:	2c031e63          	bnez	t1,ffffffffc0202a3c <slub_check_invariants+0x5ce>
            seen[index / 8] |= 1U << (index % 8);
ffffffffc0202764:	00ff17bb          	sllw	a5,t5,a5
ffffffffc0202768:	8d5d                	or	a0,a0,a5
ffffffffc020276a:	faa68023          	sb	a0,-96(a3)
            assert(++free_count <= s->total);
ffffffffc020276e:	001d0313          	addi	t1,s10,1
ffffffffc0202772:	25a88563          	beq	a7,s10,ffffffffc02029bc <slub_check_invariants+0x54e>
        for (struct slot *slot = s->freelist; slot != NULL; slot = slot->next) {
ffffffffc0202776:	6210                	ld	a2,0(a2)
ffffffffc0202778:	c605                	beqz	a2,ffffffffc02027a0 <slub_check_invariants+0x332>
    if (addr < start || (addr - start) % s->cache->size != 0) {
ffffffffc020277a:	fb0672e3          	bgeu	a2,a6,ffffffffc020271e <slub_check_invariants+0x2b0>
            assert(slot_index(s, slot, &index) && !bit_set(s, index));
ffffffffc020277e:	00004697          	auipc	a3,0x4
ffffffffc0202782:	1aa68693          	addi	a3,a3,426 # ffffffffc0206928 <buddy_system_pmm_manager+0x9d8>
ffffffffc0202786:	00002617          	auipc	a2,0x2
ffffffffc020278a:	65260613          	addi	a2,a2,1618 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020278e:	0fd00593          	li	a1,253
ffffffffc0202792:	00004517          	auipc	a0,0x4
ffffffffc0202796:	a4e50513          	addi	a0,a0,-1458 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc020279a:	a29fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        size_t free_count = 0, used_count = 0;
ffffffffc020279e:	4301                	li	t1,0
            assert(slot + s->cache->size <= (uintptr_t)s + PGSIZE);
ffffffffc02027a0:	6785                	lui	a5,0x1
ffffffffc02027a2:	9dbe                	add	s11,s11,a5
ffffffffc02027a4:	01c80533          	add	a0,a6,t3
ffffffffc02027a8:	22adea63          	bltu	s11,a0,ffffffffc02029dc <slub_check_invariants+0x56e>
        for (size_t i = 0; i < s->total; ++i) {
ffffffffc02027ac:	4601                	li	a2,0
ffffffffc02027ae:	a811                	j	ffffffffc02027c2 <slub_check_invariants+0x354>
            assert(slot % ALIGNMENT == 0 && slot >= (uintptr_t)s + HEADER_SIZE);
ffffffffc02027b0:	00f57793          	andi	a5,a0,15
ffffffffc02027b4:	1a079463          	bnez	a5,ffffffffc020295c <slub_check_invariants+0x4ee>
ffffffffc02027b8:	1b056263          	bltu	a0,a6,ffffffffc020295c <slub_check_invariants+0x4ee>
            assert(slot + s->cache->size <= (uintptr_t)s + PGSIZE);
ffffffffc02027bc:	9572                	add	a0,a0,t3
ffffffffc02027be:	20adef63          	bltu	s11,a0,ffffffffc02029dc <slub_check_invariants+0x56e>
    return (s->allocated[i / 8] >> (i % 8)) & 1;
ffffffffc02027c2:	00365793          	srli	a5,a2,0x3
            assert(bit_set(s, i) != ((seen[i / 8] >> (i % 8)) & 1));
ffffffffc02027c6:	07010d13          	addi	s10,sp,112
    return (s->allocated[i / 8] >> (i % 8)) & 1;
ffffffffc02027ca:	00f586b3          	add	a3,a1,a5
            assert(bit_set(s, i) != ((seen[i / 8] >> (i % 8)) & 1));
ffffffffc02027ce:	97ea                	add	a5,a5,s10
    return (s->allocated[i / 8] >> (i % 8)) & 1;
ffffffffc02027d0:	0106c683          	lbu	a3,16(a3)
            assert(bit_set(s, i) != ((seen[i / 8] >> (i % 8)) & 1));
ffffffffc02027d4:	fa07c783          	lbu	a5,-96(a5) # fa0 <kern_entry-0xffffffffc01ff060>
    return (s->allocated[i / 8] >> (i % 8)) & 1;
ffffffffc02027d8:	00767d13          	andi	s10,a2,7
ffffffffc02027dc:	41a6d6bb          	sraw	a3,a3,s10
            assert(bit_set(s, i) != ((seen[i / 8] >> (i % 8)) & 1));
ffffffffc02027e0:	41a7d7bb          	sraw	a5,a5,s10
    return (s->allocated[i / 8] >> (i % 8)) & 1;
ffffffffc02027e4:	8a85                	andi	a3,a3,1
            assert(bit_set(s, i) != ((seen[i / 8] >> (i % 8)) & 1));
ffffffffc02027e6:	8b85                	andi	a5,a5,1
            used_count += bit_set(s, i);
ffffffffc02027e8:	9736                	add	a4,a4,a3
            assert(bit_set(s, i) != ((seen[i / 8] >> (i % 8)) & 1));
ffffffffc02027ea:	20d78963          	beq	a5,a3,ffffffffc02029fc <slub_check_invariants+0x58e>
        for (size_t i = 0; i < s->total; ++i) {
ffffffffc02027ee:	0605                	addi	a2,a2,1
ffffffffc02027f0:	fcc890e3          	bne	a7,a2,ffffffffc02027b0 <slub_check_invariants+0x342>
        for (size_t i = s->total; i < MAX_SLOTS; ++i) { assert(!bit_set(s, i)); }
ffffffffc02027f4:	02788f63          	beq	a7,t2,ffffffffc0202832 <slub_check_invariants+0x3c4>
    return (s->allocated[i / 8] >> (i % 8)) & 1;
ffffffffc02027f8:	0038d793          	srli	a5,a7,0x3
ffffffffc02027fc:	97ae                	add	a5,a5,a1
ffffffffc02027fe:	0107c783          	lbu	a5,16(a5)
ffffffffc0202802:	0078f693          	andi	a3,a7,7
ffffffffc0202806:	40d7d7bb          	sraw	a5,a5,a3
        for (size_t i = s->total; i < MAX_SLOTS; ++i) { assert(!bit_set(s, i)); }
ffffffffc020280a:	8b85                	andi	a5,a5,1
ffffffffc020280c:	26079863          	bnez	a5,ffffffffc0202a7c <slub_check_invariants+0x60e>
ffffffffc0202810:	86c6                	mv	a3,a7
ffffffffc0202812:	a829                	j	ffffffffc020282c <slub_check_invariants+0x3be>
    return (s->allocated[i / 8] >> (i % 8)) & 1;
ffffffffc0202814:	0036d793          	srli	a5,a3,0x3
ffffffffc0202818:	97ae                	add	a5,a5,a1
ffffffffc020281a:	0107c783          	lbu	a5,16(a5)
ffffffffc020281e:	0076f613          	andi	a2,a3,7
ffffffffc0202822:	40c7d7bb          	sraw	a5,a5,a2
        for (size_t i = s->total; i < MAX_SLOTS; ++i) { assert(!bit_set(s, i)); }
ffffffffc0202826:	8b85                	andi	a5,a5,1
ffffffffc0202828:	24079a63          	bnez	a5,ffffffffc0202a7c <slub_check_invariants+0x60e>
ffffffffc020282c:	0685                	addi	a3,a3,1
ffffffffc020282e:	fe7693e3          	bne	a3,t2,ffffffffc0202814 <slub_check_invariants+0x3a6>
        assert(used_count == s->used && s->used + free_count == s->total);
ffffffffc0202832:	2ce91563          	bne	s2,a4,ffffffffc0202afc <slub_check_invariants+0x68e>
ffffffffc0202836:	006907b3          	add	a5,s2,t1
ffffffffc020283a:	2cf89163          	bne	a7,a5,ffffffffc0202afc <slub_check_invariants+0x68e>
    return list->next == list;
ffffffffc020283e:	ff85b703          	ld	a4,-8(a1)
        assert(list_empty(&s->available) == (s->used == s->total));
ffffffffc0202842:	15c1                	addi	a1,a1,-16
ffffffffc0202844:	412887b3          	sub	a5,a7,s2
ffffffffc0202848:	8f0d                	sub	a4,a4,a1
ffffffffc020284a:	0017b793          	seqz	a5,a5
ffffffffc020284e:	00173713          	seqz	a4,a4
ffffffffc0202852:	40e79563          	bne	a5,a4,ffffffffc0202c5c <slub_check_invariants+0x7ee>
        available_count[ci] += free_count != 0;
ffffffffc0202856:	1898                	addi	a4,sp,112
ffffffffc0202858:	003f9793          	slli	a5,t6,0x3
ffffffffc020285c:	97ba                	add	a5,a5,a4
ffffffffc020285e:	fc07b703          	ld	a4,-64(a5)
ffffffffc0202862:	00603333          	snez	t1,t1
ffffffffc0202866:	933a                	add	t1,t1,a4
ffffffffc0202868:	fc67b023          	sd	t1,-64(a5)
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc020286c:	dfd497e3          	bne	s1,t4,ffffffffc020265a <slub_check_invariants+0x1ec>
ffffffffc0202870:	6422                	ld	s0,8(sp)
ffffffffc0202872:	00008897          	auipc	a7,0x8
ffffffffc0202876:	7c688893          	addi	a7,a7,1990 # ffffffffc020b038 <caches+0x8>
ffffffffc020287a:	03010f93          	addi	t6,sp,48
ffffffffc020287e:	00009397          	auipc	t2,0x9
ffffffffc0202882:	87238393          	addi	t2,t2,-1934 # ffffffffc020b0f0 <free_blocks.2>
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc0202886:	7e7d                	lui	t3,0xfffff
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0202888:	fb028813          	addi	a6,t0,-80
            assert(s->kind == SMALL && s->used > 0 && s->used < s->total);
ffffffffc020288c:	4f05                	li	t5,1
    return listelm->next;
ffffffffc020288e:	0008b783          	ld	a5,0(a7)
        assert(list_next(list_prev(head)) == head && list_prev(list_next(head)) == head);
ffffffffc0202892:	679c                	ld	a5,8(a5)
ffffffffc0202894:	38f89463          	bne	a7,a5,ffffffffc0202c1c <slub_check_invariants+0x7ae>
ffffffffc0202898:	6814                	ld	a3,16(s0)
ffffffffc020289a:	629c                	ld	a5,0(a3)
ffffffffc020289c:	38f89063          	bne	a7,a5,ffffffffc0202c1c <slub_check_invariants+0x7ae>
            assert(++count <= available_count[ci]); /* catches cycles/duplicates */
ffffffffc02028a0:	000fb303          	ld	t1,0(t6)
        size_t count = 0;
ffffffffc02028a4:	4581                	li	a1,0
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
ffffffffc02028a6:	09168463          	beq	a3,a7,ffffffffc020292e <slub_check_invariants+0x4c0>
            assert(++count <= available_count[ci]); /* catches cycles/duplicates */
ffffffffc02028aa:	0585                	addi	a1,a1,1
ffffffffc02028ac:	34b36863          	bltu	t1,a1,ffffffffc0202bfc <slub_check_invariants+0x78e>
            struct slab *s = to_struct(le, struct slab, available);
ffffffffc02028b0:	fc068513          	addi	a0,a3,-64
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc02028b4:	01c57633          	and	a2,a0,t3
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc02028b8:	01d28e63          	beq	t0,t4,ffffffffc02028d4 <slub_check_invariants+0x466>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc02028bc:	8742                	mv	a4,a6
        if ((uintptr_t)s == base) {
ffffffffc02028be:	02c80b63          	beq	a6,a2,ffffffffc02028f4 <slub_check_invariants+0x486>
ffffffffc02028c2:	8796                	mv	a5,t0
ffffffffc02028c4:	a029                	j	ffffffffc02028ce <slub_check_invariants+0x460>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc02028c6:	fb078713          	addi	a4,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc02028ca:	02c70563          	beq	a4,a2,ffffffffc02028f4 <slub_check_invariants+0x486>
ffffffffc02028ce:	679c                	ld	a5,8(a5)
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc02028d0:	ffd79be3          	bne	a5,t4,ffffffffc02028c6 <slub_check_invariants+0x458>
            assert(find_slab(s) == s && s->cache == &caches[ci]);
ffffffffc02028d4:	00004697          	auipc	a3,0x4
ffffffffc02028d8:	fa468693          	addi	a3,a3,-92 # ffffffffc0206878 <buddy_system_pmm_manager+0x928>
ffffffffc02028dc:	00002617          	auipc	a2,0x2
ffffffffc02028e0:	4fc60613          	addi	a2,a2,1276 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02028e4:	11700593          	li	a1,279
ffffffffc02028e8:	00004517          	auipc	a0,0x4
ffffffffc02028ec:	8f850513          	addi	a0,a0,-1800 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02028f0:	8d3fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc02028f4:	fea710e3          	bne	a4,a0,ffffffffc02028d4 <slub_check_invariants+0x466>
ffffffffc02028f8:	fd06b783          	ld	a5,-48(a3)
ffffffffc02028fc:	fc879ce3          	bne	a5,s0,ffffffffc02028d4 <slub_check_invariants+0x466>
            assert(s->kind == SMALL && s->used > 0 && s->used < s->total);
ffffffffc0202900:	fc86a783          	lw	a5,-56(a3)
ffffffffc0202904:	1be79c63          	bne	a5,t5,ffffffffc0202abc <slub_check_invariants+0x64e>
ffffffffc0202908:	ff06b783          	ld	a5,-16(a3)
ffffffffc020290c:	1a078863          	beqz	a5,ffffffffc0202abc <slub_check_invariants+0x64e>
ffffffffc0202910:	fe86b703          	ld	a4,-24(a3)
ffffffffc0202914:	1ae7f463          	bgeu	a5,a4,ffffffffc0202abc <slub_check_invariants+0x64e>
ffffffffc0202918:	669c                	ld	a5,8(a3)
            assert(list_prev(list_next(le)) == le && list_next(list_prev(le)) == le);
ffffffffc020291a:	6398                	ld	a4,0(a5)
ffffffffc020291c:	18e69063          	bne	a3,a4,ffffffffc0202a9c <slub_check_invariants+0x62e>
ffffffffc0202920:	6298                	ld	a4,0(a3)
ffffffffc0202922:	6718                	ld	a4,8(a4)
ffffffffc0202924:	16e69c63          	bne	a3,a4,ffffffffc0202a9c <slub_check_invariants+0x62e>
ffffffffc0202928:	86be                	mv	a3,a5
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
ffffffffc020292a:	f91690e3          	bne	a3,a7,ffffffffc02028aa <slub_check_invariants+0x43c>
        assert(count == available_count[ci]);
ffffffffc020292e:	1a659763          	bne	a1,t1,ffffffffc0202adc <slub_check_invariants+0x66e>
    for (size_t ci = 0; ci < CACHE_COUNT; ++ci) {
ffffffffc0202932:	0461                	addi	s0,s0,24
ffffffffc0202934:	01868893          	addi	a7,a3,24
ffffffffc0202938:	0fa1                	addi	t6,t6,8
ffffffffc020293a:	f4839ae3          	bne	t2,s0,ffffffffc020288e <slub_check_invariants+0x420>
}
ffffffffc020293e:	60ee                	ld	ra,216(sp)
ffffffffc0202940:	644e                	ld	s0,208(sp)
ffffffffc0202942:	64ae                	ld	s1,200(sp)
ffffffffc0202944:	690e                	ld	s2,192(sp)
ffffffffc0202946:	79ea                	ld	s3,184(sp)
ffffffffc0202948:	7a4a                	ld	s4,176(sp)
ffffffffc020294a:	7aaa                	ld	s5,168(sp)
ffffffffc020294c:	7b0a                	ld	s6,160(sp)
ffffffffc020294e:	6bea                	ld	s7,152(sp)
ffffffffc0202950:	6c4a                	ld	s8,144(sp)
ffffffffc0202952:	6caa                	ld	s9,136(sp)
ffffffffc0202954:	6d0a                	ld	s10,128(sp)
ffffffffc0202956:	7de6                	ld	s11,120(sp)
ffffffffc0202958:	612d                	addi	sp,sp,224
ffffffffc020295a:	8082                	ret
            assert(slot % ALIGNMENT == 0 && slot >= (uintptr_t)s + HEADER_SIZE);
ffffffffc020295c:	00004697          	auipc	a3,0x4
ffffffffc0202960:	d8468693          	addi	a3,a3,-636 # ffffffffc02066e0 <buddy_system_pmm_manager+0x790>
ffffffffc0202964:	00002617          	auipc	a2,0x2
ffffffffc0202968:	47460613          	addi	a2,a2,1140 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020296c:	10500593          	li	a1,261
ffffffffc0202970:	00004517          	auipc	a0,0x4
ffffffffc0202974:	87050513          	addi	a0,a0,-1936 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202978:	84bfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(!PageReserved(s->page + p) && !PageProperty(s->page + p));
ffffffffc020297c:	00004697          	auipc	a3,0x4
ffffffffc0202980:	b2468693          	addi	a3,a3,-1244 # ffffffffc02064a0 <buddy_system_pmm_manager+0x550>
ffffffffc0202984:	00002617          	auipc	a2,0x2
ffffffffc0202988:	45460613          	addi	a2,a2,1108 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020298c:	0e400593          	li	a1,228
ffffffffc0202990:	00004517          	auipc	a0,0x4
ffffffffc0202994:	85050513          	addi	a0,a0,-1968 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202998:	82bfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(list_empty(&s->page[p].page_link));
ffffffffc020299c:	00004697          	auipc	a3,0x4
ffffffffc02029a0:	b4468693          	addi	a3,a3,-1212 # ffffffffc02064e0 <buddy_system_pmm_manager+0x590>
ffffffffc02029a4:	00002617          	auipc	a2,0x2
ffffffffc02029a8:	43460613          	addi	a2,a2,1076 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02029ac:	0e500593          	li	a1,229
ffffffffc02029b0:	00004517          	auipc	a0,0x4
ffffffffc02029b4:	83050513          	addi	a0,a0,-2000 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02029b8:	80bfd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(++free_count <= s->total);
ffffffffc02029bc:	00004697          	auipc	a3,0x4
ffffffffc02029c0:	d0468693          	addi	a3,a3,-764 # ffffffffc02066c0 <buddy_system_pmm_manager+0x770>
ffffffffc02029c4:	00002617          	auipc	a2,0x2
ffffffffc02029c8:	41460613          	addi	a2,a2,1044 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02029cc:	10100593          	li	a1,257
ffffffffc02029d0:	00004517          	auipc	a0,0x4
ffffffffc02029d4:	81050513          	addi	a0,a0,-2032 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02029d8:	feafd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(slot + s->cache->size <= (uintptr_t)s + PGSIZE);
ffffffffc02029dc:	00004697          	auipc	a3,0x4
ffffffffc02029e0:	d4468693          	addi	a3,a3,-700 # ffffffffc0206720 <buddy_system_pmm_manager+0x7d0>
ffffffffc02029e4:	00002617          	auipc	a2,0x2
ffffffffc02029e8:	3f460613          	addi	a2,a2,1012 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02029ec:	10600593          	li	a1,262
ffffffffc02029f0:	00003517          	auipc	a0,0x3
ffffffffc02029f4:	7f050513          	addi	a0,a0,2032 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02029f8:	fcafd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(bit_set(s, i) != ((seen[i / 8] >> (i % 8)) & 1));
ffffffffc02029fc:	00004697          	auipc	a3,0x4
ffffffffc0202a00:	d5468693          	addi	a3,a3,-684 # ffffffffc0206750 <buddy_system_pmm_manager+0x800>
ffffffffc0202a04:	00002617          	auipc	a2,0x2
ffffffffc0202a08:	3d460613          	addi	a2,a2,980 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202a0c:	10800593          	li	a1,264
ffffffffc0202a10:	00003517          	auipc	a0,0x3
ffffffffc0202a14:	7d050513          	addi	a0,a0,2000 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202a18:	faafd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert((uintptr_t)slot % ALIGNMENT == 0);
ffffffffc0202a1c:	00004697          	auipc	a3,0x4
ffffffffc0202a20:	c4c68693          	addi	a3,a3,-948 # ffffffffc0206668 <buddy_system_pmm_manager+0x718>
ffffffffc0202a24:	00002617          	auipc	a2,0x2
ffffffffc0202a28:	3b460613          	addi	a2,a2,948 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202a2c:	0fe00593          	li	a1,254
ffffffffc0202a30:	00003517          	auipc	a0,0x3
ffffffffc0202a34:	7b050513          	addi	a0,a0,1968 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202a38:	f8afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(!(seen[index / 8] & (1U << (index % 8))));
ffffffffc0202a3c:	00004697          	auipc	a3,0x4
ffffffffc0202a40:	c5468693          	addi	a3,a3,-940 # ffffffffc0206690 <buddy_system_pmm_manager+0x740>
ffffffffc0202a44:	00002617          	auipc	a2,0x2
ffffffffc0202a48:	39460613          	addi	a2,a2,916 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202a4c:	0ff00593          	li	a1,255
ffffffffc0202a50:	00003517          	auipc	a0,0x3
ffffffffc0202a54:	79050513          	addi	a0,a0,1936 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202a58:	f6afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(s->page + s->npages <= q->page ||
ffffffffc0202a5c:	00004697          	auipc	a3,0x4
ffffffffc0202a60:	aac68693          	addi	a3,a3,-1364 # ffffffffc0206508 <buddy_system_pmm_manager+0x5b8>
ffffffffc0202a64:	00002617          	auipc	a2,0x2
ffffffffc0202a68:	37460613          	addi	a2,a2,884 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202a6c:	0ea00593          	li	a1,234
ffffffffc0202a70:	00003517          	auipc	a0,0x3
ffffffffc0202a74:	77050513          	addi	a0,a0,1904 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202a78:	f4afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        for (size_t i = s->total; i < MAX_SLOTS; ++i) { assert(!bit_set(s, i)); }
ffffffffc0202a7c:	00004697          	auipc	a3,0x4
ffffffffc0202a80:	d0468693          	addi	a3,a3,-764 # ffffffffc0206780 <buddy_system_pmm_manager+0x830>
ffffffffc0202a84:	00002617          	auipc	a2,0x2
ffffffffc0202a88:	35460613          	addi	a2,a2,852 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202a8c:	10a00593          	li	a1,266
ffffffffc0202a90:	00003517          	auipc	a0,0x3
ffffffffc0202a94:	75050513          	addi	a0,a0,1872 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202a98:	f2afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(list_prev(list_next(le)) == le && list_next(list_prev(le)) == le);
ffffffffc0202a9c:	00003697          	auipc	a3,0x3
ffffffffc0202aa0:	85c68693          	addi	a3,a3,-1956 # ffffffffc02052f8 <etext+0x7b2>
ffffffffc0202aa4:	00002617          	auipc	a2,0x2
ffffffffc0202aa8:	33460613          	addi	a2,a2,820 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202aac:	11900593          	li	a1,281
ffffffffc0202ab0:	00003517          	auipc	a0,0x3
ffffffffc0202ab4:	73050513          	addi	a0,a0,1840 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202ab8:	f0afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(s->kind == SMALL && s->used > 0 && s->used < s->total);
ffffffffc0202abc:	00004697          	auipc	a3,0x4
ffffffffc0202ac0:	dec68693          	addi	a3,a3,-532 # ffffffffc02068a8 <buddy_system_pmm_manager+0x958>
ffffffffc0202ac4:	00002617          	auipc	a2,0x2
ffffffffc0202ac8:	31460613          	addi	a2,a2,788 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202acc:	11800593          	li	a1,280
ffffffffc0202ad0:	00003517          	auipc	a0,0x3
ffffffffc0202ad4:	71050513          	addi	a0,a0,1808 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202ad8:	eeafd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(count == available_count[ci]);
ffffffffc0202adc:	00004697          	auipc	a3,0x4
ffffffffc0202ae0:	e0468693          	addi	a3,a3,-508 # ffffffffc02068e0 <buddy_system_pmm_manager+0x990>
ffffffffc0202ae4:	00002617          	auipc	a2,0x2
ffffffffc0202ae8:	2f460613          	addi	a2,a2,756 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202aec:	11b00593          	li	a1,283
ffffffffc0202af0:	00003517          	auipc	a0,0x3
ffffffffc0202af4:	6f050513          	addi	a0,a0,1776 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202af8:	ecafd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(used_count == s->used && s->used + free_count == s->total);
ffffffffc0202afc:	00004697          	auipc	a3,0x4
ffffffffc0202b00:	c9468693          	addi	a3,a3,-876 # ffffffffc0206790 <buddy_system_pmm_manager+0x840>
ffffffffc0202b04:	00002617          	auipc	a2,0x2
ffffffffc0202b08:	2d460613          	addi	a2,a2,724 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202b0c:	10b00593          	li	a1,267
ffffffffc0202b10:	00003517          	auipc	a0,0x3
ffffffffc0202b14:	6d050513          	addi	a0,a0,1744 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202b18:	eaafd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(s->used > 0 && s->used <= s->total);
ffffffffc0202b1c:	00004697          	auipc	a3,0x4
ffffffffc0202b20:	b2468693          	addi	a3,a3,-1244 # ffffffffc0206640 <buddy_system_pmm_manager+0x6f0>
ffffffffc0202b24:	00002617          	auipc	a2,0x2
ffffffffc0202b28:	2b460613          	addi	a2,a2,692 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202b2c:	0f800593          	li	a1,248
ffffffffc0202b30:	00003517          	auipc	a0,0x3
ffffffffc0202b34:	6b050513          	addi	a0,a0,1712 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202b38:	e8afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(s->freelist == NULL && s->total == 0 && s->used == 0);
ffffffffc0202b3c:	00004697          	auipc	a3,0x4
ffffffffc0202b40:	a4468693          	addi	a3,a3,-1468 # ffffffffc0206580 <buddy_system_pmm_manager+0x630>
ffffffffc0202b44:	00002617          	auipc	a2,0x2
ffffffffc0202b48:	29460613          	addi	a2,a2,660 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202b4c:	0ef00593          	li	a1,239
ffffffffc0202b50:	00003517          	auipc	a0,0x3
ffffffffc0202b54:	69050513          	addi	a0,a0,1680 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202b58:	e6afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(s->cache == NULL && list_empty(&s->available));
ffffffffc0202b5c:	00004697          	auipc	a3,0x4
ffffffffc0202b60:	9f468693          	addi	a3,a3,-1548 # ffffffffc0206550 <buddy_system_pmm_manager+0x600>
ffffffffc0202b64:	00002617          	auipc	a2,0x2
ffffffffc0202b68:	27460613          	addi	a2,a2,628 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202b6c:	0ee00593          	li	a1,238
ffffffffc0202b70:	00003517          	auipc	a0,0x3
ffffffffc0202b74:	67050513          	addi	a0,a0,1648 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202b78:	e4afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(s->total > 0 && s->total <= MAX_SLOTS);
ffffffffc0202b7c:	00004697          	auipc	a3,0x4
ffffffffc0202b80:	a9c68693          	addi	a3,a3,-1380 # ffffffffc0206618 <buddy_system_pmm_manager+0x6c8>
ffffffffc0202b84:	00002617          	auipc	a2,0x2
ffffffffc0202b88:	25460613          	addi	a2,a2,596 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202b8c:	0f700593          	li	a1,247
ffffffffc0202b90:	00003517          	auipc	a0,0x3
ffffffffc0202b94:	65050513          	addi	a0,a0,1616 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202b98:	e2afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(s->total == (PGSIZE - HEADER_SIZE) / s->cache->size);
ffffffffc0202b9c:	00004697          	auipc	a3,0x4
ffffffffc0202ba0:	a4468693          	addi	a3,a3,-1468 # ffffffffc02065e0 <buddy_system_pmm_manager+0x690>
ffffffffc0202ba4:	00002617          	auipc	a2,0x2
ffffffffc0202ba8:	23460613          	addi	a2,a2,564 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202bac:	0f600593          	li	a1,246
ffffffffc0202bb0:	00003517          	auipc	a0,0x3
ffffffffc0202bb4:	63050513          	addi	a0,a0,1584 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202bb8:	e0afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(s->page->u >= 0 && s->page->u < sizeof(size_t) * 8);
ffffffffc0202bbc:	00004697          	auipc	a3,0x4
ffffffffc0202bc0:	88468693          	addi	a3,a3,-1916 # ffffffffc0206440 <buddy_system_pmm_manager+0x4f0>
ffffffffc0202bc4:	00002617          	auipc	a2,0x2
ffffffffc0202bc8:	21460613          	addi	a2,a2,532 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202bcc:	0e100593          	li	a1,225
ffffffffc0202bd0:	00003517          	auipc	a0,0x3
ffffffffc0202bd4:	61050513          	addi	a0,a0,1552 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202bd8:	deafd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(s->page->property == s->npages && !PageProperty(s->page));
ffffffffc0202bdc:	00004697          	auipc	a3,0x4
ffffffffc0202be0:	82468693          	addi	a3,a3,-2012 # ffffffffc0206400 <buddy_system_pmm_manager+0x4b0>
ffffffffc0202be4:	00002617          	auipc	a2,0x2
ffffffffc0202be8:	1f460613          	addi	a2,a2,500 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202bec:	0e000593          	li	a1,224
ffffffffc0202bf0:	00003517          	auipc	a0,0x3
ffffffffc0202bf4:	5f050513          	addi	a0,a0,1520 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202bf8:	dcafd0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(++count <= available_count[ci]); /* catches cycles/duplicates */
ffffffffc0202bfc:	00004697          	auipc	a3,0x4
ffffffffc0202c00:	c5c68693          	addi	a3,a3,-932 # ffffffffc0206858 <buddy_system_pmm_manager+0x908>
ffffffffc0202c04:	00002617          	auipc	a2,0x2
ffffffffc0202c08:	1d460613          	addi	a2,a2,468 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202c0c:	11400593          	li	a1,276
ffffffffc0202c10:	00003517          	auipc	a0,0x3
ffffffffc0202c14:	5d050513          	addi	a0,a0,1488 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202c18:	daafd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(list_next(list_prev(head)) == head && list_prev(list_next(head)) == head);
ffffffffc0202c1c:	00004697          	auipc	a3,0x4
ffffffffc0202c20:	bec68693          	addi	a3,a3,-1044 # ffffffffc0206808 <buddy_system_pmm_manager+0x8b8>
ffffffffc0202c24:	00002617          	auipc	a2,0x2
ffffffffc0202c28:	1b460613          	addi	a2,a2,436 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202c2c:	11200593          	li	a1,274
ffffffffc0202c30:	00003517          	auipc	a0,0x3
ffffffffc0202c34:	5b050513          	addi	a0,a0,1456 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202c38:	d8afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(npage > nbase);
ffffffffc0202c3c:	00003697          	auipc	a3,0x3
ffffffffc0202c40:	59468693          	addi	a3,a3,1428 # ffffffffc02061d0 <buddy_system_pmm_manager+0x280>
ffffffffc0202c44:	00002617          	auipc	a2,0x2
ffffffffc0202c48:	19460613          	addi	a2,a2,404 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202c4c:	0ce00593          	li	a1,206
ffffffffc0202c50:	00003517          	auipc	a0,0x3
ffffffffc0202c54:	59050513          	addi	a0,a0,1424 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202c58:	d6afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(list_empty(&s->available) == (s->used == s->total));
ffffffffc0202c5c:	00004697          	auipc	a3,0x4
ffffffffc0202c60:	b7468693          	addi	a3,a3,-1164 # ffffffffc02067d0 <buddy_system_pmm_manager+0x880>
ffffffffc0202c64:	00002617          	auipc	a2,0x2
ffffffffc0202c68:	17460613          	addi	a2,a2,372 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202c6c:	10c00593          	li	a1,268
ffffffffc0202c70:	00003517          	auipc	a0,0x3
ffffffffc0202c74:	57050513          	addi	a0,a0,1392 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202c78:	d4afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(list_next(list_prev(&live)) == &live &&
ffffffffc0202c7c:	00003697          	auipc	a3,0x3
ffffffffc0202c80:	57468693          	addi	a3,a3,1396 # ffffffffc02061f0 <buddy_system_pmm_manager+0x2a0>
ffffffffc0202c84:	00002617          	auipc	a2,0x2
ffffffffc0202c88:	15460613          	addi	a2,a2,340 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202c8c:	0cf00593          	li	a1,207
ffffffffc0202c90:	00003517          	auipc	a0,0x3
ffffffffc0202c94:	55050513          	addi	a0,a0,1360 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202c98:	d2afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(page2ppn(s->page) >= nbase && page2ppn(s->page) < npage);
ffffffffc0202c9c:	00003697          	auipc	a3,0x3
ffffffffc0202ca0:	6cc68693          	addi	a3,a3,1740 # ffffffffc0206368 <buddy_system_pmm_manager+0x418>
ffffffffc0202ca4:	00002617          	auipc	a2,0x2
ffffffffc0202ca8:	13460613          	addi	a2,a2,308 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202cac:	0dd00593          	li	a1,221
ffffffffc0202cb0:	00003517          	auipc	a0,0x3
ffffffffc0202cb4:	53050513          	addi	a0,a0,1328 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202cb8:	d0afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert((uintptr_t)objects(s) % ALIGNMENT == 0);
ffffffffc0202cbc:	00003697          	auipc	a3,0x3
ffffffffc0202cc0:	68468693          	addi	a3,a3,1668 # ffffffffc0206340 <buddy_system_pmm_manager+0x3f0>
ffffffffc0202cc4:	00002617          	auipc	a2,0x2
ffffffffc0202cc8:	11460613          	addi	a2,a2,276 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202ccc:	0dc00593          	li	a1,220
ffffffffc0202cd0:	00003517          	auipc	a0,0x3
ffffffffc0202cd4:	51050513          	addi	a0,a0,1296 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202cd8:	ceafd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(s->npages > 0 && s->npages <= npage - page2ppn(s->page));
ffffffffc0202cdc:	00003697          	auipc	a3,0x3
ffffffffc0202ce0:	6c468693          	addi	a3,a3,1732 # ffffffffc02063a0 <buddy_system_pmm_manager+0x450>
ffffffffc0202ce4:	00002617          	auipc	a2,0x2
ffffffffc0202ce8:	0f460613          	addi	a2,a2,244 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202cec:	0de00593          	li	a1,222
ffffffffc0202cf0:	00003517          	auipc	a0,0x3
ffffffffc0202cf4:	4f050513          	addi	a0,a0,1264 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202cf8:	ccafd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(s->kind == SMALL && s->npages == 1);
ffffffffc0202cfc:	00004697          	auipc	a3,0x4
ffffffffc0202d00:	8bc68693          	addi	a3,a3,-1860 # ffffffffc02065b8 <buddy_system_pmm_manager+0x668>
ffffffffc0202d04:	00002617          	auipc	a2,0x2
ffffffffc0202d08:	0d460613          	addi	a2,a2,212 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202d0c:	0f200593          	li	a1,242
ffffffffc0202d10:	00003517          	auipc	a0,0x3
ffffffffc0202d14:	4d050513          	addi	a0,a0,1232 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202d18:	caafd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(s->magic == SLUB_MAGIC && page_address(s->page) == s);
ffffffffc0202d1c:	00003697          	auipc	a3,0x3
ffffffffc0202d20:	57468693          	addi	a3,a3,1396 # ffffffffc0206290 <buddy_system_pmm_manager+0x340>
ffffffffc0202d24:	00002617          	auipc	a2,0x2
ffffffffc0202d28:	0b460613          	addi	a2,a2,180 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202d2c:	0d700593          	li	a1,215
ffffffffc0202d30:	00003517          	auipc	a0,0x3
ffffffffc0202d34:	4b050513          	addi	a0,a0,1200 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202d38:	c8afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert((uintptr_t)s % PGSIZE == 0 && (uintptr_t)s % ALIGNMENT == 0);
ffffffffc0202d3c:	00003697          	auipc	a3,0x3
ffffffffc0202d40:	58c68693          	addi	a3,a3,1420 # ffffffffc02062c8 <buddy_system_pmm_manager+0x378>
ffffffffc0202d44:	00002617          	auipc	a2,0x2
ffffffffc0202d48:	09460613          	addi	a2,a2,148 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202d4c:	0d900593          	li	a1,217
ffffffffc0202d50:	00003517          	auipc	a0,0x3
ffffffffc0202d54:	49050513          	addi	a0,a0,1168 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202d58:	c6afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(list_prev(list_next(le)) == le && list_next(list_prev(le)) == le);
ffffffffc0202d5c:	00002697          	auipc	a3,0x2
ffffffffc0202d60:	59c68693          	addi	a3,a3,1436 # ffffffffc02052f8 <etext+0x7b2>
ffffffffc0202d64:	00002617          	auipc	a2,0x2
ffffffffc0202d68:	07460613          	addi	a2,a2,116 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202d6c:	0d800593          	li	a1,216
ffffffffc0202d70:	00003517          	auipc	a0,0x3
ffffffffc0202d74:	47050513          	addi	a0,a0,1136 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202d78:	c4afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert((s->npages & (s->npages - 1)) == 0);
ffffffffc0202d7c:	00003697          	auipc	a3,0x3
ffffffffc0202d80:	65c68693          	addi	a3,a3,1628 # ffffffffc02063d8 <buddy_system_pmm_manager+0x488>
ffffffffc0202d84:	00002617          	auipc	a2,0x2
ffffffffc0202d88:	05460613          	addi	a2,a2,84 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202d8c:	0df00593          	li	a1,223
ffffffffc0202d90:	00003517          	auipc	a0,0x3
ffffffffc0202d94:	45050513          	addi	a0,a0,1104 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202d98:	c2afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(++live_count <= npage - nbase); /* bounds cycles in live */
ffffffffc0202d9c:	00003697          	auipc	a3,0x3
ffffffffc0202da0:	4d468693          	addi	a3,a3,1236 # ffffffffc0206270 <buddy_system_pmm_manager+0x320>
ffffffffc0202da4:	00002617          	auipc	a2,0x2
ffffffffc0202da8:	03460613          	addi	a2,a2,52 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202dac:	0d500593          	li	a1,213
ffffffffc0202db0:	00003517          	auipc	a0,0x3
ffffffffc0202db4:	43050513          	addi	a0,a0,1072 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202db8:	c0afd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(caches[ci].size == ((size_t)ALIGNMENT << ci));
ffffffffc0202dbc:	00003697          	auipc	a3,0x3
ffffffffc0202dc0:	48468693          	addi	a3,a3,1156 # ffffffffc0206240 <buddy_system_pmm_manager+0x2f0>
ffffffffc0202dc4:	00002617          	auipc	a2,0x2
ffffffffc0202dc8:	01460613          	addi	a2,a2,20 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202dcc:	0d200593          	li	a1,210
ffffffffc0202dd0:	00003517          	auipc	a0,0x3
ffffffffc0202dd4:	41050513          	addi	a0,a0,1040 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202dd8:	beafd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(((size_t)1 << s->page->u) == s->npages);
ffffffffc0202ddc:	00003697          	auipc	a3,0x3
ffffffffc0202de0:	69c68693          	addi	a3,a3,1692 # ffffffffc0206478 <buddy_system_pmm_manager+0x528>
ffffffffc0202de4:	00002617          	auipc	a2,0x2
ffffffffc0202de8:	ff460613          	addi	a2,a2,-12 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202dec:	0e200593          	li	a1,226
ffffffffc0202df0:	00003517          	auipc	a0,0x3
ffffffffc0202df4:	3f050513          	addi	a0,a0,1008 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202df8:	bcafd0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0202dfc <kmalloc.part.0>:
void *kmalloc(size_t size) {
ffffffffc0202dfc:	1141                	addi	sp,sp,-16
ffffffffc0202dfe:	00008817          	auipc	a6,0x8
ffffffffc0202e02:	23280813          	addi	a6,a6,562 # ffffffffc020b030 <caches>
ffffffffc0202e06:	e406                	sd	ra,8(sp)
ffffffffc0202e08:	8742                	mv	a4,a6
    size_t i = 0;
ffffffffc0202e0a:	4781                	li	a5,0
    while (i < CACHE_COUNT && caches[i].size < size) {
ffffffffc0202e0c:	4621                	li	a2,8
ffffffffc0202e0e:	6314                	ld	a3,0(a4)
ffffffffc0202e10:	06a6f163          	bgeu	a3,a0,ffffffffc0202e72 <kmalloc.part.0+0x76>
        ++i;
ffffffffc0202e14:	0785                	addi	a5,a5,1
    while (i < CACHE_COUNT && caches[i].size < size) {
ffffffffc0202e16:	0761                	addi	a4,a4,24
ffffffffc0202e18:	fec79be3          	bne	a5,a2,ffffffffc0202e0e <kmalloc.part.0+0x12>
    if (size > SIZE_MAX_VALUE - HEADER_SIZE) {
ffffffffc0202e1c:	f7f00793          	li	a5,-129
ffffffffc0202e20:	0ea7e363          	bltu	a5,a0,ffffffffc0202f06 <kmalloc.part.0+0x10a>
    size_t bytes = size + HEADER_SIZE;
ffffffffc0202e24:	08050513          	addi	a0,a0,128
    size_t needed = bytes / PGSIZE + (bytes % PGSIZE != 0);
ffffffffc0202e28:	03451793          	slli	a5,a0,0x34
ffffffffc0202e2c:	00f037b3          	snez	a5,a5
ffffffffc0202e30:	8131                	srli	a0,a0,0xc
ffffffffc0202e32:	97aa                	add	a5,a5,a0
    while (count < needed) {
ffffffffc0202e34:	4705                	li	a4,1
ffffffffc0202e36:	0ef77c63          	bgeu	a4,a5,ffffffffc0202f2e <kmalloc.part.0+0x132>
    size_t count = 1;
ffffffffc0202e3a:	4505                	li	a0,1
        count *= 2;
ffffffffc0202e3c:	0506                	slli	a0,a0,0x1
    while (count < needed) {
ffffffffc0202e3e:	fef56fe3          	bltu	a0,a5,ffffffffc0202e3c <kmalloc.part.0+0x40>
    if (count > SIZE_MAX_VALUE / PGSIZE || npage <= nbase ||
ffffffffc0202e42:	57fd                	li	a5,-1
ffffffffc0202e44:	83b1                	srli	a5,a5,0xc
ffffffffc0202e46:	0ca7e063          	bltu	a5,a0,ffffffffc0202f06 <kmalloc.part.0+0x10a>
ffffffffc0202e4a:	000a9797          	auipc	a5,0xa9
ffffffffc0202e4e:	ad67b783          	ld	a5,-1322(a5) # ffffffffc02ab920 <npage>
ffffffffc0202e52:	00005717          	auipc	a4,0x5
ffffffffc0202e56:	a6e73703          	ld	a4,-1426(a4) # ffffffffc02078c0 <nbase>
ffffffffc0202e5a:	0af77663          	bgeu	a4,a5,ffffffffc0202f06 <kmalloc.part.0+0x10a>
        count > npage - nbase) {
ffffffffc0202e5e:	8f99                	sub	a5,a5,a4
    if (count > SIZE_MAX_VALUE / PGSIZE || npage <= nbase ||
ffffffffc0202e60:	0aa7e363          	bltu	a5,a0,ffffffffc0202f06 <kmalloc.part.0+0x10a>
        struct slab *s = new_slab(npages, NULL);
ffffffffc0202e64:	4581                	li	a1,0
ffffffffc0202e66:	cdaff0ef          	jal	ra,ffffffffc0202340 <new_slab>
        return s == NULL ? NULL : objects(s);
ffffffffc0202e6a:	cd51                	beqz	a0,ffffffffc0202f06 <kmalloc.part.0+0x10a>
    return (char *)s + HEADER_SIZE;
ffffffffc0202e6c:	08050513          	addi	a0,a0,128
ffffffffc0202e70:	a059                	j	ffffffffc0202ef6 <kmalloc.part.0+0xfa>
    struct cache *cache = &caches[i];
ffffffffc0202e72:	00179713          	slli	a4,a5,0x1
ffffffffc0202e76:	97ba                	add	a5,a5,a4
ffffffffc0202e78:	00379713          	slli	a4,a5,0x3
    return list->next == list;
ffffffffc0202e7c:	00e805b3          	add	a1,a6,a4
ffffffffc0202e80:	699c                	ld	a5,16(a1)
    struct slab *s = list_empty(&cache->available) ? new_slab(1, cache) :
ffffffffc0202e82:	0721                	addi	a4,a4,8
ffffffffc0202e84:	9742                	add	a4,a4,a6
ffffffffc0202e86:	06e78b63          	beq	a5,a4,ffffffffc0202efc <kmalloc.part.0+0x100>
ffffffffc0202e8a:	fc078793          	addi	a5,a5,-64
    struct slot *slot = s->freelist;
ffffffffc0202e8e:	7f88                	ld	a0,56(a5)
    assert(slot != NULL && slot_index(s, slot, &index) && !bit_set(s, index));
ffffffffc0202e90:	cd3d                	beqz	a0,ffffffffc0202f0e <kmalloc.part.0+0x112>
    return (char *)s + HEADER_SIZE;
ffffffffc0202e92:	08078713          	addi	a4,a5,128
    if (addr < start || (addr - start) % s->cache->size != 0) {
ffffffffc0202e96:	06e56c63          	bltu	a0,a4,ffffffffc0202f0e <kmalloc.part.0+0x112>
ffffffffc0202e9a:	6b94                	ld	a3,16(a5)
ffffffffc0202e9c:	40e50733          	sub	a4,a0,a4
ffffffffc0202ea0:	6294                	ld	a3,0(a3)
ffffffffc0202ea2:	02d77633          	remu	a2,a4,a3
ffffffffc0202ea6:	e625                	bnez	a2,ffffffffc0202f0e <kmalloc.part.0+0x112>
    *index = (addr - start) / s->cache->size;
ffffffffc0202ea8:	02d75733          	divu	a4,a4,a3
    return *index < s->total;
ffffffffc0202eac:	0287b883          	ld	a7,40(a5)
    assert(slot != NULL && slot_index(s, slot, &index) && !bit_set(s, index));
ffffffffc0202eb0:	05177f63          	bgeu	a4,a7,ffffffffc0202f0e <kmalloc.part.0+0x112>
    return (s->allocated[i / 8] >> (i % 8)) & 1;
ffffffffc0202eb4:	00375693          	srli	a3,a4,0x3
ffffffffc0202eb8:	96be                	add	a3,a3,a5
ffffffffc0202eba:	0606c603          	lbu	a2,96(a3)
ffffffffc0202ebe:	8b1d                	andi	a4,a4,7
ffffffffc0202ec0:	40e655bb          	sraw	a1,a2,a4
    assert(slot != NULL && slot_index(s, slot, &index) && !bit_set(s, index));
ffffffffc0202ec4:	8985                	andi	a1,a1,1
ffffffffc0202ec6:	e5a1                	bnez	a1,ffffffffc0202f0e <kmalloc.part.0+0x112>
    s->freelist = slot->next;
ffffffffc0202ec8:	00053803          	ld	a6,0(a0)
    s->allocated[index / 8] |= 1U << (index % 8);
ffffffffc0202ecc:	4585                	li	a1,1
ffffffffc0202ece:	00e5973b          	sllw	a4,a1,a4
ffffffffc0202ed2:	8e59                	or	a2,a2,a4
    s->freelist = slot->next;
ffffffffc0202ed4:	0307bc23          	sd	a6,56(a5)
    s->allocated[index / 8] |= 1U << (index % 8);
ffffffffc0202ed8:	06c68023          	sb	a2,96(a3)
    if (++s->used == s->total) {
ffffffffc0202edc:	7b98                	ld	a4,48(a5)
ffffffffc0202ede:	0705                	addi	a4,a4,1
ffffffffc0202ee0:	fb98                	sd	a4,48(a5)
ffffffffc0202ee2:	01171a63          	bne	a4,a7,ffffffffc0202ef6 <kmalloc.part.0+0xfa>
    __list_del(listelm->prev, listelm->next);
ffffffffc0202ee6:	63b0                	ld	a2,64(a5)
ffffffffc0202ee8:	67b4                	ld	a3,72(a5)
        list_del_init(&s->available);
ffffffffc0202eea:	04078713          	addi	a4,a5,64
    prev->next = next;
ffffffffc0202eee:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0202ef0:	e290                	sd	a2,0(a3)
    elm->prev = elm->next = elm;
ffffffffc0202ef2:	e7b8                	sd	a4,72(a5)
ffffffffc0202ef4:	e3b8                	sd	a4,64(a5)
}
ffffffffc0202ef6:	60a2                	ld	ra,8(sp)
ffffffffc0202ef8:	0141                	addi	sp,sp,16
ffffffffc0202efa:	8082                	ret
    struct slab *s = list_empty(&cache->available) ? new_slab(1, cache) :
ffffffffc0202efc:	4505                	li	a0,1
ffffffffc0202efe:	c42ff0ef          	jal	ra,ffffffffc0202340 <new_slab>
ffffffffc0202f02:	87aa                	mv	a5,a0
    if (s == NULL) {
ffffffffc0202f04:	f549                	bnez	a0,ffffffffc0202e8e <kmalloc.part.0+0x92>
            return NULL;
ffffffffc0202f06:	4501                	li	a0,0
}
ffffffffc0202f08:	60a2                	ld	ra,8(sp)
ffffffffc0202f0a:	0141                	addi	sp,sp,16
ffffffffc0202f0c:	8082                	ret
    assert(slot != NULL && slot_index(s, slot, &index) && !bit_set(s, index));
ffffffffc0202f0e:	00004697          	auipc	a3,0x4
ffffffffc0202f12:	a0a68693          	addi	a3,a3,-1526 # ffffffffc0206918 <buddy_system_pmm_manager+0x9c8>
ffffffffc0202f16:	00002617          	auipc	a2,0x2
ffffffffc0202f1a:	ec260613          	addi	a2,a2,-318 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0202f1e:	09d00593          	li	a1,157
ffffffffc0202f22:	00003517          	auipc	a0,0x3
ffffffffc0202f26:	2be50513          	addi	a0,a0,702 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0202f2a:	a98fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
    if (count > SIZE_MAX_VALUE / PGSIZE || npage <= nbase ||
ffffffffc0202f2e:	000a9717          	auipc	a4,0xa9
ffffffffc0202f32:	9f273703          	ld	a4,-1550(a4) # ffffffffc02ab920 <npage>
ffffffffc0202f36:	00005797          	auipc	a5,0x5
ffffffffc0202f3a:	98a7b783          	ld	a5,-1654(a5) # ffffffffc02078c0 <nbase>
    size_t count = 1;
ffffffffc0202f3e:	4505                	li	a0,1
    if (count > SIZE_MAX_VALUE / PGSIZE || npage <= nbase ||
ffffffffc0202f40:	f2e7e2e3          	bltu	a5,a4,ffffffffc0202e64 <kmalloc.part.0+0x68>
            return NULL;
ffffffffc0202f44:	4501                	li	a0,0
ffffffffc0202f46:	b7c9                	j	ffffffffc0202f08 <kmalloc.part.0+0x10c>

ffffffffc0202f48 <combined_init>:
static void combined_init(void) {
ffffffffc0202f48:	1141                	addi	sp,sp,-16
    buddy_system_pmm_manager.init();
ffffffffc0202f4a:	00003797          	auipc	a5,0x3
ffffffffc0202f4e:	00e7b783          	ld	a5,14(a5) # ffffffffc0205f58 <buddy_system_pmm_manager+0x8>
static void combined_init(void) {
ffffffffc0202f52:	e406                	sd	ra,8(sp)
    buddy_system_pmm_manager.init();
ffffffffc0202f54:	9782                	jalr	a5
ffffffffc0202f56:	000a8797          	auipc	a5,0xa8
ffffffffc0202f5a:	19a78793          	addi	a5,a5,410 # ffffffffc02ab0f0 <live>
ffffffffc0202f5e:	e79c                	sd	a5,8(a5)
ffffffffc0202f60:	e39c                	sd	a5,0(a5)
    for (size_t i = 0; i < CACHE_COUNT; ++i) {
ffffffffc0202f62:	4701                	li	a4,0
ffffffffc0202f64:	00008797          	auipc	a5,0x8
ffffffffc0202f68:	0d478793          	addi	a5,a5,212 # ffffffffc020b038 <caches+0x8>
        caches[i].size = (size_t)ALIGNMENT << i;
ffffffffc0202f6c:	45c1                	li	a1,16
    for (size_t i = 0; i < CACHE_COUNT; ++i) {
ffffffffc0202f6e:	4621                	li	a2,8
        caches[i].size = (size_t)ALIGNMENT << i;
ffffffffc0202f70:	00e596b3          	sll	a3,a1,a4
ffffffffc0202f74:	fed7bc23          	sd	a3,-8(a5)
ffffffffc0202f78:	e79c                	sd	a5,8(a5)
ffffffffc0202f7a:	e39c                	sd	a5,0(a5)
    for (size_t i = 0; i < CACHE_COUNT; ++i) {
ffffffffc0202f7c:	0705                	addi	a4,a4,1
ffffffffc0202f7e:	07e1                	addi	a5,a5,24
ffffffffc0202f80:	fec718e3          	bne	a4,a2,ffffffffc0202f70 <combined_init+0x28>
}
ffffffffc0202f84:	60a2                	ld	ra,8(sp)
ffffffffc0202f86:	0141                	addi	sp,sp,16
ffffffffc0202f88:	8082                	ret

ffffffffc0202f8a <kfree>:
    if (ptr == NULL) {
ffffffffc0202f8a:	10050163          	beqz	a0,ffffffffc020308c <kfree+0x102>
    return listelm->next;
ffffffffc0202f8e:	000a8617          	auipc	a2,0xa8
ffffffffc0202f92:	16260613          	addi	a2,a2,354 # ffffffffc02ab0f0 <live>
ffffffffc0202f96:	661c                	ld	a5,8(a2)
void kfree(void *ptr) {
ffffffffc0202f98:	1141                	addi	sp,sp,-16
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc0202f9a:	76fd                	lui	a3,0xfffff
void kfree(void *ptr) {
ffffffffc0202f9c:	e406                	sd	ra,8(sp)
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc0202f9e:	8ee9                	and	a3,a3,a0
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0202fa0:	00c79663          	bne	a5,a2,ffffffffc0202fac <kfree+0x22>
ffffffffc0202fa4:	a229                	j	ffffffffc02030ae <kfree+0x124>
ffffffffc0202fa6:	679c                	ld	a5,8(a5)
ffffffffc0202fa8:	10c78363          	beq	a5,a2,ffffffffc02030ae <kfree+0x124>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0202fac:	fb078713          	addi	a4,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc0202fb0:	fed71be3          	bne	a4,a3,ffffffffc0202fa6 <kfree+0x1c>
    assert(s != NULL && s->magic == SLUB_MAGIC);
ffffffffc0202fb4:	6314                	ld	a3,0(a4)
ffffffffc0202fb6:	00005797          	auipc	a5,0x5
ffffffffc0202fba:	9027b783          	ld	a5,-1790(a5) # ffffffffc02078b8 <error_string+0x40>
ffffffffc0202fbe:	0ef69863          	bne	a3,a5,ffffffffc02030ae <kfree+0x124>
    if (s->kind == LARGE) {
ffffffffc0202fc2:	471c                	lw	a5,8(a4)
ffffffffc0202fc4:	4689                	li	a3,2
ffffffffc0202fc6:	06d78863          	beq	a5,a3,ffffffffc0203036 <kfree+0xac>
    assert(s->kind == SMALL && slot_index(s, ptr, &index));
ffffffffc0202fca:	4685                	li	a3,1
ffffffffc0202fcc:	0cd79163          	bne	a5,a3,ffffffffc020308e <kfree+0x104>
    return (char *)s + HEADER_SIZE;
ffffffffc0202fd0:	08070793          	addi	a5,a4,128
    if (addr < start || (addr - start) % s->cache->size != 0) {
ffffffffc0202fd4:	0af56d63          	bltu	a0,a5,ffffffffc020308e <kfree+0x104>
ffffffffc0202fd8:	01073883          	ld	a7,16(a4)
ffffffffc0202fdc:	40f507b3          	sub	a5,a0,a5
ffffffffc0202fe0:	0008b683          	ld	a3,0(a7)
ffffffffc0202fe4:	02d7f633          	remu	a2,a5,a3
ffffffffc0202fe8:	e25d                	bnez	a2,ffffffffc020308e <kfree+0x104>
    *index = (addr - start) / s->cache->size;
ffffffffc0202fea:	02d7d7b3          	divu	a5,a5,a3
    return *index < s->total;
ffffffffc0202fee:	02873303          	ld	t1,40(a4)
    assert(s->kind == SMALL && slot_index(s, ptr, &index));
ffffffffc0202ff2:	0867fe63          	bgeu	a5,t1,ffffffffc020308e <kfree+0x104>
    return (s->allocated[i / 8] >> (i % 8)) & 1;
ffffffffc0202ff6:	0037d593          	srli	a1,a5,0x3
ffffffffc0202ffa:	95ba                	add	a1,a1,a4
ffffffffc0202ffc:	0605c803          	lbu	a6,96(a1)
ffffffffc0203000:	8b9d                	andi	a5,a5,7
ffffffffc0203002:	40f856bb          	sraw	a3,a6,a5
    assert(bit_set(s, index) && s->used > 0);
ffffffffc0203006:	8a85                	andi	a3,a3,1
ffffffffc0203008:	c2f9                	beqz	a3,ffffffffc02030ce <kfree+0x144>
ffffffffc020300a:	7b14                	ld	a3,48(a4)
ffffffffc020300c:	c2e9                	beqz	a3,ffffffffc02030ce <kfree+0x144>
    s->allocated[index / 8] &= ~(1U << (index % 8));
ffffffffc020300e:	4605                	li	a2,1
ffffffffc0203010:	00f617bb          	sllw	a5,a2,a5
ffffffffc0203014:	fff7c793          	not	a5,a5
ffffffffc0203018:	00f877b3          	and	a5,a6,a5
ffffffffc020301c:	06f58023          	sb	a5,96(a1)
    if (s->used == s->total) {
ffffffffc0203020:	04668763          	beq	a3,t1,ffffffffc020306e <kfree+0xe4>
    slot->next = s->freelist;
ffffffffc0203024:	7f1c                	ld	a5,56(a4)
    if (--s->used == 0) {
ffffffffc0203026:	16fd                	addi	a3,a3,-1
    slot->next = s->freelist;
ffffffffc0203028:	e11c                	sd	a5,0(a0)
    s->freelist = slot;
ffffffffc020302a:	ff08                	sd	a0,56(a4)
    if (--s->used == 0) {
ffffffffc020302c:	fb14                	sd	a3,48(a4)
ffffffffc020302e:	ca81                	beqz	a3,ffffffffc020303e <kfree+0xb4>
}
ffffffffc0203030:	60a2                	ld	ra,8(sp)
ffffffffc0203032:	0141                	addi	sp,sp,16
ffffffffc0203034:	8082                	ret
    return (char *)s + HEADER_SIZE;
ffffffffc0203036:	08070793          	addi	a5,a4,128
        assert(ptr == objects(s));
ffffffffc020303a:	0af51a63          	bne	a0,a5,ffffffffc02030ee <kfree+0x164>
    __list_del(listelm->prev, listelm->next);
ffffffffc020303e:	6334                	ld	a3,64(a4)
ffffffffc0203040:	673c                	ld	a5,72(a4)
    struct Page *page = s->page;
ffffffffc0203042:	6f08                	ld	a0,24(a4)
    size_t npages = s->npages;
ffffffffc0203044:	730c                	ld	a1,32(a4)
    prev->next = next;
ffffffffc0203046:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0203048:	e394                	sd	a3,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020304a:	6f3c                	ld	a5,88(a4)
ffffffffc020304c:	6b34                	ld	a3,80(a4)
    list_del_init(&s->available);
ffffffffc020304e:	04070613          	addi	a2,a4,64
    elm->prev = elm->next = elm;
ffffffffc0203052:	e730                	sd	a2,72(a4)
ffffffffc0203054:	e330                	sd	a2,64(a4)
    prev->next = next;
ffffffffc0203056:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0203058:	e394                	sd	a3,0(a5)
}
ffffffffc020305a:	60a2                	ld	ra,8(sp)
    list_del_init(&s->live);
ffffffffc020305c:	05070793          	addi	a5,a4,80
    elm->prev = elm->next = elm;
ffffffffc0203060:	ef3c                	sd	a5,88(a4)
ffffffffc0203062:	eb3c                	sd	a5,80(a4)
    s->magic = 0;
ffffffffc0203064:	00073023          	sd	zero,0(a4)
}
ffffffffc0203068:	0141                	addi	sp,sp,16
    free_pages(page, npages);
ffffffffc020306a:	842ff06f          	j	ffffffffc02020ac <free_pages>
        assert(list_empty(&s->available));
ffffffffc020306e:	6730                	ld	a2,72(a4)
ffffffffc0203070:	04070793          	addi	a5,a4,64
ffffffffc0203074:	08c79d63          	bne	a5,a2,ffffffffc020310e <kfree+0x184>
    __list_add(elm, listelm, listelm->next);
ffffffffc0203078:	0108b603          	ld	a2,16(a7)
        list_add(&s->cache->available, &s->available);
ffffffffc020307c:	00888593          	addi	a1,a7,8
    prev->next = next->prev = elm;
ffffffffc0203080:	e21c                	sd	a5,0(a2)
ffffffffc0203082:	00f8b823          	sd	a5,16(a7)
    elm->next = next;
ffffffffc0203086:	e730                	sd	a2,72(a4)
    elm->prev = prev;
ffffffffc0203088:	e32c                	sd	a1,64(a4)
}
ffffffffc020308a:	bf69                	j	ffffffffc0203024 <kfree+0x9a>
ffffffffc020308c:	8082                	ret
    assert(s->kind == SMALL && slot_index(s, ptr, &index));
ffffffffc020308e:	00004697          	auipc	a3,0x4
ffffffffc0203092:	91268693          	addi	a3,a3,-1774 # ffffffffc02069a0 <buddy_system_pmm_manager+0xa50>
ffffffffc0203096:	00002617          	auipc	a2,0x2
ffffffffc020309a:	d4260613          	addi	a2,a2,-702 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020309e:	0bc00593          	li	a1,188
ffffffffc02030a2:	00003517          	auipc	a0,0x3
ffffffffc02030a6:	13e50513          	addi	a0,a0,318 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02030aa:	918fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(s != NULL && s->magic == SLUB_MAGIC);
ffffffffc02030ae:	00004697          	auipc	a3,0x4
ffffffffc02030b2:	8b268693          	addi	a3,a3,-1870 # ffffffffc0206960 <buddy_system_pmm_manager+0xa10>
ffffffffc02030b6:	00002617          	auipc	a2,0x2
ffffffffc02030ba:	d2260613          	addi	a2,a2,-734 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02030be:	0b500593          	li	a1,181
ffffffffc02030c2:	00003517          	auipc	a0,0x3
ffffffffc02030c6:	11e50513          	addi	a0,a0,286 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02030ca:	8f8fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(bit_set(s, index) && s->used > 0);
ffffffffc02030ce:	00004697          	auipc	a3,0x4
ffffffffc02030d2:	90268693          	addi	a3,a3,-1790 # ffffffffc02069d0 <buddy_system_pmm_manager+0xa80>
ffffffffc02030d6:	00002617          	auipc	a2,0x2
ffffffffc02030da:	d0260613          	addi	a2,a2,-766 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02030de:	0bd00593          	li	a1,189
ffffffffc02030e2:	00003517          	auipc	a0,0x3
ffffffffc02030e6:	0fe50513          	addi	a0,a0,254 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02030ea:	8d8fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(ptr == objects(s));
ffffffffc02030ee:	00004697          	auipc	a3,0x4
ffffffffc02030f2:	89a68693          	addi	a3,a3,-1894 # ffffffffc0206988 <buddy_system_pmm_manager+0xa38>
ffffffffc02030f6:	00002617          	auipc	a2,0x2
ffffffffc02030fa:	ce260613          	addi	a2,a2,-798 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02030fe:	0b700593          	li	a1,183
ffffffffc0203102:	00003517          	auipc	a0,0x3
ffffffffc0203106:	0de50513          	addi	a0,a0,222 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc020310a:	8b8fd0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(list_empty(&s->available));
ffffffffc020310e:	00004697          	auipc	a3,0x4
ffffffffc0203112:	8ea68693          	addi	a3,a3,-1814 # ffffffffc02069f8 <buddy_system_pmm_manager+0xaa8>
ffffffffc0203116:	00002617          	auipc	a2,0x2
ffffffffc020311a:	cc260613          	addi	a2,a2,-830 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020311e:	0c000593          	li	a1,192
ffffffffc0203122:	00003517          	auipc	a0,0x3
ffffffffc0203126:	0be50513          	addi	a0,a0,190 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc020312a:	898fd0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020312e <slub_check>:
    assert(npage > nbase && npage - nbase <= PAGE_LIMIT && list_empty(&live));
ffffffffc020312e:	000a8797          	auipc	a5,0xa8
ffffffffc0203132:	7f278793          	addi	a5,a5,2034 # ffffffffc02ab920 <npage>
void slub_check(void) {
ffffffffc0203136:	a8010113          	addi	sp,sp,-1408
ffffffffc020313a:	72fd                	lui	t0,0xfffff
    assert(npage > nbase && npage - nbase <= PAGE_LIMIT && list_empty(&live));
ffffffffc020313c:	639c                	ld	a5,0(a5)
void slub_check(void) {
ffffffffc020313e:	56113c23          	sd	ra,1400(sp)
ffffffffc0203142:	56813823          	sd	s0,1392(sp)
ffffffffc0203146:	56913423          	sd	s1,1384(sp)
ffffffffc020314a:	57213023          	sd	s2,1376(sp)
ffffffffc020314e:	55313c23          	sd	s3,1368(sp)
ffffffffc0203152:	55413823          	sd	s4,1360(sp)
ffffffffc0203156:	55513423          	sd	s5,1352(sp)
ffffffffc020315a:	55613023          	sd	s6,1344(sp)
ffffffffc020315e:	53713c23          	sd	s7,1336(sp)
ffffffffc0203162:	53813823          	sd	s8,1328(sp)
ffffffffc0203166:	53913423          	sd	s9,1320(sp)
ffffffffc020316a:	53a13023          	sd	s10,1312(sp)
ffffffffc020316e:	51b13c23          	sd	s11,1304(sp)
    assert(npage > nbase && npage - nbase <= PAGE_LIMIT && list_empty(&live));
ffffffffc0203172:	00004717          	auipc	a4,0x4
ffffffffc0203176:	74e73703          	ld	a4,1870(a4) # ffffffffc02078c0 <nbase>
void slub_check(void) {
ffffffffc020317a:	9116                	add	sp,sp,t0
    assert(npage > nbase && npage - nbase <= PAGE_LIMIT && list_empty(&live));
ffffffffc020317c:	f83a                	sd	a4,48(sp)
ffffffffc020317e:	5cf77be3          	bgeu	a4,a5,ffffffffc0203f54 <slub_check+0xe26>
ffffffffc0203182:	8f99                	sub	a5,a5,a4
ffffffffc0203184:	6721                	lui	a4,0x8
ffffffffc0203186:	5cf767e3          	bltu	a4,a5,ffffffffc0203f54 <slub_check+0xe26>
    return list->next == list;
ffffffffc020318a:	000a8b17          	auipc	s6,0xa8
ffffffffc020318e:	f66b0b13          	addi	s6,s6,-154 # ffffffffc02ab0f0 <live>
ffffffffc0203192:	008b3703          	ld	a4,8(s6)
ffffffffc0203196:	5b671fe3          	bne	a4,s6,ffffffffc0203f54 <slub_check+0xe26>
    size_t before = nr_free_pages(), sum = 0;
ffffffffc020319a:	f1ffe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
    for (size_t i = 0; i < npage - nbase; ++i) {
ffffffffc020319e:	000a8797          	auipc	a5,0xa8
ffffffffc02031a2:	78278793          	addi	a5,a5,1922 # ffffffffc02ab920 <npage>
ffffffffc02031a6:	6398                	ld	a4,0(a5)
ffffffffc02031a8:	77c2                	ld	a5,48(sp)
    size_t before = nr_free_pages(), sum = 0;
ffffffffc02031aa:	f02a                	sd	a0,32(sp)
    for (size_t i = 0; i < npage - nbase; ++i) {
ffffffffc02031ac:	40f70533          	sub	a0,a4,a5
ffffffffc02031b0:	02f70f63          	beq	a4,a5,ffffffffc02031ee <slub_check+0xc0>
ffffffffc02031b4:	050a                	slli	a0,a0,0x2
ffffffffc02031b6:	00008717          	auipc	a4,0x8
ffffffffc02031ba:	f3a70713          	addi	a4,a4,-198 # ffffffffc020b0f0 <free_blocks.2>
ffffffffc02031be:	000a8617          	auipc	a2,0xa8
ffffffffc02031c2:	76a63603          	ld	a2,1898(a2) # ffffffffc02ab928 <pages>
ffffffffc02031c6:	00e50833          	add	a6,a0,a4
ffffffffc02031ca:	0641                	addi	a2,a2,16
    size_t before = nr_free_pages(), sum = 0;
ffffffffc02031cc:	4501                	li	a0,0
        free_blocks[i] = PageProperty(&pages[i]) ? pages[i].property : 0;
ffffffffc02031ce:	ff863783          	ld	a5,-8(a2)
ffffffffc02031d2:	4681                	li	a3,0
ffffffffc02031d4:	8b89                	andi	a5,a5,2
ffffffffc02031d6:	c791                	beqz	a5,ffffffffc02031e2 <slub_check+0xb4>
ffffffffc02031d8:	4214                	lw	a3,0(a2)
        sum += free_blocks[i];
ffffffffc02031da:	02069793          	slli	a5,a3,0x20
ffffffffc02031de:	9381                	srli	a5,a5,0x20
ffffffffc02031e0:	953e                	add	a0,a0,a5
        free_blocks[i] = PageProperty(&pages[i]) ? pages[i].property : 0;
ffffffffc02031e2:	c314                	sw	a3,0(a4)
    for (size_t i = 0; i < npage - nbase; ++i) {
ffffffffc02031e4:	0711                	addi	a4,a4,4
ffffffffc02031e6:	02860613          	addi	a2,a2,40
ffffffffc02031ea:	ff0712e3          	bne	a4,a6,ffffffffc02031ce <slub_check+0xa0>
    assert(sum == before);
ffffffffc02031ee:	7782                	ld	a5,32(sp)
ffffffffc02031f0:	54f512e3          	bne	a0,a5,ffffffffc0203f34 <slub_check+0xe06>
    slub_check_invariants();
ffffffffc02031f4:	a7aff0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
    for (size_t round = 0; round < 3; ++round) {
ffffffffc02031f8:	6685                	lui	a3,0x1
ffffffffc02031fa:	4a068793          	addi	a5,a3,1184 # 14a0 <kern_entry-0xffffffffc01feb60>
ffffffffc02031fe:	1890                	addi	a2,sp,112
        const size_t sizes[] = {1, 15, 16, 17, 31, 32, 33, 63, 64, 65,
ffffffffc0203200:	7cfd                	lui	s9,0xfffff
ffffffffc0203202:	97b2                	add	a5,a5,a2
    slub_check_invariants();
ffffffffc0203204:	4605                	li	a2,1
ffffffffc0203206:	d68c8713          	addi	a4,s9,-664 # ffffffffffffed68 <end+0x3fd53418>
ffffffffc020320a:	f432                	sd	a2,40(sp)
            assert(memcmp(&saved_live, &live, sizeof(live)) == 0);
ffffffffc020320c:	4a068693          	addi	a3,a3,1184
ffffffffc0203210:	1890                	addi	a2,sp,112
ffffffffc0203212:	97ba                	add	a5,a5,a4
ffffffffc0203214:	96b2                	add	a3,a3,a2
ffffffffc0203216:	b68c8713          	addi	a4,s9,-1176
ffffffffc020321a:	e83e                	sd	a5,16(sp)
ffffffffc020321c:	9736                	add	a4,a4,a3
ffffffffc020321e:	10878793          	addi	a5,a5,264
    slub_check_invariants();
ffffffffc0203222:	fc02                	sd	zero,56(sp)
            assert(memcmp(&saved_live, &live, sizeof(live)) == 0);
ffffffffc0203224:	e0ba                	sd	a4,64(sp)
ffffffffc0203226:	f4be                	sd	a5,104(sp)
        const size_t sizes[] = {1, 15, 16, 17, 31, 32, 33, 63, 64, 65,
ffffffffc0203228:	00004717          	auipc	a4,0x4
ffffffffc020322c:	30070713          	addi	a4,a4,768 # ffffffffc0207528 <buddy_system_pmm_manager+0x15d8>
ffffffffc0203230:	1a9c                	addi	a5,sp,368
ffffffffc0203232:	6f14                	ld	a3,24(a4)
ffffffffc0203234:	6308                	ld	a0,0(a4)
ffffffffc0203236:	670c                	ld	a1,8(a4)
ffffffffc0203238:	6b10                	ld	a2,16(a4)
ffffffffc020323a:	ef94                	sd	a3,24(a5)
ffffffffc020323c:	e388                	sd	a0,0(a5)
ffffffffc020323e:	e78c                	sd	a1,8(a5)
ffffffffc0203240:	eb90                	sd	a2,16(a5)
ffffffffc0203242:	02070713          	addi	a4,a4,32
ffffffffc0203246:	00004697          	auipc	a3,0x4
ffffffffc020324a:	3e268693          	addi	a3,a3,994 # ffffffffc0207628 <buddy_system_pmm_manager+0x16d8>
ffffffffc020324e:	02078793          	addi	a5,a5,32
ffffffffc0203252:	fed710e3          	bne	a4,a3,ffffffffc0203232 <slub_check+0x104>
ffffffffc0203256:	6298                	ld	a4,0(a3)
ffffffffc0203258:	6685                	lui	a3,0x1
ffffffffc020325a:	4a068693          	addi	a3,a3,1184 # 14a0 <kern_entry-0xffffffffc01feb60>
ffffffffc020325e:	1890                	addi	a2,sp,112
ffffffffc0203260:	6dc2                	ld	s11,16(sp)
ffffffffc0203262:	c60c8d13          	addi	s10,s9,-928
ffffffffc0203266:	96b2                	add	a3,a3,a2
ffffffffc0203268:	01a68bb3          	add	s7,a3,s10
ffffffffc020326c:	7922                	ld	s2,40(sp)
ffffffffc020326e:	ec5e                	sd	s7,24(sp)
ffffffffc0203270:	e398                	sd	a4,0(a5)
ffffffffc0203272:	4a85                	li	s5,1
            while (ci < CACHE_COUNT && caches[ci].size < sizes[i]) { ++ci; }
ffffffffc0203274:	44a1                	li	s1,8
                assert(s->total == (PGSIZE - HEADER_SIZE) / caches[ci].size);
ffffffffc0203276:	8a6e                	mv	s4,s11
            size_t ci = 0, old = nr_free_pages();
ffffffffc0203278:	e41fe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
            while (ci < CACHE_COUNT && caches[ci].size < sizes[i]) { ++ci; }
ffffffffc020327c:	000bb603          	ld	a2,0(s7)
ffffffffc0203280:	00008997          	auipc	s3,0x8
ffffffffc0203284:	db098993          	addi	s3,s3,-592 # ffffffffc020b030 <caches>
            size_t ci = 0, old = nr_free_pages();
ffffffffc0203288:	8daa                	mv	s11,a0
            while (ci < CACHE_COUNT && caches[ci].size < sizes[i]) { ++ci; }
ffffffffc020328a:	844e                	mv	s0,s3
ffffffffc020328c:	87ce                	mv	a5,s3
            size_t ci = 0, old = nr_free_pages();
ffffffffc020328e:	4701                	li	a4,0
            while (ci < CACHE_COUNT && caches[ci].size < sizes[i]) { ++ci; }
ffffffffc0203290:	6394                	ld	a3,0(a5)
ffffffffc0203292:	10c6fc63          	bgeu	a3,a2,ffffffffc02033aa <slub_check+0x27c>
ffffffffc0203296:	0705                	addi	a4,a4,1
ffffffffc0203298:	07e1                	addi	a5,a5,24
ffffffffc020329a:	fe971be3          	bne	a4,s1,ffffffffc0203290 <slub_check+0x162>
            bool fresh = ci < CACHE_COUNT && list_empty(&caches[ci].available);
ffffffffc020329e:	4d01                	li	s10,0
    if (size == 0) {
ffffffffc02032a0:	12060563          	beqz	a2,ffffffffc02033ca <slub_check+0x29c>
ffffffffc02032a4:	8532                	mv	a0,a2
ffffffffc02032a6:	e43a                	sd	a4,8(sp)
ffffffffc02032a8:	e032                	sd	a2,0(sp)
ffffffffc02032aa:	b53ff0ef          	jal	ra,ffffffffc0202dfc <kmalloc.part.0>
            ptrs[i] = kmalloc(sizes[i]);
ffffffffc02032ae:	00aa3023          	sd	a0,0(s4)
ffffffffc02032b2:	8c2a                	mv	s8,a0
            assert(ptrs[i] != NULL && (uintptr_t)ptrs[i] % ALIGNMENT == 0);
ffffffffc02032b4:	10050b63          	beqz	a0,ffffffffc02033ca <slub_check+0x29c>
ffffffffc02032b8:	00f57793          	andi	a5,a0,15
ffffffffc02032bc:	10079763          	bnez	a5,ffffffffc02033ca <slub_check+0x29c>
    return listelm->next;
ffffffffc02032c0:	008b3783          	ld	a5,8(s6)
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc02032c4:	019575b3          	and	a1,a0,s9
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc02032c8:	03678063          	beq	a5,s6,ffffffffc02032e8 <slub_check+0x1ba>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc02032cc:	fb078693          	addi	a3,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc02032d0:	6602                	ld	a2,0(sp)
ffffffffc02032d2:	6722                	ld	a4,8(sp)
ffffffffc02032d4:	00b69763          	bne	a3,a1,ffffffffc02032e2 <slub_check+0x1b4>
ffffffffc02032d8:	a805                	j	ffffffffc0203308 <slub_check+0x1da>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc02032da:	fb078693          	addi	a3,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc02032de:	02b68563          	beq	a3,a1,ffffffffc0203308 <slub_check+0x1da>
ffffffffc02032e2:	679c                	ld	a5,8(a5)
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc02032e4:	ff679be3          	bne	a5,s6,ffffffffc02032da <slub_check+0x1ac>
            assert(s != NULL);
ffffffffc02032e8:	00004697          	auipc	a3,0x4
ffffffffc02032ec:	1d868693          	addi	a3,a3,472 # ffffffffc02074c0 <buddy_system_pmm_manager+0x1570>
ffffffffc02032f0:	00002617          	auipc	a2,0x2
ffffffffc02032f4:	ae860613          	addi	a2,a2,-1304 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02032f8:	14400593          	li	a1,324
ffffffffc02032fc:	00003517          	auipc	a0,0x3
ffffffffc0203300:	ee450513          	addi	a0,a0,-284 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203304:	ebffc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(s->kind == SMALL && s->cache == &caches[ci]);
ffffffffc0203308:	468c                	lw	a1,8(a3)
            if (ci < CACHE_COUNT) {
ffffffffc020330a:	0e970063          	beq	a4,s1,ffffffffc02033ea <slub_check+0x2bc>
                assert(s->kind == SMALL && s->cache == &caches[ci]);
ffffffffc020330e:	4785                	li	a5,1
ffffffffc0203310:	40f592e3          	bne	a1,a5,ffffffffc0203f14 <slub_check+0xde6>
ffffffffc0203314:	00171793          	slli	a5,a4,0x1
ffffffffc0203318:	00e785b3          	add	a1,a5,a4
ffffffffc020331c:	6a88                	ld	a0,16(a3)
ffffffffc020331e:	058e                	slli	a1,a1,0x3
ffffffffc0203320:	95a2                	add	a1,a1,s0
ffffffffc0203322:	3eb519e3          	bne	a0,a1,ffffffffc0203f14 <slub_check+0xde6>
                assert(ci == 0 || caches[ci - 1].size < sizes[i]);
ffffffffc0203326:	cb19                	beqz	a4,ffffffffc020333c <slub_check+0x20e>
ffffffffc0203328:	fff70513          	addi	a0,a4,-1
ffffffffc020332c:	00151593          	slli	a1,a0,0x1
ffffffffc0203330:	95aa                	add	a1,a1,a0
ffffffffc0203332:	058e                	slli	a1,a1,0x3
ffffffffc0203334:	95a2                	add	a1,a1,s0
ffffffffc0203336:	618c                	ld	a1,0(a1)
ffffffffc0203338:	3ac5fee3          	bgeu	a1,a2,ffffffffc0203ef4 <slub_check+0xdc6>
                assert(s->total == (PGSIZE - HEADER_SIZE) / caches[ci].size);
ffffffffc020333c:	97ba                	add	a5,a5,a4
ffffffffc020333e:	078e                	slli	a5,a5,0x3
ffffffffc0203340:	97a2                	add	a5,a5,s0
ffffffffc0203342:	639c                	ld	a5,0(a5)
ffffffffc0203344:	7698                	ld	a4,40(a3)
ffffffffc0203346:	6685                	lui	a3,0x1
ffffffffc0203348:	f8068693          	addi	a3,a3,-128 # f80 <kern_entry-0xffffffffc01ff080>
ffffffffc020334c:	02f6d7b3          	divu	a5,a3,a5
ffffffffc0203350:	38f712e3          	bne	a4,a5,ffffffffc0203ed4 <slub_check+0xda6>
                assert(old - nr_free_pages() == (fresh ? 1 : 0));
ffffffffc0203354:	e032                	sd	a2,0(sp)
ffffffffc0203356:	d63fe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc020335a:	40ad8db3          	sub	s11,s11,a0
ffffffffc020335e:	6602                	ld	a2,0(sp)
ffffffffc0203360:	35ad9ae3          	bne	s11,s10,ffffffffc0203eb4 <slub_check+0xd86>
            for (size_t j = 0; j < i; ++j) {
ffffffffc0203364:	4785                	li	a5,1
ffffffffc0203366:	0efa8863          	beq	s5,a5,ffffffffc0203456 <slub_check+0x328>
                assert((uintptr_t)ptrs[i] + sizes[i] <= (uintptr_t)ptrs[j] ||
ffffffffc020336a:	66e2                	ld	a3,24(sp)
ffffffffc020336c:	67c2                	ld	a5,16(sp)
ffffffffc020336e:	00cc05b3          	add	a1,s8,a2
ffffffffc0203372:	6398                	ld	a4,0(a5)
ffffffffc0203374:	00b77663          	bgeu	a4,a1,ffffffffc0203380 <slub_check+0x252>
ffffffffc0203378:	6288                	ld	a0,0(a3)
ffffffffc020337a:	972a                	add	a4,a4,a0
ffffffffc020337c:	2aec62e3          	bltu	s8,a4,ffffffffc0203e20 <slub_check+0xcf2>
            for (size_t j = 0; j < i; ++j) {
ffffffffc0203380:	07a1                	addi	a5,a5,8
ffffffffc0203382:	06a1                	addi	a3,a3,8
ffffffffc0203384:	ff4797e3          	bne	a5,s4,ffffffffc0203372 <slub_check+0x244>
            memset(ptrs[i], (int)(i + round + 1), sizes[i]);
ffffffffc0203388:	85ca                	mv	a1,s2
ffffffffc020338a:	8562                	mv	a0,s8
ffffffffc020338c:	76c010ef          	jal	ra,ffffffffc0204af8 <memset>
            slub_check_invariants();
ffffffffc0203390:	8deff0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
        for (size_t i = 0; i < N; ++i) {
ffffffffc0203394:	02100793          	li	a5,33
ffffffffc0203398:	0cfa8663          	beq	s5,a5,ffffffffc0203464 <slub_check+0x336>
ffffffffc020339c:	2905                	addiw	s2,s2,1
ffffffffc020339e:	0ba1                	addi	s7,s7,8
ffffffffc02033a0:	0a85                	addi	s5,s5,1
ffffffffc02033a2:	0ff97913          	zext.b	s2,s2
ffffffffc02033a6:	0a21                	addi	s4,s4,8
ffffffffc02033a8:	bdc1                	j	ffffffffc0203278 <slub_check+0x14a>
            bool fresh = ci < CACHE_COUNT && list_empty(&caches[ci].available);
ffffffffc02033aa:	00171793          	slli	a5,a4,0x1
ffffffffc02033ae:	97ba                	add	a5,a5,a4
ffffffffc02033b0:	078e                	slli	a5,a5,0x3
    return list->next == list;
ffffffffc02033b2:	00f406b3          	add	a3,s0,a5
ffffffffc02033b6:	0106bd03          	ld	s10,16(a3)
ffffffffc02033ba:	07a1                	addi	a5,a5,8
ffffffffc02033bc:	97a2                	add	a5,a5,s0
ffffffffc02033be:	40fd07b3          	sub	a5,s10,a5
ffffffffc02033c2:	0017bd13          	seqz	s10,a5
    if (size == 0) {
ffffffffc02033c6:	ec061fe3          	bnez	a2,ffffffffc02032a4 <slub_check+0x176>
            assert(ptrs[i] != NULL && (uintptr_t)ptrs[i] % ALIGNMENT == 0);
ffffffffc02033ca:	00003697          	auipc	a3,0x3
ffffffffc02033ce:	6a668693          	addi	a3,a3,1702 # ffffffffc0206a70 <buddy_system_pmm_manager+0xb20>
ffffffffc02033d2:	00002617          	auipc	a2,0x2
ffffffffc02033d6:	a0660613          	addi	a2,a2,-1530 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02033da:	14200593          	li	a1,322
ffffffffc02033de:	00003517          	auipc	a0,0x3
ffffffffc02033e2:	e0250513          	addi	a0,a0,-510 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02033e6:	dddfc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                while (expected * PGSIZE < sizes[i] + HEADER_SIZE) { expected *= 2; }
ffffffffc02033ea:	08060713          	addi	a4,a2,128
ffffffffc02033ee:	6785                	lui	a5,0x1
                size_t expected = 1;
ffffffffc02033f0:	4d05                	li	s10,1
                while (expected * PGSIZE < sizes[i] + HEADER_SIZE) { expected *= 2; }
ffffffffc02033f2:	00e7f763          	bgeu	a5,a4,ffffffffc0203400 <slub_check+0x2d2>
ffffffffc02033f6:	00dd1793          	slli	a5,s10,0xd
ffffffffc02033fa:	0d06                	slli	s10,s10,0x1
ffffffffc02033fc:	fee7ede3          	bltu	a5,a4,ffffffffc02033f6 <slub_check+0x2c8>
                assert(s->kind == LARGE && s->npages == expected);
ffffffffc0203400:	4709                	li	a4,2
ffffffffc0203402:	3ce599e3          	bne	a1,a4,ffffffffc0203fd4 <slub_check+0xea6>
ffffffffc0203406:	7298                	ld	a4,32(a3)
ffffffffc0203408:	3da716e3          	bne	a4,s10,ffffffffc0203fd4 <slub_check+0xea6>
    return (char *)s + HEADER_SIZE;
ffffffffc020340c:	08068713          	addi	a4,a3,128
                assert(ptrs[i] == objects(s) && (uintptr_t)ptrs[i] < (uintptr_t)s + PGSIZE);
ffffffffc0203410:	28ec12e3          	bne	s8,a4,ffffffffc0203e94 <slub_check+0xd66>
ffffffffc0203414:	6705                	lui	a4,0x1
ffffffffc0203416:	9736                	add	a4,a4,a3
ffffffffc0203418:	26ec7ee3          	bgeu	s8,a4,ffffffffc0203e94 <slub_check+0xd66>
                assert((uintptr_t)ptrs[i] + sizes[i] <= (uintptr_t)s + expected * PGSIZE);
ffffffffc020341c:	00cc0733          	add	a4,s8,a2
ffffffffc0203420:	97b6                	add	a5,a5,a3
ffffffffc0203422:	3ce7e9e3          	bltu	a5,a4,ffffffffc0203ff4 <slub_check+0xec6>
                assert(old - nr_free_pages() == expected);
ffffffffc0203426:	e032                	sd	a2,0(sp)
ffffffffc0203428:	c91fe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc020342c:	40ad8db3          	sub	s11,s11,a0
ffffffffc0203430:	6602                	ld	a2,0(sp)
ffffffffc0203432:	f3ad89e3          	beq	s11,s10,ffffffffc0203364 <slub_check+0x236>
ffffffffc0203436:	00003697          	auipc	a3,0x3
ffffffffc020343a:	7fa68693          	addi	a3,a3,2042 # ffffffffc0206c30 <buddy_system_pmm_manager+0xce0>
ffffffffc020343e:	00002617          	auipc	a2,0x2
ffffffffc0203442:	99a60613          	addi	a2,a2,-1638 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203446:	15100593          	li	a1,337
ffffffffc020344a:	00003517          	auipc	a0,0x3
ffffffffc020344e:	d9650513          	addi	a0,a0,-618 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203452:	d71fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            memset(ptrs[i], (int)(i + round + 1), sizes[i]);
ffffffffc0203456:	85ca                	mv	a1,s2
ffffffffc0203458:	8562                	mv	a0,s8
ffffffffc020345a:	69e010ef          	jal	ra,ffffffffc0204af8 <memset>
            slub_check_invariants();
ffffffffc020345e:	810ff0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
        for (size_t i = 0; i < N; ++i) {
ffffffffc0203462:	bf2d                	j	ffffffffc020339c <slub_check+0x26e>
        const size_t failures[] = {0, SIZE_MAX_VALUE,
ffffffffc0203464:	6685                	lui	a3,0x1
            (npage - nbase) * PGSIZE};
ffffffffc0203466:	000a8797          	auipc	a5,0xa8
ffffffffc020346a:	4ba78793          	addi	a5,a5,1210 # ffffffffc02ab920 <npage>
        const size_t failures[] = {0, SIZE_MAX_VALUE,
ffffffffc020346e:	1890                	addi	a2,sp,112
            (npage - nbase) * PGSIZE};
ffffffffc0203470:	639c                	ld	a5,0(a5)
ffffffffc0203472:	74c2                	ld	s1,48(sp)
        const size_t failures[] = {0, SIZE_MAX_VALUE,
ffffffffc0203474:	4a068713          	addi	a4,a3,1184 # 14a0 <kern_entry-0xffffffffc01feb60>
ffffffffc0203478:	9732                	add	a4,a4,a2
ffffffffc020347a:	01970ab3          	add	s5,a4,s9
ffffffffc020347e:	4a068713          	addi	a4,a3,1184
ffffffffc0203482:	9732                	add	a4,a4,a2
ffffffffc0203484:	b78c8913          	addi	s2,s9,-1160
            (npage - nbase) * PGSIZE};
ffffffffc0203488:	8f85                	sub	a5,a5,s1
ffffffffc020348a:	07b2                	slli	a5,a5,0xc
ffffffffc020348c:	993a                	add	s2,s2,a4
        const size_t failures[] = {0, SIZE_MAX_VALUE,
ffffffffc020348e:	577d                	li	a4,-1
ffffffffc0203490:	b8eab023          	sd	a4,-1152(s5)
ffffffffc0203494:	b8fabc23          	sd	a5,-1128(s5)
ffffffffc0203498:	f8000713          	li	a4,-128
            memcpy(saved_caches, caches, sizeof(caches));
ffffffffc020349c:	4a068793          	addi	a5,a3,1184
            (npage - nbase) * PGSIZE};
ffffffffc02034a0:	e4ce                	sd	s3,72(sp)
        const size_t failures[] = {0, SIZE_MAX_VALUE,
ffffffffc02034a2:	b8eab423          	sd	a4,-1144(s5)
            memcpy(saved_caches, caches, sizeof(caches));
ffffffffc02034a6:	ba0c8993          	addi	s3,s9,-1120
        const size_t failures[] = {0, SIZE_MAX_VALUE,
ffffffffc02034aa:	f7f00713          	li	a4,-129
            memcpy(saved_caches, caches, sizeof(caches));
ffffffffc02034ae:	97b2                	add	a5,a5,a2
        const size_t failures[] = {0, SIZE_MAX_VALUE,
ffffffffc02034b0:	b60abc23          	sd	zero,-1160(s5)
ffffffffc02034b4:	b8eab823          	sd	a4,-1136(s5)
ffffffffc02034b8:	02890d93          	addi	s11,s2,40
            memcpy(saved_caches, caches, sizeof(caches));
ffffffffc02034bc:	99be                	add	s3,s3,a5
                held[i].count = PageProperty(&pages[i]) ? pages[i].property : 0;
ffffffffc02034be:	000a8a17          	auipc	s4,0xa8
ffffffffc02034c2:	46aa0a13          	addi	s4,s4,1130 # ffffffffc02ab928 <pages>
            list_entry_t saved_live = live;
ffffffffc02034c6:	000b3703          	ld	a4,0(s6)
ffffffffc02034ca:	008b3783          	ld	a5,8(s6)
            memcpy(saved_caches, caches, sizeof(caches));
ffffffffc02034ce:	0c000613          	li	a2,192
ffffffffc02034d2:	00008597          	auipc	a1,0x8
ffffffffc02034d6:	b5e58593          	addi	a1,a1,-1186 # ffffffffc020b030 <caches>
ffffffffc02034da:	854e                	mv	a0,s3
            list_entry_t saved_live = live;
ffffffffc02034dc:	b6eab423          	sd	a4,-1176(s5)
ffffffffc02034e0:	b6fab823          	sd	a5,-1168(s5)
            memcpy(saved_caches, caches, sizeof(caches));
ffffffffc02034e4:	626010ef          	jal	ra,ffffffffc0204b0a <memcpy>
            for (size_t i = 0; i < N; ++i) {
ffffffffc02034e8:	6705                	lui	a4,0x1
ffffffffc02034ea:	4a070793          	addi	a5,a4,1184 # 14a0 <kern_entry-0xffffffffc01feb60>
ffffffffc02034ee:	1894                	addi	a3,sp,112
ffffffffc02034f0:	97b6                	add	a5,a5,a3
ffffffffc02034f2:	76fd                	lui	a3,0xfffff
ffffffffc02034f4:	e7068613          	addi	a2,a3,-400 # ffffffffffffee70 <end+0x3fd53520>
ffffffffc02034f8:	00c78bb3          	add	s7,a5,a2
    return listelm->next;
ffffffffc02034fc:	008b3503          	ld	a0,8(s6)
ffffffffc0203500:	4a070793          	addi	a5,a4,1184
ffffffffc0203504:	1898                	addi	a4,sp,112
ffffffffc0203506:	97ba                	add	a5,a5,a4
ffffffffc0203508:	65c2                	ld	a1,16(sp)
ffffffffc020350a:	f8068713          	addi	a4,a3,-128
ffffffffc020350e:	00e78c33          	add	s8,a5,a4
ffffffffc0203512:	8ee2                	mv	t4,s8
ffffffffc0203514:	8e5e                	mv	t3,s7
ffffffffc0203516:	4f01                	li	t5,0
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0203518:	fb050313          	addi	t1,a0,-80
            for (size_t i = 0; i < N; ++i) {
ffffffffc020351c:	02100f93          	li	t6,33
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc0203520:	6194                	ld	a3,0(a1)
ffffffffc0203522:	0196f6b3          	and	a3,a3,s9
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0203526:	01651463          	bne	a0,s6,ffffffffc020352e <slub_check+0x400>
ffffffffc020352a:	0f60106f          	j	ffffffffc0204620 <slub_check+0x14f2>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc020352e:	871a                	mv	a4,t1
        if ((uintptr_t)s == base) {
ffffffffc0203530:	00d30c63          	beq	t1,a3,ffffffffc0203548 <slub_check+0x41a>
ffffffffc0203534:	87aa                	mv	a5,a0
ffffffffc0203536:	679c                	ld	a5,8(a5)
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0203538:	01679463          	bne	a5,s6,ffffffffc0203540 <slub_check+0x412>
ffffffffc020353c:	0e40106f          	j	ffffffffc0204620 <slub_check+0x14f2>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0203540:	fb078713          	addi	a4,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc0203544:	fed719e3          	bne	a4,a3,ffffffffc0203536 <slub_check+0x408>
                saved[i] = *heads[i];
ffffffffc0203548:	87ba                	mv	a5,a4
                heads[i] = find_slab(ptrs[i]);
ffffffffc020354a:	00ee3023          	sd	a4,0(t3) # fffffffffffff000 <end+0x3fd536b0>
                saved[i] = *heads[i];
ffffffffc020354e:	08078293          	addi	t0,a5,128
ffffffffc0203552:	8776                	mv	a4,t4
ffffffffc0203554:	0007b883          	ld	a7,0(a5)
ffffffffc0203558:	0087b803          	ld	a6,8(a5)
ffffffffc020355c:	6b90                	ld	a2,16(a5)
ffffffffc020355e:	6f94                	ld	a3,24(a5)
ffffffffc0203560:	01173023          	sd	a7,0(a4)
ffffffffc0203564:	01073423          	sd	a6,8(a4)
ffffffffc0203568:	eb10                	sd	a2,16(a4)
ffffffffc020356a:	ef14                	sd	a3,24(a4)
ffffffffc020356c:	02078793          	addi	a5,a5,32
ffffffffc0203570:	02070713          	addi	a4,a4,32
ffffffffc0203574:	fe5790e3          	bne	a5,t0,ffffffffc0203554 <slub_check+0x426>
            for (size_t i = 0; i < N; ++i) {
ffffffffc0203578:	0f05                	addi	t5,t5,1
ffffffffc020357a:	05a1                	addi	a1,a1,8
ffffffffc020357c:	0e21                	addi	t3,t3,8
ffffffffc020357e:	080e8e93          	addi	t4,t4,128
ffffffffc0203582:	f9ff1fe3          	bne	t5,t6,ffffffffc0203520 <slub_check+0x3f2>
            for (size_t i = 0; i < npage - nbase; ++i) {
ffffffffc0203586:	000a8797          	auipc	a5,0xa8
ffffffffc020358a:	39a78793          	addi	a5,a5,922 # ffffffffc02ab920 <npage>
ffffffffc020358e:	6398                	ld	a4,0(a5)
ffffffffc0203590:	409707b3          	sub	a5,a4,s1
ffffffffc0203594:	02970863          	beq	a4,s1,ffffffffc02035c4 <slub_check+0x496>
ffffffffc0203598:	000a3683          	ld	a3,0(s4)
ffffffffc020359c:	00028717          	auipc	a4,0x28
ffffffffc02035a0:	b5c70713          	addi	a4,a4,-1188 # ffffffffc022b0f8 <held.1+0x8>
ffffffffc02035a4:	0792                	slli	a5,a5,0x4
ffffffffc02035a6:	06c1                	addi	a3,a3,16
ffffffffc02035a8:	00e78633          	add	a2,a5,a4
                held[i].count = PageProperty(&pages[i]) ? pages[i].property : 0;
ffffffffc02035ac:	ff86b783          	ld	a5,-8(a3)
ffffffffc02035b0:	8b89                	andi	a5,a5,2
ffffffffc02035b2:	c399                	beqz	a5,ffffffffc02035b8 <slub_check+0x48a>
ffffffffc02035b4:	0006e783          	lwu	a5,0(a3)
ffffffffc02035b8:	e31c                	sd	a5,0(a4)
            for (size_t i = 0; i < npage - nbase; ++i) {
ffffffffc02035ba:	0741                	addi	a4,a4,16
ffffffffc02035bc:	02868693          	addi	a3,a3,40
ffffffffc02035c0:	fec716e3          	bne	a4,a2,ffffffffc02035ac <slub_check+0x47e>
            size_t old = nr_free_pages();
ffffffffc02035c4:	af5fe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
            assert(kmalloc(failures[f]) == NULL && nr_free_pages() == old);
ffffffffc02035c8:	00093783          	ld	a5,0(s2)
            size_t old = nr_free_pages();
ffffffffc02035cc:	8d2a                	mv	s10,a0
    if (size == 0) {
ffffffffc02035ce:	c791                	beqz	a5,ffffffffc02035da <slub_check+0x4ac>
ffffffffc02035d0:	853e                	mv	a0,a5
ffffffffc02035d2:	82bff0ef          	jal	ra,ffffffffc0202dfc <kmalloc.part.0>
            assert(kmalloc(failures[f]) == NULL && nr_free_pages() == old);
ffffffffc02035d6:	26051fe3          	bnez	a0,ffffffffc0204054 <slub_check+0xf26>
ffffffffc02035da:	adffe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc02035de:	27a51be3          	bne	a0,s10,ffffffffc0204054 <slub_check+0xf26>
            assert(memcmp(&saved_live, &live, sizeof(live)) == 0);
ffffffffc02035e2:	6506                	ld	a0,64(sp)
ffffffffc02035e4:	4641                	li	a2,16
ffffffffc02035e6:	000a8597          	auipc	a1,0xa8
ffffffffc02035ea:	b0a58593          	addi	a1,a1,-1270 # ffffffffc02ab0f0 <live>
ffffffffc02035ee:	534010ef          	jal	ra,ffffffffc0204b22 <memcmp>
ffffffffc02035f2:	240511e3          	bnez	a0,ffffffffc0204034 <slub_check+0xf06>
            assert(memcmp(saved_caches, caches, sizeof(caches)) == 0);
ffffffffc02035f6:	0c000613          	li	a2,192
ffffffffc02035fa:	00008597          	auipc	a1,0x8
ffffffffc02035fe:	a3658593          	addi	a1,a1,-1482 # ffffffffc020b030 <caches>
ffffffffc0203602:	854e                	mv	a0,s3
ffffffffc0203604:	51e010ef          	jal	ra,ffffffffc0204b22 <memcmp>
ffffffffc0203608:	200516e3          	bnez	a0,ffffffffc0204014 <slub_check+0xee6>
ffffffffc020360c:	108b8d13          	addi	s10,s7,264
                assert(memcmp(&saved[i], heads[i], HEADER_SIZE) == 0);
ffffffffc0203610:	000bb583          	ld	a1,0(s7)
ffffffffc0203614:	08000613          	li	a2,128
ffffffffc0203618:	8562                	mv	a0,s8
ffffffffc020361a:	508010ef          	jal	ra,ffffffffc0204b22 <memcmp>
ffffffffc020361e:	14051be3          	bnez	a0,ffffffffc0203f74 <slub_check+0xe46>
            for (size_t i = 0; i < N; ++i) {
ffffffffc0203622:	0ba1                	addi	s7,s7,8
ffffffffc0203624:	080c0c13          	addi	s8,s8,128
ffffffffc0203628:	ffab94e3          	bne	s7,s10,ffffffffc0203610 <slub_check+0x4e2>
            for (size_t i = 0; i < npage - nbase; ++i) {
ffffffffc020362c:	000a8797          	auipc	a5,0xa8
ffffffffc0203630:	2f478793          	addi	a5,a5,756 # ffffffffc02ab920 <npage>
ffffffffc0203634:	639c                	ld	a5,0(a5)
ffffffffc0203636:	40978533          	sub	a0,a5,s1
ffffffffc020363a:	02978a63          	beq	a5,s1,ffffffffc020366e <slub_check+0x540>
ffffffffc020363e:	000a3683          	ld	a3,0(s4)
ffffffffc0203642:	00028717          	auipc	a4,0x28
ffffffffc0203646:	ab670713          	addi	a4,a4,-1354 # ffffffffc022b0f8 <held.1+0x8>
ffffffffc020364a:	4601                	li	a2,0
ffffffffc020364c:	06a1                	addi	a3,a3,8
                assert((PageProperty(&pages[i]) ? pages[i].property : 0) == held[i].count);
ffffffffc020364e:	629c                	ld	a5,0(a3)
ffffffffc0203650:	8b89                	andi	a5,a5,2
ffffffffc0203652:	c399                	beqz	a5,ffffffffc0203658 <slub_check+0x52a>
ffffffffc0203654:	0086e783          	lwu	a5,8(a3)
ffffffffc0203658:	630c                	ld	a1,0(a4)
ffffffffc020365a:	12f59de3          	bne	a1,a5,ffffffffc0203f94 <slub_check+0xe66>
                held[i].count = 0;
ffffffffc020365e:	00073023          	sd	zero,0(a4)
            for (size_t i = 0; i < npage - nbase; ++i) {
ffffffffc0203662:	0605                	addi	a2,a2,1
ffffffffc0203664:	02868693          	addi	a3,a3,40
ffffffffc0203668:	0741                	addi	a4,a4,16
ffffffffc020366a:	fec512e3          	bne	a0,a2,ffffffffc020364e <slub_check+0x520>
        for (size_t f = 0; f < sizeof(failures) / sizeof(failures[0]); ++f) {
ffffffffc020366e:	0921                	addi	s2,s2,8
            slub_check_invariants();
ffffffffc0203670:	dfffe0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
        for (size_t f = 0; f < sizeof(failures) / sizeof(failures[0]); ++f) {
ffffffffc0203674:	e5b919e3          	bne	s2,s11,ffffffffc02034c6 <slub_check+0x398>
ffffffffc0203678:	7762                	ld	a4,56(sp)
            struct slab *s = find_slab(ptrs[i]);
ffffffffc020367a:	6785                	lui	a5,0x1
ffffffffc020367c:	4a078793          	addi	a5,a5,1184 # 14a0 <kern_entry-0xffffffffc01feb60>
ffffffffc0203680:	1894                	addi	a3,sp,112
ffffffffc0203682:	7aa6                	ld	s5,104(sp)
ffffffffc0203684:	97b6                	add	a5,a5,a3
        for (size_t step = 0; step < N; ++step) {
ffffffffc0203686:	02170d13          	addi	s10,a4,33
ffffffffc020368a:	89ba                	mv	s3,a4
            size_t i = (step + round * 7) % N;
ffffffffc020368c:	02100a13          	li	s4,33
            struct slab *s = find_slab(ptrs[i]);
ffffffffc0203690:	01978933          	add	s2,a5,s9
            bool last = s->kind == LARGE || s->used == 1;
ffffffffc0203694:	4c09                	li	s8,2
ffffffffc0203696:	4b85                	li	s7,1
ffffffffc0203698:	e06a                	sd	s10,0(sp)
            size_t i = (step + round * 7) % N;
ffffffffc020369a:	0349f4b3          	remu	s1,s3,s4
ffffffffc020369e:	6562                	ld	a0,24(sp)
ffffffffc02036a0:	76a2                	ld	a3,40(sp)
ffffffffc02036a2:	65c2                	ld	a1,16(sp)
ffffffffc02036a4:	a801                	j	ffffffffc02036b4 <slub_check+0x586>
            for (size_t j = 0; j < N; ++j) {
ffffffffc02036a6:	2685                	addiw	a3,a3,1
ffffffffc02036a8:	05a1                	addi	a1,a1,8
ffffffffc02036aa:	0ff6f693          	zext.b	a3,a3
ffffffffc02036ae:	0521                	addi	a0,a0,8
ffffffffc02036b0:	03558f63          	beq	a1,s5,ffffffffc02036ee <slub_check+0x5c0>
                if (ptrs[j] != NULL) {
ffffffffc02036b4:	619c                	ld	a5,0(a1)
ffffffffc02036b6:	dbe5                	beqz	a5,ffffffffc02036a6 <slub_check+0x578>
                    for (size_t k = 0; k < sizes[j]; ++k) {
ffffffffc02036b8:	6110                	ld	a2,0(a0)
ffffffffc02036ba:	d675                	beqz	a2,ffffffffc02036a6 <slub_check+0x578>
ffffffffc02036bc:	963e                	add	a2,a2,a5
ffffffffc02036be:	a021                	j	ffffffffc02036c6 <slub_check+0x598>
ffffffffc02036c0:	0785                	addi	a5,a5,1
ffffffffc02036c2:	fec782e3          	beq	a5,a2,ffffffffc02036a6 <slub_check+0x578>
                        assert(((uint8_t *)ptrs[j])[k] == (uint8_t)(j + round + 1));
ffffffffc02036c6:	0007c703          	lbu	a4,0(a5)
ffffffffc02036ca:	fed70be3          	beq	a4,a3,ffffffffc02036c0 <slub_check+0x592>
ffffffffc02036ce:	00003697          	auipc	a3,0x3
ffffffffc02036d2:	71268693          	addi	a3,a3,1810 # ffffffffc0206de0 <buddy_system_pmm_manager+0xe90>
ffffffffc02036d6:	00001617          	auipc	a2,0x1
ffffffffc02036da:	70260613          	addi	a2,a2,1794 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02036de:	18200593          	li	a1,386
ffffffffc02036e2:	00003517          	auipc	a0,0x3
ffffffffc02036e6:	afe50513          	addi	a0,a0,-1282 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02036ea:	ad9fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            struct slab *s = find_slab(ptrs[i]);
ffffffffc02036ee:	048e                	slli	s1,s1,0x3
ffffffffc02036f0:	009907b3          	add	a5,s2,s1
ffffffffc02036f4:	d687bd03          	ld	s10,-664(a5)
ffffffffc02036f8:	008b3783          	ld	a5,8(s6)
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc02036fc:	019d76b3          	and	a3,s10,s9
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0203700:	01679963          	bne	a5,s6,ffffffffc0203712 <slub_check+0x5e4>
ffffffffc0203704:	7170006f          	j	ffffffffc020461a <slub_check+0x14ec>
ffffffffc0203708:	679c                	ld	a5,8(a5)
ffffffffc020370a:	01679463          	bne	a5,s6,ffffffffc0203712 <slub_check+0x5e4>
ffffffffc020370e:	70d0006f          	j	ffffffffc020461a <slub_check+0x14ec>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0203712:	fb078d93          	addi	s11,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc0203716:	fedd99e3          	bne	s11,a3,ffffffffc0203708 <slub_check+0x5da>
            bool last = s->kind == LARGE || s->used == 1;
ffffffffc020371a:	008da783          	lw	a5,8(s11)
ffffffffc020371e:	17878563          	beq	a5,s8,ffffffffc0203888 <slub_check+0x75a>
ffffffffc0203722:	030db783          	ld	a5,48(s11)
ffffffffc0203726:	17778163          	beq	a5,s7,ffffffffc0203888 <slub_check+0x75a>
            size_t released = last ? s->npages : 0, old = nr_free_pages();
ffffffffc020372a:	98ffe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc020372e:	8daa                	mv	s11,a0
            kfree(ptrs[i]);
ffffffffc0203730:	856a                	mv	a0,s10
ffffffffc0203732:	859ff0ef          	jal	ra,ffffffffc0202f8a <kfree>
            ptrs[i] = NULL;
ffffffffc0203736:	00990733          	add	a4,s2,s1
ffffffffc020373a:	d6073423          	sd	zero,-664(a4)
            assert(nr_free_pages() == old + released);
ffffffffc020373e:	97bfe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0203742:	1cad9563          	bne	s11,a0,ffffffffc020390c <slub_check+0x7de>
            void *replacement = kmalloc(sizes[i]);
ffffffffc0203746:	94ca                	add	s1,s1,s2
            slub_check_invariants();
ffffffffc0203748:	d27fe0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
            void *replacement = kmalloc(sizes[i]);
ffffffffc020374c:	c604bd83          	ld	s11,-928(s1)
    if (size == 0) {
ffffffffc0203750:	180d8e63          	beqz	s11,ffffffffc02038ec <slub_check+0x7be>
ffffffffc0203754:	856e                	mv	a0,s11
ffffffffc0203756:	ea6ff0ef          	jal	ra,ffffffffc0202dfc <kmalloc.part.0>
ffffffffc020375a:	8d2a                	mv	s10,a0
            assert(replacement != NULL && (uintptr_t)replacement % ALIGNMENT == 0);
ffffffffc020375c:	18050863          	beqz	a0,ffffffffc02038ec <slub_check+0x7be>
ffffffffc0203760:	00f57793          	andi	a5,a0,15
ffffffffc0203764:	84aa                	mv	s1,a0
ffffffffc0203766:	18079363          	bnez	a5,ffffffffc02038ec <slub_check+0x7be>
            memset(replacement, 0xe7, sizes[i]);
ffffffffc020376a:	866e                	mv	a2,s11
ffffffffc020376c:	0e700593          	li	a1,231
ffffffffc0203770:	388010ef          	jal	ra,ffffffffc0204af8 <memset>
            slub_check_invariants();
ffffffffc0203774:	cfbfe0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
            for (size_t k = 0; k < sizes[i]; ++k) {
ffffffffc0203778:	01ad8733          	add	a4,s11,s10
                assert(((uint8_t *)replacement)[k] == 0xe7);
ffffffffc020377c:	0e700693          	li	a3,231
ffffffffc0203780:	0004c783          	lbu	a5,0(s1)
ffffffffc0203784:	02d798e3          	bne	a5,a3,ffffffffc0203fb4 <slub_check+0xe86>
            for (size_t k = 0; k < sizes[i]; ++k) {
ffffffffc0203788:	0485                	addi	s1,s1,1
ffffffffc020378a:	fee49be3          	bne	s1,a4,ffffffffc0203780 <slub_check+0x652>
            kfree(replacement);
ffffffffc020378e:	856a                	mv	a0,s10
ffffffffc0203790:	ffaff0ef          	jal	ra,ffffffffc0202f8a <kfree>
            slub_check_invariants();
ffffffffc0203794:	cdbfe0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
        for (size_t step = 0; step < N; ++step) {
ffffffffc0203798:	6782                	ld	a5,0(sp)
ffffffffc020379a:	0985                	addi	s3,s3,1
ffffffffc020379c:	eef99fe3          	bne	s3,a5,ffffffffc020369a <slub_check+0x56c>
            size_t size = caches[ci].size, count = (PGSIZE - HEADER_SIZE) / size;
ffffffffc02037a0:	6785                	lui	a5,0x1
ffffffffc02037a2:	f8078793          	addi	a5,a5,-128 # f80 <kern_entry-0xffffffffc01ff080>
ffffffffc02037a6:	f0be                	sd	a5,96(sp)
                    assert(nr_free_pages() == before - 2);
ffffffffc02037a8:	7782                	ld	a5,32(sp)
        for (size_t step = 0; step < N; ++step) {
ffffffffc02037aa:	6ba6                	ld	s7,72(sp)
ffffffffc02037ac:	000a8d17          	auipc	s10,0xa8
ffffffffc02037b0:	954d0d13          	addi	s10,s10,-1708 # ffffffffc02ab100 <slots.0>
                    assert(nr_free_pages() == before - 2);
ffffffffc02037b4:	17f9                	addi	a5,a5,-2
ffffffffc02037b6:	e43e                	sd	a5,8(sp)
ffffffffc02037b8:	e05e                	sd	s7,0(sp)
            size_t size = caches[ci].size, count = (PGSIZE - HEADER_SIZE) / size;
ffffffffc02037ba:	6782                	ld	a5,0(sp)
ffffffffc02037bc:	0007bb83          	ld	s7,0(a5)
ffffffffc02037c0:	7786                	ld	a5,96(sp)
ffffffffc02037c2:	0377d4b3          	divu	s1,a5,s7
            assert(count > 0 && count <= MAX_SLOTS);
ffffffffc02037c6:	0ff00793          	li	a5,255
ffffffffc02037ca:	fff48993          	addi	s3,s1,-1
ffffffffc02037ce:	6b37e363          	bltu	a5,s3,ffffffffc0203e74 <slub_check+0xd46>
ffffffffc02037d2:	7a82                	ld	s5,32(sp)
ffffffffc02037d4:	000a8917          	auipc	s2,0xa8
ffffffffc02037d8:	92c90913          	addi	s2,s2,-1748 # ffffffffc02ab100 <slots.0>
            for (size_t i = 0; i <= count; ++i) {
ffffffffc02037dc:	4c01                	li	s8,0
                memset(slots[i], (int)(i % 251) + 1, size);
ffffffffc02037de:	0fb00a13          	li	s4,251
    if (size == 0) {
ffffffffc02037e2:	060b8f63          	beqz	s7,ffffffffc0203860 <slub_check+0x732>
ffffffffc02037e6:	855e                	mv	a0,s7
ffffffffc02037e8:	e14ff0ef          	jal	ra,ffffffffc0202dfc <kmalloc.part.0>
                slots[i] = kmalloc(size);
ffffffffc02037ec:	00a93023          	sd	a0,0(s2)
                assert(slots[i] != NULL && (uintptr_t)slots[i] % ALIGNMENT == 0);
ffffffffc02037f0:	cd25                	beqz	a0,ffffffffc0203868 <slub_check+0x73a>
ffffffffc02037f2:	00f57d93          	andi	s11,a0,15
ffffffffc02037f6:	060d9963          	bnez	s11,ffffffffc0203868 <slub_check+0x73a>
ffffffffc02037fa:	008b3783          	ld	a5,8(s6)
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc02037fe:	019576b3          	and	a3,a0,s9
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0203802:	01679763          	bne	a5,s6,ffffffffc0203810 <slub_check+0x6e2>
ffffffffc0203806:	6090006f          	j	ffffffffc020460e <slub_check+0x14e0>
ffffffffc020380a:	679c                	ld	a5,8(a5)
ffffffffc020380c:	616781e3          	beq	a5,s6,ffffffffc020460e <slub_check+0x14e0>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0203810:	fb078713          	addi	a4,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc0203814:	fed71be3          	bne	a4,a3,ffffffffc020380a <slub_check+0x6dc>
                assert(find_slab(slots[i])->cache == &caches[ci]);
ffffffffc0203818:	6b1c                	ld	a5,16(a4)
ffffffffc020381a:	6702                	ld	a4,0(sp)
ffffffffc020381c:	62e79c63          	bne	a5,a4,ffffffffc0203e54 <slub_check+0xd26>
                memset(slots[i], (int)(i % 251) + 1, size);
ffffffffc0203820:	034c77b3          	remu	a5,s8,s4
ffffffffc0203824:	865e                	mv	a2,s7
ffffffffc0203826:	0017859b          	addiw	a1,a5,1
ffffffffc020382a:	0ff5f593          	zext.b	a1,a1
ffffffffc020382e:	2ca010ef          	jal	ra,ffffffffc0204af8 <memset>
                assert(nr_free_pages() == before - (i < count ? 1 : 2));
ffffffffc0203832:	887fe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0203836:	009c37b3          	sltu	a5,s8,s1
ffffffffc020383a:	0017c793          	xori	a5,a5,1
ffffffffc020383e:	1782                	slli	a5,a5,0x20
ffffffffc0203840:	9381                	srli	a5,a5,0x20
ffffffffc0203842:	0785                	addi	a5,a5,1
ffffffffc0203844:	40fa87b3          	sub	a5,s5,a5
ffffffffc0203848:	02f516e3          	bne	a0,a5,ffffffffc0204074 <slub_check+0xf46>
                slub_check_invariants();
ffffffffc020384c:	c23fe0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
            for (size_t i = 0; i <= count; ++i) {
ffffffffc0203850:	0921                	addi	s2,s2,8
ffffffffc0203852:	001c0793          	addi	a5,s8,1
ffffffffc0203856:	0d848b63          	beq	s1,s8,ffffffffc020392c <slub_check+0x7fe>
ffffffffc020385a:	8c3e                	mv	s8,a5
    if (size == 0) {
ffffffffc020385c:	f80b95e3          	bnez	s7,ffffffffc02037e6 <slub_check+0x6b8>
                slots[i] = kmalloc(size);
ffffffffc0203860:	0c0e                	slli	s8,s8,0x3
ffffffffc0203862:	9c6a                	add	s8,s8,s10
ffffffffc0203864:	000c3023          	sd	zero,0(s8)
                assert(slots[i] != NULL && (uintptr_t)slots[i] % ALIGNMENT == 0);
ffffffffc0203868:	00003697          	auipc	a3,0x3
ffffffffc020386c:	66068693          	addi	a3,a3,1632 # ffffffffc0206ec8 <buddy_system_pmm_manager+0xf78>
ffffffffc0203870:	00001617          	auipc	a2,0x1
ffffffffc0203874:	56860613          	addi	a2,a2,1384 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203878:	1a200593          	li	a1,418
ffffffffc020387c:	00003517          	auipc	a0,0x3
ffffffffc0203880:	96450513          	addi	a0,a0,-1692 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203884:	93ffc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            size_t released = last ? s->npages : 0, old = nr_free_pages();
ffffffffc0203888:	020db783          	ld	a5,32(s11)
ffffffffc020388c:	e43e                	sd	a5,8(sp)
ffffffffc020388e:	82bfe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0203892:	86aa                	mv	a3,a0
            kfree(ptrs[i]);
ffffffffc0203894:	856a                	mv	a0,s10
            size_t released = last ? s->npages : 0, old = nr_free_pages();
ffffffffc0203896:	8d36                	mv	s10,a3
            kfree(ptrs[i]);
ffffffffc0203898:	ef2ff0ef          	jal	ra,ffffffffc0202f8a <kfree>
            ptrs[i] = NULL;
ffffffffc020389c:	00990633          	add	a2,s2,s1
ffffffffc02038a0:	d6063423          	sd	zero,-664(a2)
            assert(nr_free_pages() == old + released);
ffffffffc02038a4:	815fe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc02038a8:	67a2                	ld	a5,8(sp)
ffffffffc02038aa:	97ea                	add	a5,a5,s10
ffffffffc02038ac:	06f51063          	bne	a0,a5,ffffffffc020390c <slub_check+0x7de>
ffffffffc02038b0:	008b3783          	ld	a5,8(s6)
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc02038b4:	019df733          	and	a4,s11,s9
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc02038b8:	01679663          	bne	a5,s6,ffffffffc02038c4 <slub_check+0x796>
ffffffffc02038bc:	b569                	j	ffffffffc0203746 <slub_check+0x618>
ffffffffc02038be:	679c                	ld	a5,8(a5)
ffffffffc02038c0:	e96783e3          	beq	a5,s6,ffffffffc0203746 <slub_check+0x618>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc02038c4:	fb078693          	addi	a3,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc02038c8:	fed71be3          	bne	a4,a3,ffffffffc02038be <slub_check+0x790>
            if (last) { assert(find_slab(head_address) == NULL); }
ffffffffc02038cc:	00004697          	auipc	a3,0x4
ffffffffc02038d0:	c0468693          	addi	a3,a3,-1020 # ffffffffc02074d0 <buddy_system_pmm_manager+0x1580>
ffffffffc02038d4:	00001617          	auipc	a2,0x1
ffffffffc02038d8:	50460613          	addi	a2,a2,1284 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02038dc:	18d00593          	li	a1,397
ffffffffc02038e0:	00003517          	auipc	a0,0x3
ffffffffc02038e4:	90050513          	addi	a0,a0,-1792 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02038e8:	8dbfc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(replacement != NULL && (uintptr_t)replacement % ALIGNMENT == 0);
ffffffffc02038ec:	00003697          	auipc	a3,0x3
ffffffffc02038f0:	55468693          	addi	a3,a3,1364 # ffffffffc0206e40 <buddy_system_pmm_manager+0xef0>
ffffffffc02038f4:	00001617          	auipc	a2,0x1
ffffffffc02038f8:	4e460613          	addi	a2,a2,1252 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02038fc:	19100593          	li	a1,401
ffffffffc0203900:	00003517          	auipc	a0,0x3
ffffffffc0203904:	8e050513          	addi	a0,a0,-1824 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203908:	8bbfc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(nr_free_pages() == old + released);
ffffffffc020390c:	00003697          	auipc	a3,0x3
ffffffffc0203910:	50c68693          	addi	a3,a3,1292 # ffffffffc0206e18 <buddy_system_pmm_manager+0xec8>
ffffffffc0203914:	00001617          	auipc	a2,0x1
ffffffffc0203918:	4c460613          	addi	a2,a2,1220 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020391c:	18c00593          	li	a1,396
ffffffffc0203920:	00003517          	auipc	a0,0x3
ffffffffc0203924:	8c050513          	addi	a0,a0,-1856 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203928:	89bfc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            struct slab *first = find_slab(slots[0]);
ffffffffc020392c:	000d3503          	ld	a0,0(s10)
ffffffffc0203930:	008b3e03          	ld	t3,8(s6)
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc0203934:	01957733          	and	a4,a0,s9
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0203938:	7f6e0a63          	beq	t3,s6,ffffffffc020412c <slub_check+0xffe>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc020393c:	fb0e0593          	addi	a1,t3,-80
ffffffffc0203940:	86ae                	mv	a3,a1
        if ((uintptr_t)s == base) {
ffffffffc0203942:	7ce58963          	beq	a1,a4,ffffffffc0204114 <slub_check+0xfe6>
ffffffffc0203946:	87f2                	mv	a5,t3
ffffffffc0203948:	a029                	j	ffffffffc0203952 <slub_check+0x824>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc020394a:	fb078c13          	addi	s8,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc020394e:	4eec0963          	beq	s8,a4,ffffffffc0203e40 <slub_check+0xd12>
ffffffffc0203952:	679c                	ld	a5,8(a5)
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0203954:	ff679be3          	bne	a5,s6,ffffffffc020394a <slub_check+0x81c>
            assert(first != find_slab(slots[count]));
ffffffffc0203958:	00349913          	slli	s2,s1,0x3
ffffffffc020395c:	012d07b3          	add	a5,s10,s2
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc0203960:	639c                	ld	a5,0(a5)
    return NULL;
ffffffffc0203962:	4c01                	li	s8,0
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc0203964:	0197f7b3          	and	a5,a5,s9
        if ((uintptr_t)s == base) {
ffffffffc0203968:	00f58e63          	beq	a1,a5,ffffffffc0203984 <slub_check+0x856>
ffffffffc020396c:	8772                	mv	a4,t3
ffffffffc020396e:	a029                	j	ffffffffc0203978 <slub_check+0x84a>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0203970:	fb070693          	addi	a3,a4,-80
        if ((uintptr_t)s == base) {
ffffffffc0203974:	00f68663          	beq	a3,a5,ffffffffc0203980 <slub_check+0x852>
ffffffffc0203978:	6718                	ld	a4,8(a4)
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc020397a:	ff671be3          	bne	a4,s6,ffffffffc0203970 <slub_check+0x842>
    return NULL;
ffffffffc020397e:	4681                	li	a3,0
            assert(first != find_slab(slots[count]));
ffffffffc0203980:	7b868663          	beq	a3,s8,ffffffffc020412c <slub_check+0xffe>
            assert(first->used == count && first->total == count);
ffffffffc0203984:	030c3783          	ld	a5,48(s8)
ffffffffc0203988:	76979663          	bne	a5,s1,ffffffffc02040f4 <slub_check+0xfc6>
ffffffffc020398c:	028c3783          	ld	a5,40(s8)
ffffffffc0203990:	76979263          	bne	a5,s1,ffffffffc02040f4 <slub_check+0xfc6>
            assert(list_empty(&first->available));
ffffffffc0203994:	048c3783          	ld	a5,72(s8)
ffffffffc0203998:	040c0713          	addi	a4,s8,64
ffffffffc020399c:	ec3a                	sd	a4,24(sp)
ffffffffc020399e:	72f71b63          	bne	a4,a5,ffffffffc02040d4 <slub_check+0xfa6>
ffffffffc02039a2:	000a7a17          	auipc	s4,0xa7
ffffffffc02039a6:	766a0a13          	addi	s4,s4,1894 # ffffffffc02ab108 <slots.0+0x8>
ffffffffc02039aa:	8352                	mv	t1,s4
ffffffffc02039ac:	86aa                	mv	a3,a0
            for (size_t i = 0; i < count; ++i) { assert(find_slab(slots[i]) == first); }
ffffffffc02039ae:	4881                	li	a7,0
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc02039b0:	0196f6b3          	and	a3,a3,s9
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc02039b4:	872e                	mv	a4,a1
        if ((uintptr_t)s == base) {
ffffffffc02039b6:	02d58b63          	beq	a1,a3,ffffffffc02039ec <slub_check+0x8be>
ffffffffc02039ba:	87f2                	mv	a5,t3
ffffffffc02039bc:	a029                	j	ffffffffc02039c6 <slub_check+0x898>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc02039be:	fb078713          	addi	a4,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc02039c2:	02d70563          	beq	a4,a3,ffffffffc02039ec <slub_check+0x8be>
ffffffffc02039c6:	679c                	ld	a5,8(a5)
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc02039c8:	ff679be3          	bne	a5,s6,ffffffffc02039be <slub_check+0x890>
            for (size_t i = 0; i < count; ++i) { assert(find_slab(slots[i]) == first); }
ffffffffc02039cc:	00003697          	auipc	a3,0x3
ffffffffc02039d0:	5f468693          	addi	a3,a3,1524 # ffffffffc0206fc0 <buddy_system_pmm_manager+0x1070>
ffffffffc02039d4:	00001617          	auipc	a2,0x1
ffffffffc02039d8:	40460613          	addi	a2,a2,1028 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02039dc:	1ac00593          	li	a1,428
ffffffffc02039e0:	00003517          	auipc	a0,0x3
ffffffffc02039e4:	80050513          	addi	a0,a0,-2048 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02039e8:	fdafc0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc02039ec:	feec10e3          	bne	s8,a4,ffffffffc02039cc <slub_check+0x89e>
ffffffffc02039f0:	0885                	addi	a7,a7,1
ffffffffc02039f2:	0098f663          	bgeu	a7,s1,ffffffffc02039fe <slub_check+0x8d0>
ffffffffc02039f6:	00033683          	ld	a3,0(t1)
ffffffffc02039fa:	0321                	addi	t1,t1,8
ffffffffc02039fc:	bf55                	j	ffffffffc02039b0 <slub_check+0x882>
            if (count > 1) {
ffffffffc02039fe:	4785                	li	a5,1
ffffffffc0203a00:	36f49c63          	bne	s1,a5,ffffffffc0203d78 <slub_check+0xc4a>
            for (size_t i = 0; i <= count; ++i) {
ffffffffc0203a04:	4581                	li	a1,0
                    assert(((uint8_t *)slots[i])[j] == (uint8_t)(i % 251 + 1));
ffffffffc0203a06:	0fb00813          	li	a6,251
ffffffffc0203a0a:	0305f6b3          	remu	a3,a1,a6
                for (size_t j = 0; j < size; ++j) {
ffffffffc0203a0e:	4781                	li	a5,0
                    assert(((uint8_t *)slots[i])[j] == (uint8_t)(i % 251 + 1));
ffffffffc0203a10:	2685                	addiw	a3,a3,1
ffffffffc0203a12:	0ff6f693          	zext.b	a3,a3
ffffffffc0203a16:	00f50733          	add	a4,a0,a5
ffffffffc0203a1a:	00074703          	lbu	a4,0(a4)
ffffffffc0203a1e:	66d71b63          	bne	a4,a3,ffffffffc0204094 <slub_check+0xf66>
                for (size_t j = 0; j < size; ++j) {
ffffffffc0203a22:	0785                	addi	a5,a5,1
ffffffffc0203a24:	ff77e9e3          	bltu	a5,s7,ffffffffc0203a16 <slub_check+0x8e8>
            for (size_t i = 0; i <= count; ++i) {
ffffffffc0203a28:	00158793          	addi	a5,a1,1
ffffffffc0203a2c:	00b48763          	beq	s1,a1,ffffffffc0203a3a <slub_check+0x90c>
                    assert(((uint8_t *)slots[i])[j] == (uint8_t)(i % 251 + 1));
ffffffffc0203a30:	000a3503          	ld	a0,0(s4)
ffffffffc0203a34:	85be                	mv	a1,a5
ffffffffc0203a36:	0a21                	addi	s4,s4,8
ffffffffc0203a38:	bfc9                	j	ffffffffc0203a0a <slub_check+0x8dc>
ffffffffc0203a3a:	996a                	add	s2,s2,s10
                assert(nr_free_pages() == old + (last ? 1 : 0));
ffffffffc0203a3c:	4985                	li	s3,1
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc0203a3e:	00093703          	ld	a4,0(s2)
ffffffffc0203a42:	008b3783          	ld	a5,8(s6)
ffffffffc0203a46:	01977733          	and	a4,a4,s9
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0203a4a:	01679763          	bne	a5,s6,ffffffffc0203a58 <slub_check+0x92a>
ffffffffc0203a4e:	3c70006f          	j	ffffffffc0204614 <slub_check+0x14e6>
ffffffffc0203a52:	679c                	ld	a5,8(a5)
ffffffffc0203a54:	3d6780e3          	beq	a5,s6,ffffffffc0204614 <slub_check+0x14e6>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0203a58:	fb078493          	addi	s1,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc0203a5c:	fee49be3          	bne	s1,a4,ffffffffc0203a52 <slub_check+0x924>
                bool last = s->used == 1;
ffffffffc0203a60:	0304ba83          	ld	s5,48(s1)
                size_t old = nr_free_pages();
ffffffffc0203a64:	e54fe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0203a68:	8a2a                	mv	s4,a0
                kfree(slots[i]);
ffffffffc0203a6a:	00093503          	ld	a0,0(s2)
ffffffffc0203a6e:	d1cff0ef          	jal	ra,ffffffffc0202f8a <kfree>
                slots[i] = NULL;
ffffffffc0203a72:	00093023          	sd	zero,0(s2)
                assert(nr_free_pages() == old + (last ? 1 : 0));
ffffffffc0203a76:	e42fe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0203a7a:	013a8c63          	beq	s5,s3,ffffffffc0203a92 <slub_check+0x964>
ffffffffc0203a7e:	63451b63          	bne	a0,s4,ffffffffc02040b4 <slub_check+0xf86>
                slub_check_invariants();
ffffffffc0203a82:	9edfe0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
            for (size_t i = count + 1; i-- > 0;) {
ffffffffc0203a86:	ff890793          	addi	a5,s2,-8
ffffffffc0203a8a:	05a90563          	beq	s2,s10,ffffffffc0203ad4 <slub_check+0x9a6>
ffffffffc0203a8e:	893e                	mv	s2,a5
ffffffffc0203a90:	b77d                	j	ffffffffc0203a3e <slub_check+0x910>
                assert(nr_free_pages() == old + (last ? 1 : 0));
ffffffffc0203a92:	0a05                	addi	s4,s4,1
ffffffffc0203a94:	63451063          	bne	a0,s4,ffffffffc02040b4 <slub_check+0xf86>
ffffffffc0203a98:	008b3783          	ld	a5,8(s6)
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc0203a9c:	0194f4b3          	and	s1,s1,s9
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0203aa0:	01679663          	bne	a5,s6,ffffffffc0203aac <slub_check+0x97e>
ffffffffc0203aa4:	bff9                	j	ffffffffc0203a82 <slub_check+0x954>
ffffffffc0203aa6:	679c                	ld	a5,8(a5)
ffffffffc0203aa8:	fd678de3          	beq	a5,s6,ffffffffc0203a82 <slub_check+0x954>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0203aac:	fb078713          	addi	a4,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc0203ab0:	fee49be3          	bne	s1,a4,ffffffffc0203aa6 <slub_check+0x978>
                if (last) { assert(find_slab(head_address) == NULL); }
ffffffffc0203ab4:	00004697          	auipc	a3,0x4
ffffffffc0203ab8:	a1c68693          	addi	a3,a3,-1508 # ffffffffc02074d0 <buddy_system_pmm_manager+0x1580>
ffffffffc0203abc:	00001617          	auipc	a2,0x1
ffffffffc0203ac0:	31c60613          	addi	a2,a2,796 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203ac4:	1ce00593          	li	a1,462
ffffffffc0203ac8:	00002517          	auipc	a0,0x2
ffffffffc0203acc:	71850513          	addi	a0,a0,1816 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203ad0:	ef2fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
        for (size_t ci = 0; ci < CACHE_COUNT; ++ci) {
ffffffffc0203ad4:	6782                	ld	a5,0(sp)
ffffffffc0203ad6:	00007717          	auipc	a4,0x7
ffffffffc0203ada:	61a70713          	addi	a4,a4,1562 # ffffffffc020b0f0 <free_blocks.2>
ffffffffc0203ade:	07e1                	addi	a5,a5,24
ffffffffc0203ae0:	e03e                	sd	a5,0(sp)
ffffffffc0203ae2:	cce79ce3          	bne	a5,a4,ffffffffc02037ba <slub_check+0x68c>
        void *kept = kmalloc(caches[0].size);
ffffffffc0203ae6:	6008                	ld	a0,0(s0)
    if (size == 0) {
ffffffffc0203ae8:	72050263          	beqz	a0,ffffffffc020420c <slub_check+0x10de>
ffffffffc0203aec:	b10ff0ef          	jal	ra,ffffffffc0202dfc <kmalloc.part.0>
ffffffffc0203af0:	8a2a                	mv	s4,a0
        assert(kept != NULL);
ffffffffc0203af2:	70050d63          	beqz	a0,ffffffffc020420c <slub_check+0x10de>
        memset(kept, 0xa5, caches[0].size);
ffffffffc0203af6:	6010                	ld	a2,0(s0)
ffffffffc0203af8:	0a500593          	li	a1,165
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc0203afc:	8aaa                	mv	s5,a0
        memset(kept, 0xa5, caches[0].size);
ffffffffc0203afe:	7fb000ef          	jal	ra,ffffffffc0204af8 <memset>
ffffffffc0203b02:	008b3783          	ld	a5,8(s6)
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc0203b06:	019a7bb3          	and	s7,s4,s9
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0203b0a:	01679763          	bne	a5,s6,ffffffffc0203b18 <slub_check+0x9ea>
ffffffffc0203b0e:	3070006f          	j	ffffffffc0204614 <slub_check+0x14e6>
ffffffffc0203b12:	679c                	ld	a5,8(a5)
ffffffffc0203b14:	316780e3          	beq	a5,s6,ffffffffc0204614 <slub_check+0x14e6>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0203b18:	fb078493          	addi	s1,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc0203b1c:	ff749be3          	bne	s1,s7,ffffffffc0203b12 <slub_check+0x9e4>
        assert(s->used == 1 && s->total > 1);
ffffffffc0203b20:	0304bd03          	ld	s10,48(s1)
ffffffffc0203b24:	4785                	li	a5,1
ffffffffc0203b26:	70fd1363          	bne	s10,a5,ffffffffc020422c <slub_check+0x10fe>
ffffffffc0203b2a:	749c                	ld	a5,40(s1)
ffffffffc0203b2c:	00fd6463          	bltu	s10,a5,ffffffffc0203b34 <slub_check+0xa06>
ffffffffc0203b30:	adf5                	j	ffffffffc020422c <slub_check+0x10fe>
        while (count <= nr_free_pages() / 2) { count *= 2; }
ffffffffc0203b32:	0d06                	slli	s10,s10,0x1
ffffffffc0203b34:	d84fe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0203b38:	00155793          	srli	a5,a0,0x1
ffffffffc0203b3c:	ffa7fbe3          	bgeu	a5,s10,ffffffffc0203b32 <slub_check+0xa04>
ffffffffc0203b40:	00027997          	auipc	s3,0x27
ffffffffc0203b44:	5b098993          	addi	s3,s3,1456 # ffffffffc022b0f0 <held.1>
                assert(held_count < PAGE_LIMIT && !PageReserved(page));
ffffffffc0203b48:	6921                	lui	s2,0x8
ffffffffc0203b4a:	004d9c13          	slli	s8,s11,0x4
ffffffffc0203b4e:	9c4e                	add	s8,s8,s3
ffffffffc0203b50:	a00d                	j	ffffffffc0203b72 <slub_check+0xa44>
ffffffffc0203b52:	752dfd63          	bgeu	s11,s2,ffffffffc02042ac <slub_check+0x117e>
ffffffffc0203b56:	651c                	ld	a5,8(a0)
ffffffffc0203b58:	8b85                	andi	a5,a5,1
ffffffffc0203b5a:	74079963          	bnez	a5,ffffffffc02042ac <slub_check+0x117e>
                assert(page->property == count);
ffffffffc0203b5e:	01056783          	lwu	a5,16(a0)
ffffffffc0203b62:	6fa79563          	bne	a5,s10,ffffffffc020424c <slub_check+0x111e>
                held[held_count].page = page;
ffffffffc0203b66:	00ac3023          	sd	a0,0(s8)
                held[held_count++].count = count;
ffffffffc0203b6a:	01ac3423          	sd	s10,8(s8)
ffffffffc0203b6e:	0d85                	addi	s11,s11,1
ffffffffc0203b70:	0c41                	addi	s8,s8,16
            while ((page = alloc_pages(count)) != NULL) {
ffffffffc0203b72:	856a                	mv	a0,s10
ffffffffc0203b74:	d2cfe0ef          	jal	ra,ffffffffc02020a0 <alloc_pages>
ffffffffc0203b78:	fd69                	bnez	a0,ffffffffc0203b52 <slub_check+0xa24>
        for (; count != 0; count /= 2) {
ffffffffc0203b7a:	001d5d13          	srli	s10,s10,0x1
ffffffffc0203b7e:	fc0d16e3          	bnez	s10,ffffffffc0203b4a <slub_check+0xa1c>
        assert(nr_free_pages() == 0);
ffffffffc0203b82:	d36fe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0203b86:	6e051363          	bnez	a0,ffffffffc020426c <slub_check+0x113e>
        struct slab saved = *s;
ffffffffc0203b8a:	8726                	mv	a4,s1
ffffffffc0203b8c:	071c                	addi	a5,sp,896
ffffffffc0203b8e:	08048693          	addi	a3,s1,128
ffffffffc0203b92:	00073803          	ld	a6,0(a4)
ffffffffc0203b96:	6708                	ld	a0,8(a4)
ffffffffc0203b98:	6b0c                	ld	a1,16(a4)
ffffffffc0203b9a:	6f10                	ld	a2,24(a4)
ffffffffc0203b9c:	0107b023          	sd	a6,0(a5)
ffffffffc0203ba0:	e788                	sd	a0,8(a5)
ffffffffc0203ba2:	eb8c                	sd	a1,16(a5)
ffffffffc0203ba4:	ef90                	sd	a2,24(a5)
ffffffffc0203ba6:	02070713          	addi	a4,a4,32
ffffffffc0203baa:	02078793          	addi	a5,a5,32
ffffffffc0203bae:	fed712e3          	bne	a4,a3,ffffffffc0203b92 <slub_check+0xa64>
        memcpy(saved_caches, caches, sizeof(caches));
ffffffffc0203bb2:	6785                	lui	a5,0x1
ffffffffc0203bb4:	1898                	addi	a4,sp,112
ffffffffc0203bb6:	4a078793          	addi	a5,a5,1184 # 14a0 <kern_entry-0xffffffffc01feb60>
ffffffffc0203bba:	97ba                	add	a5,a5,a4
ffffffffc0203bbc:	f80c8513          	addi	a0,s9,-128
ffffffffc0203bc0:	953e                	add	a0,a0,a5
ffffffffc0203bc2:	0c000613          	li	a2,192
ffffffffc0203bc6:	00007597          	auipc	a1,0x7
ffffffffc0203bca:	46a58593          	addi	a1,a1,1130 # ffffffffc020b030 <caches>
ffffffffc0203bce:	73d000ef          	jal	ra,ffffffffc0204b0a <memcpy>
        list_entry_t saved_live = live;
ffffffffc0203bd2:	000b3703          	ld	a4,0(s6)
ffffffffc0203bd6:	008b3783          	ld	a5,8(s6)
ffffffffc0203bda:	6c26                	ld	s8,72(sp)
ffffffffc0203bdc:	f93a                	sd	a4,176(sp)
ffffffffc0203bde:	fd3e                	sd	a5,184(sp)
        for (size_t ci = 1; ci < CACHE_COUNT; ++ci) {
ffffffffc0203be0:	00007917          	auipc	s2,0x7
ffffffffc0203be4:	4f890913          	addi	s2,s2,1272 # ffffffffc020b0d8 <caches+0xa8>
            assert(kmalloc(caches[ci].size) == NULL);
ffffffffc0203be8:	018c3503          	ld	a0,24(s8)
    if (size == 0) {
ffffffffc0203bec:	c509                	beqz	a0,ffffffffc0203bf6 <slub_check+0xac8>
ffffffffc0203bee:	a0eff0ef          	jal	ra,ffffffffc0202dfc <kmalloc.part.0>
            assert(kmalloc(caches[ci].size) == NULL);
ffffffffc0203bf2:	68051d63          	bnez	a0,ffffffffc020428c <slub_check+0x115e>
        for (size_t ci = 1; ci < CACHE_COUNT; ++ci) {
ffffffffc0203bf6:	0c61                	addi	s8,s8,24
            slub_check_invariants();
ffffffffc0203bf8:	877fe0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
        for (size_t ci = 1; ci < CACHE_COUNT; ++ci) {
ffffffffc0203bfc:	ff2c16e3          	bne	s8,s2,ffffffffc0203be8 <slub_check+0xaba>
        assert(kmalloc(caches[CACHE_COUNT - 1].size + 1) == NULL);
ffffffffc0203c00:	7448                	ld	a0,168(s0)
ffffffffc0203c02:	0505                	addi	a0,a0,1
    if (size == 0) {
ffffffffc0203c04:	c509                	beqz	a0,ffffffffc0203c0e <slub_check+0xae0>
ffffffffc0203c06:	9f6ff0ef          	jal	ra,ffffffffc0202dfc <kmalloc.part.0>
        assert(kmalloc(caches[CACHE_COUNT - 1].size + 1) == NULL);
ffffffffc0203c0a:	6c051163          	bnez	a0,ffffffffc02042cc <slub_check+0x119e>
        assert(nr_free_pages() == 0 && memcmp(&saved, s, HEADER_SIZE) == 0);
ffffffffc0203c0e:	caafe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0203c12:	70051d63          	bnez	a0,ffffffffc020432c <slub_check+0x11fe>
ffffffffc0203c16:	6905                	lui	s2,0x1
ffffffffc0203c18:	4a090793          	addi	a5,s2,1184 # 14a0 <kern_entry-0xffffffffc01feb60>
ffffffffc0203c1c:	1898                	addi	a4,sp,112
ffffffffc0203c1e:	e70c8513          	addi	a0,s9,-400
ffffffffc0203c22:	97ba                	add	a5,a5,a4
ffffffffc0203c24:	08000613          	li	a2,128
ffffffffc0203c28:	85a6                	mv	a1,s1
ffffffffc0203c2a:	953e                	add	a0,a0,a5
ffffffffc0203c2c:	6f7000ef          	jal	ra,ffffffffc0204b22 <memcmp>
ffffffffc0203c30:	6e051e63          	bnez	a0,ffffffffc020432c <slub_check+0x11fe>
        assert(memcmp(saved_caches, caches, sizeof(caches)) == 0);
ffffffffc0203c34:	4a090793          	addi	a5,s2,1184
ffffffffc0203c38:	1898                	addi	a4,sp,112
ffffffffc0203c3a:	f80c8513          	addi	a0,s9,-128
ffffffffc0203c3e:	97ba                	add	a5,a5,a4
ffffffffc0203c40:	0c000613          	li	a2,192
ffffffffc0203c44:	00007597          	auipc	a1,0x7
ffffffffc0203c48:	3ec58593          	addi	a1,a1,1004 # ffffffffc020b030 <caches>
ffffffffc0203c4c:	953e                	add	a0,a0,a5
ffffffffc0203c4e:	6d5000ef          	jal	ra,ffffffffc0204b22 <memcmp>
ffffffffc0203c52:	6a051d63          	bnez	a0,ffffffffc020430c <slub_check+0x11de>
        assert(memcmp(&saved_live, &live, sizeof(live)) == 0);
ffffffffc0203c56:	6785                	lui	a5,0x1
ffffffffc0203c58:	4a078793          	addi	a5,a5,1184 # 14a0 <kern_entry-0xffffffffc01feb60>
ffffffffc0203c5c:	1898                	addi	a4,sp,112
ffffffffc0203c5e:	ba0c8513          	addi	a0,s9,-1120
ffffffffc0203c62:	97ba                	add	a5,a5,a4
ffffffffc0203c64:	4641                	li	a2,16
ffffffffc0203c66:	000a7597          	auipc	a1,0xa7
ffffffffc0203c6a:	48a58593          	addi	a1,a1,1162 # ffffffffc02ab0f0 <live>
ffffffffc0203c6e:	953e                	add	a0,a0,a5
ffffffffc0203c70:	6b3000ef          	jal	ra,ffffffffc0204b22 <memcmp>
ffffffffc0203c74:	6c051c63          	bnez	a0,ffffffffc020434c <slub_check+0x121e>
        void *reused = kmalloc(caches[0].size);
ffffffffc0203c78:	6008                	ld	a0,0(s0)
    if (size == 0) {
ffffffffc0203c7a:	66050963          	beqz	a0,ffffffffc02042ec <slub_check+0x11be>
ffffffffc0203c7e:	97eff0ef          	jal	ra,ffffffffc0202dfc <kmalloc.part.0>
ffffffffc0203c82:	892a                	mv	s2,a0
        assert(reused != NULL && reused != kept && find_slab(reused) == s);
ffffffffc0203c84:	66050463          	beqz	a0,ffffffffc02042ec <slub_check+0x11be>
ffffffffc0203c88:	66aa0263          	beq	s4,a0,ffffffffc02042ec <slub_check+0x11be>
ffffffffc0203c8c:	008b3783          	ld	a5,8(s6)
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc0203c90:	8c2a                	mv	s8,a0
ffffffffc0203c92:	019576b3          	and	a3,a0,s9
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0203c96:	01679663          	bne	a5,s6,ffffffffc0203ca2 <slub_check+0xb74>
ffffffffc0203c9a:	ad89                	j	ffffffffc02042ec <slub_check+0x11be>
ffffffffc0203c9c:	679c                	ld	a5,8(a5)
ffffffffc0203c9e:	65678763          	beq	a5,s6,ffffffffc02042ec <slub_check+0x11be>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0203ca2:	fb078713          	addi	a4,a5,-80
        if ((uintptr_t)s == base) {
ffffffffc0203ca6:	fed71be3          	bne	a4,a3,ffffffffc0203c9c <slub_check+0xb6e>
        assert(reused != NULL && reused != kept && find_slab(reused) == s);
ffffffffc0203caa:	64e49163          	bne	s1,a4,ffffffffc02042ec <slub_check+0x11be>
        assert(s->used == 2 && nr_free_pages() == 0);
ffffffffc0203cae:	7898                	ld	a4,48(s1)
ffffffffc0203cb0:	4789                	li	a5,2
ffffffffc0203cb2:	6cf71d63          	bne	a4,a5,ffffffffc020438c <slub_check+0x125e>
ffffffffc0203cb6:	c02fe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0203cba:	6c051963          	bnez	a0,ffffffffc020438c <slub_check+0x125e>
        memset(reused, 0x5a, caches[0].size);
ffffffffc0203cbe:	6010                	ld	a2,0(s0)
ffffffffc0203cc0:	05a00593          	li	a1,90
ffffffffc0203cc4:	854a                	mv	a0,s2
ffffffffc0203cc6:	633000ef          	jal	ra,ffffffffc0204af8 <memset>
        for (size_t i = 0; i < caches[0].size; ++i) {
ffffffffc0203cca:	601c                	ld	a5,0(s0)
ffffffffc0203ccc:	c395                	beqz	a5,ffffffffc0203cf0 <slub_check+0xbc2>
ffffffffc0203cce:	97d2                	add	a5,a5,s4
            assert(((uint8_t *)kept)[i] == 0xa5 && ((uint8_t *)reused)[i] == 0x5a);
ffffffffc0203cd0:	0a500693          	li	a3,165
ffffffffc0203cd4:	05a00713          	li	a4,90
ffffffffc0203cd8:	000ac603          	lbu	a2,0(s5)
ffffffffc0203cdc:	68d61863          	bne	a2,a3,ffffffffc020436c <slub_check+0x123e>
ffffffffc0203ce0:	000c4603          	lbu	a2,0(s8)
ffffffffc0203ce4:	68e61463          	bne	a2,a4,ffffffffc020436c <slub_check+0x123e>
        for (size_t i = 0; i < caches[0].size; ++i) {
ffffffffc0203ce8:	0a85                	addi	s5,s5,1
ffffffffc0203cea:	0c05                	addi	s8,s8,1
ffffffffc0203cec:	ff5796e3          	bne	a5,s5,ffffffffc0203cd8 <slub_check+0xbaa>
        slub_check_invariants();
ffffffffc0203cf0:	f7efe0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
        while (held_count != 0) {
ffffffffc0203cf4:	004d9793          	slli	a5,s11,0x4
ffffffffc0203cf8:	17c1                	addi	a5,a5,-16
ffffffffc0203cfa:	99be                	add	s3,s3,a5
ffffffffc0203cfc:	020d8063          	beqz	s11,ffffffffc0203d1c <slub_check+0xbee>
            free_pages(held[held_count].page, held[held_count].count);
ffffffffc0203d00:	0089b583          	ld	a1,8(s3)
ffffffffc0203d04:	0009b503          	ld	a0,0(s3)
        while (held_count != 0) {
ffffffffc0203d08:	19c1                	addi	s3,s3,-16
            --held_count;
ffffffffc0203d0a:	1dfd                	addi	s11,s11,-1
            free_pages(held[held_count].page, held[held_count].count);
ffffffffc0203d0c:	ba0fe0ef          	jal	ra,ffffffffc02020ac <free_pages>
            held[held_count].page = NULL;
ffffffffc0203d10:	0009b823          	sd	zero,16(s3)
            held[held_count].count = 0;
ffffffffc0203d14:	0009bc23          	sd	zero,24(s3)
        while (held_count != 0) {
ffffffffc0203d18:	fe0d94e3          	bnez	s11,ffffffffc0203d00 <slub_check+0xbd2>
        kfree(reused);
ffffffffc0203d1c:	854a                	mv	a0,s2
ffffffffc0203d1e:	a6cff0ef          	jal	ra,ffffffffc0202f8a <kfree>
        assert(nr_free_pages() == before - 1);
ffffffffc0203d22:	b96fe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0203d26:	7782                	ld	a5,32(sp)
ffffffffc0203d28:	17fd                	addi	a5,a5,-1
ffffffffc0203d2a:	68f51163          	bne	a0,a5,ffffffffc02043ac <slub_check+0x127e>
        kfree(kept);
ffffffffc0203d2e:	8552                	mv	a0,s4
ffffffffc0203d30:	a5aff0ef          	jal	ra,ffffffffc0202f8a <kfree>
ffffffffc0203d34:	008b3703          	ld	a4,8(s6)
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0203d38:	6b670a63          	beq	a4,s6,ffffffffc02043ec <slub_check+0x12be>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0203d3c:	fb070693          	addi	a3,a4,-80
        if ((uintptr_t)s == base) {
ffffffffc0203d40:	00db9763          	bne	s7,a3,ffffffffc0203d4e <slub_check+0xc20>
ffffffffc0203d44:	a561                	j	ffffffffc02043cc <slub_check+0x129e>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0203d46:	fb070793          	addi	a5,a4,-80
        if ((uintptr_t)s == base) {
ffffffffc0203d4a:	68fb8163          	beq	s7,a5,ffffffffc02043cc <slub_check+0x129e>
ffffffffc0203d4e:	6718                	ld	a4,8(a4)
    for (list_entry_t *le = list_next(&live); le != &live; le = list_next(le)) {
ffffffffc0203d50:	ff671be3          	bne	a4,s6,ffffffffc0203d46 <slub_check+0xc18>
        slub_check_invariants();
ffffffffc0203d54:	f1afe0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
        assert(list_empty(&live) && nr_free_pages() == before);
ffffffffc0203d58:	00003697          	auipc	a3,0x3
ffffffffc0203d5c:	57868693          	addi	a3,a3,1400 # ffffffffc02072d0 <buddy_system_pmm_manager+0x1380>
ffffffffc0203d60:	00001617          	auipc	a2,0x1
ffffffffc0203d64:	07860613          	addi	a2,a2,120 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203d68:	20800593          	li	a1,520
ffffffffc0203d6c:	00002517          	auipc	a0,0x2
ffffffffc0203d70:	47450513          	addi	a0,a0,1140 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203d74:	c4efc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                size_t holes = count / 2;
ffffffffc0203d78:	0014d793          	srli	a5,s1,0x1
ffffffffc0203d7c:	ecbe                	sd	a5,88(sp)
                for (size_t i = 0; i < holes; ++i) {
ffffffffc0203d7e:	40f487b3          	sub	a5,s1,a5
ffffffffc0203d82:	e8be                	sd	a5,80(sp)
                size_t holes = count / 2;
ffffffffc0203d84:	000a7a97          	auipc	s5,0xa7
ffffffffc0203d88:	384a8a93          	addi	s5,s5,900 # ffffffffc02ab108 <slots.0+0x8>
ffffffffc0203d8c:	a029                	j	ffffffffc0203d96 <slub_check+0xc68>
                    kfree(slots[i]);
ffffffffc0203d8e:	000ab503          	ld	a0,0(s5)
ffffffffc0203d92:	19fd                	addi	s3,s3,-1
ffffffffc0203d94:	0aa1                	addi	s5,s5,8
ffffffffc0203d96:	9f4ff0ef          	jal	ra,ffffffffc0202f8a <kfree>
                    assert(first->used == count - i - 1);
ffffffffc0203d9a:	030c3783          	ld	a5,48(s8)
ffffffffc0203d9e:	45379763          	bne	a5,s3,ffffffffc02041ec <slub_check+0x10be>
                    assert(!list_empty(&first->available));
ffffffffc0203da2:	048c3783          	ld	a5,72(s8)
ffffffffc0203da6:	6762                	ld	a4,24(sp)
ffffffffc0203da8:	42f70263          	beq	a4,a5,ffffffffc02041cc <slub_check+0x109e>
                    assert(nr_free_pages() == before - 2);
ffffffffc0203dac:	b0cfe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0203db0:	67a2                	ld	a5,8(sp)
ffffffffc0203db2:	3ef51d63          	bne	a0,a5,ffffffffc02041ac <slub_check+0x107e>
                    slub_check_invariants();
ffffffffc0203db6:	eb8fe0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
                for (size_t i = 0; i < holes; ++i) {
ffffffffc0203dba:	67c6                	ld	a5,80(sp)
ffffffffc0203dbc:	fcf999e3          	bne	s3,a5,ffffffffc0203d8e <slub_check+0xc60>
                for (size_t i = holes; i-- > 0;) {
ffffffffc0203dc0:	67e6                	ld	a5,88(sp)
ffffffffc0203dc2:	00379a93          	slli	s5,a5,0x3
ffffffffc0203dc6:	1ae1                	addi	s5,s5,-8
ffffffffc0203dc8:	fff78993          	addi	s3,a5,-1
ffffffffc0203dcc:	9aea                	add	s5,s5,s10
    if (size == 0) {
ffffffffc0203dce:	855e                	mv	a0,s7
ffffffffc0203dd0:	82cff0ef          	jal	ra,ffffffffc0202dfc <kmalloc.part.0>
                    assert(replacement == slots[i]);
ffffffffc0203dd4:	000ab783          	ld	a5,0(s5)
ffffffffc0203dd8:	3aa79a63          	bne	a5,a0,ffffffffc020418c <slub_check+0x105e>
                    memset(replacement, (int)(i % 251) + 1, size);
ffffffffc0203ddc:	0fb00793          	li	a5,251
ffffffffc0203de0:	02f9f5b3          	remu	a1,s3,a5
ffffffffc0203de4:	865e                	mv	a2,s7
ffffffffc0203de6:	2585                	addiw	a1,a1,1
ffffffffc0203de8:	0ff5f593          	zext.b	a1,a1
ffffffffc0203dec:	50d000ef          	jal	ra,ffffffffc0204af8 <memset>
                    assert(nr_free_pages() == before - 2);
ffffffffc0203df0:	ac8fe0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc0203df4:	67a2                	ld	a5,8(sp)
ffffffffc0203df6:	36a79b63          	bne	a5,a0,ffffffffc020416c <slub_check+0x103e>
                    slub_check_invariants();
ffffffffc0203dfa:	e74fe0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
                for (size_t i = holes; i-- > 0;) {
ffffffffc0203dfe:	19fd                	addi	s3,s3,-1
ffffffffc0203e00:	57fd                	li	a5,-1
ffffffffc0203e02:	1ae1                	addi	s5,s5,-8
ffffffffc0203e04:	fcf995e3          	bne	s3,a5,ffffffffc0203dce <slub_check+0xca0>
                assert(first->used == count && list_empty(&first->available));
ffffffffc0203e08:	030c3783          	ld	a5,48(s8)
ffffffffc0203e0c:	34979063          	bne	a5,s1,ffffffffc020414c <slub_check+0x101e>
ffffffffc0203e10:	048c3783          	ld	a5,72(s8)
ffffffffc0203e14:	6762                	ld	a4,24(sp)
ffffffffc0203e16:	32f71b63          	bne	a4,a5,ffffffffc020414c <slub_check+0x101e>
                    assert(((uint8_t *)slots[i])[j] == (uint8_t)(i % 251 + 1));
ffffffffc0203e1a:	000d3503          	ld	a0,0(s10)
ffffffffc0203e1e:	b6dd                	j	ffffffffc0203a04 <slub_check+0x8d6>
                assert((uintptr_t)ptrs[i] + sizes[i] <= (uintptr_t)ptrs[j] ||
ffffffffc0203e20:	00003697          	auipc	a3,0x3
ffffffffc0203e24:	e3868693          	addi	a3,a3,-456 # ffffffffc0206c58 <buddy_system_pmm_manager+0xd08>
ffffffffc0203e28:	00001617          	auipc	a2,0x1
ffffffffc0203e2c:	fb060613          	addi	a2,a2,-80 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203e30:	15400593          	li	a1,340
ffffffffc0203e34:	00002517          	auipc	a0,0x2
ffffffffc0203e38:	3ac50513          	addi	a0,a0,940 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203e3c:	b86fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(first != find_slab(slots[count]));
ffffffffc0203e40:	00349913          	slli	s2,s1,0x3
ffffffffc0203e44:	012d07b3          	add	a5,s10,s2
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc0203e48:	639c                	ld	a5,0(a5)
ffffffffc0203e4a:	0197f7b3          	and	a5,a5,s9
        if ((uintptr_t)s == base) {
ffffffffc0203e4e:	b0f59fe3          	bne	a1,a5,ffffffffc020396c <slub_check+0x83e>
ffffffffc0203e52:	b63d                	j	ffffffffc0203980 <slub_check+0x852>
                assert(find_slab(slots[i])->cache == &caches[ci]);
ffffffffc0203e54:	00003697          	auipc	a3,0x3
ffffffffc0203e58:	0b468693          	addi	a3,a3,180 # ffffffffc0206f08 <buddy_system_pmm_manager+0xfb8>
ffffffffc0203e5c:	00001617          	auipc	a2,0x1
ffffffffc0203e60:	f7c60613          	addi	a2,a2,-132 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203e64:	1a300593          	li	a1,419
ffffffffc0203e68:	00002517          	auipc	a0,0x2
ffffffffc0203e6c:	37850513          	addi	a0,a0,888 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203e70:	b52fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(count > 0 && count <= MAX_SLOTS);
ffffffffc0203e74:	00003697          	auipc	a3,0x3
ffffffffc0203e78:	03468693          	addi	a3,a3,52 # ffffffffc0206ea8 <buddy_system_pmm_manager+0xf58>
ffffffffc0203e7c:	00001617          	auipc	a2,0x1
ffffffffc0203e80:	f5c60613          	addi	a2,a2,-164 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203e84:	19f00593          	li	a1,415
ffffffffc0203e88:	00002517          	auipc	a0,0x2
ffffffffc0203e8c:	35850513          	addi	a0,a0,856 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203e90:	b32fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(ptrs[i] == objects(s) && (uintptr_t)ptrs[i] < (uintptr_t)s + PGSIZE);
ffffffffc0203e94:	00003697          	auipc	a3,0x3
ffffffffc0203e98:	d0c68693          	addi	a3,a3,-756 # ffffffffc0206ba0 <buddy_system_pmm_manager+0xc50>
ffffffffc0203e9c:	00001617          	auipc	a2,0x1
ffffffffc0203ea0:	f3c60613          	addi	a2,a2,-196 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203ea4:	14f00593          	li	a1,335
ffffffffc0203ea8:	00002517          	auipc	a0,0x2
ffffffffc0203eac:	33850513          	addi	a0,a0,824 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203eb0:	b12fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(old - nr_free_pages() == (fresh ? 1 : 0));
ffffffffc0203eb4:	00003697          	auipc	a3,0x3
ffffffffc0203eb8:	c8c68693          	addi	a3,a3,-884 # ffffffffc0206b40 <buddy_system_pmm_manager+0xbf0>
ffffffffc0203ebc:	00001617          	auipc	a2,0x1
ffffffffc0203ec0:	f1c60613          	addi	a2,a2,-228 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203ec4:	14900593          	li	a1,329
ffffffffc0203ec8:	00002517          	auipc	a0,0x2
ffffffffc0203ecc:	31850513          	addi	a0,a0,792 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203ed0:	af2fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(s->total == (PGSIZE - HEADER_SIZE) / caches[ci].size);
ffffffffc0203ed4:	00003697          	auipc	a3,0x3
ffffffffc0203ed8:	c3468693          	addi	a3,a3,-972 # ffffffffc0206b08 <buddy_system_pmm_manager+0xbb8>
ffffffffc0203edc:	00001617          	auipc	a2,0x1
ffffffffc0203ee0:	efc60613          	addi	a2,a2,-260 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203ee4:	14800593          	li	a1,328
ffffffffc0203ee8:	00002517          	auipc	a0,0x2
ffffffffc0203eec:	2f850513          	addi	a0,a0,760 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203ef0:	ad2fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(ci == 0 || caches[ci - 1].size < sizes[i]);
ffffffffc0203ef4:	00003697          	auipc	a3,0x3
ffffffffc0203ef8:	be468693          	addi	a3,a3,-1052 # ffffffffc0206ad8 <buddy_system_pmm_manager+0xb88>
ffffffffc0203efc:	00001617          	auipc	a2,0x1
ffffffffc0203f00:	edc60613          	addi	a2,a2,-292 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203f04:	14700593          	li	a1,327
ffffffffc0203f08:	00002517          	auipc	a0,0x2
ffffffffc0203f0c:	2d850513          	addi	a0,a0,728 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203f10:	ab2fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(s->kind == SMALL && s->cache == &caches[ci]);
ffffffffc0203f14:	00003697          	auipc	a3,0x3
ffffffffc0203f18:	b9468693          	addi	a3,a3,-1132 # ffffffffc0206aa8 <buddy_system_pmm_manager+0xb58>
ffffffffc0203f1c:	00001617          	auipc	a2,0x1
ffffffffc0203f20:	ebc60613          	addi	a2,a2,-324 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203f24:	14600593          	li	a1,326
ffffffffc0203f28:	00002517          	auipc	a0,0x2
ffffffffc0203f2c:	2b850513          	addi	a0,a0,696 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203f30:	a92fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(sum == before);
ffffffffc0203f34:	00003697          	auipc	a3,0x3
ffffffffc0203f38:	b2c68693          	addi	a3,a3,-1236 # ffffffffc0206a60 <buddy_system_pmm_manager+0xb10>
ffffffffc0203f3c:	00001617          	auipc	a2,0x1
ffffffffc0203f40:	e9c60613          	addi	a2,a2,-356 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203f44:	12f00593          	li	a1,303
ffffffffc0203f48:	00002517          	auipc	a0,0x2
ffffffffc0203f4c:	29850513          	addi	a0,a0,664 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203f50:	a72fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(npage > nbase && npage - nbase <= PAGE_LIMIT && list_empty(&live));
ffffffffc0203f54:	00003697          	auipc	a3,0x3
ffffffffc0203f58:	ac468693          	addi	a3,a3,-1340 # ffffffffc0206a18 <buddy_system_pmm_manager+0xac8>
ffffffffc0203f5c:	00001617          	auipc	a2,0x1
ffffffffc0203f60:	e7c60613          	addi	a2,a2,-388 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203f64:	12900593          	li	a1,297
ffffffffc0203f68:	00002517          	auipc	a0,0x2
ffffffffc0203f6c:	27850513          	addi	a0,a0,632 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203f70:	a52fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(memcmp(&saved[i], heads[i], HEADER_SIZE) == 0);
ffffffffc0203f74:	00003697          	auipc	a3,0x3
ffffffffc0203f78:	df468693          	addi	a3,a3,-524 # ffffffffc0206d68 <buddy_system_pmm_manager+0xe18>
ffffffffc0203f7c:	00001617          	auipc	a2,0x1
ffffffffc0203f80:	e5c60613          	addi	a2,a2,-420 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203f84:	17400593          	li	a1,372
ffffffffc0203f88:	00002517          	auipc	a0,0x2
ffffffffc0203f8c:	25850513          	addi	a0,a0,600 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203f90:	a32fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert((PageProperty(&pages[i]) ? pages[i].property : 0) == held[i].count);
ffffffffc0203f94:	00003697          	auipc	a3,0x3
ffffffffc0203f98:	e0468693          	addi	a3,a3,-508 # ffffffffc0206d98 <buddy_system_pmm_manager+0xe48>
ffffffffc0203f9c:	00001617          	auipc	a2,0x1
ffffffffc0203fa0:	e3c60613          	addi	a2,a2,-452 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203fa4:	17700593          	li	a1,375
ffffffffc0203fa8:	00002517          	auipc	a0,0x2
ffffffffc0203fac:	23850513          	addi	a0,a0,568 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203fb0:	a12fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(((uint8_t *)replacement)[k] == 0xe7);
ffffffffc0203fb4:	00003697          	auipc	a3,0x3
ffffffffc0203fb8:	ecc68693          	addi	a3,a3,-308 # ffffffffc0206e80 <buddy_system_pmm_manager+0xf30>
ffffffffc0203fbc:	00001617          	auipc	a2,0x1
ffffffffc0203fc0:	e1c60613          	addi	a2,a2,-484 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203fc4:	19500593          	li	a1,405
ffffffffc0203fc8:	00002517          	auipc	a0,0x2
ffffffffc0203fcc:	21850513          	addi	a0,a0,536 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203fd0:	9f2fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(s->kind == LARGE && s->npages == expected);
ffffffffc0203fd4:	00003697          	auipc	a3,0x3
ffffffffc0203fd8:	b9c68693          	addi	a3,a3,-1124 # ffffffffc0206b70 <buddy_system_pmm_manager+0xc20>
ffffffffc0203fdc:	00001617          	auipc	a2,0x1
ffffffffc0203fe0:	dfc60613          	addi	a2,a2,-516 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0203fe4:	14e00593          	li	a1,334
ffffffffc0203fe8:	00002517          	auipc	a0,0x2
ffffffffc0203fec:	1f850513          	addi	a0,a0,504 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0203ff0:	9d2fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert((uintptr_t)ptrs[i] + sizes[i] <= (uintptr_t)s + expected * PGSIZE);
ffffffffc0203ff4:	00003697          	auipc	a3,0x3
ffffffffc0203ff8:	bf468693          	addi	a3,a3,-1036 # ffffffffc0206be8 <buddy_system_pmm_manager+0xc98>
ffffffffc0203ffc:	00001617          	auipc	a2,0x1
ffffffffc0204000:	ddc60613          	addi	a2,a2,-548 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0204004:	15000593          	li	a1,336
ffffffffc0204008:	00002517          	auipc	a0,0x2
ffffffffc020400c:	1d850513          	addi	a0,a0,472 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204010:	9b2fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(memcmp(saved_caches, caches, sizeof(caches)) == 0);
ffffffffc0204014:	00003697          	auipc	a3,0x3
ffffffffc0204018:	d1c68693          	addi	a3,a3,-740 # ffffffffc0206d30 <buddy_system_pmm_manager+0xde0>
ffffffffc020401c:	00001617          	auipc	a2,0x1
ffffffffc0204020:	dbc60613          	addi	a2,a2,-580 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0204024:	17200593          	li	a1,370
ffffffffc0204028:	00002517          	auipc	a0,0x2
ffffffffc020402c:	1b850513          	addi	a0,a0,440 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204030:	992fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(memcmp(&saved_live, &live, sizeof(live)) == 0);
ffffffffc0204034:	00003697          	auipc	a3,0x3
ffffffffc0204038:	ccc68693          	addi	a3,a3,-820 # ffffffffc0206d00 <buddy_system_pmm_manager+0xdb0>
ffffffffc020403c:	00001617          	auipc	a2,0x1
ffffffffc0204040:	d9c60613          	addi	a2,a2,-612 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0204044:	17100593          	li	a1,369
ffffffffc0204048:	00002517          	auipc	a0,0x2
ffffffffc020404c:	19850513          	addi	a0,a0,408 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204050:	972fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(kmalloc(failures[f]) == NULL && nr_free_pages() == old);
ffffffffc0204054:	00003697          	auipc	a3,0x3
ffffffffc0204058:	c7468693          	addi	a3,a3,-908 # ffffffffc0206cc8 <buddy_system_pmm_manager+0xd78>
ffffffffc020405c:	00001617          	auipc	a2,0x1
ffffffffc0204060:	d7c60613          	addi	a2,a2,-644 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0204064:	17000593          	li	a1,368
ffffffffc0204068:	00002517          	auipc	a0,0x2
ffffffffc020406c:	17850513          	addi	a0,a0,376 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204070:	952fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(nr_free_pages() == before - (i < count ? 1 : 2));
ffffffffc0204074:	00003697          	auipc	a3,0x3
ffffffffc0204078:	ec468693          	addi	a3,a3,-316 # ffffffffc0206f38 <buddy_system_pmm_manager+0xfe8>
ffffffffc020407c:	00001617          	auipc	a2,0x1
ffffffffc0204080:	d5c60613          	addi	a2,a2,-676 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0204084:	1a500593          	li	a1,421
ffffffffc0204088:	00002517          	auipc	a0,0x2
ffffffffc020408c:	15850513          	addi	a0,a0,344 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204090:	932fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                    assert(((uint8_t *)slots[i])[j] == (uint8_t)(i % 251 + 1));
ffffffffc0204094:	00003697          	auipc	a3,0x3
ffffffffc0204098:	ffc68693          	addi	a3,a3,-4 # ffffffffc0207090 <buddy_system_pmm_manager+0x1140>
ffffffffc020409c:	00001617          	auipc	a2,0x1
ffffffffc02040a0:	d3c60613          	addi	a2,a2,-708 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02040a4:	1c300593          	li	a1,451
ffffffffc02040a8:	00002517          	auipc	a0,0x2
ffffffffc02040ac:	13850513          	addi	a0,a0,312 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02040b0:	912fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(nr_free_pages() == old + (last ? 1 : 0));
ffffffffc02040b4:	00003697          	auipc	a3,0x3
ffffffffc02040b8:	01468693          	addi	a3,a3,20 # ffffffffc02070c8 <buddy_system_pmm_manager+0x1178>
ffffffffc02040bc:	00001617          	auipc	a2,0x1
ffffffffc02040c0:	d1c60613          	addi	a2,a2,-740 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02040c4:	1cd00593          	li	a1,461
ffffffffc02040c8:	00002517          	auipc	a0,0x2
ffffffffc02040cc:	11850513          	addi	a0,a0,280 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02040d0:	8f2fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(list_empty(&first->available));
ffffffffc02040d4:	00003697          	auipc	a3,0x3
ffffffffc02040d8:	f9c68693          	addi	a3,a3,-100 # ffffffffc0207070 <buddy_system_pmm_manager+0x1120>
ffffffffc02040dc:	00001617          	auipc	a2,0x1
ffffffffc02040e0:	cfc60613          	addi	a2,a2,-772 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02040e4:	1ab00593          	li	a1,427
ffffffffc02040e8:	00002517          	auipc	a0,0x2
ffffffffc02040ec:	0f850513          	addi	a0,a0,248 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02040f0:	8d2fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(first->used == count && first->total == count);
ffffffffc02040f4:	00003697          	auipc	a3,0x3
ffffffffc02040f8:	e9c68693          	addi	a3,a3,-356 # ffffffffc0206f90 <buddy_system_pmm_manager+0x1040>
ffffffffc02040fc:	00001617          	auipc	a2,0x1
ffffffffc0204100:	cdc60613          	addi	a2,a2,-804 # ffffffffc0204dd8 <etext+0x292>
ffffffffc0204104:	1aa00593          	li	a1,426
ffffffffc0204108:	00002517          	auipc	a0,0x2
ffffffffc020410c:	0d850513          	addi	a0,a0,216 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204110:	8b2fc0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(first != find_slab(slots[count]));
ffffffffc0204114:	00349913          	slli	s2,s1,0x3
ffffffffc0204118:	012d07b3          	add	a5,s10,s2
    uintptr_t base = (uintptr_t)ptr & ~((uintptr_t)PGSIZE - 1);
ffffffffc020411c:	639c                	ld	a5,0(a5)
ffffffffc020411e:	0197f7b3          	and	a5,a5,s9
        if ((uintptr_t)s == base) {
ffffffffc0204122:	00f58563          	beq	a1,a5,ffffffffc020412c <slub_check+0xffe>
        struct slab *s = to_struct(le, struct slab, live);
ffffffffc0204126:	8c2e                	mv	s8,a1
ffffffffc0204128:	845ff06f          	j	ffffffffc020396c <slub_check+0x83e>
            assert(first != find_slab(slots[count]));
ffffffffc020412c:	00003697          	auipc	a3,0x3
ffffffffc0204130:	e3c68693          	addi	a3,a3,-452 # ffffffffc0206f68 <buddy_system_pmm_manager+0x1018>
ffffffffc0204134:	00001617          	auipc	a2,0x1
ffffffffc0204138:	ca460613          	addi	a2,a2,-860 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020413c:	1a900593          	li	a1,425
ffffffffc0204140:	00002517          	auipc	a0,0x2
ffffffffc0204144:	0a050513          	addi	a0,a0,160 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204148:	87afc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(first->used == count && list_empty(&first->available));
ffffffffc020414c:	00003697          	auipc	a3,0x3
ffffffffc0204150:	f0c68693          	addi	a3,a3,-244 # ffffffffc0207058 <buddy_system_pmm_manager+0x1108>
ffffffffc0204154:	00001617          	auipc	a2,0x1
ffffffffc0204158:	c8460613          	addi	a2,a2,-892 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020415c:	1bf00593          	li	a1,447
ffffffffc0204160:	00002517          	auipc	a0,0x2
ffffffffc0204164:	08050513          	addi	a0,a0,128 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204168:	85afc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                    assert(nr_free_pages() == before - 2);
ffffffffc020416c:	00003697          	auipc	a3,0x3
ffffffffc0204170:	eb468693          	addi	a3,a3,-332 # ffffffffc0207020 <buddy_system_pmm_manager+0x10d0>
ffffffffc0204174:	00001617          	auipc	a2,0x1
ffffffffc0204178:	c6460613          	addi	a2,a2,-924 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020417c:	1bc00593          	li	a1,444
ffffffffc0204180:	00002517          	auipc	a0,0x2
ffffffffc0204184:	06050513          	addi	a0,a0,96 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204188:	83afc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                    assert(replacement == slots[i]);
ffffffffc020418c:	00003697          	auipc	a3,0x3
ffffffffc0204190:	eb468693          	addi	a3,a3,-332 # ffffffffc0207040 <buddy_system_pmm_manager+0x10f0>
ffffffffc0204194:	00001617          	auipc	a2,0x1
ffffffffc0204198:	c4460613          	addi	a2,a2,-956 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020419c:	1ba00593          	li	a1,442
ffffffffc02041a0:	00002517          	auipc	a0,0x2
ffffffffc02041a4:	04050513          	addi	a0,a0,64 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02041a8:	81afc0ef          	jal	ra,ffffffffc02001c2 <__panic>
                    assert(nr_free_pages() == before - 2);
ffffffffc02041ac:	00003697          	auipc	a3,0x3
ffffffffc02041b0:	e7468693          	addi	a3,a3,-396 # ffffffffc0207020 <buddy_system_pmm_manager+0x10d0>
ffffffffc02041b4:	00001617          	auipc	a2,0x1
ffffffffc02041b8:	c2460613          	addi	a2,a2,-988 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02041bc:	1b400593          	li	a1,436
ffffffffc02041c0:	00002517          	auipc	a0,0x2
ffffffffc02041c4:	02050513          	addi	a0,a0,32 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02041c8:	ffbfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
                    assert(!list_empty(&first->available));
ffffffffc02041cc:	00003697          	auipc	a3,0x3
ffffffffc02041d0:	e3468693          	addi	a3,a3,-460 # ffffffffc0207000 <buddy_system_pmm_manager+0x10b0>
ffffffffc02041d4:	00001617          	auipc	a2,0x1
ffffffffc02041d8:	c0460613          	addi	a2,a2,-1020 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02041dc:	1b300593          	li	a1,435
ffffffffc02041e0:	00002517          	auipc	a0,0x2
ffffffffc02041e4:	00050513          	mv	a0,a0
ffffffffc02041e8:	fdbfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
                    assert(first->used == count - i - 1);
ffffffffc02041ec:	00003697          	auipc	a3,0x3
ffffffffc02041f0:	df468693          	addi	a3,a3,-524 # ffffffffc0206fe0 <buddy_system_pmm_manager+0x1090>
ffffffffc02041f4:	00001617          	auipc	a2,0x1
ffffffffc02041f8:	be460613          	addi	a2,a2,-1052 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02041fc:	1b200593          	li	a1,434
ffffffffc0204200:	00002517          	auipc	a0,0x2
ffffffffc0204204:	fe050513          	addi	a0,a0,-32 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204208:	fbbfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(kept != NULL);
ffffffffc020420c:	00003697          	auipc	a3,0x3
ffffffffc0204210:	ee468693          	addi	a3,a3,-284 # ffffffffc02070f0 <buddy_system_pmm_manager+0x11a0>
ffffffffc0204214:	00001617          	auipc	a2,0x1
ffffffffc0204218:	bc460613          	addi	a2,a2,-1084 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020421c:	1d600593          	li	a1,470
ffffffffc0204220:	00002517          	auipc	a0,0x2
ffffffffc0204224:	fc050513          	addi	a0,a0,-64 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204228:	f9bfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(s->used == 1 && s->total > 1);
ffffffffc020422c:	00003697          	auipc	a3,0x3
ffffffffc0204230:	ed468693          	addi	a3,a3,-300 # ffffffffc0207100 <buddy_system_pmm_manager+0x11b0>
ffffffffc0204234:	00001617          	auipc	a2,0x1
ffffffffc0204238:	ba460613          	addi	a2,a2,-1116 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020423c:	1d900593          	li	a1,473
ffffffffc0204240:	00002517          	auipc	a0,0x2
ffffffffc0204244:	fa050513          	addi	a0,a0,-96 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204248:	f7bfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(page->property == count);
ffffffffc020424c:	00003697          	auipc	a3,0x3
ffffffffc0204250:	f0468693          	addi	a3,a3,-252 # ffffffffc0207150 <buddy_system_pmm_manager+0x1200>
ffffffffc0204254:	00001617          	auipc	a2,0x1
ffffffffc0204258:	b8460613          	addi	a2,a2,-1148 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020425c:	1e000593          	li	a1,480
ffffffffc0204260:	00002517          	auipc	a0,0x2
ffffffffc0204264:	f8050513          	addi	a0,a0,-128 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204268:	f5bfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(nr_free_pages() == 0);
ffffffffc020426c:	00003697          	auipc	a3,0x3
ffffffffc0204270:	fec68693          	addi	a3,a3,-20 # ffffffffc0207258 <buddy_system_pmm_manager+0x1308>
ffffffffc0204274:	00001617          	auipc	a2,0x1
ffffffffc0204278:	b6460613          	addi	a2,a2,-1180 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020427c:	1e500593          	li	a1,485
ffffffffc0204280:	00002517          	auipc	a0,0x2
ffffffffc0204284:	f6050513          	addi	a0,a0,-160 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204288:	f3bfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(kmalloc(caches[ci].size) == NULL);
ffffffffc020428c:	00003697          	auipc	a3,0x3
ffffffffc0204290:	edc68693          	addi	a3,a3,-292 # ffffffffc0207168 <buddy_system_pmm_manager+0x1218>
ffffffffc0204294:	00001617          	auipc	a2,0x1
ffffffffc0204298:	b4460613          	addi	a2,a2,-1212 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020429c:	1eb00593          	li	a1,491
ffffffffc02042a0:	00002517          	auipc	a0,0x2
ffffffffc02042a4:	f4050513          	addi	a0,a0,-192 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02042a8:	f1bfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(held_count < PAGE_LIMIT && !PageReserved(page));
ffffffffc02042ac:	00003697          	auipc	a3,0x3
ffffffffc02042b0:	e7468693          	addi	a3,a3,-396 # ffffffffc0207120 <buddy_system_pmm_manager+0x11d0>
ffffffffc02042b4:	00001617          	auipc	a2,0x1
ffffffffc02042b8:	b2460613          	addi	a2,a2,-1244 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02042bc:	1df00593          	li	a1,479
ffffffffc02042c0:	00002517          	auipc	a0,0x2
ffffffffc02042c4:	f2050513          	addi	a0,a0,-224 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02042c8:	efbfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(kmalloc(caches[CACHE_COUNT - 1].size + 1) == NULL);
ffffffffc02042cc:	00003697          	auipc	a3,0x3
ffffffffc02042d0:	ec468693          	addi	a3,a3,-316 # ffffffffc0207190 <buddy_system_pmm_manager+0x1240>
ffffffffc02042d4:	00001617          	auipc	a2,0x1
ffffffffc02042d8:	b0460613          	addi	a2,a2,-1276 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02042dc:	1ee00593          	li	a1,494
ffffffffc02042e0:	00002517          	auipc	a0,0x2
ffffffffc02042e4:	f0050513          	addi	a0,a0,-256 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02042e8:	edbfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(reused != NULL && reused != kept && find_slab(reused) == s);
ffffffffc02042ec:	00003697          	auipc	a3,0x3
ffffffffc02042f0:	f1c68693          	addi	a3,a3,-228 # ffffffffc0207208 <buddy_system_pmm_manager+0x12b8>
ffffffffc02042f4:	00001617          	auipc	a2,0x1
ffffffffc02042f8:	ae460613          	addi	a2,a2,-1308 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02042fc:	1f300593          	li	a1,499
ffffffffc0204300:	00002517          	auipc	a0,0x2
ffffffffc0204304:	ee050513          	addi	a0,a0,-288 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204308:	ebbfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(memcmp(saved_caches, caches, sizeof(caches)) == 0);
ffffffffc020430c:	00003697          	auipc	a3,0x3
ffffffffc0204310:	a2468693          	addi	a3,a3,-1500 # ffffffffc0206d30 <buddy_system_pmm_manager+0xde0>
ffffffffc0204314:	00001617          	auipc	a2,0x1
ffffffffc0204318:	ac460613          	addi	a2,a2,-1340 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020431c:	1f000593          	li	a1,496
ffffffffc0204320:	00002517          	auipc	a0,0x2
ffffffffc0204324:	ec050513          	addi	a0,a0,-320 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204328:	e9bfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(nr_free_pages() == 0 && memcmp(&saved, s, HEADER_SIZE) == 0);
ffffffffc020432c:	00003697          	auipc	a3,0x3
ffffffffc0204330:	e9c68693          	addi	a3,a3,-356 # ffffffffc02071c8 <buddy_system_pmm_manager+0x1278>
ffffffffc0204334:	00001617          	auipc	a2,0x1
ffffffffc0204338:	aa460613          	addi	a2,a2,-1372 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020433c:	1ef00593          	li	a1,495
ffffffffc0204340:	00002517          	auipc	a0,0x2
ffffffffc0204344:	ea050513          	addi	a0,a0,-352 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204348:	e7bfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(memcmp(&saved_live, &live, sizeof(live)) == 0);
ffffffffc020434c:	00003697          	auipc	a3,0x3
ffffffffc0204350:	9b468693          	addi	a3,a3,-1612 # ffffffffc0206d00 <buddy_system_pmm_manager+0xdb0>
ffffffffc0204354:	00001617          	auipc	a2,0x1
ffffffffc0204358:	a8460613          	addi	a2,a2,-1404 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020435c:	1f100593          	li	a1,497
ffffffffc0204360:	00002517          	auipc	a0,0x2
ffffffffc0204364:	e8050513          	addi	a0,a0,-384 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204368:	e5bfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
            assert(((uint8_t *)kept)[i] == 0xa5 && ((uint8_t *)reused)[i] == 0x5a);
ffffffffc020436c:	00003697          	auipc	a3,0x3
ffffffffc0204370:	f0468693          	addi	a3,a3,-252 # ffffffffc0207270 <buddy_system_pmm_manager+0x1320>
ffffffffc0204374:	00001617          	auipc	a2,0x1
ffffffffc0204378:	a6460613          	addi	a2,a2,-1436 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020437c:	1f700593          	li	a1,503
ffffffffc0204380:	00002517          	auipc	a0,0x2
ffffffffc0204384:	e6050513          	addi	a0,a0,-416 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204388:	e3bfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(s->used == 2 && nr_free_pages() == 0);
ffffffffc020438c:	00003697          	auipc	a3,0x3
ffffffffc0204390:	ebc68693          	addi	a3,a3,-324 # ffffffffc0207248 <buddy_system_pmm_manager+0x12f8>
ffffffffc0204394:	00001617          	auipc	a2,0x1
ffffffffc0204398:	a4460613          	addi	a2,a2,-1468 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020439c:	1f400593          	li	a1,500
ffffffffc02043a0:	00002517          	auipc	a0,0x2
ffffffffc02043a4:	e4050513          	addi	a0,a0,-448 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02043a8:	e1bfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(nr_free_pages() == before - 1);
ffffffffc02043ac:	00003697          	auipc	a3,0x3
ffffffffc02043b0:	f0468693          	addi	a3,a3,-252 # ffffffffc02072b0 <buddy_system_pmm_manager+0x1360>
ffffffffc02043b4:	00001617          	auipc	a2,0x1
ffffffffc02043b8:	a2460613          	addi	a2,a2,-1500 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02043bc:	20100593          	li	a1,513
ffffffffc02043c0:	00002517          	auipc	a0,0x2
ffffffffc02043c4:	e2050513          	addi	a0,a0,-480 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02043c8:	dfbfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(find_slab(kept) == NULL);
ffffffffc02043cc:	00003697          	auipc	a3,0x3
ffffffffc02043d0:	12468693          	addi	a3,a3,292 # ffffffffc02074f0 <buddy_system_pmm_manager+0x15a0>
ffffffffc02043d4:	00001617          	auipc	a2,0x1
ffffffffc02043d8:	a0460613          	addi	a2,a2,-1532 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02043dc:	20300593          	li	a1,515
ffffffffc02043e0:	00002517          	auipc	a0,0x2
ffffffffc02043e4:	e0050513          	addi	a0,a0,-512 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02043e8:	ddbfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        slub_check_invariants();
ffffffffc02043ec:	882fe0ef          	jal	ra,ffffffffc020246e <slub_check_invariants>
        assert(list_empty(&live) && nr_free_pages() == before);
ffffffffc02043f0:	cc9fd0ef          	jal	ra,ffffffffc02020b8 <nr_free_pages>
ffffffffc02043f4:	7782                	ld	a5,32(sp)
ffffffffc02043f6:	96f511e3          	bne	a0,a5,ffffffffc0203d58 <slub_check+0xc2a>
        for (size_t i = 0; i < npage - nbase; ++i) {
ffffffffc02043fa:	000a7797          	auipc	a5,0xa7
ffffffffc02043fe:	52678793          	addi	a5,a5,1318 # ffffffffc02ab920 <npage>
ffffffffc0204402:	639c                	ld	a5,0(a5)
ffffffffc0204404:	7742                	ld	a4,48(sp)
        sum = 0;
ffffffffc0204406:	4581                	li	a1,0
        for (size_t i = 0; i < npage - nbase; ++i) {
ffffffffc0204408:	40e78eb3          	sub	t4,a5,a4
ffffffffc020440c:	0ce78263          	beq	a5,a4,ffffffffc02044d0 <slub_check+0x13a2>
            struct Page *p = &pages[i];
ffffffffc0204410:	000a7717          	auipc	a4,0xa7
ffffffffc0204414:	51873703          	ld	a4,1304(a4) # ffffffffc02ab928 <pages>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0204418:	5521                	li	a0,-24
ffffffffc020441a:	00007897          	auipc	a7,0x7
ffffffffc020441e:	cd688893          	addi	a7,a7,-810 # ffffffffc020b0f0 <free_blocks.2>
ffffffffc0204422:	01870793          	addi	a5,a4,24
        for (size_t i = 0; i < npage - nbase; ++i) {
ffffffffc0204426:	4801                	li	a6,0
        sum = 0;
ffffffffc0204428:	4581                	li	a1,0
                assert(!PageReserved(p) && p->u >= 0 && p->u < sizeof(size_t) * 8);
ffffffffc020442a:	03f00e13          	li	t3,63
                assert(((size_t)1 << p->u) == free_blocks[i]);
ffffffffc020442e:	4305                	li	t1,1
ffffffffc0204430:	8d19                	sub	a0,a0,a4
ffffffffc0204432:	a0b5                	j	ffffffffc020449e <slub_check+0x1370>
            assert((PageProperty(p) ? p->property : 0) == free_blocks[i]);
ffffffffc0204434:	ff87a683          	lw	a3,-8(a5)
ffffffffc0204438:	07e69c63          	bne	a3,t5,ffffffffc02044b0 <slub_check+0x1382>
            if (free_blocks[i] != 0) {
ffffffffc020443c:	1a068763          	beqz	a3,ffffffffc02045ea <slub_check+0x14bc>
                assert(!PageReserved(p) && p->u >= 0 && p->u < sizeof(size_t) * 8);
ffffffffc0204440:	8b05                	andi	a4,a4,1
ffffffffc0204442:	1a071663          	bnez	a4,ffffffffc02045ee <slub_check+0x14c0>
ffffffffc0204446:	ffc7a703          	lw	a4,-4(a5)
ffffffffc020444a:	1aee6263          	bltu	t3,a4,ffffffffc02045ee <slub_check+0x14c0>
                assert(((size_t)1 << p->u) == free_blocks[i]);
ffffffffc020444e:	02069613          	slli	a2,a3,0x20
ffffffffc0204452:	9201                	srli	a2,a2,0x20
ffffffffc0204454:	00e31733          	sll	a4,t1,a4
ffffffffc0204458:	16c71963          	bne	a4,a2,ffffffffc02045ca <slub_check+0x149c>
ffffffffc020445c:	00003417          	auipc	s0,0x3
ffffffffc0204460:	45440413          	addi	s0,s0,1108 # ffffffffc02078b0 <error_string+0x38>
ffffffffc0204464:	6000                	ld	s0,0(s0)
ffffffffc0204466:	00f50733          	add	a4,a0,a5
ffffffffc020446a:	870d                	srai	a4,a4,0x3
ffffffffc020446c:	02870733          	mul	a4,a4,s0
ffffffffc0204470:	7442                	ld	s0,48(sp)
                assert((page2ppn(p) & (free_blocks[i] - 1)) == 0);
ffffffffc0204472:	36fd                	addiw	a3,a3,-1
ffffffffc0204474:	1682                	slli	a3,a3,0x20
ffffffffc0204476:	9281                	srli	a3,a3,0x20
ffffffffc0204478:	9722                	add	a4,a4,s0
ffffffffc020447a:	8f75                	and	a4,a4,a3
ffffffffc020447c:	12071763          	bnez	a4,ffffffffc02045aa <slub_check+0x147c>
ffffffffc0204480:	6398                	ld	a4,0(a5)
                assert(list_next(list_prev(&p->page_link)) == &p->page_link);
ffffffffc0204482:	6718                	ld	a4,8(a4)
ffffffffc0204484:	10e79363          	bne	a5,a4,ffffffffc020458a <slub_check+0x145c>
    return listelm->prev;
ffffffffc0204488:	6798                	ld	a4,8(a5)
                assert(list_prev(list_next(&p->page_link)) == &p->page_link);
ffffffffc020448a:	6318                	ld	a4,0(a4)
ffffffffc020448c:	0ae79f63          	bne	a5,a4,ffffffffc020454a <slub_check+0x141c>
        for (size_t i = 0; i < npage - nbase; ++i) {
ffffffffc0204490:	0805                	addi	a6,a6,1
            sum += free_blocks[i];
ffffffffc0204492:	95b2                	add	a1,a1,a2
        for (size_t i = 0; i < npage - nbase; ++i) {
ffffffffc0204494:	0891                	addi	a7,a7,4
ffffffffc0204496:	02878793          	addi	a5,a5,40
ffffffffc020449a:	03d80b63          	beq	a6,t4,ffffffffc02044d0 <slub_check+0x13a2>
            assert((PageProperty(p) ? p->property : 0) == free_blocks[i]);
ffffffffc020449e:	ff07b703          	ld	a4,-16(a5)
ffffffffc02044a2:	0008af03          	lw	t5,0(a7)
ffffffffc02044a6:	00277613          	andi	a2,a4,2
ffffffffc02044aa:	f649                	bnez	a2,ffffffffc0204434 <slub_check+0x1306>
ffffffffc02044ac:	fe0f02e3          	beqz	t5,ffffffffc0204490 <slub_check+0x1362>
ffffffffc02044b0:	00003697          	auipc	a3,0x3
ffffffffc02044b4:	e5068693          	addi	a3,a3,-432 # ffffffffc0207300 <buddy_system_pmm_manager+0x13b0>
ffffffffc02044b8:	00001617          	auipc	a2,0x1
ffffffffc02044bc:	92060613          	addi	a2,a2,-1760 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02044c0:	20c00593          	li	a1,524
ffffffffc02044c4:	00002517          	auipc	a0,0x2
ffffffffc02044c8:	d1c50513          	addi	a0,a0,-740 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02044cc:	cf7fb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(sum == before);
ffffffffc02044d0:	7782                	ld	a5,32(sp)
ffffffffc02044d2:	08f59c63          	bne	a1,a5,ffffffffc020456a <slub_check+0x143c>
    for (size_t round = 0; round < 3; ++round) {
ffffffffc02044d6:	77a2                	ld	a5,40(sp)
ffffffffc02044d8:	76e2                	ld	a3,56(sp)
ffffffffc02044da:	2785                	addiw	a5,a5,1
ffffffffc02044dc:	0ff7f713          	zext.b	a4,a5
ffffffffc02044e0:	069d                	addi	a3,a3,7
ffffffffc02044e2:	f43a                	sd	a4,40(sp)
ffffffffc02044e4:	4791                	li	a5,4
ffffffffc02044e6:	fc36                	sd	a3,56(sp)
ffffffffc02044e8:	00f70463          	beq	a4,a5,ffffffffc02044f0 <slub_check+0x13c2>
ffffffffc02044ec:	d3dfe06f          	j	ffffffffc0203228 <slub_check+0xfa>
    memset(free_blocks, 0, sizeof(free_blocks));
ffffffffc02044f0:	00020637          	lui	a2,0x20
ffffffffc02044f4:	4581                	li	a1,0
ffffffffc02044f6:	00007517          	auipc	a0,0x7
ffffffffc02044fa:	bfa50513          	addi	a0,a0,-1030 # ffffffffc020b0f0 <free_blocks.2>
ffffffffc02044fe:	5fa000ef          	jal	ra,ffffffffc0204af8 <memset>
}
ffffffffc0204502:	6285                	lui	t0,0x1
ffffffffc0204504:	9116                	add	sp,sp,t0
ffffffffc0204506:	57813083          	ld	ra,1400(sp)
ffffffffc020450a:	57013403          	ld	s0,1392(sp)
ffffffffc020450e:	56813483          	ld	s1,1384(sp)
ffffffffc0204512:	56013903          	ld	s2,1376(sp)
ffffffffc0204516:	55813983          	ld	s3,1368(sp)
ffffffffc020451a:	55013a03          	ld	s4,1360(sp)
ffffffffc020451e:	54813a83          	ld	s5,1352(sp)
ffffffffc0204522:	54013b03          	ld	s6,1344(sp)
ffffffffc0204526:	53813b83          	ld	s7,1336(sp)
ffffffffc020452a:	53013c03          	ld	s8,1328(sp)
ffffffffc020452e:	52813c83          	ld	s9,1320(sp)
ffffffffc0204532:	52013d03          	ld	s10,1312(sp)
ffffffffc0204536:	51813d83          	ld	s11,1304(sp)
    cprintf("slub check passed: 3 rounds, boundaries, isolation, reuse, full/partial, reclaim, large, OOM, exact free-block restoration\n");
ffffffffc020453a:	00003517          	auipc	a0,0x3
ffffffffc020453e:	f0650513          	addi	a0,a0,-250 # ffffffffc0207440 <buddy_system_pmm_manager+0x14f0>
}
ffffffffc0204542:	58010113          	addi	sp,sp,1408
    cprintf("slub check passed: 3 rounds, boundaries, isolation, reuse, full/partial, reclaim, large, OOM, exact free-block restoration\n");
ffffffffc0204546:	c07fb06f          	j	ffffffffc020014c <cprintf>
                assert(list_prev(list_next(&p->page_link)) == &p->page_link);
ffffffffc020454a:	00003697          	auipc	a3,0x3
ffffffffc020454e:	ebe68693          	addi	a3,a3,-322 # ffffffffc0207408 <buddy_system_pmm_manager+0x14b8>
ffffffffc0204552:	00001617          	auipc	a2,0x1
ffffffffc0204556:	88660613          	addi	a2,a2,-1914 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020455a:	21200593          	li	a1,530
ffffffffc020455e:	00002517          	auipc	a0,0x2
ffffffffc0204562:	c8250513          	addi	a0,a0,-894 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204566:	c5dfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(sum == before);
ffffffffc020456a:	00002697          	auipc	a3,0x2
ffffffffc020456e:	4f668693          	addi	a3,a3,1270 # ffffffffc0206a60 <buddy_system_pmm_manager+0xb10>
ffffffffc0204572:	00001617          	auipc	a2,0x1
ffffffffc0204576:	86660613          	addi	a2,a2,-1946 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020457a:	21600593          	li	a1,534
ffffffffc020457e:	00002517          	auipc	a0,0x2
ffffffffc0204582:	c6250513          	addi	a0,a0,-926 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc0204586:	c3dfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(list_next(list_prev(&p->page_link)) == &p->page_link);
ffffffffc020458a:	00003697          	auipc	a3,0x3
ffffffffc020458e:	e4668693          	addi	a3,a3,-442 # ffffffffc02073d0 <buddy_system_pmm_manager+0x1480>
ffffffffc0204592:	00001617          	auipc	a2,0x1
ffffffffc0204596:	84660613          	addi	a2,a2,-1978 # ffffffffc0204dd8 <etext+0x292>
ffffffffc020459a:	21100593          	li	a1,529
ffffffffc020459e:	00002517          	auipc	a0,0x2
ffffffffc02045a2:	c4250513          	addi	a0,a0,-958 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02045a6:	c1dfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert((page2ppn(p) & (free_blocks[i] - 1)) == 0);
ffffffffc02045aa:	00003697          	auipc	a3,0x3
ffffffffc02045ae:	df668693          	addi	a3,a3,-522 # ffffffffc02073a0 <buddy_system_pmm_manager+0x1450>
ffffffffc02045b2:	00001617          	auipc	a2,0x1
ffffffffc02045b6:	82660613          	addi	a2,a2,-2010 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02045ba:	21000593          	li	a1,528
ffffffffc02045be:	00002517          	auipc	a0,0x2
ffffffffc02045c2:	c2250513          	addi	a0,a0,-990 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02045c6:	bfdfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(((size_t)1 << p->u) == free_blocks[i]);
ffffffffc02045ca:	00003697          	auipc	a3,0x3
ffffffffc02045ce:	dae68693          	addi	a3,a3,-594 # ffffffffc0207378 <buddy_system_pmm_manager+0x1428>
ffffffffc02045d2:	00001617          	auipc	a2,0x1
ffffffffc02045d6:	80660613          	addi	a2,a2,-2042 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02045da:	20f00593          	li	a1,527
ffffffffc02045de:	00002517          	auipc	a0,0x2
ffffffffc02045e2:	c0250513          	addi	a0,a0,-1022 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc02045e6:	bddfb0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc02045ea:	4601                	li	a2,0
ffffffffc02045ec:	b555                	j	ffffffffc0204490 <slub_check+0x1362>
                assert(!PageReserved(p) && p->u >= 0 && p->u < sizeof(size_t) * 8);
ffffffffc02045ee:	00003697          	auipc	a3,0x3
ffffffffc02045f2:	d4a68693          	addi	a3,a3,-694 # ffffffffc0207338 <buddy_system_pmm_manager+0x13e8>
ffffffffc02045f6:	00000617          	auipc	a2,0x0
ffffffffc02045fa:	7e260613          	addi	a2,a2,2018 # ffffffffc0204dd8 <etext+0x292>
ffffffffc02045fe:	20e00593          	li	a1,526
ffffffffc0204602:	00002517          	auipc	a0,0x2
ffffffffc0204606:	bde50513          	addi	a0,a0,-1058 # ffffffffc02061e0 <buddy_system_pmm_manager+0x290>
ffffffffc020460a:	bb9fb0ef          	jal	ra,ffffffffc02001c2 <__panic>
                assert(find_slab(slots[i])->cache == &caches[ci]);
ffffffffc020460e:	01003783          	ld	a5,16(zero) # 10 <kern_entry-0xffffffffc01ffff0>
ffffffffc0204612:	9002                	ebreak
        assert(s->used == 1 && s->total > 1);
ffffffffc0204614:	03003783          	ld	a5,48(zero) # 30 <kern_entry-0xffffffffc01fffd0>
ffffffffc0204618:	9002                	ebreak
            bool last = s->kind == LARGE || s->used == 1;
ffffffffc020461a:	00802783          	lw	a5,8(zero) # 8 <kern_entry-0xffffffffc01ffff8>
ffffffffc020461e:	9002                	ebreak
                saved[i] = *heads[i];
ffffffffc0204620:	6705                	lui	a4,0x1
ffffffffc0204622:	1894                	addi	a3,sp,112
ffffffffc0204624:	4a070713          	addi	a4,a4,1184 # 14a0 <kern_entry-0xffffffffc01feb60>
ffffffffc0204628:	9736                	add	a4,a4,a3
ffffffffc020462a:	77fd                	lui	a5,0xfffff
ffffffffc020462c:	97ba                	add	a5,a5,a4
ffffffffc020462e:	0f1e                	slli	t5,t5,0x7
ffffffffc0204630:	9f3e                	add	t5,t5,a5
ffffffffc0204632:	e03e                	sd	a5,0(sp)
ffffffffc0204634:	4701                	li	a4,0
ffffffffc0204636:	f80f0793          	addi	a5,t5,-128
ffffffffc020463a:	08000693          	li	a3,128
ffffffffc020463e:	00073803          	ld	a6,0(a4)
ffffffffc0204642:	6708                	ld	a0,8(a4)
ffffffffc0204644:	6b0c                	ld	a1,16(a4)
ffffffffc0204646:	6f10                	ld	a2,24(a4)
ffffffffc0204648:	0107b023          	sd	a6,0(a5) # fffffffffffff000 <end+0x3fd536b0>
ffffffffc020464c:	e788                	sd	a0,8(a5)
ffffffffc020464e:	eb8c                	sd	a1,16(a5)
ffffffffc0204650:	ef90                	sd	a2,24(a5)
ffffffffc0204652:	02070713          	addi	a4,a4,32
ffffffffc0204656:	02078793          	addi	a5,a5,32
ffffffffc020465a:	fed712e3          	bne	a4,a3,ffffffffc020463e <slub_check+0x1510>
ffffffffc020465e:	b7c1                	j	ffffffffc020461e <slub_check+0x14f0>

ffffffffc0204660 <combined_check>:
}
static void combined_check(void) {
ffffffffc0204660:	1141                	addi	sp,sp,-16
ffffffffc0204662:	e406                	sd	ra,8(sp)
    buddy_system_pmm_manager.check();
ffffffffc0204664:	00002797          	auipc	a5,0x2
ffffffffc0204668:	91c7b783          	ld	a5,-1764(a5) # ffffffffc0205f80 <buddy_system_pmm_manager+0x30>
ffffffffc020466c:	9782                	jalr	a5
    slub_check();
}
ffffffffc020466e:	60a2                	ld	ra,8(sp)
ffffffffc0204670:	0141                	addi	sp,sp,16
    slub_check();
ffffffffc0204672:	abdfe06f          	j	ffffffffc020312e <slub_check>

ffffffffc0204676 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0204676:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020467a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020467c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204680:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0204682:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204686:	f022                	sd	s0,32(sp)
ffffffffc0204688:	ec26                	sd	s1,24(sp)
ffffffffc020468a:	e84a                	sd	s2,16(sp)
ffffffffc020468c:	f406                	sd	ra,40(sp)
ffffffffc020468e:	e44e                	sd	s3,8(sp)
ffffffffc0204690:	84aa                	mv	s1,a0
ffffffffc0204692:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0204694:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0204698:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020469a:	03067e63          	bgeu	a2,a6,ffffffffc02046d6 <printnum+0x60>
ffffffffc020469e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02046a0:	00805763          	blez	s0,ffffffffc02046ae <printnum+0x38>
ffffffffc02046a4:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02046a6:	85ca                	mv	a1,s2
ffffffffc02046a8:	854e                	mv	a0,s3
ffffffffc02046aa:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02046ac:	fc65                	bnez	s0,ffffffffc02046a4 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02046ae:	1a02                	slli	s4,s4,0x20
ffffffffc02046b0:	00003797          	auipc	a5,0x3
ffffffffc02046b4:	fb878793          	addi	a5,a5,-72 # ffffffffc0207668 <slub_pmm_manager+0x38>
ffffffffc02046b8:	020a5a13          	srli	s4,s4,0x20
ffffffffc02046bc:	9a3e                	add	s4,s4,a5
}
ffffffffc02046be:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02046c0:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02046c4:	70a2                	ld	ra,40(sp)
ffffffffc02046c6:	69a2                	ld	s3,8(sp)
ffffffffc02046c8:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02046ca:	85ca                	mv	a1,s2
ffffffffc02046cc:	87a6                	mv	a5,s1
}
ffffffffc02046ce:	6942                	ld	s2,16(sp)
ffffffffc02046d0:	64e2                	ld	s1,24(sp)
ffffffffc02046d2:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02046d4:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02046d6:	03065633          	divu	a2,a2,a6
ffffffffc02046da:	8722                	mv	a4,s0
ffffffffc02046dc:	f9bff0ef          	jal	ra,ffffffffc0204676 <printnum>
ffffffffc02046e0:	b7f9                	j	ffffffffc02046ae <printnum+0x38>

ffffffffc02046e2 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02046e2:	7119                	addi	sp,sp,-128
ffffffffc02046e4:	f4a6                	sd	s1,104(sp)
ffffffffc02046e6:	f0ca                	sd	s2,96(sp)
ffffffffc02046e8:	ecce                	sd	s3,88(sp)
ffffffffc02046ea:	e8d2                	sd	s4,80(sp)
ffffffffc02046ec:	e4d6                	sd	s5,72(sp)
ffffffffc02046ee:	e0da                	sd	s6,64(sp)
ffffffffc02046f0:	fc5e                	sd	s7,56(sp)
ffffffffc02046f2:	f06a                	sd	s10,32(sp)
ffffffffc02046f4:	fc86                	sd	ra,120(sp)
ffffffffc02046f6:	f8a2                	sd	s0,112(sp)
ffffffffc02046f8:	f862                	sd	s8,48(sp)
ffffffffc02046fa:	f466                	sd	s9,40(sp)
ffffffffc02046fc:	ec6e                	sd	s11,24(sp)
ffffffffc02046fe:	892a                	mv	s2,a0
ffffffffc0204700:	84ae                	mv	s1,a1
ffffffffc0204702:	8d32                	mv	s10,a2
ffffffffc0204704:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204706:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020470a:	5b7d                	li	s6,-1
ffffffffc020470c:	00003a97          	auipc	s5,0x3
ffffffffc0204710:	f90a8a93          	addi	s5,s5,-112 # ffffffffc020769c <slub_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204714:	00003b97          	auipc	s7,0x3
ffffffffc0204718:	164b8b93          	addi	s7,s7,356 # ffffffffc0207878 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020471c:	000d4503          	lbu	a0,0(s10)
ffffffffc0204720:	001d0413          	addi	s0,s10,1
ffffffffc0204724:	01350a63          	beq	a0,s3,ffffffffc0204738 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0204728:	c121                	beqz	a0,ffffffffc0204768 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020472a:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020472c:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020472e:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204730:	fff44503          	lbu	a0,-1(s0)
ffffffffc0204734:	ff351ae3          	bne	a0,s3,ffffffffc0204728 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204738:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020473c:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0204740:	4c81                	li	s9,0
ffffffffc0204742:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0204744:	5c7d                	li	s8,-1
ffffffffc0204746:	5dfd                	li	s11,-1
ffffffffc0204748:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020474c:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020474e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0204752:	0ff5f593          	zext.b	a1,a1
ffffffffc0204756:	00140d13          	addi	s10,s0,1
ffffffffc020475a:	04b56263          	bltu	a0,a1,ffffffffc020479e <vprintfmt+0xbc>
ffffffffc020475e:	058a                	slli	a1,a1,0x2
ffffffffc0204760:	95d6                	add	a1,a1,s5
ffffffffc0204762:	4194                	lw	a3,0(a1)
ffffffffc0204764:	96d6                	add	a3,a3,s5
ffffffffc0204766:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0204768:	70e6                	ld	ra,120(sp)
ffffffffc020476a:	7446                	ld	s0,112(sp)
ffffffffc020476c:	74a6                	ld	s1,104(sp)
ffffffffc020476e:	7906                	ld	s2,96(sp)
ffffffffc0204770:	69e6                	ld	s3,88(sp)
ffffffffc0204772:	6a46                	ld	s4,80(sp)
ffffffffc0204774:	6aa6                	ld	s5,72(sp)
ffffffffc0204776:	6b06                	ld	s6,64(sp)
ffffffffc0204778:	7be2                	ld	s7,56(sp)
ffffffffc020477a:	7c42                	ld	s8,48(sp)
ffffffffc020477c:	7ca2                	ld	s9,40(sp)
ffffffffc020477e:	7d02                	ld	s10,32(sp)
ffffffffc0204780:	6de2                	ld	s11,24(sp)
ffffffffc0204782:	6109                	addi	sp,sp,128
ffffffffc0204784:	8082                	ret
            padc = '0';
ffffffffc0204786:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0204788:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020478c:	846a                	mv	s0,s10
ffffffffc020478e:	00140d13          	addi	s10,s0,1
ffffffffc0204792:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0204796:	0ff5f593          	zext.b	a1,a1
ffffffffc020479a:	fcb572e3          	bgeu	a0,a1,ffffffffc020475e <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020479e:	85a6                	mv	a1,s1
ffffffffc02047a0:	02500513          	li	a0,37
ffffffffc02047a4:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02047a6:	fff44783          	lbu	a5,-1(s0)
ffffffffc02047aa:	8d22                	mv	s10,s0
ffffffffc02047ac:	f73788e3          	beq	a5,s3,ffffffffc020471c <vprintfmt+0x3a>
ffffffffc02047b0:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02047b4:	1d7d                	addi	s10,s10,-1
ffffffffc02047b6:	ff379de3          	bne	a5,s3,ffffffffc02047b0 <vprintfmt+0xce>
ffffffffc02047ba:	b78d                	j	ffffffffc020471c <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02047bc:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02047c0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02047c4:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02047c6:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02047ca:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02047ce:	02d86463          	bltu	a6,a3,ffffffffc02047f6 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02047d2:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02047d6:	002c169b          	slliw	a3,s8,0x2
ffffffffc02047da:	0186873b          	addw	a4,a3,s8
ffffffffc02047de:	0017171b          	slliw	a4,a4,0x1
ffffffffc02047e2:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02047e4:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02047e8:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02047ea:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02047ee:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02047f2:	fed870e3          	bgeu	a6,a3,ffffffffc02047d2 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02047f6:	f40ddce3          	bgez	s11,ffffffffc020474e <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02047fa:	8de2                	mv	s11,s8
ffffffffc02047fc:	5c7d                	li	s8,-1
ffffffffc02047fe:	bf81                	j	ffffffffc020474e <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0204800:	fffdc693          	not	a3,s11
ffffffffc0204804:	96fd                	srai	a3,a3,0x3f
ffffffffc0204806:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020480a:	00144603          	lbu	a2,1(s0)
ffffffffc020480e:	2d81                	sext.w	s11,s11
ffffffffc0204810:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204812:	bf35                	j	ffffffffc020474e <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0204814:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204818:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020481c:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020481e:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0204820:	bfd9                	j	ffffffffc02047f6 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0204822:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204824:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204828:	01174463          	blt	a4,a7,ffffffffc0204830 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020482c:	1a088e63          	beqz	a7,ffffffffc02049e8 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0204830:	000a3603          	ld	a2,0(s4)
ffffffffc0204834:	46c1                	li	a3,16
ffffffffc0204836:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0204838:	2781                	sext.w	a5,a5
ffffffffc020483a:	876e                	mv	a4,s11
ffffffffc020483c:	85a6                	mv	a1,s1
ffffffffc020483e:	854a                	mv	a0,s2
ffffffffc0204840:	e37ff0ef          	jal	ra,ffffffffc0204676 <printnum>
            break;
ffffffffc0204844:	bde1                	j	ffffffffc020471c <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0204846:	000a2503          	lw	a0,0(s4)
ffffffffc020484a:	85a6                	mv	a1,s1
ffffffffc020484c:	0a21                	addi	s4,s4,8
ffffffffc020484e:	9902                	jalr	s2
            break;
ffffffffc0204850:	b5f1                	j	ffffffffc020471c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204852:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204854:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204858:	01174463          	blt	a4,a7,ffffffffc0204860 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc020485c:	18088163          	beqz	a7,ffffffffc02049de <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0204860:	000a3603          	ld	a2,0(s4)
ffffffffc0204864:	46a9                	li	a3,10
ffffffffc0204866:	8a2e                	mv	s4,a1
ffffffffc0204868:	bfc1                	j	ffffffffc0204838 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020486a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020486e:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204870:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204872:	bdf1                	j	ffffffffc020474e <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0204874:	85a6                	mv	a1,s1
ffffffffc0204876:	02500513          	li	a0,37
ffffffffc020487a:	9902                	jalr	s2
            break;
ffffffffc020487c:	b545                	j	ffffffffc020471c <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020487e:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0204882:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204884:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204886:	b5e1                	j	ffffffffc020474e <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0204888:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020488a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020488e:	01174463          	blt	a4,a7,ffffffffc0204896 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0204892:	14088163          	beqz	a7,ffffffffc02049d4 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0204896:	000a3603          	ld	a2,0(s4)
ffffffffc020489a:	46a1                	li	a3,8
ffffffffc020489c:	8a2e                	mv	s4,a1
ffffffffc020489e:	bf69                	j	ffffffffc0204838 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02048a0:	03000513          	li	a0,48
ffffffffc02048a4:	85a6                	mv	a1,s1
ffffffffc02048a6:	e03e                	sd	a5,0(sp)
ffffffffc02048a8:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02048aa:	85a6                	mv	a1,s1
ffffffffc02048ac:	07800513          	li	a0,120
ffffffffc02048b0:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02048b2:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02048b4:	6782                	ld	a5,0(sp)
ffffffffc02048b6:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02048b8:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02048bc:	bfb5                	j	ffffffffc0204838 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02048be:	000a3403          	ld	s0,0(s4)
ffffffffc02048c2:	008a0713          	addi	a4,s4,8
ffffffffc02048c6:	e03a                	sd	a4,0(sp)
ffffffffc02048c8:	14040263          	beqz	s0,ffffffffc0204a0c <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02048cc:	0fb05763          	blez	s11,ffffffffc02049ba <vprintfmt+0x2d8>
ffffffffc02048d0:	02d00693          	li	a3,45
ffffffffc02048d4:	0cd79163          	bne	a5,a3,ffffffffc0204996 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02048d8:	00044783          	lbu	a5,0(s0)
ffffffffc02048dc:	0007851b          	sext.w	a0,a5
ffffffffc02048e0:	cf85                	beqz	a5,ffffffffc0204918 <vprintfmt+0x236>
ffffffffc02048e2:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02048e6:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02048ea:	000c4563          	bltz	s8,ffffffffc02048f4 <vprintfmt+0x212>
ffffffffc02048ee:	3c7d                	addiw	s8,s8,-1
ffffffffc02048f0:	036c0263          	beq	s8,s6,ffffffffc0204914 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02048f4:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02048f6:	0e0c8e63          	beqz	s9,ffffffffc02049f2 <vprintfmt+0x310>
ffffffffc02048fa:	3781                	addiw	a5,a5,-32
ffffffffc02048fc:	0ef47b63          	bgeu	s0,a5,ffffffffc02049f2 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0204900:	03f00513          	li	a0,63
ffffffffc0204904:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204906:	000a4783          	lbu	a5,0(s4)
ffffffffc020490a:	3dfd                	addiw	s11,s11,-1
ffffffffc020490c:	0a05                	addi	s4,s4,1
ffffffffc020490e:	0007851b          	sext.w	a0,a5
ffffffffc0204912:	ffe1                	bnez	a5,ffffffffc02048ea <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0204914:	01b05963          	blez	s11,ffffffffc0204926 <vprintfmt+0x244>
ffffffffc0204918:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020491a:	85a6                	mv	a1,s1
ffffffffc020491c:	02000513          	li	a0,32
ffffffffc0204920:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204922:	fe0d9be3          	bnez	s11,ffffffffc0204918 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204926:	6a02                	ld	s4,0(sp)
ffffffffc0204928:	bbd5                	j	ffffffffc020471c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020492a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020492c:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0204930:	01174463          	blt	a4,a7,ffffffffc0204938 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0204934:	08088d63          	beqz	a7,ffffffffc02049ce <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0204938:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020493c:	0a044d63          	bltz	s0,ffffffffc02049f6 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0204940:	8622                	mv	a2,s0
ffffffffc0204942:	8a66                	mv	s4,s9
ffffffffc0204944:	46a9                	li	a3,10
ffffffffc0204946:	bdcd                	j	ffffffffc0204838 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0204948:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020494c:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc020494e:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0204950:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0204954:	8fb5                	xor	a5,a5,a3
ffffffffc0204956:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020495a:	02d74163          	blt	a4,a3,ffffffffc020497c <vprintfmt+0x29a>
ffffffffc020495e:	00369793          	slli	a5,a3,0x3
ffffffffc0204962:	97de                	add	a5,a5,s7
ffffffffc0204964:	639c                	ld	a5,0(a5)
ffffffffc0204966:	cb99                	beqz	a5,ffffffffc020497c <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0204968:	86be                	mv	a3,a5
ffffffffc020496a:	00003617          	auipc	a2,0x3
ffffffffc020496e:	d2e60613          	addi	a2,a2,-722 # ffffffffc0207698 <slub_pmm_manager+0x68>
ffffffffc0204972:	85a6                	mv	a1,s1
ffffffffc0204974:	854a                	mv	a0,s2
ffffffffc0204976:	0ce000ef          	jal	ra,ffffffffc0204a44 <printfmt>
ffffffffc020497a:	b34d                	j	ffffffffc020471c <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020497c:	00003617          	auipc	a2,0x3
ffffffffc0204980:	d0c60613          	addi	a2,a2,-756 # ffffffffc0207688 <slub_pmm_manager+0x58>
ffffffffc0204984:	85a6                	mv	a1,s1
ffffffffc0204986:	854a                	mv	a0,s2
ffffffffc0204988:	0bc000ef          	jal	ra,ffffffffc0204a44 <printfmt>
ffffffffc020498c:	bb41                	j	ffffffffc020471c <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020498e:	00003417          	auipc	s0,0x3
ffffffffc0204992:	cf240413          	addi	s0,s0,-782 # ffffffffc0207680 <slub_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204996:	85e2                	mv	a1,s8
ffffffffc0204998:	8522                	mv	a0,s0
ffffffffc020499a:	e43e                	sd	a5,8(sp)
ffffffffc020499c:	0fc000ef          	jal	ra,ffffffffc0204a98 <strnlen>
ffffffffc02049a0:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02049a4:	01b05b63          	blez	s11,ffffffffc02049ba <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02049a8:	67a2                	ld	a5,8(sp)
ffffffffc02049aa:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02049ae:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02049b0:	85a6                	mv	a1,s1
ffffffffc02049b2:	8552                	mv	a0,s4
ffffffffc02049b4:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02049b6:	fe0d9ce3          	bnez	s11,ffffffffc02049ae <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02049ba:	00044783          	lbu	a5,0(s0)
ffffffffc02049be:	00140a13          	addi	s4,s0,1
ffffffffc02049c2:	0007851b          	sext.w	a0,a5
ffffffffc02049c6:	d3a5                	beqz	a5,ffffffffc0204926 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02049c8:	05e00413          	li	s0,94
ffffffffc02049cc:	bf39                	j	ffffffffc02048ea <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02049ce:	000a2403          	lw	s0,0(s4)
ffffffffc02049d2:	b7ad                	j	ffffffffc020493c <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02049d4:	000a6603          	lwu	a2,0(s4)
ffffffffc02049d8:	46a1                	li	a3,8
ffffffffc02049da:	8a2e                	mv	s4,a1
ffffffffc02049dc:	bdb1                	j	ffffffffc0204838 <vprintfmt+0x156>
ffffffffc02049de:	000a6603          	lwu	a2,0(s4)
ffffffffc02049e2:	46a9                	li	a3,10
ffffffffc02049e4:	8a2e                	mv	s4,a1
ffffffffc02049e6:	bd89                	j	ffffffffc0204838 <vprintfmt+0x156>
ffffffffc02049e8:	000a6603          	lwu	a2,0(s4)
ffffffffc02049ec:	46c1                	li	a3,16
ffffffffc02049ee:	8a2e                	mv	s4,a1
ffffffffc02049f0:	b5a1                	j	ffffffffc0204838 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02049f2:	9902                	jalr	s2
ffffffffc02049f4:	bf09                	j	ffffffffc0204906 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02049f6:	85a6                	mv	a1,s1
ffffffffc02049f8:	02d00513          	li	a0,45
ffffffffc02049fc:	e03e                	sd	a5,0(sp)
ffffffffc02049fe:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204a00:	6782                	ld	a5,0(sp)
ffffffffc0204a02:	8a66                	mv	s4,s9
ffffffffc0204a04:	40800633          	neg	a2,s0
ffffffffc0204a08:	46a9                	li	a3,10
ffffffffc0204a0a:	b53d                	j	ffffffffc0204838 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0204a0c:	03b05163          	blez	s11,ffffffffc0204a2e <vprintfmt+0x34c>
ffffffffc0204a10:	02d00693          	li	a3,45
ffffffffc0204a14:	f6d79de3          	bne	a5,a3,ffffffffc020498e <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0204a18:	00003417          	auipc	s0,0x3
ffffffffc0204a1c:	c6840413          	addi	s0,s0,-920 # ffffffffc0207680 <slub_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204a20:	02800793          	li	a5,40
ffffffffc0204a24:	02800513          	li	a0,40
ffffffffc0204a28:	00140a13          	addi	s4,s0,1
ffffffffc0204a2c:	bd6d                	j	ffffffffc02048e6 <vprintfmt+0x204>
ffffffffc0204a2e:	00003a17          	auipc	s4,0x3
ffffffffc0204a32:	c53a0a13          	addi	s4,s4,-941 # ffffffffc0207681 <slub_pmm_manager+0x51>
ffffffffc0204a36:	02800513          	li	a0,40
ffffffffc0204a3a:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204a3e:	05e00413          	li	s0,94
ffffffffc0204a42:	b565                	j	ffffffffc02048ea <vprintfmt+0x208>

ffffffffc0204a44 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204a44:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0204a46:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204a4a:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204a4c:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204a4e:	ec06                	sd	ra,24(sp)
ffffffffc0204a50:	f83a                	sd	a4,48(sp)
ffffffffc0204a52:	fc3e                	sd	a5,56(sp)
ffffffffc0204a54:	e0c2                	sd	a6,64(sp)
ffffffffc0204a56:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0204a58:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204a5a:	c89ff0ef          	jal	ra,ffffffffc02046e2 <vprintfmt>
}
ffffffffc0204a5e:	60e2                	ld	ra,24(sp)
ffffffffc0204a60:	6161                	addi	sp,sp,80
ffffffffc0204a62:	8082                	ret

ffffffffc0204a64 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0204a64:	4781                	li	a5,0
ffffffffc0204a66:	00006717          	auipc	a4,0x6
ffffffffc0204a6a:	5aa73703          	ld	a4,1450(a4) # ffffffffc020b010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0204a6e:	88ba                	mv	a7,a4
ffffffffc0204a70:	852a                	mv	a0,a0
ffffffffc0204a72:	85be                	mv	a1,a5
ffffffffc0204a74:	863e                	mv	a2,a5
ffffffffc0204a76:	00000073          	ecall
ffffffffc0204a7a:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0204a7c:	8082                	ret

ffffffffc0204a7e <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0204a7e:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0204a82:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0204a84:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0204a86:	cb81                	beqz	a5,ffffffffc0204a96 <strlen+0x18>
        cnt ++;
ffffffffc0204a88:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0204a8a:	00a707b3          	add	a5,a4,a0
ffffffffc0204a8e:	0007c783          	lbu	a5,0(a5)
ffffffffc0204a92:	fbfd                	bnez	a5,ffffffffc0204a88 <strlen+0xa>
ffffffffc0204a94:	8082                	ret
    }
    return cnt;
}
ffffffffc0204a96:	8082                	ret

ffffffffc0204a98 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0204a98:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204a9a:	e589                	bnez	a1,ffffffffc0204aa4 <strnlen+0xc>
ffffffffc0204a9c:	a811                	j	ffffffffc0204ab0 <strnlen+0x18>
        cnt ++;
ffffffffc0204a9e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204aa0:	00f58863          	beq	a1,a5,ffffffffc0204ab0 <strnlen+0x18>
ffffffffc0204aa4:	00f50733          	add	a4,a0,a5
ffffffffc0204aa8:	00074703          	lbu	a4,0(a4)
ffffffffc0204aac:	fb6d                	bnez	a4,ffffffffc0204a9e <strnlen+0x6>
ffffffffc0204aae:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0204ab0:	852e                	mv	a0,a1
ffffffffc0204ab2:	8082                	ret

ffffffffc0204ab4 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204ab4:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204ab8:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204abc:	cb89                	beqz	a5,ffffffffc0204ace <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0204abe:	0505                	addi	a0,a0,1
ffffffffc0204ac0:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204ac2:	fee789e3          	beq	a5,a4,ffffffffc0204ab4 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204ac6:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0204aca:	9d19                	subw	a0,a0,a4
ffffffffc0204acc:	8082                	ret
ffffffffc0204ace:	4501                	li	a0,0
ffffffffc0204ad0:	bfed                	j	ffffffffc0204aca <strcmp+0x16>

ffffffffc0204ad2 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0204ad2:	c20d                	beqz	a2,ffffffffc0204af4 <strncmp+0x22>
ffffffffc0204ad4:	962e                	add	a2,a2,a1
ffffffffc0204ad6:	a031                	j	ffffffffc0204ae2 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0204ad8:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0204ada:	00e79a63          	bne	a5,a4,ffffffffc0204aee <strncmp+0x1c>
ffffffffc0204ade:	00b60b63          	beq	a2,a1,ffffffffc0204af4 <strncmp+0x22>
ffffffffc0204ae2:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0204ae6:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0204ae8:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0204aec:	f7f5                	bnez	a5,ffffffffc0204ad8 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204aee:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0204af2:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204af4:	4501                	li	a0,0
ffffffffc0204af6:	8082                	ret

ffffffffc0204af8 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0204af8:	ca01                	beqz	a2,ffffffffc0204b08 <memset+0x10>
ffffffffc0204afa:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0204afc:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0204afe:	0785                	addi	a5,a5,1
ffffffffc0204b00:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0204b04:	fec79de3          	bne	a5,a2,ffffffffc0204afe <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0204b08:	8082                	ret

ffffffffc0204b0a <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0204b0a:	ca19                	beqz	a2,ffffffffc0204b20 <memcpy+0x16>
ffffffffc0204b0c:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0204b0e:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0204b10:	0005c703          	lbu	a4,0(a1)
ffffffffc0204b14:	0585                	addi	a1,a1,1
ffffffffc0204b16:	0785                	addi	a5,a5,1
ffffffffc0204b18:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0204b1c:	fec59ae3          	bne	a1,a2,ffffffffc0204b10 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0204b20:	8082                	ret

ffffffffc0204b22 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0204b22:	c205                	beqz	a2,ffffffffc0204b42 <memcmp+0x20>
ffffffffc0204b24:	962e                	add	a2,a2,a1
ffffffffc0204b26:	a019                	j	ffffffffc0204b2c <memcmp+0xa>
ffffffffc0204b28:	00c58d63          	beq	a1,a2,ffffffffc0204b42 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0204b2c:	00054783          	lbu	a5,0(a0)
ffffffffc0204b30:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0204b34:	0505                	addi	a0,a0,1
ffffffffc0204b36:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0204b38:	fee788e3          	beq	a5,a4,ffffffffc0204b28 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204b3c:	40e7853b          	subw	a0,a5,a4
ffffffffc0204b40:	8082                	ret
    }
    return 0;
ffffffffc0204b42:	4501                	li	a0,0
}
ffffffffc0204b44:	8082                	ret
