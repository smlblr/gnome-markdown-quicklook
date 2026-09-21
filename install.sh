#!/bin/bash
# GNOME Markdown QuickLook - installer
# Usage (clone + local):
#   git clone https://github.com/smlblr/gnome-markdown-quicklook.git
#   cd gnome-markdown-quicklook && ./install.sh
# Usage (one-liner, no clone):
#   curl -fsSL https://raw.githubusercontent.com/smlblr/gnome-markdown-quicklook/main/install.sh | bash

set -e

# Colors and symbols
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

readonly CHECK='✓'
readonly CROSS='✗'
readonly ARROW='→'
readonly STAR='★'

# Project info
readonly PROJECT_NAME="GNOME Markdown QuickLook"
readonly PROJECT_URL="https://github.com/smlblr/gnome-markdown-quicklook"
readonly RAW_URL="https://raw.githubusercontent.com/smlblr/gnome-markdown-quicklook/main"
readonly MERMAID_JS_URL="https://unpkg.com/mermaid@10/dist/mermaid.min.js"
readonly MATHJAX_JS_URL="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"

# Bu script'in kendi dosya yolu — git clone edilmiş bir kopyadan mı yoksa
# `curl | bash` ile boru hattından mı çalıştığını ayırt etmek için kullanılır.
# `curl | bash` durumunda BASH_SOURCE gerçek bir dosyaya işaret etmez, bu
# yüzden SCRIPT_DIR boş kalır ve installer otomatik olarak GitHub'dan indirme
# moduna düşer (aşağıdaki download_files bunu kontrol eder).
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR=""
fi

# Installation paths
if [[ $EUID -eq 0 ]]; then
    readonly INSTALL_MODE="system"
    readonly SUSHI_DIR="/usr/share/sushi/viewers"
    readonly CONVERTER_DIR="/usr/local/bin"
    readonly MIME_DIR="/usr/share/mime/packages"
    readonly VENDOR_DIR="/usr/share/sushi/vendor"
else
    readonly INSTALL_MODE="user"
    readonly SUSHI_DIR="$HOME/.local/share/sushi/viewers"
    readonly CONVERTER_DIR="$HOME/.local/bin"
    readonly MIME_DIR="$HOME/.local/share/mime/packages"
    readonly VENDOR_DIR="$HOME/.local/share/sushi/vendor"
fi

# Utility functions
print_header() {
    echo -e "${PURPLE}"
    echo "╭─────────────────────────────────────────────────────────────╮"
    echo "│                                                             │"
    echo "│  ${STAR} ${WHITE}GNOME Markdown QuickLook${PURPLE} ${STAR}                            │"
    echo "│                                                             │"
    echo "│  ${WHITE}Beautiful markdown previews for GNOME${PURPLE}                   │"
    echo "│  ${CYAN}Press Space in Nautilus to preview .md files${PURPLE}            │"
    echo "│                                                             │"
    echo "╰─────────────────────────────────────────────────────────────╯"
    echo -e "${NC}"
}

print_step() { echo -e "${BLUE}${ARROW}${NC} $1"; }
print_success() { echo -e "${GREEN}${CHECK}${NC} $1"; }
print_error() { echo -e "${RED}${CROSS}${NC} $1"; }
print_warning() { echo -e "${YELLOW}!${NC} $1"; }
print_info() { echo -e "${CYAN}i${NC} $1"; }

check_dependencies() {
    print_step "Checking system dependencies..."

    local missing_deps=()

    if ! command -v sushi &> /dev/null; then
        missing_deps+=("gnome-sushi")
    fi
    if ! pkg-config --exists webkit2gtk-4.1 && ! pkg-config --exists webkit2gtk-4.0; then
        missing_deps+=("libwebkit2gtk-4.1-0")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_info "Install with: ${YELLOW}sudo apt install ${missing_deps[*]}${NC}"
        exit 1
    fi

    print_success "All system dependencies found"
}

ensure_uv() {
    # Converter, PEP 723 satır içi bağımlılıklarıyla `uv run --script` olarak
    # çalışır — ayrı bir venv/pip kurulumuna gerek yok, sadece uv'nin kendisi
    # gerekli. Shebang'ı buradaki gerçek yola göre yazacağız (aşağıda), bu
    # yüzden farklı kullanıcılarda/PATH'lerde de doğru çalışır.
    print_step "Checking for uv..."
    if command -v uv &> /dev/null; then
        UV_PATH="$(command -v uv)"
        print_success "uv found at $UV_PATH"
        return
    fi
    if [[ -x "$HOME/.local/bin/uv" ]]; then
        UV_PATH="$HOME/.local/bin/uv"
        print_success "uv found at $UV_PATH"
        return
    fi
    print_info "uv not found, installing (https://astral.sh/uv)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    UV_PATH="$HOME/.local/bin/uv"
    if [[ ! -x "$UV_PATH" ]]; then
        print_error "uv installation failed"
        exit 1
    fi
    print_success "uv installed at $UV_PATH"
}

download_files() {
    if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/src/gnome_markdown_quicklook/converter.py" ]]; then
        print_step "Using local checkout at $SCRIPT_DIR"
        SRC_CONVERTER="$SCRIPT_DIR/src/gnome_markdown_quicklook/converter.py"
        SRC_MARKDOWN_JS="$SCRIPT_DIR/src/sushi-viewers/markdown.js"
        return
    fi

    print_step "Downloading project files from GitHub..."
    local temp_dir
    temp_dir=$(mktemp -d)
    curl -fsSL "${RAW_URL}/src/gnome_markdown_quicklook/converter.py" -o "$temp_dir/converter.py"
    curl -fsSL "${RAW_URL}/src/sushi-viewers/markdown.js" -o "$temp_dir/markdown.js"

    if [[ ! -f "$temp_dir/converter.py" || ! -f "$temp_dir/markdown.js" ]]; then
        print_error "Failed to download project files"
        exit 1
    fi
    SRC_CONVERTER="$temp_dir/converter.py"
    SRC_MARKDOWN_JS="$temp_dir/markdown.js"
    print_success "Project files downloaded"
}

install_files() {
    print_step "Installing extension files..."
    mkdir -p "$SUSHI_DIR" "$CONVERTER_DIR" "$MIME_DIR" "$VENDOR_DIR"

    # Converter: kaynaktaki shebang satırını atlayıp kendi PEP 723 başlığımızı
    # bu makinedeki gerçek uv yoluyla yazıyoruz — sabit bir ev dizini
    # (/home/x/...) gömmek başka kullanıcıda çalışmaz.
    {
        cat <<EOF
#!/usr/bin/env -S $UV_PATH run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "markdown>=3.5",
#     "pygments>=2.15",
#     "pymdown-extensions>=10.0",
#     "commonmark>=0.9.1",
#     "markdown-it-py>=3.0.0",
#     "python-markdown-math>=0.8",
# ]
# ///
EOF
        # Kaynak dosyanın kendi shebang + PEP 723 başlığı atlanıyor (satır
        # sayısına değil "# /// script" ... "# ///" işaretçilerine göre, bağımlılık
        # listesi uzasa da doğru çalışsın diye) — yoksa iki PEP 723 bloğu üst
        # üste binip TOML ayrıştırma hatası veriyor ("key with no value").
        awk 'NR==1{next} !done && /^# \/\/\/ script$/{sk=1;next} !done && sk && /^# \/\/\/$/{sk=0;done=1;next} sk{next} {print}' "$SRC_CONVERTER"
    } > "$CONVERTER_DIR/sushi-markdown-converter"
    chmod +x "$CONVERTER_DIR/sushi-markdown-converter"

    cp "$SRC_MARKDOWN_JS" "$SUSHI_DIR/markdown.js"

    print_success "Extension files installed"
}

install_vendor_assets() {
    # mermaid.js / mathjax.js satır içi gömülüyor (bkz. converter.py) — bu
    # yüzden offline çalışır ve her önizlemede CDN'e çıkmaz. Dosyalar
    # büyük olduğu için (mermaid ~3 MB, mathjax ~1 MB) depoya değil, buraya
    # bir kere indiriliyor.
    print_step "Downloading Mermaid + MathJax (one-time, ~4 MB)..."
    if [[ ! -f "$VENDOR_DIR/mermaid.min.js" ]]; then
        curl -fsSL "$MERMAID_JS_URL" -o "$VENDOR_DIR/mermaid.min.js" \
            && print_success "Mermaid diagrams enabled" \
            || print_warning "Could not download mermaid.min.js — diagrams will fall back to CDN"
    else
        print_info "Mermaid already vendored, skipping"
    fi
    if [[ ! -f "$VENDOR_DIR/mathjax.min.js" ]]; then
        curl -fsSL "$MATHJAX_JS_URL" -o "$VENDOR_DIR/mathjax.min.js" \
            && print_success "Math rendering enabled" \
            || print_warning "Could not download mathjax.min.js — math will fall back to CDN"
    else
        print_info "MathJax already vendored, skipping"
    fi
}

install_apparmor_profile() {
    # Ubuntu 24.04+ (ve aynı kernel.apparmor_restrict_unprivileged_userns=1
    # ayarını taşıyan diğer dağıtımlar), profilsiz süreçlerin açtığı
    # kullanıcı ad alanlarını kısıtlı bir AppArmor profiline sokar. WebKit,
    # sushi'nin web sürecini bwrap sandbox'ında başlatırken bu profil altında
    # uid_map yazamaz ve önizleyici SIGTRAP ile çöker (Space'e basınca hiçbir
    # şey açılmaz). Profil olmadan bu araç Ubuntu 24.04+'ta çalışmaz.
    if ! command -v apparmor_parser &> /dev/null; then
        print_info "AppArmor not present, skipping sandbox profile"
        return
    fi
    local restrict_file="/proc/sys/kernel/apparmor_restrict_unprivileged_userns"
    if [[ -f "$restrict_file" ]] && [[ "$(cat "$restrict_file" 2>/dev/null)" != "1" ]]; then
        print_info "Unprivileged userns not restricted on this system, skipping AppArmor profile"
        return
    fi
    if [[ -f /etc/apparmor.d/gnome-sushi ]]; then
        print_info "AppArmor profile already installed"
        return
    fi

    print_warning "This system restricts unprivileged user namespaces (Ubuntu 24.04+ default)."
    print_warning "Without an AppArmor profile, gnome-sushi's preview crashes on every markdown file."
    print_step "Installing /etc/apparmor.d/gnome-sushi (requires sudo)..."

    sudo tee /etc/apparmor.d/gnome-sushi >/dev/null <<'EOF'
# GNOME Files' quick-look previewer (sushi) needs to open a user namespace
# for WebKit's bubblewrap sandbox. Same pattern as Ubuntu's own
# nautilus/epiphany/desktop-icons-ng profiles: unconfined, just named and
# granted userns so it isn't caught by the unprivileged_userns restriction.
abi <abi/4.0>,
include <tunables/global>

profile gnome-sushi /usr/libexec/org.gnome.NautilusPreviewer flags=(unconfined) {
  userns,

  include if exists <local/gnome-sushi>
}
EOF
    sudo apparmor_parser -r /etc/apparmor.d/gnome-sushi
    print_success "AppArmor profile installed"
}

setup_mime_types() {
    print_step "Configuring file associations..."

    cat > "$MIME_DIR/markdown.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="text/markdown">
    <comment>Markdown document</comment>
    <glob pattern="*.md"/>
    <glob pattern="*.markdown"/>
    <glob pattern="*.mdown"/>
    <glob pattern="*.mkd"/>
    <glob pattern="*.mkdn"/>
  </mime-type>
  <mime-type type="text/x-markdown">
    <comment>Markdown document</comment>
    <glob pattern="*.md"/>
    <glob pattern="*.markdown"/>
  </mime-type>
</mime-info>
EOF

    if [[ "$INSTALL_MODE" == "system" ]]; then
        update-mime-database /usr/share/mime &> /dev/null
    else
        update-mime-database "$HOME/.local/share/mime" &> /dev/null
    fi

    print_success "File associations configured"
}

finalize_installation() {
    print_step "Finalizing installation..."

    pkill -x sushi 2>/dev/null || true
    pkill -f '^/usr/bin/gjs /usr/libexec/org.gnome.NautilusPreviewer' 2>/dev/null || true

    if [[ "$INSTALL_MODE" == "user" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        print_info "Added ${CYAN}~/.local/bin${NC} to PATH in ~/.bashrc"
    fi

    print_success "Installation finalized"
}

print_completion() {
    echo
    echo -e "${GREEN}╭─────────────────────────────────────────────────────────────╮"
    echo -e "│  ${CHECK} Installation completed successfully!                     │"
    echo -e "╰─────────────────────────────────────────────────────────────╯${NC}"
    echo
    print_info "Quick Start:"
    echo -e "  ${CYAN}1.${NC} Open ${YELLOW}Nautilus${NC} (GNOME Files)"
    echo -e "  ${CYAN}2.${NC} Select any ${YELLOW}.md${NC} file"
    echo -e "  ${CYAN}3.${NC} Press ${YELLOW}Space${NC} for preview"
    echo -e "  ${CYAN}4.${NC} Press ${YELLOW}Escape${NC} to close"
    echo
    print_info "Supported formats: ${CYAN}.md .markdown .mdown .mkd .mkdn${NC}"
    print_info "Features: ${CYAN}Syntax highlighting, tables, math, Mermaid diagrams, themes${NC}"
    echo
    print_info "Documentation: ${BLUE}${PROJECT_URL}${NC}"

    if [[ "$INSTALL_MODE" == "user" ]]; then
        echo
        print_warning "Run ${YELLOW}source ~/.bashrc${NC} or restart terminal for PATH updates"
    fi
}

main() {
    print_header
    echo -e "${WHITE}Installing to:${NC} ${CYAN}$INSTALL_MODE${NC} (${SUSHI_DIR})"
    echo

    check_dependencies
    ensure_uv
    download_files
    install_files
    install_vendor_assets
    install_apparmor_profile
    setup_mime_types
    finalize_installation

    print_completion
}

main "$@"
