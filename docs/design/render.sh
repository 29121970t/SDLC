#!/usr/bin/env bash
# Regenerate every PNG of the graphic part from the SysML v2 model.
#
# Requires: sysml (OpenSysML CLI), python3, Graphviz (dot, neato).
# Set SYSML=/path/to/sysml when the binary is not on PATH.
set -euo pipefail

cd "$(dirname "$0")/../.."

command -v "${SYSML:-sysml}" >/dev/null || { echo "sysml not found; set SYSML=/path/to/sysml" >&2; exit 1; }
command -v dot >/dev/null || { echo "graphviz (dot) not found" >&2; exit 1; }
command -v neato >/dev/null || { echo "graphviz (neato) not found" >&2; exit 1; }

python3 docs/design/render.py ContextView docs/design/diagrams/context.png
python3 docs/design/render.py UseCaseView docs/design/diagrams/usecase.png
python3 docs/design/render.py RecommendationsView docs/design/mockups/01-recommendations.png mockup
python3 docs/design/render.py CatalogView docs/design/mockups/02-catalog.png mockup
python3 docs/design/render.py MovieCardView docs/design/mockups/03-movie-card.png mockup
python3 docs/design/render.py ProfileView docs/design/mockups/04-profile.png mockup

echo "PNG regenerated from docs/design/kinovector.sysml"
