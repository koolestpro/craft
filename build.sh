#!/usr/bin/env bash
# Build every Craft app's CLI into ./bin, so the whole suite is available on PATH.
#
#   ./build.sh                 # all apps
#   ./build.sh filmcraft       # only the named apps
#
# Optional per-app cargo features (override with env vars), for example:
#   FEATURES_filmcraft="whisper" FEATURES_photocraft="heif" ./build.sh
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p bin

all_apps=(cadcraft designcraft effectcraft filmcraft lightcraft pdfcraft photocraft vectorcraft wordcraft)

# Default extra features per app (space separated, empty means none).
default_features_filmcraft="whisper"
default_features_photocraft="heif"
default_features_pdfcraft="mcp"
default_features_lightcraft="denoise"

if [ "$#" -gt 0 ]; then
  apps=("$@")
else
  apps=("${all_apps[@]}")
fi

for app in "${apps[@]}"; do
  if [ ! -d "$app/.git" ] && [ ! -f "$app/.git" ]; then
    echo "skip $app: submodule not checked out (run: git submodule update --init --recursive)"
    continue
  fi

  feats_var="default_features_${app}"
  override_var="FEATURES_${app}"
  if [ -n "${!override_var+x}" ]; then
    feats="${!override_var}"
  else
    feats="${!feats_var:-}"
  fi

  echo "==> building ${app}-cli ${feats:+ (features: $feats)}"
  ( cd "$app" && cargo build --release -p "${app}-cli" ${feats:+--features "$feats"} )

  built="$app/target/release/${app}-cli"
  if [ -x "$built" ]; then
    cp -f "$built" "bin/${app}-cli"
    echo "    -> bin/${app}-cli"
  else
    echo "    warning: $built not found"
  fi
done

echo "done. CLIs in $(pwd)/bin"
