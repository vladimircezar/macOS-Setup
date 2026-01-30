#!/usr/bin/env bash
set -euo pipefail

################################################################################
# pre-setup.sh (interactive)
# - Sets up SSH for personal GitHub (github-personal)
# - Clones dotfiles bare repo to ~/.dotfiles and checks out into ~
# - Installs Xcode CLT and Homebrew if needed
################################################################################

log() { printf "\n%s\n" "$*"; }
die() { printf "\nERROR: %s\n" "$*" >&2; exit 1; }

is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

confirm() {
  local prompt="$1"
  local reply
  read -r -p "$prompt [y/N] " reply
  [[ "${reply,,}" == "y" || "${reply,,}" == "yes" ]]
}

require_macos() {
  is_macos || die "This script is for macOS."
}

ensure_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools: already installed."
    return 0
  fi

  log "Xcode Command Line Tools are missing. macOS will pop a dialog."
  log "Click Install, then come back here."
  xcode-select --install >/dev/null 2>&1 || true

  while ! xcode-select -p >/dev/null 2>&1; do
    read -r -p "Press Enter once Command Line Tools finish installing... " _
  done

  log "Xcode Command Line Tools: installed."
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    log "Homebrew: already installed."
    return 0
  fi

  log "Homebrew is missing. Installing it now."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Make brew available in this script session
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  command -v brew >/dev/null 2>&1 || die "Homebrew install finished but brew is not on PATH."
  log "Homebrew: installed."
}

ensure_ssh_dir() {
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  touch "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
}

ensure_ssh_agent() {
  if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
    eval "$(ssh-agent -s)" >/dev/null
  fi
}

append_ssh_config_block_if_missing() {
  local marker="$1"
  local block="$2"

  if grep -q "$marker" "$HOME/.ssh/config"; then
    return 0
  fi

  {
    printf "\n%s\n" "$marker"
    printf "%s\n" "$block"
  } >> "$HOME/.ssh/config"
}

create_personal_key() {
  local key_path="$HOME/.ssh/id_ed25519_github_personal"

  if [[ -f "$key_path" ]]; then
    log "Personal key already exists: $key_path"
  else
    log "Creating personal GitHub SSH key: $key_path"
    ssh-keygen -t ed25519 -C "personal-github" -f "$key_path"
  fi

  ensure_ssh_agent

  if ssh-add -l 2>/dev/null | grep -q "$key_path"; then
    log "SSH agent already has the personal key."
  else
    ssh-add --apple-use-keychain "$key_path" >/dev/null
    log "Added personal key to SSH agent + Keychain."
  fi

  local personal_block
  personal_block=$(
    cat <<'EOF'
Host github-personal
  HostName github.com
  User git
  AddKeysToAgent yes
  UseKeychain yes
  IdentitiesOnly yes
  IdentityFile ~/.ssh/id_ed25519_github_personal
EOF
  )

  append_ssh_config_block_if_missing "# BEGIN github-personal" "$personal_block"
  if ! grep -q "# END github-personal" "$HOME/.ssh/config"; then
    printf "%s\n" "# END github-personal" >> "$HOME/.ssh/config"
  fi

  log "SSH config ensured: ~/.ssh/config (github-personal)."
}

show_and_copy_pubkey() {
  local pub_path="$HOME/.ssh/id_ed25519_github_personal.pub"
  [[ -f "$pub_path" ]] || die "Missing pubkey: $pub_path"

  log "Copying your personal GitHub public key to clipboard."
  pbcopy < "$pub_path"

  log "Public key (also copied to clipboard):"
  cat "$pub_path"
}

wait_for_github_key_add() {
  log "Now add that key to your personal GitHub account:"
  log "GitHub Settings -> SSH and GPG keys -> New SSH key"
  log "Opening the page now."
  open "https://github.com/settings/ssh/new" >/dev/null 2>&1 || true

  while true; do
    read -r -p "Press Enter after you've added the key to GitHub... " _
    log "Testing SSH auth to GitHub (github-personal)."
    set +e
    ssh -T git@github-personal 2>&1 | tee /tmp/ssh-github-personal-test.txt
    local rc=$?
    set -e

    # GitHub returns rc=1 for successful auth message sometimes, so check text.
    if grep -qi "successfully authenticated" /tmp/ssh-github-personal-test.txt; then
      log "SSH auth looks good."
      break
    fi

    log "That did not look authenticated yet. Add the key on GitHub, then try again."
  done
}

dotfiles_git() {
  /usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" "$@"
}

clone_dotfiles_bare() {
  local github_user="$1"
  local repo_name="$2"
  local remote="git@github-personal:${github_user}/${repo_name}.git"

  if [[ -d "$HOME/.dotfiles" ]]; then
    log "Dotfiles bare repo already exists at ~/.dotfiles"
    dotfiles_git remote set-url origin "$remote" >/dev/null 2>&1 || dotfiles_git remote add origin "$remote"
    dotfiles_git fetch origin >/dev/null
    return 0
  fi

  log "Cloning dotfiles as a bare repo to ~/.dotfiles"
  git clone --bare "$remote" "$HOME/.dotfiles"
}

backup_conflicting_files() {
  local backup_dir="$HOME/dotfiles-backup-initial-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_dir"

  local files
  files="$(dotfiles_git ls-tree -r --name-only HEAD || true)"

  if [[ -z "$files" ]]; then
    log "No files found in dotfiles repo HEAD. Skipping backup."
    return 0
  fi

  local moved_any="0"
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    local abs="$HOME/$rel"

    if [[ -e "$abs" || -L "$abs" ]]; then
      mkdir -p "$backup_dir/$(dirname "$rel")"
      mv "$abs" "$backup_dir/$rel"
      moved_any="1"
    fi
  done <<< "$files"

  if [[ "$moved_any" == "1" ]]; then
    log "Backed up existing files to: $backup_dir"
  else
    rmdir "$backup_dir" >/dev/null 2>&1 || true
    log "No existing tracked files needed backup."
  fi
}

checkout_dotfiles() {
  dotfiles_git config --local status.showUntrackedFiles no

  log "Checking out dotfiles into your home directory."
  backup_conflicting_files
  dotfiles_git checkout -f

  # Ensure branch is main if it exists
  dotfiles_git branch --show-current >/dev/null 2>&1 || true
}

optional_shell_packages() {
  if ! confirm "Install a few shell packages now (pure, fzf, lsd, nvim, autosuggestions, syntax-highlighting)?"; then
    return 0
  fi

  brew install pure fzf lsd neovim zsh-autosuggestions zsh-syntax-highlighting
}

main() {
  require_macos

  log "Pre-setup for a new Mac."
  log "This will set up SSH for GitHub personal, pull your dotfiles, and get Homebrew ready."

  local github_user repo_name
  read -r -p "Personal GitHub username [vladimircezar]: " github_user
  github_user="${github_user:-vladimircezar}"

  read -r -p "Dotfiles repo name [dotfiles]: " repo_name
  repo_name="${repo_name:-dotfiles}"

  ensure_xcode_clt
  ensure_homebrew

  ensure_ssh_dir
  create_personal_key
  show_and_copy_pubkey
  wait_for_github_key_add

  clone_dotfiles_bare "$github_user" "$repo_name"
  checkout_dotfiles

  optional_shell_packages

  log "Done."
  log "Next steps:"
  log "1) Open a new terminal tab OR run: source ~/.zshrc"
  log "2) Verify: dotwhere"
  log "3) Then run your main installer: ./install.sh"
}

main "$@"

