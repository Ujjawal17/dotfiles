#!/usr/bin/env bash
# Set up a machine from this repo: install packages, zsh framework, and link
# every module's files into $HOME as symlinks (existing files are backed up).
#
#   ./install.sh               link core modules (zsh, git, nvim, kitty)
#   ./install.sh --desktop     + sway desktop modules (Linux only)
#   ./install.sh --packages    also install packages for this OS
#   ./install.sh --extras      also install dev/thesis/cloud tooling (Arch)
#   ./install.sh --dry-run     show what would happen, change nothing
#
# Flags combine, e.g. a fresh Arch laptop: ./install.sh --packages --desktop

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

CORE_MODULES=(zsh git nvim kitty)
DESKTOP_MODULES=(sway waybar mako wofi scripts backgrounds apps)

desktop=0 packages=0 extras=0 dry=0
for arg in "$@"; do
  case "$arg" in
    --desktop)  desktop=1 ;;
    --packages) packages=1 ;;
    --extras)   extras=1 ;;
    --dry-run)  dry=1 ;;
    -h|--help)  sed -n '2,11p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown option: $arg (see --help)" >&2; exit 1 ;;
  esac
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
run()  { if [[ $dry -eq 1 ]]; then echo "  [dry-run] $*"; else "$@"; fi; }

# Package list without comments or blank lines
list() { grep -hvE '^\s*(#|$)' "$@"; }

detect_os() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux)
      if [[ -f /etc/arch-release ]]; then echo arch
      elif command -v apt-get >/dev/null; then echo debian
      else echo linux; fi ;;
    *) echo unknown ;;
  esac
}
OS="$(detect_os)"

if [[ $desktop -eq 1 && $OS == macos ]]; then
  warn "--desktop is for Linux (sway); ignoring it on macOS"
  desktop=0
fi

# ---------------------------------------------------------------- packages
install_packages() {
  local p="$DOTFILES/packages"
  case "$OS" in
    arch)
      local files=("$p/arch-core.txt")
      [[ $desktop -eq 1 ]] && files+=("$p/arch-desktop.txt")
      [[ $extras -eq 1 ]]  && files+=("$p/arch-extras.txt")
      say "pacman: $(basename -a "${files[@]}" | paste -sd' ')"
      # shellcheck disable=SC2046
      run sudo pacman -S --needed $(list "${files[@]}")
      if [[ $desktop -eq 1 ]]; then
        if ! command -v yay >/dev/null; then
          say "bootstrapping yay (AUR helper)"
          local tmp; tmp="$(mktemp -d)"
          run git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
          run bash -c "cd '$tmp/yay-bin' && makepkg -si --noconfirm"
        fi
        say "AUR: aur.txt"
        # shellcheck disable=SC2046
        run yay -S --needed $(list "$p/aur.txt")
      fi
      ;;
    debian)
      say "apt: debian.txt"
      run sudo apt-get update
      # shellcheck disable=SC2046
      run sudo apt-get install -y $(list "$p/debian.txt")
      # Debian names the binary fdfind; expose it as fd
      if command -v fdfind >/dev/null && ! command -v fd >/dev/null; then
        run mkdir -p "$HOME/.local/bin"
        run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
      fi
      install_meslo_font
      [[ $desktop -eq 1 ]] && warn "desktop packages are only listed for Arch; install sway & co. manually"
      ;;
    macos)
      command -v brew >/dev/null || { warn "install Homebrew first: https://brew.sh"; return; }
      say "brew bundle: Brewfile"
      run brew bundle --file="$p/Brewfile"
      ;;
    *) warn "no package list for this OS; skipping packages" ;;
  esac
}

# Meslo Nerd Font for distros that don't package it (fonts fall back without it)
install_meslo_font() {
  local dir="$HOME/.local/share/fonts/MesloLGS-NF"
  [[ -d $dir ]] && return
  say "downloading Meslo Nerd Font to $dir"
  local tmp; tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/Meslo.tar.xz" \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.tar.xz
  run mkdir -p "$dir"
  run tar -xJf "$tmp/Meslo.tar.xz" -C "$dir"
  command -v fc-cache >/dev/null && run fc-cache -f "$dir"
}

# ---------------------------------------------------------------- zsh
# Plain git clones instead of the oh-my-zsh installer, which would replace .zshrc
clone() { # clone <repo> <dest>
  [[ -d $2 ]] && return
  run git clone --depth=1 -q "https://github.com/$1.git" "$2"
}

setup_zsh() {
  say "oh-my-zsh, powerlevel10k and plugins"
  local omz="$HOME/.oh-my-zsh" custom="$HOME/.oh-my-zsh/custom"
  clone ohmyzsh/ohmyzsh "$omz"
  clone romkatv/powerlevel10k "$custom/themes/powerlevel10k"
  clone zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
  clone zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"
  clone zsh-users/zsh-completions "$custom/plugins/zsh-completions"
}

# ---------------------------------------------------------------- linking
# Symlink every file of a module to the same path under $HOME. Files are
# linked one by one, so apps can still create their own files next to them.
link_module() {
  local module="$1" src rel dst
  [[ -d "$DOTFILES/$module" ]] || { warn "no module '$module'"; return; }
  while IFS= read -r -d '' src; do
    rel="${src#"$DOTFILES/$module/"}"
    dst="$HOME/$rel"
    if [[ -L $dst && "$(readlink "$dst")" == "$src" ]]; then
      continue # already linked
    fi
    if [[ -e $dst || -L $dst ]]; then
      run mkdir -p "$BACKUP/$(dirname "$rel")"
      run mv "$dst" "$BACKUP/$rel"
      echo "  backed up ~/$rel"
    fi
    run mkdir -p "$(dirname "$dst")"
    run ln -s "$src" "$dst"
    echo "  linked ~/$rel"
  done < <(find "$DOTFILES/$module" -type f -print0 | sort -z)
}

# ---------------------------------------------------------------- main
say "OS: $OS   desktop: $desktop   packages: $packages   extras: $extras   dry-run: $dry"

[[ $packages -eq 1 ]] && install_packages
command -v git >/dev/null || { warn "git is required; run with --packages or install it"; exit 1; }
setup_zsh

modules=("${CORE_MODULES[@]}")
[[ $desktop -eq 1 ]] && modules+=("${DESKTOP_MODULES[@]}")
for m in "${modules[@]}"; do
  say "linking $m"
  link_module "$m"
done

[[ -d $BACKUP ]] && say "previous files saved in $BACKUP"

cat <<EOF

Done. Remaining manual steps:
  - make zsh your shell:        chsh -s "\$(command -v zsh)"
  - machine-only settings/keys:  ~/.zshrc.local  (e.g. export ANTHROPIC_API_KEY=...)
  - open nvim once so lazy.nvim and Mason install plugins and language servers
EOF
if [[ $desktop -eq 1 ]]; then
  cat <<EOF
  - OpenWhispr global hotkeys:  sudo usermod -aG input "\$USER"  (then log out/in)
  - start sway from your display manager or TTY; greetd/services are not managed here
EOF
fi
