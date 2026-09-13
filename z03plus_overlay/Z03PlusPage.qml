import QtQuick 2.0
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import "../Funcs/UILogics.js" as UILogic
import "../ZybControls/"
import "../Style"
import Z03Plus 1.0

Rectangle {
    id: root
    anchors.fill: parent
    color: "#0F0F0F"
    property color cardColor: Qt.rgba(60/255, 61/255, 66/255, 0.6)
    property bool sshPageVisible: false
    SshService { id: sshService }

    ZybBackButton {
        id: backButton
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.leftMargin: 10
        onBackClicked: {
            root.visible = false
            UILogic.backToSetPage()
        }
    }

    ZybText {
        text: qsTr("Z03Plus 扩展")
        font.styleName: "Bold"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: backButton.verticalCenter
    }

    Flickable {
        id: featureList
        anchors.top: backButton.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        clip: true
        contentWidth: width
        contentHeight: featureGrid.height + 10
        flickableDirection: Flickable.VerticalFlick

        Grid {
            id: featureGrid
            width: featureList.width
            columns: 2
            rowSpacing: 12
            columnSpacing: 12

            BasicButton {
                text: qsTr("文件管理")
                implicitWidth: (featureList.width - 12) / 2
                implicitHeight: 62
                radius: 8
                checkable: false
                backgroundTheme: root.cardColor
                onClicked: showTip(qsTr("文件管理：正在接入本地文件后端"))
            }
            BasicButton {
                text: qsTr("文本阅读")
                implicitWidth: (featureList.width - 12) / 2
                implicitHeight: 62
                radius: 8
                checkable: false
                backgroundTheme: root.cardColor
                onClicked: showTip(qsTr("TXT / MD 阅读：正在接入文件读取后端"))
            }
            BasicButton {
                text: qsTr("存储空间")
                implicitWidth: (featureList.width - 12) / 2
                implicitHeight: 62
                radius: 8
                checkable: false
                backgroundTheme: root.cardColor
                onClicked: showTip(qsTr("数据目录：/home/user  和  /mnt/data"))
            }
            BasicButton {
                text: qsTr("更多功能")
                implicitWidth: (featureList.width - 12) / 2
                implicitHeight: 62
                radius: 8
                checkable: false
                backgroundTheme: root.cardColor
                onClicked: showTip(qsTr("网络、播放器、录音功能正在适配"))
            }
            BasicButton {
                text: qsTr("显示与灯光")
                implicitWidth: (featureList.width - 12) / 2
                implicitHeight: 62
                radius: 8
                checkable: false
                backgroundTheme: root.cardColor
                onClicked: StackView.view.push("qrc:/ZybQmlFiles/ZybSet/SetLightPage.qml")
            }
            BasicButton {
                text: qsTr("ADB / SSH")
                implicitWidth: (featureList.width - 12) / 2
                implicitHeight: 62
                radius: 8
                checkable: false
                backgroundTheme: root.cardColor
                onClicked: { root.sshPageVisible = true; root.refreshSshStatus() }
            }
            BasicButton {
                text: qsTr("音乐播放器")
                implicitWidth: (featureList.width - 12) / 2
                implicitHeight: 62
                radius: 8
                checkable: false
                backgroundTheme: root.cardColor
                onClicked: showTip(qsTr("播放器正在接入 /mnt/data 媒体文件"))
            }
            BasicButton {
                text: qsTr("录音与息屏")
                implicitWidth: (featureList.width - 12) / 2
                implicitHeight: 62
                radius: 8
                checkable: false
                backgroundTheme: root.cardColor
                onClicked: showTip(qsTr("录音与息屏硬件接口正在适配"))
            }
        }
    }

    Rectangle {
        id: sshPage
        visible: root.sshPageVisible
        z: 20
        anchors.fill: parent
        color: "#0F0F0F"

        ZybBackButton {
            anchors.top: parent.top; anchors.topMargin: 10
            anchors.left: parent.left; anchors.leftMargin: 10
            onBackClicked: root.sshPageVisible = false
        }
        ZybText {
            text: qsTr("SSH 远程连接")
            font.styleName: "Bold"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: 18
        }
        BasicButton {
            text: "⏻"
            anchors.right: refreshButton.left; anchors.rightMargin: 10
            anchors.top: parent.top; anchors.topMargin: 9
            width: 56; height: 48; radius: 24; checkable: false
            backgroundTheme: root.cardColor
            onClicked: {
                if (root.sshRunning === qsTr("已开启")) {
                    sshService.stop()
                    root.showTip(qsTr("正在关闭 SSH 服务"))
                } else {
                    sshService.start()
                    root.showTip(qsTr("正在启动 SSH 服务"))
                }
                sshRefreshTimer.restart()
            }
        }
        BasicButton {
            id: refreshButton
            text: "↻"
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.top: parent.top; anchors.topMargin: 9
            width: 52; height: 48; radius: 24; checkable: false
            backgroundTheme: root.cardColor
            onClicked: root.refreshSshStatus()
        }
        Flickable {
            anchors.left: parent.left; anchors.leftMargin: 28
            anchors.right: parent.right; anchors.rightMargin: 20
            anchors.top: parent.top; anchors.topMargin: 74
            anchors.bottom: parent.bottom; anchors.bottomMargin: 14
            clip: true
            contentWidth: width
            contentHeight: sshDetails.height + 10
            flickableDirection: Flickable.VerticalFlick
            Column {
                id: sshDetails
                width: parent.width - 8
                spacing: 14
            ZybText { text: qsTr("服务：") + root.sshRunning }
            ZybText { text: qsTr("IP 地址：") + root.sshIp; wrapMode: Text.WrapAnywhere }
            ZybText { text: qsTr("端口：") + root.sshPort }
            ZybText { text: qsTr("用户名：") + root.sshUser }
            ZybText { text: qsTr("公钥：") + root.sshKeyStatus }
            ZybText { text: qsTr("连接命令：") + root.sshCommand; wrapMode: Text.WrapAnywhere }
            ZybText {
                width: parent.width; color: "#B8B8B8"; font.pixelSize: 18
                wrapMode: Text.WordWrap
                text: qsTr("使用 SSH 公钥免密码登录；仅允许 user 登录，root 的 SSH 登录已禁用。")
            }
            }
        }
    }

    property string sshRunning: "未知"
    property string sshIp: "正在读取…"
    property string sshPort: "22"
    property string sshUser: "user"
    property string sshKeyStatus: "未配置"
    property string sshCommand: ""
    property int sshRefreshAttempts: 0
    Timer {
        id: sshRefreshTimer
        interval: 700
        repeat: false
        onTriggered: {
            root.loadSshStatus()
            if (root.sshRefreshAttempts > 0) {
                root.sshRefreshAttempts--
                sshRefreshTimer.restart()
            }
        }
    }

    function refreshSshStatus() {
        sshService.refresh()
        sshRefreshAttempts = 2
        sshRefreshTimer.restart()
    }

    function loadSshStatus() {
        var values = sshService.status()
        if (!values || !values.running)
            return
        root.sshRunning = values.running === "on" ? qsTr("已开启") : qsTr("未开启")
        root.sshIp = values.ip || qsTr("未连接 Wi-Fi")
        root.sshPort = values.port || "22"
        root.sshUser = values.user || "user"
        root.sshKeyStatus = values.key_status || qsTr("未配置")
        root.sshCommand = values.command || ""
    }

    function showTip(message) {
        tip.text = message
        tip.visible = true
        tipTimer.restart()
    }
    Text {
        id: tip
        visible: false
        z: 10
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 22
        color: "#12CFA7"
        font.pixelSize: 22
    }
    Timer { id: tipTimer; interval: 1800; onTriggered: tip.visible = false }
}
