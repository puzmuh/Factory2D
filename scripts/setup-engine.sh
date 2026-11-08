#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/vendor"
if [[ ! -d "$ROOT/vendor/Ro2DEngine/.git" ]]; then
  git clone https://github.com/nrmu9/Ro2DEngine.git "$ROOT/vendor/Ro2DEngine"
fi
git -C "$ROOT/vendor/Ro2DEngine" fetch origin f97a2711e869caa2b29fbf810e5f60d60e63ca10
git -C "$ROOT/vendor/Ro2DEngine" checkout --detach f97a2711e869caa2b29fbf810e5f60d60e63ca10
printf '%s\n' 'Pinned Ro2DEngine installed.'
