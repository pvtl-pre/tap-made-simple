# Step By Step Deployment

This deployment option will build everything piecemeal order to learn how the component parts of Tanzu Application Platform (TAP) are constructed. Multiple scripts, which comprise the one-step guide, will be executed.

## Setup Environment Variable for params.yaml

Configuration is stored in a file called `params.yaml`. A sample redacted version of this file is included in the root directory and named `REDACTED-params.yaml`. It is recommended a copy of this file, renamed to `params.yaml`, is placed in a directory called `local-config`. Make adjustments to this copy. Set an environment variable called `PARAMS_YAML` to the relative path to `params.yaml`. If following the recommendation, the value would be `local-config/params.yaml`.

```shell
# Update the path from the default if a different params.yaml file name or location is used
export PARAMS_YAML=local-config/params.yaml
```

Ensure that a copy of `params.yaml` indicates the Jumpbox OS. Either `MacOS` or `Linux`.

## Azure Infrastructure

### 1. [Prep Azure Objects](./azure-infrastructure/01-prep-azure-objects.md)

### 2. [Deploy Azure Container Registry](./azure-infrastructure/02-deploy-azure-container-registry.md)

### 3. [Deploy Azure Kubernetes Clusters](./azure-infrastructure/03-deploy-azure-k8s-clusters.md)

## TAP Prerequisites

### 1. [Download and Install Cluster Essentials](./tap-prereqs/01-download-and-install-cluster-essentials.md)

### 2. [Download and Install Tanzu CLI](./tap-prereqs/02-download-and-install-tanzu-cli.md)

## Minimal TAP Profiles

### 1. [Add TAP Package Repository](./minimal-tap-profiles/01-add-tap-package-repository.md)

### 2. [Generate Profiles From Templates](./minimal-tap-profiles/02-generate-profiles-from-templates.md)

### 3. [Apply View Profile](./minimal-tap-profiles/03-apply-view-profile.md)

### 4. [Apply Build Profile](./minimal-tap-profiles/04-apply-build-profile.md)

### 5. [Apply Run Profiles](./minimal-tap-profiles/05-apply-run-profiles.md)

### 6. [Apply Iterate Profile](./minimal-tap-profiles/06-apply-iterate-profile.md)

### 7. [Allow TAP GUI to View Resources](./minimal-tap-profiles/07-allow-tap-gui-to-view-resources.md)

## Ingress

### 1. [Apply Load Balancer](./ingress/01-apply-load-balancer.md)

### 2. [Configure DNS](./ingress/02-configure-dns.md)

## TAP GUI Configuration

### 1. [Apply TAP GUI Auth](./tap-gui-configuration/01-apply-tap-gui-auth.md)

### 2. [Apply TAP GUI Database](./tap-gui-configuration/02-apply-tap-gui-database.md)

## Supply Chain Basic

### 1. [Apply Supply Chain Basic](./supply-chain-basic/01-apply-supply-chain-basic.md)

### 2. [Apply Developer Namespace (Legacy)](./supply-chain-basic/02-apply-dev-namespace-legacy.md)

## Workloads

### 1. [Apply Application Accelerator](./workloads/01-apply-application-accelerator.md)

### 2. [Apply TAP GUI Catalogs](./workloads/02-apply-tap-gui-catalogs.md)

### 3. [Apply Application Live View](./workloads/03-apply-application-live-view.md)

### 4. [Apply Java Workload](./workloads/04-apply-java-workload.md)

## Supply Chain Testing

### 1. [Apply Pipelines](./supply-chain-testing/01-apply-pipelines.md)

### 2. [Apply Supply Chain Testing](./supply-chain-testing/02-apply-supply-chain-testing.md)

### 3. [Apply Java Workload for Supply Chain Testing](./supply-chain-testing/03-apply-java-workload-for-supply-chain-testing.md)

## Supply Chain Testing and Scanning

### 1. [Apply Scan Policies](./supply-chain-testing-and-scanning/01-apply-scan-policies.md)

### 2. [Apply Scanner Access to Store Scan Results](./supply-chain-testing-and-scanning/02-apply-scanner-access-to-store-scan-results.md)

### 3. [Apply TAP GUI Access to Scan Results](./supply-chain-testing-and-scanning/03-apply-tap-gui-access-to-scan-results.md)

### 4. [Apply Supply Chain Testing and Scanning](./supply-chain-testing-and-scanning/04-apply-supply-chain-testing-and-scanning.md)

## Learning Center

### 1. [Apply Learning Center](./learning-center/01-apply-learning-center.md)

## TLS

### 1. [Apply Cloud Native Runtimes](./tls/01-apply-cloud-native-runtimes.md)

### 2. [Apply Certificate](./tls/02-apply-cert.md)

## Tear Down

Execute the following script to tear down the environment. It will delete the Azure resource group but not undo any automatic DNS changes that may have been made.

```shell
./scripts/delete-all.sh
```
