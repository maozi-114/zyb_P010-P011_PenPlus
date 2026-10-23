# Bilibili 视频页（BiliPage）

在 Z03Plus 扩展页里加一个 B 站视频入口：热门列表 + 搜索 + 播放。

## 为什么需要本地代理

B 站视频 CDN 有防盗链，要求请求带 `Referer: https://www.bilibili.com/`。
QML 的 `Video` 组件没有设置 HTTP 请求头的属性，直接播会返回 **403 Forbidden**。

`proxy3.py` 是一个最小 HTTP 转发代理（纯 socket + ssl，不依赖 Python 标准库的
`http.server`，因为设备上的 Python 是精简版，缺 `html` / `BaseHTTPServer` 模块）：

- 监听 `127.0.0.1:8899`
- `GET /ping` → 返回 `ok`，用于健康检查
- `GET /v?u=<urlencoded>` → 转发到目标 URL，自动补 `Referer` / `User-Agent`，透传 `Range`

QML 里把视频地址包一层：

```qml
player.source = "http://127.0.0.1:8899/v?u=" + encodeURIComponent(streamUrl)
```

## User-Agent 必须完整

B 站搜索接口 `x/web-interface/wbi/search/type` 有风控。被判定为爬虫时仍返回
`code: 0`，但 `data` 里只有 `v_voucher`，没有 `result`，表现为“搜不出来”。

实测（每档 5~10 次请求）：

| User-Agent | 拿到结果 |
|---|---|
| `Mozilla/5.0` | 3/5 |
| `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36` | **0/5** |
| `...AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36` | **8/8** |

所以代理里的 UA 必须是完整桌面 Chrome UA。`BiliPage.qml` 的搜索也走代理，
并对 `v_voucher` 响应自动重试最多 3 次。

## 部署

```sh
# 1. 代理
mkdir -p /mnt/data/bili
# 把 proxy3.py 传到 /mnt/data/bili/
cd /mnt/data/bili && nohup python3 proxy3.py > p3.log 2>&1 &

# 2. 开机自启
cat > /etc/init.d/biliproxy <<'EOF'
#!/bin/sh
if [ -z "$(pidof python3)" ]; then
    cd /mnt/data/bili && nohup python3 proxy3.py > /mnt/data/bili/p3.log 2>&1 &
fi
EOF
chmod +x /etc/init.d/biliproxy
ln -sf /etc/init.d/biliproxy /etc/rc5.d/S99biliproxy
ln -sf /etc/init.d/biliproxy /etc/rcS.d/S99biliproxy
```

## 打包 rcc

设备只认 **RCC v2**（v3 的 header `data_off` 是 24，v2 是 20，设备会拒绝加载）：

```sh
rcc --binary --format-version 2 --no-compress -o z03plus.rcc z03plus.qrc
```

部署后必须清 QML 缓存，否则改动不生效：

```sh
rm -f /home/.cache/Z03Plus/qmlcache/*
kill $(pidof Z03Plus)   # 约 8 秒后自动重启
```

## 用到的接口

| 用途 | 接口 |
|---|---|
| 热门列表 | `GET /x/web-interface/popular?ps=20&pn=1` |
| 搜索 | `GET /x/web-interface/wbi/search/type?search_type=video&page=1&keyword=` |
| 视频信息（取 cid） | `GET /x/web-interface/view?bvid=` |
| 播放地址 | `GET /x/player/playurl?bvid=&cid=&qn=32&fnval=1&fnver=0&fourk=1` |

`playurl` 返回的 `durl[0].url` 主地址在部分网络下不可用（403），
代码优先取 `durl[0].backup_url[0]`。

## 界面

设备面板物理是 480×960 竖屏，weston 通过 `transform=270` 在合成阶段旋转，
所以应用层看到的是 **960×480 横屏**。页面按这个尺寸做双栏：

```
┌────────────────────────────────────────────┐
│ ‹  [搜索框              ] [搜索]            │ 52px
├──────────────┬─────────────────────────────┤
│ 推荐视频 20条 │ 标题                [全屏]  │
│ ┌──────────┐ │ ┌─────────────────────────┐ │
│ │封面 标题 │ │ │        视频画面          │ │
│ │     UP主 │ │ └─────────────────────────┘ │
│ └──────────┘ │ ━━━━━━━━━━━━━━━━━━━━━━━━━  │
│              │ 0:00 / 3:33   [静音] [播放] │ 62px
└──────────────┴─────────────────────────────┘
```

- 默认**静音**，点“静音”按钮才出声，每次换视频自动回到静音
- 全屏后只保留左上角一个圆形返回按钮
- 窄屏（`width < 720`）自动退化为单栏
