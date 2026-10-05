#!/usr/bin/env bash
# Print a Markdown file to an A4 PDF via marked and headless Chrome.
set -euo pipefail

usage() {
  cat <<'EOF'
usage: print-to-pdf.sh [options] FILE.md

Options:
  -o, --output PDF      output path (default: FILE.pdf next to the input)
  -l, --lang CODE       document language and footer word (default: en)
  -t, --title TEXT      document title (default: first "# " heading)
  -c, --css FILE        extra stylesheet after print.css; repeatable
      --no-page-numbers omit the "Page N / M" footer
  -h, --help            show this help

Environment:
  CHROME                browser binary to use instead of auto-detection
EOF
}

die() {
  echo "print-to-pdf: $*" >&2
  exit 1
}

dir="$(dirname "$(readlink -f "$0")")"
out=""
lang="en"
title=""
css=()
page_numbers=1
src=""

while (($#)); do
  case "$1" in
    -o | --output) out="${2:?$1 needs a value}"; shift 2 ;;
    -l | --lang) lang="${2:?$1 needs a value}"; shift 2 ;;
    -t | --title) title="${2:?$1 needs a value}"; shift 2 ;;
    -c | --css) css+=("${2:?$1 needs a value}"); shift 2 ;;
    --no-page-numbers) page_numbers=0; shift ;;
    -h | --help) usage; exit 0 ;;
    --) shift; break ;;
    -*) usage >&2; die "unknown option: $1" ;;
    *)
      [[ -z "$src" ]] || die "only one input file is supported"
      src="$1"
      shift
      ;;
  esac
done
if (($#)); then
  [[ -z "$src" && $# -eq 1 ]] || die "only one input file is supported"
  src="$1"
fi

[[ -n "$src" ]] || { usage >&2; exit 1; }
[[ -f "$src" ]] || die "no such file: $src"
css=("$dir/print.css" "${css[@]}")
for f in "${css[@]}"; do
  [[ -f "$f" ]] || die "no such stylesheet: $f"
done

src_dir="$(cd "$(dirname "$src")" && pwd)"
src="$src_dir/$(basename "$src")"
[[ -n "$out" ]] || out="${src%.*}.pdf"

if [[ -z "$title" ]]; then
  title="$(sed -n 's/^# \{1,\}//p' "$src" | head -n 1)"
  [[ -n "$title" ]] || title="$(basename "${src%.*}")"
fi

case "$lang" in
  ms | id) page_word="Halaman" ;;
  *) page_word="Page" ;;
esac

if [[ -n "${CHROME:-}" ]]; then
  chrome="$CHROME"
  command -v "$chrome" >/dev/null || die "CHROME not found: $chrome"
else
  chrome=""
  for c in google-chrome google-chrome-stable chromium chromium-browser; do
    if command -v "$c" >/dev/null; then
      chrome="$c"
      break
    fi
  done
  [[ -n "$chrome" ]] || die "Chrome or Chromium not found; set CHROME"
fi

if command -v bunx >/dev/null; then
  marked=(bunx marked)
else
  marked=(npx --yes marked)
fi

escape_html() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

{
  printf '<!doctype html><html lang="%s"><head><meta charset="utf-8">' "$lang"
  printf '<base href="file://%s/">' "$src_dir"
  printf '<title>%s</title><style>\n' "$(escape_html "$title")"
  cat "${css[@]}"
  if ((page_numbers)); then
    printf '@page { @bottom-center { content: "%s " counter(page) " / " counter(pages); } }\n' "$page_word"
  fi
  printf '</style></head><body>\n'
  "${marked[@]}" --gfm -i "$src"
  printf '</body></html>\n'
} > "$tmp/document.html"

rm -f "$out"
"$chrome" --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$out" "file://$tmp/document.html" 2>/dev/null

[[ -s "$out" ]] || die "Chrome did not write $out"
echo "$out"
