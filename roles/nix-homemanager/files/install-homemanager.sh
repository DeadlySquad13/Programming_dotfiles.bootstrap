#!/usr/bin/env bash

if ! [ -x "$(command -v nix-env)" ]; then
	echo "Install 'nix' first"
	exit 1
fi

nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
# You may need it to fetch successfully:
# sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
nix-channel --update

nix-shell '<home-manager>' -A install;
