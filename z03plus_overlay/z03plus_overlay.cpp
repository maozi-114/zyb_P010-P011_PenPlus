// Z03Plus QRC overlay with on-device verification of the final resolved file.
#include <QFile>
#include <QResource>

extern "C" void *dlsym(void *handle, const char *symbol);
#define RTLD_NEXT ((void *)-1l)
typedef unsigned char uchar;
typedef int (*RegisterResource)(int, const uchar *, const uchar *, const uchar *);

static bool gOverlayRegistered = false;

static void logResolvedResource()
{
    QFile page(QStringLiteral(":/ZybQmlFiles/ZybSet/SetMainPage.qml"));
    QFile log(QStringLiteral("/home/user/z03plus/overlay-status.log"));
    if (!log.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return;
    log.write("overlay_registerResource=");
    log.write(gOverlayRegistered ? "true\n" : "false\n");
    QFile overlayFile(QStringLiteral(":/ZybQmlFiles/ZybSet/Z03PlusPage.qml"));
    log.write("overlay_new_page_open=");
    log.write(overlayFile.open(QIODevice::ReadOnly) ? "true\n" : "false\n");
    if (!page.open(QIODevice::ReadOnly)) {
        log.write("SetMainPage open failed\n");
        return;
    }
    const QByteArray source = page.readAll();
    log.write("bytes=");
    log.write(QByteArray::number(source.size()));
    log.write("\ncontains_z03plus=");
    log.write(source.contains("Z03Plus") ? "yes\n" : "no\n");
    log.write("register_order=overlay-before-original\n");
}

extern "C" int qRegisterResourceData(int version, const uchar *tree,
                                     const uchar *names, const uchar *data)
    __asm__("_Z21qRegisterResourceDataiPKhS0_S0_");

extern "C" int qRegisterResourceData(int version, const uchar *tree,
                                     const uchar *names, const uchar *data)
{
    static RegisterResource original = nullptr;
    if (!original)
        original = reinterpret_cast<RegisterResource>(
            dlsym(RTLD_NEXT, "_Z21qRegisterResourceDataiPKhS0_S0_"));

    const bool isZ03Resources = tree == reinterpret_cast<const uchar *>(0x001ab51c);
    if (isZ03Resources && !gOverlayRegistered)
        gOverlayRegistered = QResource::registerResource(QStringLiteral("/home/user/z03plus/z03plus.rcc"));

    const int result = original ? original(version, tree, names, data) : 0;
    if (isZ03Resources)
        logResolvedResource();
    return result;
}
