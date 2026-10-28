#!/usr/bin/env bash
# =============================================================================
# Cut a release branch from develop  ->  deploys to staging
# =============================================================================
# Promotion flow: feature/* -> develop (dev) -> release/* (staging) -> master (prod)
#
# The release branch is cut from develop, not master: it carries the integrated
# work forward for hardening. Hardening and fixes only - no new features.
#
#   ./scripts/cut-release.sh 1.4.0       -> release/1.4.0
#   ./scripts/cut-release.sh 2026.10.27  -> release/2026.10.27
#
# Pushing the branch is what triggers .github/workflows/deploy-staging.yaml.
# Nothing is rebuilt: staging promotes the digest already verified in dev.
# =============================================================================
set -euo pipefail

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>" >&2
  echo "  e.g. $0 1.4.0" >&2
  exit 1
fi

if [[ ! "$VERSION" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: version may only contain letters, digits, dot, underscore and dash (got '$VERSION')" >&2
  exit 1
fi

BRANCH="release/${VERSION}"

echo "==> Updating develop"
git checkout develop
git pull --ff-only origin develop

if git rev-parse --verify "origin/${BRANCH}" >/dev/null 2>&1; then
  echo "Error: origin/${BRANCH} already exists." >&2
  exit 1
fi

echo "==> Creating ${BRANCH} from develop"
git checkout -b "$BRANCH"

echo "==> Pushing ${BRANCH} (this triggers the staging deploy)"
git push -u origin "$BRANCH"

cat <<MSG

Release branch ${BRANCH} pushed.
  Staging deploy: .github/workflows/deploy-staging.yaml
  Promote to production once staging signs off:
      ./scripts/promote-to-prod.sh ${VERSION}
MSG
