#!/usr/bin/env bash
# =============================================================================
# Promote a release branch to production
# =============================================================================
# Merges release/<version> into master. The push to master is what triggers
# .github/workflows/deploy-prod.yaml, which then waits on the `production`
# GitHub environment's required reviewers.
#
#   ./scripts/promote-to-prod.sh 1.4.0
#
# The image is NOT rebuilt. Production promotes the same digest that was
# verified in dev and staging.
# =============================================================================
set -euo pipefail

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>" >&2
  exit 1
fi

BRANCH="release/${VERSION}"

echo "==> Fetching"
git fetch origin

if ! git rev-parse --verify "origin/${BRANCH}" >/dev/null 2>&1; then
  echo "Error: origin/${BRANCH} does not exist." >&2
  echo "Cut it first: ./scripts/cut-release.sh ${VERSION}" >&2
  exit 1
fi

echo "==> Updating master"
git checkout master
git pull --ff-only origin master

# A merge commit keeps the release branch's commits - and therefore the
# candidate image tags - reachable from the push event, which is how
# wf-promote.yaml resolves the digest.
echo "==> Merging ${BRANCH} into master"
git merge --no-ff "origin/${BRANCH}" -m "Release ${VERSION}"

echo "==> Pushing master (this queues the production deploy, pending approval)"
git push origin master

cat <<MSG

Release ${VERSION} merged to master.
  The production deploy is queued and waits for a reviewer on the
  \`production\` GitHub environment. Approve it in the Actions run.

  Now merge master back into develop so the release commits are not lost:
      git checkout develop && git merge --no-ff master && git push origin develop
MSG
