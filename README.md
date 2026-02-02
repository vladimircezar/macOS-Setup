# macOS-Setup

A no-nonsense setup kit for a new Mac.
It installs the stuff I actually use, the same way every time, with as little clicking as possible.

This repo is built around three things:
- Homebrew packages (`Brewfile`)
- Fonts (`Brewfile.fonts`)
- Mac App Store apps (`Brewfile.mas`)
Plus a couple of scripts to make the whole thing painless.

## What’s in here

- `pre-setup.sh`  
  One-time prep. Think: prerequisites, sane defaults, and setup checks.

- `install.sh`  
  The main installer. Runs the bundle installs and ties everything together.

- `Brewfile`  
  CLI tools and apps installed via Homebrew.

- `Brewfile.fonts`  
  Fonts installed via Homebrew casks.

- `Brewfile.mas`  
  Mac App Store installs via `mas` (you need to be signed in).

## Before you run anything

1. Update macOS.
2. Make sure you can run Terminal commands.
3. Read the scripts. Seriously. It’s your machine.

## Quick start

Clone the repo and run the scripts:

```bash
git clone https://github.com/vladimircezar/macOS-Setup.git
cd macOS-Setup

chmod +x pre-setup.sh install.sh

./pre-setup.sh
./install.sh
````

If you prefer to run installs manually (or debug step-by-step), you can do:

```bash
# Base packages
brew bundle --file Brewfile

# Fonts
brew bundle --file Brewfile.fonts

# Mac App Store apps (requires App Store sign-in)
brew bundle --file Brewfile.mas
```

## Mac App Store installs (mas)

`Brewfile.mas` uses `mas` under the hood.

Do this first:

1. Open the App Store app
2. Sign in with your Apple ID

Then run:

```bash
brew bundle --file Brewfile.mas
```

If `mas` complains, it’s almost always because you are not signed in.

## Keeping everything up to date

The normal routine:

```bash
brew update
brew upgrade
brew upgrade --cask
brew cleanup

# If you use Mac App Store installs
mas upgrade
```

If you want Homebrew to match the Brewfiles again:

```bash
brew bundle --file Brewfile
brew bundle --file Brewfile.fonts
brew bundle --file Brewfile.mas
```

## Adding or removing packages

Edit the Brewfiles and re-run `brew bundle`.

I like leaving comments so future-me doesn’t hate past-me:

```ruby
brew "fastfetch" # nice system info header in terminal
cask "iterm2"    # better terminal app than the default
```

Then apply:

```bash
brew bundle --file Brewfile
```

## Uninstalling what this installed

You can tell Homebrew to remove anything not listed in a Brewfile.
This can be destructive if you use Homebrew for other stuff on that Mac.

Use with your eyes open:

```bash
brew bundle cleanup --file Brewfile --force
```

## Troubleshooting

### “brew: command not found”

Install Homebrew, then restart Terminal and try again.

### Fonts fail to install

Make sure you have access to casks and try again:

```bash
brew update
brew bundle --file Brewfile.fonts
```

### `mas` fails

Open the App Store and sign in first, then:

```bash
brew bundle --file Brewfile.mas
```

## Notes

* This repo is opinionated. That’s the point.
* If you want a “work Mac” vs “personal Mac” split, make separate Brewfiles and keep them small.
* Don’t run scripts as root unless you enjoy pain.

## License

MIT
