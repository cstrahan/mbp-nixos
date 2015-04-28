#!/bin/sh

# Usage:
#
#   $ build.sh [path to <nixpkgs>]

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

export NIX_PATH
NIX_PATH="nixos-config=$DIR/configuration.nix:$NIX_PATH"

if [[ -n "$1" ]]; then
  NIX_PATH="nixpkgs=$1:$NIX_PATH"
fi

nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage --show-trace
