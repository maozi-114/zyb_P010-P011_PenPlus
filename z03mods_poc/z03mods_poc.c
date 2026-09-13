/*
 * Z03Mods stage-0 probe.
 * No libc/Qt dependencies: it proves that the ARMv7 dynamic loader accepts
 * our library before we add Qt/QML resource hooks.
 */

static long sys_write(int fd, const char *buf, unsigned long len)
{
    register long r0 __asm__("r0") = fd;
    register const char *r1 __asm__("r1") = buf;
    register unsigned long r2 __asm__("r2") = len;
    register long r7 __asm__("r7") = 4; /* __NR_write, ARM EABI */
    __asm__ volatile ("svc 0" : "+r"(r0) : "r"(r1), "r"(r2), "r"(r7) : "memory");
    return r0;
}

static long sys_open(const char *path, int flags, int mode)
{
    register const char *r0 __asm__("r0") = path;
    register int r1 __asm__("r1") = flags;
    register int r2 __asm__("r2") = mode;
    register long r7 __asm__("r7") = 5; /* __NR_open, ARM EABI */
    __asm__ volatile ("svc 0" : "+r"(r0) : "r"(r1), "r"(r2), "r"(r7) : "memory");
    return (long)r0;
}

static long sys_close(int fd)
{
    register long r0 __asm__("r0") = fd;
    register long r7 __asm__("r7") = 6; /* __NR_close, ARM EABI */
    __asm__ volatile ("svc 0" : "+r"(r0) : "r"(r7) : "memory");
    return r0;
}

__attribute__((constructor)) static void z03mods_loaded(void)
{
    static const char path[] = "/home/user/z03mods/preload-ok.log";
    static const char message[] = "Z03Mods stage-0 preload loaded\n";
    /* O_WRONLY | O_CREAT | O_APPEND, 0644 */
    long fd = sys_open(path, 1 | 0100 | 02000, 0644);
    if (fd >= 0) {
        sys_write((int)fd, message, sizeof(message) - 1);
        sys_close((int)fd);
    }
}
