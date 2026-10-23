#!/usr/bin/env python3
import socket, ssl, threading, sys

PORT = 8899
REFERER = "https://www.bilibili.com/"
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

def parse_url(u):
    if u.startswith("https://"):
        rest = u[8:]; port = 443; tls = True
    elif u.startswith("http://"):
        rest = u[7:]; port = 80; tls = False
    else:
        return None
    if "/" in rest:
        host, path = rest.split("/", 1); path = "/" + path
    else:
        host, path = rest, "/"
    if ":" in host:
        host, ps = host.split(":", 1); port = int(ps)
    return host, port, path, tls

def handle(c):
    try:
        data = c.recv(8192).decode("latin1")
        if not data: return
        line = data.split("\r\n")[0]
        parts = line.split(" ")
        if len(parts) < 2: return
        path = parts[1]
        if path.startswith("/ping"):
            c.sendall(b"HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok"); return
        if not path.startswith("/v?u="):
            c.sendall(b"HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n"); return
        target = path[5:]
        # 反转义
        out = []
        i = 0
        while i < len(target):
            if target[i] == "%" and i + 2 < len(target):
                out.append(chr(int(target[i+1:i+3], 16))); i += 3
            else:
                out.append(target[i]); i += 1
        target = "".join(out)
        info = parse_url(target)
        if not info:
            c.sendall(b"HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n\r\n"); return
        host, port, tpath, tls = info
        rng = None
        for h in data.split("\r\n"):
            if h.lower().startswith("range:"): rng = h.split(":", 1)[1].strip()
        s = socket.create_connection((host, port), timeout=20)
        if tls:
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            s = ctx.wrap_socket(s, server_hostname=host)
        req = "GET " + tpath + " HTTP/1.1\r\n"
        req += "Host: " + host + "\r\n"
        req += "Referer: " + REFERER + "\r\n"
        req += "User-Agent: " + UA + "\r\n"
        req += "Accept: */*\r\n"
        req += "Connection: close\r\n"
        if rng: req += "Range: " + rng + "\r\n"
        req += "\r\n"
        s.sendall(req.encode("latin1"))
        while True:
            b = s.recv(65536)
            if not b: break
            c.sendall(b)
        s.close()
    except Exception as e:
        try: c.sendall(("HTTP/1.1 502 Bad Gateway\r\nContent-Length: 0\r\n\r\n").encode())
        except: pass
    finally:
        try: c.close()
        except: pass

srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", PORT))
srv.listen(32)
while True:
    c, a = srv.accept()
    threading.Thread(target=handle, args=(c,), daemon=True).start()
