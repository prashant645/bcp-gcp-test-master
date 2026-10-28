# demoappdeploytokyma

Minimal Node.js Hello World service deployed to SAP BTP Kyma on GCP.

## Run locally

```bash
npm test
npm start
curl http://localhost:3000/
```

## Branching and deployment

The branching model follows the SAP promotion-branch pattern. Branches map to
environments; a single image digest built from a feature branch is promoted by
reference rather than rebuilt. Full contract, diagrams and limitations:
**[docs/branching-strategy.md](docs/branching-strategy.md)**.

| Branch | Maps to | Namespace | Behaviour |
|---|---|---|---|
| `master` | Production | `demoapp-prod` | Protected. Merge deploys prod after reviewer approval. Only `release/**` and `hotfix/**` merge in. |
| `release/**` | Staging / pre-prod | `demoapp-staging` | Cut from `develop`. Hardening and fixes only. |
| `develop` | Dev | `demoapp-dev` | Integration branch. Auto-deploys on merge. |
| `feature/**`, `bugfix/**`, `hotfix/**` | CI only | — | Builds, tests, scans, publishes candidate image. No deploy. |

`feature/** → develop (dev) → release/** (staging) → master (prod)`. Only
`ci.yaml` ever builds an image; every environment afterwards promotes that same
Artifactory digest and changes only its Helm values.

```bash
./scripts/cut-release.sh 1.4.0        # release/1.4.0 -> staging
./scripts/promote-to-prod.sh 1.4.0    # merge to master -> prod (gated)
./scripts/cut-hotfix.sh null-pointer  # hotfix/null-pointer off master
```

## Public URLs

| Env | URL |
|---|---|
| dev | `https://demoapp-dev.a35836f.stage.kyma.ondemand.com` |
| staging | `https://demoapp-staging.a35836f.stage.kyma.ondemand.com` |
| prod | `https://demoapp.a35836f.stage.kyma.ondemand.com` |

All three share one Kyma cluster (shoot `a35836f`, stage), separated by namespace.

## Required repository secrets

| Secret | Purpose |
|---|---|
| `GCP_KUBECONFIG_B64` | base64-encoded kubeconfig for the Kyma cluster |
| `REGISTRY_USERNAME` | SAP Artifactory login, also used for the in-cluster pull secret |
| `REGISTRY_PASSWORD` | as above |

```bash
base64 < kyma.kubeconfig.yaml | tr -d '\n' \
  | GH_HOST=github.tools.sap gh secret set GCP_KUBECONFIG_B64 \
      --repo <owner>/<repo>
```

Each promotion job recreates its namespace and the `hello-world-registry` pull
secret idempotently, so there is no manual per-namespace bootstrap.

One-time repository setup (branch protection, the `production` environment and
its required reviewers): **[docs/branch-protection.md](docs/branch-protection.md)**.
