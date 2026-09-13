import QtQuick 2.0
import QtQuick.Controls 2.3
import "../Funcs/UILogics.js" as UILogic
import "../ZybControls/"
import "../Style"

Rectangle {
    id: root
    anchors.fill: parent
    color: "#0F0F0F"
    property string running: "未知"
    property string ip: "正在读取…"
    property string port: "22"
    property string user: "p010"
    property string keyStatus: "未配置"
    property string command: ""

    ZybBackButton {
        anchors.top: parent.top; anchors.topMargin: 10
        anchors.left: parent.left; anchors.leftMargin: 10
        onBackClicked: StackView.view.pop()
    }
    ZybText {
        text: qsTr("SSH 远程连接")
        font.styleName: "Bold"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top; anchors.topMargin: 18
    }

    Column {
        anchors.left: parent.left; anchors.leftMargin: 36
        anchors.right: parent.right; anchors.rightMargin: 36
        anchors.top: parent.top; anchors.topMargin: 74
        spacing: 14
        ZybText { text: qsTr("服务：") + root.running }
        ZybText { text: qsTr("IP 地址：") + root.ip; wrapMode: Text.WrapAnywhere }
        ZybText { text: qsTr("端口：") + root.port }
        ZybText { text: qsTr("用户名：") + root.user }
        ZybText { text: qsTr("公钥：") + root.keyStatus }
        ZybText { text: qsTr("连接命令：") + root.command; wrapMode: Text.WrapAnywhere }
        ZybText {
            width: parent.width
            text: qsTr("使用 SSH 公钥免密码登录；仅允许 user 登录，root 的 SSH 登录已禁用。请只在可信 Wi-Fi 网络使用。")
            wrapMode: Text.WordWrap
            color: "#B8B8B8"
            font.pixelSize: 18
        }
        BasicButton {
            text: qsTr("刷新状态")
            width: 210; height: 58; radius: 8; checkable: false
            backgroundTheme: Qt.rgba(60/255, 61/255, 66/255, 0.6)
            onClicked: root.loadStatus()
        }
    }

    function loadStatus() {
        var request = new XMLHttpRequest()
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE || request.status !== 200)
                return
            var rows = request.responseText.split("\n")
            for (var i = 0; i < rows.length; ++i) {
                var part = rows[i].indexOf("=")
                if (part < 1) continue
                var key = rows[i].slice(0, part)
                var value = rows[i].slice(part + 1)
                if (key === "running") root.running = value === "on" ? qsTr("已开启") : qsTr("未开启")
                else if (key === "ip") root.ip = value
                else if (key === "port") root.port = value
                else if (key === "user") root.user = value
                else if (key === "key_status") root.keyStatus = value
                else if (key === "command") root.command = value
            }
        }
        request.open("GET", "file:///home/user/z03plus/ssh-status.txt?" + Date.now())
        request.send()
    }
    Component.onCompleted: loadStatus()
}
