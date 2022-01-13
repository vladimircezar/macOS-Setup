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
    hub
    imagemagick
    jump
    libjpeg
    libmemcached 
    markdown
    mas
    mc
    npm
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
    brave-browser
    charles
    discord
    firefox
    google-chrome
    insomnia
    iterm2
    microsoft-teams
    postman
    slack
    telegram
    virtualbox
    visual-studio-code
    wireshark
)

echo_warn "Installing cask apps..."
brew install --cask ${CASKS[@]}

echo_warn "Installing fonts..."
brew tap homebrew/cask-fonts

FONTS=(
    font-anonymous-pro
    font-clear-sans
    font-covered-by-your-grace
    font-hack
    font-inconsolata-for-powerline
    font-input
    font-league-gothic
    font-meslo-lg
    font-nixie-one
    font-office-code-pro
    font-pt-mono
    font-raleway
    font-rambla
    font-roboto
    font-share-tech
    font-source-code-pro 
    font-source-code-pro-for-powerline
    font-ubuntu
    font-fira-code
    font-fira-mono
    font-fira-mono-for-powerline
    font-fira-sans
)

brew install --cask ${FONTS[@]}

echo_warn "Installing Ruby gems"

RUBY_GEMS=(
    bundler
    filewatcher
    cocoapods
)

sudo gem install ${RUBY_GEMS[@]}

echo_warn "Installing global npm packages..."
npm install marked -g

echo_warn "Configuring OSX..."

# Expand Save and Print Dialogs by Default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true && \
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true && \
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true && \
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Advanced Option: Always Search Within Folder
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Advanced Option: Disable .DS_Store File Creation
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Advanced Option: Show Path Bar
defaults write com.apple.finder ShowPathbar -bool true

# Require password as soon as screensaver or sleep mode starts
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

echo_warn "Creating folder structure..."
# [[ ! -d Wiki ]] && mkdir Wiki
# [[ ! -d Workspace ]] && mkdir 

echo_warn "Installing App Store Apps"

mas install 1289583905 # Pixelmator Pro
mas install 640199958  # Developer 
mas install 409201541  # Pages
mas install 409203825  # Numbers
mas install 409183694  # Keynote
mas install 747648890  # Telegram
mas install 1479641484 # Fireworks
mas install 682658836  # GarageBand
mas install 1496833156 # Playgrounds
mas install 809625456  # Asset Catalog Creator Pro
mas install 1436953057 # Ghostery – Privacy Ad Blocker
mas install 1147396723 # WhatsApp
mas install 1006087419 # SnippetsLab
mas install 408981434  # iMovie
mas install 1355679052 # Dropover
mas install 803453959  # Slack (4.22.1)
mas install 1090488118 # Gemini 2
mas install 1081457679 # Ebook Converter
mas install 1081413713 # GIF Brewery 3
mas install 899247664  # TestFlight
mas install 1437681957 # Audiobook Builder
mas install 1490879410 # TrashMe 3
mas install 1529448980 # Reeder 5.

echo_warn "Bootstrapping complete"
