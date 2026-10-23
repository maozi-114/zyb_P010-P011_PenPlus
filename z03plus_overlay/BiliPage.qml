import QtQuick 2.0
import QtQuick.Controls 2.3
import QtQuick.VirtualKeyboard 2.0
import QtMultimedia 5.0

// Bilibili browser/player for the 960x480 landscape surface (480x960 panel + weston transform).
Rectangle {
    id: page
    anchors.fill: parent
    color: "#0E1014"

    readonly property int barH: 52
    readonly property int listW: Math.min(392, Math.max(300, Math.round(width * 0.40)))
    readonly property int rowH: 76
    readonly property int thumbW: 96
    readonly property int thumbH: 54

    property bool playing: false
    property bool fullscreen: false
    property bool soundOn: false
    property bool busy: false
    property bool searching: false
    property string keyword: ""
    property string listTitle: "热门视频"
    property string currentBvid: ""
    property string currentTitle: ""
    property string message: ""
    property int requestId: 0

    signal closeRequested()

    ListModel { id: videos }

    Video {
        id: player
        anchors.fill: page.fullscreen ? page : videoBox
        z: page.fullscreen ? 60 : 1
        fillMode: VideoOutput.PreserveAspectFit
        autoPlay: false
        muted: !page.soundOn
        volume: page.soundOn ? 1.0 : 0.0
        onStatusChanged: {
            if (status === MediaPlayer.Loading) page.message = "正在加载视频…"
            else if (status === MediaPlayer.Buffering) page.message = "正在缓冲…"
            else if (status === MediaPlayer.Loaded || status === MediaPlayer.Buffered) page.message = ""
            else if (status === MediaPlayer.EndOfMedia) page.message = "播放结束"
            else if (status === MediaPlayer.InvalidMedia) page.message = "视频无法播放"
        }
        onErrorChanged: if (error !== MediaPlayer.NoError) page.message = errorString.length ? errorString : "播放失败"
    }

    // ---------- top bar ----------
    Rectangle {
        id: topBar
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: page.barH; color: "#171A20"; z: 30
        visible: !page.fullscreen

        Rectangle {
            id: backBtn
            width: 44; height: 36
            anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
            radius: 8; color: backMa.pressed ? "#333944" : "#232830"
            Text { anchors.centerIn: parent; text: "‹"; color: "#FFFFFF"; font.pixelSize: 30 }
            MouseArea {
                id: backMa; anchors.fill: parent
                onClicked: { player.stop(); page.closeRequested() }
            }
        }

        Rectangle {
            id: searchBox
            anchors.left: backBtn.right; anchors.leftMargin: 10
            anchors.right: searchBtn.left; anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 36; radius: 18
            color: "#0B0D11"
            border.width: input.activeFocus ? 1 : 0
            border.color: "#FB7299"

            Text {
                anchors.left: parent.left; anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "搜索视频、UP 主"
                color: "#6E7581"; font.pixelSize: 14
                visible: input.text.length === 0
            }
            TextInput {
                id: input
                anchors.left: parent.left; anchors.leftMargin: 14
                anchors.right: parent.right; anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                color: "#F1F2F3"; font.pixelSize: 14
                selectByMouse: true
                clip: true
                onAccepted: page.doSearch(text)
            }
        }

        Rectangle {
            id: searchBtn
            width: 62; height: 34
            anchors.right: parent.right; anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            radius: 8; color: searchMa.pressed ? "#D95D83" : "#FB7299"
            Text { anchors.centerIn: parent; text: "搜索"; color: "#FFFFFF"; font.pixelSize: 14 }
            MouseArea {
                id: searchMa; anchors.fill: parent
                onClicked: page.doSearch(input.text)
            }
        }
    }

    // ---------- left list ----------
    Rectangle {
        id: listPane
        anchors.top: topBar.bottom; anchors.left: parent.left; anchors.bottom: parent.bottom
        width: page.listW; color: "#12151A"
        visible: !page.fullscreen

        Text {
            id: listHead
            anchors.left: parent.left; anchors.leftMargin: 16
            anchors.top: parent.top; anchors.topMargin: 10
            text: page.listTitle
            color: "#FFFFFF"; font.pixelSize: 16; font.bold: true
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 14
            anchors.verticalCenter: listHead.verticalCenter
            text: page.busy ? "加载中…" : (videos.count > 0 ? videos.count + " 条" : "")
            color: "#7C838F"; font.pixelSize: 12
        }

        ListView {
            id: list
            anchors.top: listHead.bottom; anchors.topMargin: 8
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            clip: true; model: videos; spacing: 4
            delegate: Rectangle {
                width: list.width - 12; height: page.rowH; x: 6; radius: 8
                color: rowMa.pressed ? "#2C313A" : (page.currentBvid === model.bvid ? "#2A2229" : "#1B1F26")
                Rectangle {
                    width: 3; radius: 2
                    anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
                    color: page.currentBvid === model.bvid ? "#FB7299" : "transparent"
                }
                Rectangle {
                    id: thumb
                    width: page.thumbW; height: page.thumbH
                    anchors.left: parent.left; anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 5; color: "#0A0C0F"; clip: true
                    Image {
                        anchors.fill: parent
                        source: model.cover.length ? "http://127.0.0.1:8899/v?u=" + encodeURIComponent(model.cover) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; cache: true
                        sourceSize.width: page.thumbW * 2
                        sourceSize.height: page.thumbH * 2
                    }
                    Text {
                        anchors.right: parent.right; anchors.bottom: parent.bottom
                        anchors.rightMargin: 3; anchors.bottomMargin: 2
                        text: model.duration
                        color: "#FFFFFF"; font.pixelSize: 10
                        style: Text.Outline; styleColor: "#000000"
                    }
                }
                Text {
                    anchors.left: thumb.right; anchors.leftMargin: 9
                    anchors.right: parent.right; anchors.rightMargin: 8
                    anchors.top: parent.top; anchors.topMargin: 9
                    text: model.title
                    color: "#EDEFF2"; font.pixelSize: 13
                    wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
                }
                Text {
                    anchors.left: thumb.right; anchors.leftMargin: 9
                    anchors.right: parent.right; anchors.rightMargin: 8
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                    text: model.owner
                    color: "#7C838F"; font.pixelSize: 11; elide: Text.ElideRight
                }
                MouseArea {
                    id: rowMa; anchors.fill: parent
                    onClicked: page.playVideo(model.bvid, model.title)
                }
            }
            Text {
                anchors.centerIn: parent; width: parent.width - 30
                text: page.busy ? "正在加载…" : (videos.count === 0 ? page.message : "")
                visible: videos.count === 0
                color: "#8A919D"; font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            }
        }
    }

    // ---------- right viewer ----------
    Rectangle {
        id: viewerPane
        anchors.top: topBar.bottom
        anchors.left: listPane.right; anchors.right: parent.right; anchors.bottom: parent.bottom
        color: "#0E1014"
        visible: !page.fullscreen

        Text {
            id: titleLabel
            anchors.left: parent.left; anchors.leftMargin: 14
            anchors.right: fsBtn.left; anchors.rightMargin: 10
            anchors.top: parent.top; anchors.topMargin: 8
            height: 30
            text: page.currentTitle.length ? page.currentTitle : "从左侧选择视频"
            color: "#F2F3F5"; font.pixelSize: 14; font.bold: true
            elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            id: fsBtn
            width: 58; height: 28
            anchors.right: parent.right; anchors.rightMargin: 12
            anchors.top: parent.top; anchors.topMargin: 9
            radius: 6; color: fsMa.pressed ? "#333944" : "#232830"
            visible: page.currentBvid.length > 0
            Text { anchors.centerIn: parent; text: "全屏"; color: "#E5E7EB"; font.pixelSize: 12 }
            MouseArea { id: fsMa; anchors.fill: parent; onClicked: page.fullscreen = true }
        }

        Rectangle {
            id: videoBox
            anchors.top: titleLabel.bottom; anchors.topMargin: 4
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: ctrlBar.top
            anchors.leftMargin: 12; anchors.rightMargin: 12; anchors.bottomMargin: 6
            color: "#050608"; radius: 6; clip: true
            visible: page.currentBvid.length > 0
            Text {
                anchors.centerIn: parent; width: parent.width - 24
                text: page.message
                visible: page.message.length > 0 && player.status !== MediaPlayer.Loaded && player.status !== MediaPlayer.Buffered
                color: "#E8E8E8"; font.pixelSize: 13
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; z: 2
            }
        }
        Text {
            anchors.centerIn: videoBox
            visible: page.currentBvid.length === 0
            text: "选择视频后在此播放"
            color: "#6E7581"; font.pixelSize: 15
        }

        Rectangle {
            id: ctrlBar
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: 62; color: "#171A20"

            Rectangle {
                id: track
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top; anchors.leftMargin: 14; anchors.rightMargin: 14; anchors.topMargin: 9
                height: 5; radius: 3; color: "#343A44"
                Rectangle {
                    height: parent.height; radius: 3; color: "#FB7299"
                    width: player.duration > 0 ? parent.width * Math.max(0, Math.min(1, player.position / player.duration)) : 0
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (player.seekable && player.duration > 0) player.seek(player.duration * Math.max(0, Math.min(1, mouse.x / width)))
                    onPositionChanged: if (pressed && player.seekable && player.duration > 0) player.seek(player.duration * Math.max(0, Math.min(1, mouse.x / width)))
                }
            }
            Text {
                anchors.left: parent.left; anchors.leftMargin: 14
                anchors.top: track.bottom; anchors.topMargin: 6
                text: page.timeText(player.position) + " / " + page.timeText(player.duration)
                color: "#9AA1AC"; font.pixelSize: 11
            }
            Rectangle {
                width: 66; height: 32
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                radius: 7; color: playMa.pressed ? "#D95D83" : "#FB7299"
                Text {
                    anchors.centerIn: parent
                    text: player.playbackState === MediaPlayer.PlayingState ? "暂停" : "播放"
                    color: "#FFFFFF"; font.pixelSize: 13
                }
                MouseArea {
                    id: playMa; anchors.fill: parent
                    onClicked: {
                        if (player.playbackState === MediaPlayer.PlayingState) player.pause()
                        else if (page.currentBvid.length && player.source.toString().length) player.play()
                        else if (page.currentBvid.length) page.playVideo(page.currentBvid, page.currentTitle)
                    }
                }
            }
            Rectangle {
                width: 66; height: 32
                anchors.right: parent.right; anchors.rightMargin: 86
                anchors.verticalCenter: parent.verticalCenter
                radius: 7; color: sndMa.pressed ? "#333944" : "#232830"
                Text {
                    anchors.centerIn: parent
                    text: page.soundOn ? "有声" : "静音"
                    color: "#E5E7EB"; font.pixelSize: 12
                }
                MouseArea { id: sndMa; anchors.fill: parent; onClicked: page.soundOn = !page.soundOn }
            }
        }
    }

    // ---------- fullscreen overlay: only a back button ----------
    Rectangle {
        id: fsBack
        width: 46; height: 40
        anchors.left: parent.left; anchors.leftMargin: 10
        anchors.top: parent.top; anchors.topMargin: 10
        radius: 20; color: fsBackMa.pressed ? "#4A4F58" : "#33383F"
        opacity: 0.92
        visible: page.fullscreen
        z: 70
        Text { anchors.centerIn: parent; text: "‹"; color: "#FFFFFF"; font.pixelSize: 30 }
        MouseArea {
            id: fsBackMa; anchors.fill: parent
            onClicked: page.fullscreen = false
        }
    }

    // ---------- helpers ----------
    function requestJson(url, callback) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status !== 200) { callback("网络错误 " + xhr.status, null); return }
            try { callback(null, JSON.parse(xhr.responseText)) }
            catch (e) { callback("数据解析失败", null) }
        }
        xhr.open("GET", url)
        xhr.setRequestHeader("Referer", "https://www.bilibili.com/")
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0")
        xhr.send()
    }

    function stripTags(text) {
        return String(text).replace(/<[^>]*>/g, "")
    }

    function secToText(seconds) {
        var total = Math.max(0, Math.floor(seconds))
        var h = Math.floor(total / 3600)
        var m = Math.floor((total % 3600) / 60)
        var s = total % 60
        if (h > 0) return h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    function timeText(milliseconds) {
        return secToText(milliseconds / 1000)
    }

    function fillList(items) {
        videos.clear()
        for (var i = 0; i < items.length; ++i) {
            var it = items[i]
            var cover = it.cover ? it.cover : (it.pic ? it.pic : "")
            if (cover.indexOf("//") === 0) cover = "https:" + cover
            else if (cover.indexOf("http://") === 0) cover = "https://" + cover.substring(7)
            videos.append({
                bvid: it.bvid,
                title: stripTags(it.title),
                owner: it.owner,
                cover: cover,
                duration: it.duration
            })
        }
    }

    function loadPopular() {
        var id = ++page.requestId
        page.busy = true; page.searching = false; page.listTitle = "热门视频"; page.message = ""
        requestJson("https://api.bilibili.com/x/web-interface/popular?ps=20&pn=1", function(err, data) {
            if (id !== page.requestId) return
            page.busy = false
            if (err || !data || data.code !== 0 || !data.data || !data.data.list) {
                page.message = err ? err : "热门列表获取失败"; return
            }
            var src = data.data.list, items = []
            for (var i = 0; i < src.length; ++i) {
                var v = src[i]
                items.push({
                    bvid: v.bvid,
                    title: v.title,
                    owner: v.owner ? v.owner.name : "",
                    cover: v.pic,
                    duration: secToText(v.duration)
                })
            }
            page.fillList(items)
        })
    }

    // Bilibili search is risk-controlled: it may answer code:0 with only a
    // "v_voucher" payload instead of results. The proxy carries a full desktop
    // UA which passes reliably, so search goes through it and retries on miss.
    function doSearch(text) {
        var kw = String(text).replace(/^\s+|\s+$/g, "")
        if (kw.length === 0) { page.loadPopular(); return }
        var id = ++page.requestId
        page.keyword = kw
        page.busy = true; page.searching = true
        page.listTitle = "搜索：" + kw
        page.message = ""
        searchAttempt(kw, id, 0)
    }

    function searchAttempt(kw, id, attempt) {
        var api = "https://api.bilibili.com/x/web-interface/wbi/search/type?search_type=video&page=1&keyword=" + encodeURIComponent(kw)
        requestJson("http://127.0.0.1:8899/v?u=" + encodeURIComponent(api), function(err, data) {
            if (id !== page.requestId) return
            var blocked = !err && data && data.code === 0 && data.data && !data.data.result && data.data.v_voucher
            if (blocked && attempt < 3) { searchAttempt(kw, id, attempt + 1); return }
            page.busy = false
            if (err || !data || data.code !== 0 || !data.data || !data.data.result) {
                page.message = err ? err : (blocked ? "搜索被限流，请稍后重试" : ("搜索失败：" + (data && data.message ? data.message : "无结果")))
                videos.clear(); return
            }
            var src = data.data.result, items = []
            for (var i = 0; i < src.length; ++i) {
                var v = src[i]
                if (!v.bvid) continue
                items.push({
                    bvid: v.bvid,
                    title: v.title,
                    owner: v.author,
                    cover: v.pic,
                    duration: v.duration
                })
            }
            page.fillList(items)
            if (items.length === 0) page.message = "没有找到相关视频"
        })
    }

    function playVideo(bvid, title) {
        var id = ++page.requestId
        page.currentBvid = bvid
        page.currentTitle = title
        page.message = "正在获取播放地址…"
        player.stop(); player.source = ""
        requestJson("https://api.bilibili.com/x/web-interface/view?bvid=" + encodeURIComponent(bvid), function(err, view) {
            if (id !== page.requestId) return
            if (err || !view || view.code !== 0 || !view.data || !view.data.cid) {
                page.message = err ? err : "无法读取视频信息"; return
            }
            var url = "https://api.bilibili.com/x/player/playurl?bvid=" + encodeURIComponent(bvid) +
                      "&cid=" + view.data.cid + "&qn=32&fnval=1&fnver=0&fourk=1"
            page.requestJson(url, function(e2, res) {
                if (id !== page.requestId) return
                if (e2 || !res || res.code !== 0 || !res.data || !res.data.durl || res.data.durl.length === 0) {
                    page.message = e2 ? e2 : "未取得可播放的视频流"; return
                }
                var stream = res.data.durl[0]
                var src = stream.backup_url && stream.backup_url.length ? stream.backup_url[0] : stream.url
                if (!src) { page.message = "视频地址为空"; return }
                page.soundOn = false
                player.source = "http://127.0.0.1:8899/v?u=" + encodeURIComponent(src)
                player.play()
            })
        })
    }

    Component.onCompleted: page.loadPopular()
    Component.onDestruction: { ++page.requestId; player.stop() }
}