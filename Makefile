SHELL = /bin/fish
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PATH := $(DOTFILES_DIR)/bin:$(PATH)
HOMEBREW_PREFIX := $(shell bin/is-supported bin/is-arm64 /opt/homebrew /usr/local)
export XDG_CONFIG_HOME = $(HOME)/.config
export STOW_DIR = $(DOTFILES_DIR)
export ACCEPT_EULA=Y

.PHONY: test

all: sudo core-macos packages link

sudo:
	sudo -v
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

core-macos: brew fish

brew:
	is-executable brew || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

fish: FISH=$(HOMEBREW_PREFIX)/bin/fish
fish: SHELLS=/etc/shells
fish: brew
	if ! grep -q $(FISH) $(SHELLS); then \
		brew install fish && \
		sudo append $(FISH) $(SHELLS) && \
		chsh -s $(FISH) && \
		set -U fish_user_paths $(HOMEBREW_PREFIX)/bin $fish_user_paths; \
	fi

packages: brew-packages brew-casks

brew-packages: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Brewfile || true

brew-casks: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Caskfile || true

stow: brew
	is-executable stow || brew install stow

link: stow
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
		mv -v $(HOME)/$$FILE{,.bak}; fi; done
	mkdir -p $(XDG_CONFIG_HOME)
	stow -t $(HOME) runcom
	stow -t $(XDG_CONFIG_HOME) config

unlink: stow
	stow --delete -t $(HOME) runcom
	stow --delete -t $(XDG_CONFIG_HOME) config
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE.bak ]; then \
		mv -v $(HOME)/$$FILE.bak $(HOME)/$${FILE%%.bak}; fi; done

test:
	bats test

