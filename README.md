# GNOME Markdown QuickLook

> **Beautiful markdown previews for GNOME** - Press Space in Nautilus to preview .md files with rich formatting, syntax highlighting, and multiple flavor support.

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![GNOME](https://img.shields.io/badge/GNOME-Sushi-orange.svg)](https://wiki.gnome.org/Apps/Sushi)

Similar to macOS [QLMarkdown](https://github.com/sbarex/QLMarkdown), this extension brings Quick Look-style markdown previews to GNOME Linux desktops.

> **This is a maintained fork** of [noboomu/gnome-markdown-ql](https://github.com/noboomu/gnome-markdown-ql).
> The original project's install script referenced files that didn't match its own repo layout, so a
> fresh install never actually worked. This fork fixes that, plus three bugs found while getting it
> running on Ubuntu 24.04: the preview silently crashing on every file (unrelated to this project —
> Ubuntu 24.04+ restricts unprivileged user namespaces by default, so WebKit's sandbox needs an
> AppArmor profile; `install.sh` now adds one), Mermaid diagrams never actually rendering (the fence
> was only wired up for one of eight markdown flavors), and any bare `$` character — a price, a shell
> variable — pointlessly fetching MathJax over the network.

## ✨ Features

- 🚀 **8 Markdown Flavors** - GitHub, CommonMark, Pandoc, GitLab, and more
- 🎨 **Auto Theme Detection** - Seamlessly adapts to GNOME light/dark themes
- 🔧 **Syntax Highlighting** - Powered by [Pygments](https://pygments.org/) with 40+ styles
- 📊 **Rich Content** - Tables, task lists, math equations, [Mermaid](https://mermaid.js.org/) diagrams (all 8 flavors)
- 📴 **Works Offline** - Mermaid + MathJax are vendored locally, not fetched from a CDN on every preview
- ⚡ **Instant Preview** - Sub-second rendering with WebKit2GTK; math is only loaded when real LaTeX is detected
- 🌐 **Standards Compliant** - Full HTML5 + CSS3 + JavaScript support

## 🚀 Quick Install

One-liner, no clone needed:

```bash
curl -fsSL https://raw.githubusercontent.com/smlblr/gnome-markdown-quicklook/main/install.sh | bash
```

Or clone first (lets you read `install.sh` before running it, or edit it):

```bash
git clone https://github.com/smlblr/gnome-markdown-quicklook.git
cd gnome-markdown-quicklook
./install.sh
```

**That's it!** The installer handles dependencies (installs [uv](https://github.com/astral-sh/uv) if
missing), vendors Mermaid + MathJax locally, adds the AppArmor profile Ubuntu 24.04+ needs, and sets up
file associations — automatically.

## 📋 Supported Markdown Flavors

| Flavor | Specification | Key Features |
|--------|---------------|--------------|
| **[GFM](https://github.github.com/gfm/)** | GitHub Flavored Markdown | Tables, task lists, strikethrough, @mentions |
| **[CommonMark](https://spec.commonmark.org/0.31.2/)** | CommonMark 0.31.2 | Standards-compliant parsing |
| **[PyMdown](https://facelessuser.github.io/pymdown-extensions/)** | Enhanced GitHub-like | Emoji, keyboard keys, advanced highlighting |
| **[Pandoc](https://pandoc.org/MANUAL.html#pandocs-markdown)** | Pandoc Markdown | Extensive extensions, citations, metadata |
| **[Extra](https://python-markdown.github.io/extensions/extra/)** | PHP Markdown Extra | Definition lists, abbreviations, footnotes |
| **[GitLab](https://docs.gitlab.com/ee/user/markdown.html)** | GitLab Flavored Markdown | GFM + GitLab-specific references (!123, etc.) |
| **[MMD](https://fletcher.github.io/MultiMarkdown-6/)** | MultiMarkdown v6 | Metadata, citations, advanced tables |
| **Standard** | [Python Markdown](https://python-markdown.github.io/) | Basic markdown features |

## 🎯 Usage

### Basic Usage
1. **Open Nautilus** (GNOME Files)
2. **Select any `.md` file**
3. **Press `Space`** → Preview opens instantly!
4. **Press `Escape`** to close

### Advanced Usage

**Test different flavors:**
```bash
sushi-markdown-converter document.md --flavor gfm
sushi-markdown-converter document.md --flavor commonmark
sushi-markdown-converter document.md --flavor pandoc
```

**Export to HTML:**
```bash
sushi-markdown-converter document.md --output preview.html --flavor gfm
```

**List all flavors:**
```bash
sushi-markdown-converter --help
```

## 📝 Supported File Types

- `.md` - Standard Markdown
- `.markdown` - Markdown document
- `.mdown` - Markdown document
- `.mkd` - Markdown document
- `.mkdn` - Markdown document

## 🔧 System Requirements

- **OS**: Linux with GNOME desktop
- **GNOME Sushi**: File previewer (`sudo apt install gnome-sushi`)
- **WebKit2GTK**: Web rendering (`sudo apt install libwebkit2gtk-4.1-0`)
- **[uv](https://github.com/astral-sh/uv)**: `install.sh` installs it for you if it's missing

### Ubuntu 24.04+ (and anything else with `apparmor_restrict_unprivileged_userns=1`)

Check with `cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns` — if it prints `1`, profile-less
processes that open a user namespace get shoved into a restricted AppArmor profile. WebKit's preview
sandbox does exactly that, so **without a profile, the preview crashes silently on every markdown
file** (Space does nothing). `install.sh` detects this and installs `/etc/apparmor.d/gnome-sushi`
(the same `unconfined { userns, }` pattern Ubuntu itself uses for nautilus/epiphany) — asking for
`sudo` only for that one step.

### Dependencies

The converter is a single self-contained script (PEP 723 inline metadata) — `uv run --script` resolves
its Python dependencies on first use, no separate venv or `pip install` step:
[Python Markdown](https://python-markdown.github.io/), [Pygments](https://pygments.org/),
[PyMdown Extensions](https://facelessuser.github.io/pymdown-extensions/),
[CommonMark](https://github.com/readthedocs/commonmark.py),
[markdown-it-py](https://github.com/executablebooks/markdown-it-py),
[python-markdown-math](https://github.com/mitya57/python-markdown-math).

## 🏗️ Architecture

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│ Markdown    │───▶│ Python       │───▶│ Styled      │───▶│ WebKit2      │
│ File        │    │ Converter    │    │ HTML        │    │ Preview      │
│ (.md)       │    │ (Multi-flavor)│    │ (CSS+JS)    │    │ (Sushi)      │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
```

**Components:**
1. **[GNOME Sushi](https://gitlab.gnome.org/GNOME/sushi)** - File preview framework
2. **Python Converter** - Multi-flavor markdown processor
3. **JavaScript Viewer** - WebKit2GTK integration
4. **MIME Integration** - File type associations

## 🎨 Themes & Styling

### Auto Theme Detection
- Automatically detects GNOME light/dark theme
- Switches styling and syntax highlighting accordingly
- Consistent with system appearance

### Syntax Highlighting
- **Light Theme**: GitHub-style highlighting
- **Dark Theme**: Dark-optimized color schemes
- **40+ Languages**: Powered by Pygments

## ⚡ Performance

- **Rendering**: < 200ms for typical documents (converter itself: ~150ms)
- **No unnecessary network calls**: math detection requires `$$...$$`, `\(...\)`/`\[...\]`, or a
  same-line matched `$...$` pair — a bare `$` (price, shell variable) no longer triggers MathJax
- **Memory**: ~10MB per preview; +3MB/+1MB transient while a Mermaid/MathJax-containing page renders
- **Large Files**: Handles 1MB+ documents smoothly

## 🔍 Feature Comparison

| Feature | [QLMarkdown (macOS)](https://github.com/sbarex/QLMarkdown) | GNOME Markdown QuickLook |
|---------|-------------------|---------------------------|
| **Platform** | macOS only | Linux/GNOME |
| **Flavors** | 1 (Custom GFM-like) | 8 markdown specifications |
| **Themes** | Built-in themes | System theme integration |
| **Math** | ✅ [MathJax](https://www.mathjax.org/) | ✅ [MathJax](https://www.mathjax.org/) |
| **Diagrams** | ❌ | ✅ [Mermaid](https://mermaid.js.org/) |
| **Syntax Highlighting** | ✅ | ✅ [Pygments](https://pygments.org/) |
| **Tables** | ✅ | ✅ |
| **Task Lists** | ✅ | ✅ |
| **Extensibility** | Limited | Highly extensible |
| **Performance** | Native (Swift) | WebKit2GTK |

## 🧪 Development

### Local Setup

```bash
git clone https://github.com/smlblr/gnome-markdown-quicklook.git
cd gnome-markdown-quicklook
uv sync  # or pip install -e .
```

### Testing

```bash
# Test converter directly
uv run python -m gnome_markdown_quicklook.converter tests/sample.md

# Test different flavors
uv run python -m gnome_markdown_quicklook.converter tests/sample.md --flavor gfm
uv run python -m gnome_markdown_quicklook.converter tests/sample.md --flavor commonmark
```

### Adding Flavors

1. Implement `render_<flavor>()` method in `converter.py`
2. Add to `FLAVORS` dictionary
3. Update CLI choices and documentation
4. Test with various markdown documents

## 🛠️ Manual Installation

`install.sh` does a few things a straight `cp` won't (rewrites the converter's shebang to point at
your actual `uv` path, adds the AppArmor profile, vendors Mermaid/MathJax) — running it yourself after
cloning is the supported "manual" path:

```bash
git clone https://github.com/smlblr/gnome-markdown-quicklook.git
cd gnome-markdown-quicklook
./install.sh
```

<details>
<summary>Doing every step by hand instead</summary>

```bash
# 1. System dependencies
sudo apt install gnome-sushi libwebkit2gtk-4.1-0

# 2. uv (converter is a self-contained PEP 723 script, no separate venv)
curl -LsSf https://astral.sh/uv/install.sh | sh

# 3. Clone
git clone https://github.com/smlblr/gnome-markdown-quicklook.git
cd gnome-markdown-quicklook

# 4. Install converter — replace the shebang's uv path with `command -v uv`,
#    skip the source file's own shebang + PEP 723 header (see install.sh's
#    install_files() for the exact awk one-liner), then:
chmod +x ~/.local/bin/sushi-markdown-converter

# 5. Install Sushi viewer
cp src/sushi-viewers/markdown.js ~/.local/share/sushi/viewers/

# 6. Vendor Mermaid + MathJax locally (skip and it falls back to CDN)
mkdir -p ~/.local/share/sushi/vendor
curl -fsSL https://unpkg.com/mermaid@10/dist/mermaid.min.js -o ~/.local/share/sushi/vendor/mermaid.min.js
curl -fsSL https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js -o ~/.local/share/sushi/vendor/mathjax.min.js

# 7. AppArmor profile — only if `cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns` prints 1
#    (see install.sh's install_apparmor_profile() for the profile text)

# 8. MIME type + restart sushi — see install.sh's setup_mime_types()/finalize_installation()
```

</details>

## 🐛 Troubleshooting

### Preview Not Working
1. **Check Sushi**: `which sushi` and restart with `pkill -f sushi`
2. **Check converter**: `sushi-markdown-converter --help`
3. **Check logs**: `journalctl --user -f | grep sushi`

### Dependency Issues
1. **Python packages**: `uv sync` or `pip install markdown pygments`
2. **System packages**: `sudo apt install gnome-sushi libwebkit2gtk-4.1-dev`
3. **WebKit version**: Try both `webkit2gtk-4.0` and `webkit2gtk-4.1`

### MIME Type Issues
1. **Update database**: `update-mime-database ~/.local/share/mime`
2. **Check associations**: `file --mime-type document.md`
3. **Restart session**: Log out and back in

## 🗑️ Uninstall

```bash
# User install (default)
rm -f ~/.local/bin/sushi-markdown-converter
rm -f ~/.local/share/sushi/viewers/markdown.js
rm -rf ~/.local/share/sushi/vendor
rm -f ~/.local/share/mime/packages/markdown.xml
update-mime-database ~/.local/share/mime

# AppArmor profile, if install.sh added one (Ubuntu 24.04+)
sudo apparmor_parser -R /etc/apparmor.d/gnome-sushi
sudo rm -f /etc/apparmor.d/gnome-sushi

# Restart Sushi
pkill -x sushi
```

(System-wide install: same paths under `/usr/share/sushi/...` and `/usr/local/bin`, needs `sudo`.)

## 📄 License

This project is licensed under the [GNU General Public License v2.0](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html) - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **[noboomu/gnome-markdown-ql](https://github.com/noboomu/gnome-markdown-ql)** - Original project this is forked from
- **[QLMarkdown](https://github.com/sbarex/QLMarkdown)** - Original macOS inspiration by [Sbarex](https://github.com/sbarex)
- **[GNOME Sushi](https://gitlab.gnome.org/GNOME/sushi)** - File preview framework by GNOME Project
- **[Python Markdown](https://python-markdown.github.io/)** - Core markdown processing
- **[PyMdown Extensions](https://facelessuser.github.io/pymdown-extensions/)** - Enhanced markdown features by [facelessuser](https://github.com/facelessuser)
- **[Pygments](https://pygments.org/)** - Syntax highlighting by [Georg Brandl](https://github.com/birkenfeld)
- **[Mermaid](https://mermaid.js.org/)** / **[MathJax](https://www.mathjax.org/)** - Diagrams and math rendering, vendored locally

## 🌟 Contributing

Issues and pull requests welcome at the [GitHub repository](https://github.com/smlblr/gnome-markdown-quicklook).

---

**Ready to use!** 🎉
```bash
curl -fsSL https://raw.githubusercontent.com/smlblr/gnome-markdown-quicklook/main/install.sh | bash
```
