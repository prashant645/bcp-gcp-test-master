#!/usr/bin/env bash
set -euo pipefail

# Resolve the candidate image digest to promote into an environment.
#
# The promotion model builds exactly one image, on the feature branch, tagged
# `candidate-<commit sha>`. Every later environment deploys THAT manifest by
# digest. Nothing downstream rebuilds. This script answers the only hard
# question in that model: given a commit on develop / release/* / master, which
# candidate digest does it correspond to?
#
# It tries, in order:
#   1. the commit itself              - fast-forward merges
#   2. every commit carried by the push - "Create a merge commit" merges
#   3. the head of the PR named in the commit subject - squash and rebase merges
#
# If none of them has a candidate image it exits non-zero rather than falling
# back to a rebuild, which would silently break the build-once guarantee.
#
# Usage:
#   resolve-candidate-digest.sh <image-base> <sha> [sha...]
# Prints:
#   sha256:<digest>   on stdout, nothing else

IMAGE_BASE="${1:?usage: resolve-candidate-digest.sh <image-base> <sha> [sha...]}"
shift
CANDIDATE_SHAS=("$@")

if [[ ${#CANDIDATE_SHAS[@]} -eq 0 ]]; then
  echo "No candidate commits supplied." >&2
  exit 1
fi

digest_of() {
  # Prints the manifest digest of a reference, or nothing if it does not exist.
  docker buildx imagetools inspect "$1" --format '{{.Manifest.Digest}}' 2>/dev/null || true
}

SEEN=""
for sha in "${CANDIDATE_SHAS[@]}"; do
  [[ -n "$sha" ]] || continue
  # The caller's sources overlap (the pushed commit is usually also first in
  # the history walk); do not query the registry for the same tag twice.
  case " $SEEN " in *" $sha "*) continue ;; esac
  SEEN="$SEEN $sha"
  ref="${IMAGE_BASE}:candidate-${sha}"
  echo "Looking for ${ref}" >&2
  d="$(digest_of "$ref")"
  if [[ -n "$d" ]]; then
    echo "Resolved ${sha} -> ${d}" >&2
    echo "$d"
    exit 0
  fi
done

cat >&2 <<MSG

ERROR: no candidate image found for any of these commits:
$(printf '  - %s\n' "${CANDIDATE_SHAS[@]}")

A candidate image is built by ci.yaml when a feature/bugfix/hotfix branch is
pushed or a PR is opened. Nothing is rebuilt during promotion, so if the
candidate is missing the promotion cannot proceed.

Most likely causes:
  - the branch was merged without CI ever running (e.g. pushed directly)
  - the candidate image was expired or deleted from Artifactory
  - the merge produced commits CI never saw

Fix: re-run the CI workflow on the source branch to republish the candidate,
then re-run this deploy.
MSG
exit 1
