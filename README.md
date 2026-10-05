# print-to-pdf

Print a Markdown file to a clean A4 PDF from the command line.

`print-to-pdf.sh` converts Markdown (GitHub-flavoured) to HTML with
[marked](https://marked.js.org/), styles it with a print stylesheet, and
prints it with headless Chrome. Page numbers go in the footer.

## Requirements

- **Bash** 4 or newer.
- **Bun** (`bunx`) or **Node.js** (`npx`), to run `marked`. It is fetched on
  first use; nothing to install by hand.
- **Google Chrome** or **Chromium**.

## Install

```sh
git clone <repo-url> print-to-pdf
ln -s "$PWD/print-to-pdf/print-to-pdf.sh" ~/.local/bin/print-to-pdf
```

The symlink is optional. The script finds `print.css` next to its real
location, so it works from anywhere.

## Usage

```sh
print-to-pdf.sh [options] FILE.md
```

The PDF is written next to the input (`notes.md` becomes `notes.pdf`) and
its path is printed.

| Option | Default | Effect |
|---|---|---|
| `-o, --output PDF` | `FILE.pdf` | Output path |
| `-l, --lang CODE` | `en` | Document language and footer word |
| `-t, --title TEXT` | first `# ` heading, else file name | PDF title |
| `-c, --css FILE` | none | Extra stylesheet loaded after `print.css`; repeatable |
| `--no-page-numbers` | off | Omit the `Page N / M` footer |
| `-h, --help` | | Show usage |

Set `CHROME` to pick the browser binary. Otherwise the script tries
`google-chrome`, `google-chrome-stable`, `chromium` and `chromium-browser`,
in that order.

### Examples

```sh
# notes.md -> notes.pdf
print-to-pdf.sh notes.md

# Choose the output path and title
print-to-pdf.sh -o ~/Desktop/report.pdf -t "Q3 Report" report.md

# Malay document: footer reads "Halaman 1 / 3"
print-to-pdf.sh --lang ms laporan.md

# Default styles plus your own overrides
print-to-pdf.sh -c extra.css notes.md

# Use a specific browser
CHROME=/snap/bin/chromium print-to-pdf.sh notes.md
```

## Styling

`print.css` sets A4 pages, 2 cm margins, a sans-serif body and bordered
tables. Override any rule with an extra stylesheet via `--css`, or edit
the file directly.

The footer word follows `--lang`: `ms` and `id` give "Halaman", everything
else gives "Page".

Handy hooks in the default stylesheet:

- **Page break:** put `<div class="page-break"></div>` on its own line.
- **Header block:** the paragraph straight after the `# ` title gets tighter
  spacing, for metadata such as author and date.
- **Images and links:** relative paths resolve against the Markdown file's
  directory.

To keep the first two table columns on one line (useful for dates and IDs),
add this to an extra stylesheet:

```css
td:nth-child(1),
td:nth-child(2) {
  white-space: nowrap;
}
```

## License

[MIT](LICENSE)
