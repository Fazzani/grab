#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
server_pid=
cleanup() {
  if [[ -n $server_pid ]]; then kill "$server_pid" 2>/dev/null || true; fi
  rm -rf "$work"
}
trap cleanup EXIT
cd "$work"
export EPG_TMP_DIR="$work/input"

cat > guide.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE tv SYSTEM "xmltv.dtd">
<tv><channel id="test.fr"><display-name>Test</display-name></channel><programme start="20990101000000 +0000" stop="20990101010000 +0000" channel="test.fr"><title>Test programme</title></programme></tv>
EOF
gzip -c guide.xml > guide.xml.gz
cat > server.py <<'EOF'
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith("/fail"):
            self.send_response(404)
            self.end_headers()
            return
        data = Path("guide.xml.gz").read_bytes()
        self.send_response(200)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


server = HTTPServer(("127.0.0.1", 0), Handler)
Path("port").write_text(str(server.server_port))
server.serve_forever()
EOF
python3 server.py &
server_pid=$!
for _ in {1..50}; do
  [[ -s port ]] && break
  sleep 0.1
done
port=$(cat port)

source "$repo/scripts/utils.sh"
split_epg_urls "http://127.0.0.1:$port/fail.xml?secret-token http://127.0.0.1:$port/guide.xml.gz"
bash "$repo/scripts/grab_from_url.sh" "${epg_urls[@]}" > download.log 2>&1
grep -q 'HTTP 404' download.log
if grep -q 'secret-token' download.log; then
  echo 'Download logs exposed a URL or response header' >&2
  exit 1
fi
printf '<tv><channel' > "$EPG_TMP_DIR/malformed.xml"
bash "$repo/docker/merge.sh" "$EPG_TMP_DIR"
python3 "$repo/scripts/validate_xmltv.py" merge.xml --require-programme
gzip -t merge.xml.gz
[[ -s merge.zip ]]
echo 'XMLTV integration checks passed'
