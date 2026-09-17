# Architecture

## Current production path

```text
Jenkins
   |
   v
Remote Selenium Grid
   |
   +-- Docker Chrome Node 1
   +-- Docker Chrome Node 2
   `-- Docker Chrome Node N
```

This path remains unchanged.

## Target learning and fallback path

```text
                       +----------------------+
                       | Jenkins              |
                       | GRID_MODE            |
                       | remote/local/auto    |
                       +----------+-----------+
                                  |
                        select before test run
                                  |
                 +----------------+----------------+
                 |                                 |
                 v                                 v
       +---------------------+          +------------------------+
       | Remote Grid         |          | Local Kubernetes       |
       | Existing design     |          | Selenium Grid          |
       | Docker nodes        |          | Browser node Pods      |
       +----------+----------+          +-----------+------------+
                  |                                 |
                  +----------------+----------------+
                                   |
                                   v
                            Staging website
```

## Without and with Kubernetes

| Area | Docker-only local Grid | Kubernetes local Grid |
|---|---|---|
| Startup | `docker compose up` | Helm creates several Kubernetes resources |
| Browser capacity | Fixed container count or scripts | Fixed replicas first; queue-based autoscaling later |
| Failure recovery | Docker restart policy | Controllers recreate failed Pods |
| Resource control | Per-container Docker settings | Requests, limits, quotas and scheduling |
| Networking | Host ports and Docker networks | Services, DNS, namespaces and optional ingress |
| Isolation | One Docker host | Namespace and Pod-level isolation |
| Operational complexity | Low | Medium to high |
| Learning value | Containers and Selenium Grid | Cluster operations, Helm, observability and scaling |
| Best fit | Small stable single-host Grid | Shared, scalable, controlled test platform |
| Cost | Usually lower | Cluster and operational overhead |

## Important behavior

Grid fallback is not live session migration.

```text
Allowed:
health check -> choose Grid -> create session -> finish test

Not possible:
remote session fails halfway -> move the same browser state to local Grid
```

Tests with side effects must not be blindly replayed on another Grid. Account registration, checkout, payment, and inventory tests need idempotency or explicit cleanup before retry.

## Component ownership

```text
Terraform
  creates long-lived cloud infrastructure
      |
      v
Kubernetes / Helm
  deploys Grid and test execution resources
      |
      v
Jenkins
  selects when, where and what to run
      |
      v
pytest
  owns test logic and assertions
```

