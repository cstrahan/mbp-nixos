#!/bin/sh

# Usage:
#
#   $ build.sh [path to <nixpkgs>]

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

export NIXOS_CONFIG
export NIX_PATH

NIXOS_CONFIG="$DIR/configuration.nix"
NIX_PATH="nixos-config=$NIXOS_CONFIG:$NIX_PATH"
if [[ -n "$1" ]]; then
  NIX_PATH="nixpkgs=$1:$NIX_PATH"
fi

nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage --show-trace
