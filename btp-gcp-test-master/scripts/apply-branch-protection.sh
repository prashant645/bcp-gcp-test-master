#!/usr/bin/env bash
# =============================================================================
# Apply branch protection matching the branching strategy
# =============================================================================
#   ./scripts/apply-branch-protection.sh GTLCInfra/demoappdeploytokyma
#
# Requires `gh` authenticated against github.tools.sap:
#   GH_HOST=github.tools.sap gh auth status
#
# Confirm the CI status-check name first - it must match the job name GitHub
# reports, not the workflow file name:
#   GH_HOST=github.tools.sap gh pr checks <pr-number>
# =============================================================================
set -euo pipefail

REPO="${1:-}"
CI_CHECK="${2:-Build, test, scan, publish candidate}"
export GH_HOST="${GH_HOST:-github.tools.sap}"

if [[ -z "$REPO" ]]; then
  echo "Usage: $0 <owner>/<repo> [ci-status-check-name]" >&2
  exit 1
fi

protect() {
  local branch="$1"
  local reviewers="$2"
  echo "==> Protecting ${branch} (${reviewers} required approval(s))"
  gh api -X PUT "repos/${REPO}/branches/${branch}/protection" \
    -H "Accept: application/vnd.github+json" \
    -F "required_status_checks[strict]=true" \
    -f "required_status_checks[contexts][]=${CI_CHECK}" \
    -F "enforce_admins=false" \
    -F "required_pull_request_reviews[required_approving_review_count]=${reviewers}" \
    -F "required_pull_request_reviews[require_code_owner_reviews]=true" \
    -F "required_pull_request_reviews[dismiss_stale_reviews]=true" \
    -F "restrictions=null" \
    -F "allow_force_pushes=false" \
    -F "allow_deletions=false"
}

# master is PRODUCTION: only release/** and hotfix/** merge in, and every
# merge ships. It carries the stricter review requirement.
protect master 2
protect develop 1

echo
echo "Done. Still to do by hand in the repo settings:"
echo "  - set 'develop' as the default branch"
echo "  - create the 'production' environment with required reviewers"
echo "  - add a branch ruleset blocking force-push/delete on release/**"
echo "  - restrict who may merge into master"
