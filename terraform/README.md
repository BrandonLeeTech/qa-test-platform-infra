# Terraform boundary

Terraform is the future cloud-provisioning layer of this project. It is not needed to deploy Selenium Grid into an already-running local Kubernetes cluster.

## Terraform should manage

- Virtual network and subnets
- Managed Kubernetes cluster and node pools
- Container registry
- Object storage for Allure, logs, and screenshots
- IAM / workload identity
- DNS and optional load balancer resources
- Remote Terraform state and locking

## Terraform should not manage

- Every individual pytest execution
- Short-lived Kubernetes Jobs
- Test case selection
- Selenium WebDriver sessions
- Product test data

Those belong to Jenkins, Helm/Kubernetes, and the test repository.

## Planned layout after selecting a cloud

```text
terraform/
├── modules/
│   ├── network/
│   ├── kubernetes-cluster/
│   ├── container-registry/
│   ├── artifact-storage/
│   └── workload-identity/
└── environments/
    ├── lab/
    └── production/
```

Do not create provider-specific modules until AWS, GCP, or Azure has been selected. The first milestone should run on a local cluster so that cloud cost and IAM do not obscure the Kubernetes learning objectives.

