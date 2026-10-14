#!/usr/bin/env bash
# Keep the Craft suite in sync with the original ArtCraft sources (storytold/*).
#
#   ./update.sh            report what is new upstream for each app (dry run)
#   ./update.sh --check    same report, exit 1 if anything is behind (for CI/cron)
#   ./update.sh --apply    fast-forward our fork to upstream, push it, then re-pin
#                          the submodule in the umbrella and commit
#
# Upstream is the source of truth. Our forks carry no local patches today, so an
# update is a fast-forward. If a fork ever has local commits ahead of upstream, the
# script refuses for that app and tells you to resolve it by hand.
set -euo pipefail
cd "$(dirname "$0")"

MODE="report"
case "${1:-}" in
  --check) MODE="check" ;;
  --apply) MODE="apply" ;;
  "") MODE="report" ;;
  *) echo "usage: $0 [--check|--apply]"; exit 2 ;;
esac

APPS=(cadcraft craft-launcher designcraft effectcraft filmcraft lightcraft pdfcraft photocraft vectorcraft wordcraft)
UPSTREAM_ORG="${UPSTREAM_ORG:-storytold}"

behind_any=0
changed=()

echo "Craft upstream sync (org: ${UPSTREAM_ORG})"
for app in "${APPS[@]}"; do
  if [ ! -e "$app/.git" ]; then
    echo "  skip $app (submodule not checked out; run git submodule update --init --recursive)"
    continue
  fi
  url="git@github.com:${UPSTREAM_ORG}/${app}.git"
  git -C "$app" remote get-url upstream >/dev/null 2>&1 || git -C "$app" remote add upstream "$url"
  git -C "$app" fetch -q upstream

  behind=$(git -C "$app" rev-list --count HEAD..upstream/main 2>/dev/null || echo 0)
  ahead=$(git -C "$app" rev-list --count upstream/main..HEAD 2>/dev/null || echo 0)
  printf "  %-14s behind=%-5s ahead=%s\n" "$app" "$behind" "$ahead"

  if [ "$behind" != "0" ]; then
    behind_any=1
    if [ "$MODE" = "apply" ]; then
      if [ "$ahead" != "0" ]; then
        echo "      !! $app has local commits ahead of upstream; not auto-merging. Resolve by hand."
        continue
      fi
      git -C "$app" merge --ff-only upstream/main
      git -C "$app" push -q origin main
      echo "      updated and pushed $app"
      changed+=("$app")
    fi
  fi
done

if [ "$MODE" = "apply" ] && [ "${#changed[@]}" -gt 0 ]; then
  git add "${changed[@]}"
  git commit -q -m "Update app submodules to latest upstream: ${changed[*]}"
  echo "umbrella pin updated for: ${changed[*]}"
  echo "push the umbrella with: git push"
fi

if [ "$MODE" = "check" ] && [ "$behind_any" = "1" ]; then
  echo "upstream has moved; run ./update.sh --apply"
  exit 1
fi
exit 0
