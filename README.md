# dotfiles

Configs for a zsh + Neovim + kitty setup everywhere, plus a sway desktop on Linux.
Every file is symlinked into `$HOME`, so editing a config edits this repo.

## New machine

```sh
git clone https://github.com/Ujjawal17/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --packages              # core: zsh, git, nvim, kitty
./install.sh --packages --desktop    # + sway desktop (Arch)
./install.sh --dry-run --desktop     # preview only
```

| Flag | Effect |
|---|---|
| `--packages` | Install packages for the detected OS (Arch: pacman + yay, Debian/Ubuntu: apt, macOS: Homebrew) |
| `--desktop` | Also link and install the sway desktop modules (Linux only) |
| `--extras` | Also install dev/thesis/cloud tooling (`packages/arch-extras.txt`) |
| `--dry-run` | Print what would happen without changing anything |

Existing files are moved to `~/.dotfiles-backup/<date>/` before being replaced by links.
Running the script again is safe; already-linked files are skipped.

## Modules

Each folder mirrors `$HOME`.

| Module | Contents | Installed |
|---|---|---|
| `zsh` | `.zshrc`, `.zshenv`, `.p10k.zsh` (oh-my-zsh + powerlevel10k, cloned by the script) | always |
| `git` | `.gitconfig` | always |
| `nvim` | Neovim config (lazy.nvim, Mason language servers) | always |
| `kitty` | kitty terminal config + Catppuccin theme | always |
| `sway` | sway window manager config | `--desktop` |
| `waybar` | status bar config and style | `--desktop` |
| `mako` | notification popups | `--desktop` |
| `wofi` | app launcher style | `--desktop` |
| `scripts` | `~/.local/bin/screen-record`, `idle-restore` | `--desktop` |
| `backgrounds` | wallpapers | `--desktop` |
| `apps` | desktop launchers (`termic.desktop`) | `--desktop` |

## Machine-specific settings

Put anything that must not be committed in `~/.zshrc.local` (sourced at the end of `.zshrc`):

```sh
export ANTHROPIC_API_KEY=...   # avante.nvim
export AWS_PROFILE=...
```

## Packages

| File | Used for |
|---|---|
| `packages/arch-core.txt` | CLI tools, zsh, Neovim, kitty, fonts |
| `packages/arch-desktop.txt` | sway desktop, audio, Bluetooth, apps |
| `packages/aur.txt` | AUR apps (installed with `--desktop`) |
| `packages/arch-extras.txt` | go, clang, docker, terraform, aws-cli, jupyter, tectonic, ollama |
| `packages/debian.txt` | Core CLI tools under Debian/Ubuntu names |
| `packages/Brewfile` | macOS CLI tools, kitty, fonts, apps |

Hardware and base-system packages (kernel, firmware, drivers, display manager,
NetworkManager) are left to the OS installer.

## Not managed here

Toolchains with their own installers: rustup, uv, bun, Google Cloud SDK, kubectl/helm/k3d, OpenTofu/Terragrunt.
