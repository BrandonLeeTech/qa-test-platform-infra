# Jenkins integration boundary

This repository does not change the existing Jenkins pipeline. The following is a future integration contract.

## Suggested parameters

```text
GRID_MODE=remote|local|auto
REMOTE_GRID_URL=http://remote-grid.example:4444/wd/hub
LOCAL_GRID_URL=http://local-grid.example:4444/wd/hub
TEST_ENV=STG
TEST_MARKER=part_3
TEST_PARALLELISM=1
```

## Selection sequence

1. Jenkins receives a manual or scheduled test request.
2. `select-grid.sh` checks Grid health.
3. Jenkins records the selected URL and reason in the build log.
4. pytest receives the URL through `--selenium-grid-url`.
5. The whole test case stays on the selected Grid.
6. Infrastructure failures and assertion failures are reported separately.

## Safe fallback policy

| Test class | Automatic fallback retry |
|---|---|
| Read-only browsing | Usually safe after an infrastructure failure |
| API GET / contract validation | Usually safe |
| Account registration | No, unless generated data and cleanup are idempotent |
| Cart / checkout | No, inspect state first |
| Payment | Never retry blindly |
| Inventory mutation | Never retry blindly |

## Pseudocode only

```groovy
stage('Select Grid') {
    // GRID_URL = sh(script: './scripts/select-grid.sh', returnStdout: true).trim()
}

stage('Run Web Smoke') {
    // sh "pytest ... --selenium-grid-url=${GRID_URL}"
}
```

Do not paste this into the production Jenkinsfile until network reachability, credentials, Grid capacity, and retry behavior have been reviewed.

