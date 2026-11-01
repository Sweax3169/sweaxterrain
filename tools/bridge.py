"""Local bridge between Roblox Studio and this repo, used for testing and for the README art.

    python tools/bridge.py   (listens on 127.0.0.1:8767)

GET  /src/<file>    -> a file from src/ or tools/ (Studio builds throwaway ModuleScripts from it)
POST /dump/<name>   -> body saved to dumps/<name> (terrain and structure dumps for the art tools)
POST /append/<name> -> body appended to dumps/<name> (Studio posts are limited to 1 MB)

Studio side: HttpService:GetAsync / PostAsync to http://127.0.0.1:8767. Only binds to localhost.
"""
import http.server
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DUMPS = ROOT / "dumps"
SAFE = re.compile(r"^[A-Za-z0-9_.\-]+$")


class Handler(http.server.BaseHTTPRequestHandler):
    def _send(self, code, body=b"", ctype="text/plain; charset=utf-8"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parts = self.path.strip("/").split("/")
        if len(parts) == 2 and parts[0] in ("src", "tools") and SAFE.match(parts[1]):
            f = ROOT / parts[0] / parts[1]
            if f.is_file():
                return self._send(200, f.read_bytes())
        if self.path == "/ping":
            return self._send(200, b"ok")
        self._send(404, b"not found")

    def do_POST(self):
        parts = self.path.strip("/").split("/")
        n = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(n)
        if len(parts) == 2 and parts[0] in ("dump", "append") and SAFE.match(parts[1]):
            DUMPS.mkdir(exist_ok=True)
            with open(DUMPS / parts[1], "ab" if parts[0] == "append" else "wb") as fh:
                fh.write(body)
            return self._send(200, f"saved {len(body)} bytes".encode())
        self._send(404, b"not found")

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    print("bridge on http://127.0.0.1:8767")
    http.server.ThreadingHTTPServer(("127.0.0.1", 8767), Handler).serve_forever()
