// Z03Plus QRC overlay with on-device verification of the final resolved file.
#include <QCoreApplication>
#include <QFile>
#include <QObject>
#include <QResource>
#include <QVariantMap>
#include <QtQml/qqml.h>
#include <unistd.h>

extern "C" void *dlsym(void *handle, const char *symbol);
#define RTLD_NEXT ((void *)-1l)
typedef unsigned char uchar;
typedef int (*RegisterResource)(int, const uchar *, const uchar *, const uchar *);

static bool gOverlayRegistered = false;

// QML can invoke only these fixed scripts. No command text is accepted from
// QML, so this cannot become a general shell-execution interface.
class Z03PlusSshService : public QObject
{
    Q_OBJECT
public:
    Q_INVOKABLE bool start()
    {
        return launch("/home/user/z03plus/ssh/start-sshd.sh; "
                      "/home/user/z03plus/update_ssh_status.sh");
    }

    Q_INVOKABLE bool refresh()
    {
        return launch("/home/user/z03plus/update_ssh_status.sh");
    }

    Q_INVOKABLE bool stop()
    {
        return launch("if [ -s /home/user/z03plus/ssh/sshd.pid ]; then "
                      "kill $(cat /home/user/z03plus/ssh/sshd.pid) 2>/dev/null || true; "
                      "rm -f /home/user/z03plus/ssh/sshd.pid; fi; "
                      "/home/user/z03plus/update_ssh_status.sh");
    }

    Q_INVOKABLE QVariantMap status() const
    {
        QVariantMap values;
        QFile file(QStringLiteral("/home/user/z03plus/ssh-status.txt"));
        if (!file.open(QIODevice::ReadOnly))
            return values;
        const QList<QByteArray> rows = file.readAll().split('\n');
        for (const QByteArray &row : rows) {
            const int delimiter = row.indexOf('=');
            if (delimiter > 0)
                values.insert(QString::fromLatin1(row.left(delimiter)),
                              QString::fromUtf8(row.mid(delimiter + 1)));
        }
        return values;
    }

private:
    static bool launch(const char *command)
    {
        const pid_t pid = fork();
        if (pid < 0)
            return false;
        if (pid == 0) {
            execl("/bin/sh", "sh", "-c", command, static_cast<char *>(nullptr));
            _exit(127);
        }
        return true;
    }
};

static void registerZ03PlusQmlTypes()
{
    qmlRegisterType<Z03PlusSshService>("Z03Plus", 1, 0, "SshService");
}
Q_COREAPP_STARTUP_FUNCTION(registerZ03PlusQmlTypes)

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

#include "z03plus_overlay.moc"
