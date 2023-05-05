# Deploy Azure Container Registry

## Run the Script

```shell
./scripts/02-deploy-azure-container-registry.sh
```

## What Did the Script Do?

Creates or uses an existing Azure Container Registry (ACR). You can control of the name of the ACR by setting the value for `acr_name`. If it doesn't exist, the script will validate with Azure to be unique and create it. Finally, admin credentials are created and stored in `./generated/params.yaml`.

## Values Used From params.yaml

```yaml
azure:
  acr_sku: standard
  acr_name: 
```

## Go to Next Step

[Deploy Azure Kubernetes Clusters](./03-deploy-azure-k8s-clusters.md)
