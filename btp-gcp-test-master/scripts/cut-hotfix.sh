#!/usr/bin/env bash
# =============================================================================
# Start an urgent production hotfix
# =============================================================================
# Hotfix branches are cut from master, because master is production.
#
#   ./scripts/cut-hotfix.sh null-pointer   -> hotfix/null-pointer
#
# Pushing the branch runs ci.yaml, which publishes a candidate image. The
# hotfix branch itself does NOT deploy to production: it reaches production by
# being merged into master, exactly like a release. Merge it back to develop
# too, or the fix is lost at the next release.
# =============================================================================
set -euo pipefail

NAME="${1:-}"

if [[ -z "$NAME" ]]; then
  echo "Usage: $0 <short-name>" >&2
  echo "  e.g. $0 null-pointer" >&2
  exit 1
fi

if [[ ! "$NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: name may only contain letters, digits, dot, underscore and dash (got '$NAME')" >&2
  exit 1
fi

BRANCH="hotfix/${NAME}"

echo "==> Updating master"
git checkout master
git pull --ff-only origin master

echo "==> Creating ${BRANCH} from master"
git checkout -b "$BRANCH"
git push -u origin "$BRANCH"

cat <<MSG

Hotfix branch ${BRANCH} pushed. CI will publish a candidate image.

  1. Commit the fix and let CI go green.
  2. Open a PR into master. Merging it deploys to production (gated).
  3. Merge master back into develop:
       git checkout develop && git merge --no-ff master && git push origin develop
MSG
