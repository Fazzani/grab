#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/run/scripts"
cp "$repo/build.sh" "$work/run/"
cp "$repo/scripts/grab_from_url.sh" "$repo/scripts/utils.sh" "$work/run/scripts/"
export PATH="$work/bin:$PATH"
export TEST_FIXTURE="$work/source.xml.gz"
export TEST_XML="$work/source.xml"
printf '<tv><channel id="test"/><programme channel="test" start="20990101000000 +0000" stop="20990101010000 +0000"><title>Test</title></programme></tv>\n' > "$TEST_XML"
gzip -c "$TEST_XML" > "$TEST_FIXTURE"

cat > "$work/bin/wget" <<'EOF'
#!/usr/bin/env bash
while (($#)); do
  case "$1" in
    -O) output=$2; shift 2 ;;
    https://*) url=$1; shift ;;
    *) shift ;;
  esac
done
if [[ $url == *fail* ]]; then
  echo '  HTTP/1.1 503 Service Unavailable' >&2
  echo '  Location: https://example.test/?secret-token' >&2
  exit 8
fi
case "$url" in
  *bad*) printf 'invalid gzip' > "$output" ;;
  *.zip*) printf 'mock archive' > "$output" ;;
  *.gz*) cp "$TEST_FIXTURE" "$output" ;;
  *) cp "$TEST_XML" "$output" ;;
esac
EOF
cat > "$work/bin/unzip" <<'EOF'
#!/usr/bin/env bash
archive=$3
while (($#)); do
  if [[ $1 == -d ]]; then dest=$2; shift 2; else shift; fi
done
mkdir -p "$dest/nested"
cp "$TEST_XML" "$dest/guide.xml"
if [[ $(cat "$archive") == 'invalid gzip' ]]; then exit 1; fi
cp "$TEST_XML" "$dest/nested/guide.xmltv"
EOF
cat > "$work/bin/tv_cat" <<'EOF'
#!/usr/bin/env bash
cat "${@:2}"
[[ ${TEST_FAIL_MERGE:-0} != 1 ]]
EOF
cat > "$work/bin/tv_grep" <<'EOF'
#!/usr/bin/env bash
if [[ ${TEST_EMPTY_MERGE:-0} == 1 ]]; then
  cat > /dev/null
  printf '<tv><channel id="test"/></tv>'
else
  cat
fi
EOF
cat > "$work/bin/zip" <<'EOF'
#!/usr/bin/env bash
cp "$3" "$2"
EOF
cat > "$work/bin/python3" <<'EOF'
#!/usr/bin/env bash
exec python "$@"
EOF
chmod +x "$work/bin/"*
cd "$work/run"
export EPG_TMP_DIR="$work/input"

source "$repo/scripts/utils.sh"
split_epg_urls $'https://example.test/fail.xml?secret-token  https://example.test/guide.xml.gz?key=test\nhttps://example.test/guide.zip;\thttps://example.test/example.xml?one=*&two=?\r\n'
[[ ${#epg_urls[@]} == 4 ]]
[[ ${epg_urls[0]} == 'https://example.test/fail.xml?secret-token' ]]
[[ ${epg_urls[1]} == 'https://example.test/guide.xml.gz?key=test' ]]
[[ ${epg_urls[2]} == 'https://example.test/guide.zip' ]]
[[ ${epg_urls[3]} == 'https://example.test/example.xml?one=*&two=?' ]]
split_epg_urls ''
[[ ${#epg_urls[@]} == 0 ]]
split_epg_urls 'https://example.test/fail.xml?secret-token https://example.test/guide.xml.gz?key=test'
bash ./build.sh --download "${epg_urls[@]}" > "$work/download.log" 2>&1
grep -q 'HTTP 503' "$work/download.log"
if grep -q 'secret-token' "$work/download.log"; then
  echo 'Download logs exposed a URL or response header' >&2
  exit 1
fi
files=("$EPG_TMP_DIR"/*.xml)
[[ ${#files[@]} == 1 && -s ${files[0]} ]]
cmp "$TEST_XML" "${files[0]}"

if bash ./build.sh --download 'https://example.test/fail.xml' > /dev/null 2>&1; then
  echo 'All-source download failure was ignored' >&2
  exit 1
fi
if bash ./build.sh --download 'https://example.test/bad.xml.gz' > /dev/null 2>&1; then
  echo 'Invalid gzip was accepted' >&2
  exit 1
fi
if bash ./build.sh --download 'https://example.test/bad.zip' > /dev/null 2>&1; then
  echo 'Invalid zip was accepted' >&2
  exit 1
fi
files=("$EPG_TMP_DIR"/*.xml)
[[ ${#files[@]} == 1 ]]

export EPG_TMP_DIR="$work/archive-input"
bash ./build.sh --download 'https://example.test/guide.zip'
archive_files=("$EPG_TMP_DIR"/*.xml)
[[ ${#archive_files[@]} == 2 ]]
cmp "$TEST_XML" "${archive_files[0]}"
cmp "$TEST_XML" "${archive_files[1]}"

export EPG_TMP_DIR="$work/input"
printf '<tv><channel' > "$EPG_TMP_DIR/malformed.xml"
printf 'previous merge\n' > merge.xml
TEST_FAIL_MERGE=1
export TEST_FAIL_MERGE
if bash "$repo/docker/merge.sh" "$EPG_TMP_DIR"; then
  echo 'Merge failure was ignored' >&2
  exit 1
fi
[[ $(cat merge.xml) == 'previous merge' ]]
unset TEST_FAIL_MERGE
bash "$repo/docker/merge.sh" "$EPG_TMP_DIR"
cmp "$TEST_XML" merge.xml
gzip -cd merge.xml.gz | cmp - merge.xml

TEST_EMPTY_MERGE=1
export TEST_EMPTY_MERGE
if bash "$repo/docker/merge.sh" "$EPG_TMP_DIR"; then
  echo 'A merge without programmes was accepted' >&2
  exit 1
fi
unset TEST_EMPTY_MERGE
cmp "$TEST_XML" merge.xml

mkdir "$work/invalid-input"
printf '<html>server error</html>' > "$work/invalid-input/html.xml"
printf '<?xml version="1.0" encoding="secret-token"?><tv><channel/></tv>' > "$work/invalid-input/encoding.xml"
if bash "$repo/docker/merge.sh" "$work/invalid-input"; then
  echo 'Invalid XMLTV input was accepted' >&2
  exit 1
fi
cmp "$TEST_XML" merge.xml
echo 'Pipeline regression checks passed'
