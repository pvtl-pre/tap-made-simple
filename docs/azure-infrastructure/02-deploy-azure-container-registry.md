# Deploy Azure Container Registry

## Run the Script

```shell
./scripts/02-deploy-azure-container-registry.sh
```

## What Did the Script Do?

This script creates or uses an existing Azure Container Registry (ACR). Control of the name of the ACR is done by setting the value for `acr.name`. If it doesn't exist, the script will validate uniqueness with Azure before creating it. All container images used and created by TAP will be stored in the value for `acr.repository`. Finally, admin credentials are created and stored in `./generated/params.yaml`.

## Values Used From params.yaml

```yaml
azure:
  acr:
    name: #! set or it will be automatically set
    repository: tap-made-simple
    sku: standard
```

## Go to Next Step

[Deploy Azure Kubernetes Clusters](./03-deploy-azure-k8s-clusters.md)
