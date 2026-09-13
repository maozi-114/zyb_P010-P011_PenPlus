/* Stage-2: trace every Qt QRC registration made while Z03 starts. */
typedef unsigned char uchar;
typedef int (*register_resource_t)(int, const uchar *, const uchar *, const uchar *);
extern void *dlsym(void *handle, const char *symbol);
#define RTLD_NEXT ((void *)-1l)
static long sys_write(int fd, const char *buf, unsigned long len) {
    register long r0 __asm__("r0")=fd; register const char *r1 __asm__("r1")=buf;
    register unsigned long r2 __asm__("r2")=len; register long r7 __asm__("r7")=4;
    __asm__ volatile("svc 0":"+r"(r0):"r"(r1),"r"(r2),"r"(r7):"memory"); return r0;
}
static long sys_open(const char *path,int flags,int mode) {
    register long r0 __asm__("r0")=(long)path; register long r1 __asm__("r1")=flags;
    register long r2 __asm__("r2")=mode; register long r7 __asm__("r7")=5;
    __asm__ volatile("svc 0":"+r"(r0):"r"(r1),"r"(r2),"r"(r7):"memory"); return r0;
}
static long sys_close(int fd) { register long r0 __asm__("r0")=fd; register long r7 __asm__("r7")=6; __asm__ volatile("svc 0":"+r"(r0):"r"(r7):"memory"); return r0; }
static void hex32(char *dst,unsigned long v) { static const char d[]="0123456789abcdef"; int i; for(i=7;i>=0;--i){dst[i]=d[v&15];v>>=4;} }
static void log_call(int version,const uchar *tree,const uchar *names,const uchar *data) {
    static unsigned count; static char line[]="0 v=0 tree=0x00000000 names=0x00000000 data=0x00000000\n";
    long fd; if(count>=10) return; line[0]=(char)('0'+count++); line[4]=(char)('0'+version);
    hex32(line+13,(unsigned long)tree); hex32(line+30,(unsigned long)names); hex32(line+46,(unsigned long)data);
    fd=sys_open("/home/user/z03plus/qrc-calls.log",1|0100|02000,0644); if(fd>=0){sys_write((int)fd,line,sizeof(line)-1);sys_close((int)fd);}
}
int qRegisterResourceData(int version,const uchar *tree,const uchar *names,const uchar *data) __asm__("_Z21qRegisterResourceDataiPKhS0_S0_");
int qRegisterResourceData(int version,const uchar *tree,const uchar *names,const uchar *data) {
    static register_resource_t original; if(!original) original=(register_resource_t)dlsym(RTLD_NEXT,"_Z21qRegisterResourceDataiPKhS0_S0_");
    log_call(version,tree,names,data); return original?original(version,tree,names,data):0;
}
