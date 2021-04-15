#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=../../../../../ -i bash -p wget yarn2nix jq yarn

set -exuo pipefail

if [ "$#" -ne 1 ] || [[ "$1" == -* ]]; then
  echo "Regenerates the Yarn dependency lock files for the element-desktop package."
  echo "Usage: $0 <git release tag>"
  exit 1
fi

RIOT_WEB_SRC="https://raw.githubusercontent.com/vector-im/element-desktop/$1"

cd "$(mktemp -d)"

wget "$RIOT_WEB_SRC/package.json" -O - | jq '. + {dependencies: (.dependencies + .hakDependencies) }' > package.json
wget "$RIOT_WEB_SRC/yarn.lock" -O yarn.lock
cp yarn.lock yarn.lock.orig
yarn --ignore-scripts
yarn2nix > yarn.nix

mv package.json "$OLDPWD/element-desktop-package.json"
mv yarn.lock "$OLDPWD/element-desktop-yarndeps.lock"
mv yarn.nix "$OLDPWD/element-desktop-yarndeps.nix"
