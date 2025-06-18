#!/usr/bin/env bash
# requires xcode and tools!
xcode-select -p || exit "XCode must be installed! (use the app store)"

# helpers
# function echo_ok { echo -e '\033[1;32m'"$1"'\033[0m'; }
function echo_warn { echo -e '\033[1;33m'"$1"'\033[0m'; }
# function echo_error  { echo -e '\033[1;31mERROR: '"$1"'\033[0m'; }

echo_warn "Starting bootstrapping"

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update homebrew recipes
brew update

# Install GNU `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
brew install findutils

PACKAGES=(
    bat
    create-dmg
    ffmpeg
    fx
    gh
    googler
    hub
    iftop
    imagemagick
    jq
    libjpeg
    libmemcached 
    markdown
    mas
    mc
    node
    reminders-cli
    speedtest-cli
    ssh-copy-id
    tree
    vim
    wget
    youtube-dl
)

echo_warn "Installing packages..."
brew install ${PACKAGES[@]}

echo_warn "Cleaning up..."
brew cleanup

CASKS=(
    balenaetcher
    docker
    firefox
    github
    google-chrome
    iterm2
    microsoft-teams
    postman
    signal
    sourcetree
    visual-studio-code
)

echo_warn "Installing cask apps..."
brew install --cask ${CASKS[@]}

echo_warn "Installing fonts..."
brew tap homebrew/cask-fonts

FONTS=(
  font-3270-nerd-font
  font-fira-mono-nerd-font
  font-inconsolata-go-nerd-font
  font-inconsolata-lgc-nerd-font
  font-inconsolata-nerd-font
  font-monofur-nerd-font
  font-overpass-nerd-font
  font-ubuntu-mono-nerd-font
  font-agave-nerd-font
  font-arimo-nerd-font
  font-anonymice-nerd-font
  font-aurulent-sans-mono-nerd-font
  font-bigblue-terminal-nerd-font
  font-bitstream-vera-sans-mono-nerd-font
  font-blex-mono-nerd-font
  font-caskaydia-cove-nerd-font
  font-code-new-roman-nerd-font
  font-cousine-nerd-font
  font-daddy-time-mono-nerd-font
  font-dejavu-sans-mono-nerd-font
  font-droid-sans-mono-nerd-font
  font-fantasque-sans-mono-nerd-font
  font-fira-code-nerd-font
  font-go-mono-nerd-font
  font-gohufont-nerd-font
  font-hack-nerd-font
  font-hasklug-nerd-font
  font-heavy-data-nerd-font
  font-hurmit-nerd-font
  font-im-writing-nerd-font
  font-iosevka-nerd-font
  font-jetbrains-mono-nerd-font
  font-lekton-nerd-font
  font-liberation-nerd-font
  font-meslo-lg-nerd-font
  font-monoid-nerd-font
  font-mononoki-nerd-font
  font-mplus-nerd-font
  font-noto-nerd-font
  font-open-dyslexic-nerd-font
  font-profont-nerd-font
  font-proggy-clean-tt-nerd-font
  font-roboto-mono-nerd-font
  font-sauce-code-pro-nerd-font
  font-shure-tech-mono-nerd-font
  font-space-mono-nerd-font
  font-terminess-ttf-nerd-font
  font-tinos-nerd-font
  font-ubuntu-nerd-font
  font-victor-mono-nerd-font
)

brew install --cask ${FONTS[@]}

brew tap buo/cask-upgrade # Cask upgrade

echo_warn "Installing App Store Apps"

mas install 1437681957 # Audiobook Builder
mas install 640199958  # Developer
mas install 1355679052 # Dropover
mas install 1081457679 # Ebook Converter
mas install 682658836  # GarageBand
mas install 409183694  # Keynote
mas install 409203825  # Numbers
mas install 409201541  # Pages
mas install 1289583905 # Pixelmator Pro
mas install 1496833156 # Playgrounds
mas install 803453959  # Slack
mas install 747648890  # Telegram

echo_warn "Bootstrapping complete"
