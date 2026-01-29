#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-install.log}"

echo_warn() { echo -e '\033[1;33m'"$1"'\033[0m'; }
echo_info() { echo -e '\033[1;36m'"$1"'\033[0m'; }
echo_ok()   { echo -e '\033[1;32m'"$1"'\033[0m'; }
echo_err()  { echo -e '\033[1;31m'"$1"'\033[0m' >&2; }

step() {
  echo_warn ""
  echo_warn "==> $1"
}

die() {
  echo_err "$1"
  exit 1
}

# Count items in a Brewfile so we can show a progress bar.
count_bundle_items() {
  local file="$1"
  # Count brew/cask/mas lines, ignore taps and comments.
  grep -E '^\s*(brew|cask|mas)\s+"' "$file" 2>/dev/null | wc -l | tr -d ' '
}

render_bar() {
  local current="$1"
  local total="$2"
  local width=28

  if [[ "$total" -le 0 ]]; then
    printf '\r[............................] 0/0' >&2
    return
  fi

  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))

  local filled_str
  local empty_str
  filled_str="$(printf '%*s' "$filled" '' | tr ' ' '#')"
  empty_str="$(printf '%*s' "$empty" '' | tr ' ' '.')"

  printf '\r[%s%s] %d/%d' "$filled_str" "$empty_str" "$current" "$total" >&2

  if [[ "$current" -ge "$total" ]]; then
    printf '\n' >&2
  fi
}

run_bundle_with_progress() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo_info "Skipping missing file: $file"
    return 0
  fi

  local total
  total="$(count_bundle_items "$file")"

  echo_info "Bundle file: $file"
  echo_info "Items to process (brew/cask/mas): $total"
  echo_info "Logging to: $LOG_FILE"

  local processed=0
  render_bar 0 "$total"

  # We rely on brew bundle's verbose output and count "Using/Installing/Upgrading" lines.
  # That gives a good approximation of progress and also shows what is happening.
  brew bundle --file "$file" --verbose 2>&1 | tee -a "$LOG_FILE" | while IFS= read -r line; do
    if [[ "$line" =~ ^(Using|Installing|Upgrading)\  ]]; then
      processed=$((processed + 1))
      if [[ "$processed" -le "$total" ]]; then
        render_bar "$processed" "$total"
      else
        render_bar "$total" "$total"
      fi
    fi
    echo "$line"
  done

  # Finish bar in case brew bundle output format changed and we under-counted.
  render_bar "$total" "$total"
}

main() {
  # Always run from the folder where install.sh lives (so relative Brewfile paths work).
  cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  : > "$LOG_FILE"

  step "Starting bootstrapping"

  step "Checking Xcode Command Line Tools"
  if ! xcode-select -p >/dev/null 2>&1; then
    die "Xcode Command Line Tools not found. Run: xcode-select --install"
  fi

  step "Checking Homebrew"
  if ! command -v brew >/dev/null 2>&1; then
    echo_warn "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" | tee -a "$LOG_FILE"

    # Make brew available in this shell (Apple Silicon vs Intel)
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    else
      die "Homebrew installed but brew was not found in /opt/homebrew or /usr/local"
    fi
  fi

  step "Updating Homebrew"
  brew update | tee -a "$LOG_FILE"
  brew upgrade | tee -a "$LOG_FILE"

  step "Installing core tools + apps"
  run_bundle_with_progress "./Brewfile"

  step "Installing fonts (optional, can take a while)"
  run_bundle_with_progress "./Brewfile.fonts"

  step "Installing Mac App Store apps (requires App Store sign-in)"
  if command -v mas >/dev/null 2>&1 && mas account >/dev/null 2>&1; then
    run_bundle_with_progress "./Brewfile.mas"
  else
    echo_warn "Skipping MAS installs. Sign into the Mac App Store, then run:"
    echo_warn "  brew bundle --file ./Brewfile.mas --verbose"
  fi

  step "Cleaning up"
  brew cleanup | tee -a "$LOG_FILE"

  echo_ok "Bootstrapping complete"
}

main "$@"

