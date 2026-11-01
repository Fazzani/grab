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
printf '<tv><channel id="test"/></tv>\n' | gzip > "$TEST_FIXTURE"

cat > "$work/bin/wget" <<'EOF'
#!/usr/bin/env bash
[[ ${TEST_FAIL_DOWNLOAD:-0} != 1 ]] || exit 1
cp "$TEST_FIXTURE" "$3"
EOF
cat > "$work/bin/tv_cat" <<'EOF'
#!/usr/bin/env bash
cat "$2"
[[ ${TEST_FAIL_MERGE:-0} != 1 ]]
EOF
cat > "$work/bin/tv_grep" <<'EOF'
#!/usr/bin/env bash
cat
EOF
cat > "$work/bin/zip" <<'EOF'
#!/usr/bin/env bash
cp "$3" "$2"
EOF
chmod +x "$work/bin/"*
cd "$work/run"

bash "$repo/scripts/grab_from_url.sh" 'https://example.test/guide.xml.gz?key=test'
files=(tmp/*.xml)
[[ ${#files[@]} == 1 && -s ${files[0]} ]]
gzip -cd "$TEST_FIXTURE" | cmp - "${files[0]}"

TEST_FAIL_DOWNLOAD=1
export TEST_FAIL_DOWNLOAD
if bash "$repo/scripts/grab_from_url.sh" 'https://example.test/fail.xml.gz'; then
  echo 'Download failure was ignored' >&2
  exit 1
fi
if bash ./build.sh --download 'https://example.test/fail.xml.gz'; then
  echo 'Build ignored download failure' >&2
  exit 1
fi
unset TEST_FAIL_DOWNLOAD

printf 'invalid gzip' > "$TEST_FIXTURE"
if bash "$repo/scripts/grab_from_url.sh" 'https://example.test/bad.xml.gz'; then
  echo 'Invalid gzip was accepted' >&2
  exit 1
fi
files=(tmp/*.xml)
[[ ${#files[@]} == 1 && -s ${files[0]} ]]
printf '<tv><channel id="test"/></tv>\n' | gzip > "$TEST_FIXTURE"

printf 'previous merge\n' > merge.xml
TEST_FAIL_MERGE=1
export TEST_FAIL_MERGE
if bash "$repo/docker/merge.sh" ./tmp; then
  echo 'Merge failure was ignored' >&2
  exit 1
fi
[[ $(cat merge.xml) == 'previous merge' ]]
unset TEST_FAIL_MERGE
bash "$repo/docker/merge.sh" ./tmp
cmp "${files[0]}" merge.xml
gzip -cd merge.xml.gz | cmp - merge.xml
echo 'Pipeline regression checks passed'
