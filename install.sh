#!/bin/sh
# Installe la skill graph-engineering et ses commandes.
# Usage : ./install.sh            (global, dans ~/.claude)
#         ./install.sh --projet   (dans .claude du dossier courant)
set -eu

src=$(cd "$(dirname "$0")" && pwd)

case "${1:-}" in
  --projet) dest="$(pwd)/.claude" ;;
  "")       dest="$HOME/.claude" ;;
  *)        echo "Option inconnue : $1 (attendu : --projet)" >&2; exit 1 ;;
esac

mkdir -p "$dest/skills/graph-engineering" "$dest/commands"
cp "$src/graph-engineering/SKILL.md" "$dest/skills/graph-engineering/SKILL.md"
cp "$src"/commands/*.md "$dest/commands/"

echo "Installé dans $dest"
echo "Commandes : /graphloop /graphplan /graphstatus /graphresume"
