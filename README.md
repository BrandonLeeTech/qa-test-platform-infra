# QA Test Platform Infrastructure

這個 repository 用來建立獨立的自動化測試執行平台，不存放產品 test case，也不取代既有 Jenkins 或遠端 Selenium Grid。

第一階段的目標：

1. 保留 `Jenkins -> remote Selenium Grid` 正式流程。
2. 在本地 Kubernetes 建立備援 Selenium Grid。
3. 由 Jenkins 或人工在測試開始前選擇 remote/local Grid。
4. 後續再用 Kubernetes Job 執行 pytest runner。
5. Terraform 只負責未來的雲端基礎設施，不管理每一次短生命週期測試 Job。

## Responsibilities

| Layer | Responsibility |
|---|---|
| Jenkins | 測試入口、排程、參數與 Grid 選擇 |
| pytest repository | Test case、fixture、assertion 與 runner image |
| Selenium Grid | 接收 WebDriver session 並分配 browser node |
| Kubernetes / Helm | 部署、重啟、擴展與回收本地 Grid 元件 |
| Terraform | 建立雲端 network、cluster、registry、storage 與 IAM |

## Repository layout

```text
qa-test-platform-infra/
├── docs/
│   ├── architecture.md
│   └── jenkins-integration.md
├── helm/
│   └── selenium-grid/
│       └── values-local.yaml
├── kubernetes/
│   ├── namespaces/
│   │   └── qa-platform.yaml
│   └── test-runner/
│       ├── configmap.example.yaml
│       └── job-web-smoke.example.yaml
├── scripts/
│   ├── check-prerequisites.sh
│   └── select-grid.sh
└── terraform/
    └── README.md
```

## Prerequisites

- Docker
- A local Kubernetes cluster, such as Docker Desktop Kubernetes, kind, or k3d
- `kubectl`
- Helm 3
- `curl`
- Terraform only when starting the cloud phase

Check the local tools:

```bash
./scripts/check-prerequisites.sh
```

## Phase 1: local fallback Grid

Create namespaces:

```bash
kubectl apply -f kubernetes/namespaces/qa-platform.yaml
```

Install the official Selenium Grid chart:

```bash
helm repo add docker-selenium https://www.selenium.dev/docker-selenium
helm repo update
helm upgrade --install selenium-grid docker-selenium/selenium-grid \
  --namespace selenium-grid \
  --create-namespace \
  --values helm/selenium-grid/values-local.yaml
```

For local inspection, forward the Grid router without exposing it permanently:

```bash
kubectl port-forward \
  --namespace selenium-grid \
  service/selenium-grid-router \
  4444:4444
```

Open `http://127.0.0.1:4444/ui`.

> Service names can change between chart versions. Confirm them with
> `kubectl get service -n selenium-grid` after installation.

## Grid selection

The selector checks health before a test starts. It does not migrate an active browser session.

```bash
GRID_MODE=auto \
REMOTE_GRID_URL=http://remote-grid.example:4444/wd/hub \
LOCAL_GRID_URL=http://127.0.0.1:4444/wd/hub \
./scripts/select-grid.sh
```

Supported modes:

- `remote`: require the remote Grid.
- `local`: require the local Grid.
- `auto`: prefer remote, then fall back to local.

Use the printed URL as the existing pytest option:

```bash
SELECTED_GRID_URL="$(GRID_MODE=auto \
  REMOTE_GRID_URL="$REMOTE_GRID_URL" \
  LOCAL_GRID_URL="$LOCAL_GRID_URL" \
  ./scripts/select-grid.sh)"

pytest tests/hk_sanity_web \
  -m part_3 \
  -n 1 \
  --use-grid \
  --selenium-grid-url="$SELECTED_GRID_URL" \
  --web-headless
```

## Phase 2: test-runner Job

`kubernetes/test-runner/job-web-smoke.example.yaml` is intentionally an example. Before applying it:

1. Build an immutable test-runner image from the test repository.
2. Replace the example image with a real registry tag or digest.
3. Set the selected Grid URL through ConfigMap or Jenkins.
4. Start with read-only tests and one browser session.
5. Upload Allure, logs, and screenshots before the Pod is deleted.

## Phase 3: Terraform and cloud

Terraform is intentionally deferred until the local architecture works. See `terraform/README.md` for its boundary and planned resources.

## Safety rules

- Never commit credentials, OTPs, cookies, API keys, or cloud credentials.
- Fallback occurs before session creation; an active WebDriver session cannot move between Grids.
- Keep `backoffLimit: 0` for tests that create accounts, orders, payments, or inventory changes.
- Do not use `latest` image tags for repeatable test execution.
- Keep the current Jenkins/Grid flow available during the experiment.

