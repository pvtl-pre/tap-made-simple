# Download and Install Cluster Essentials

This is the first step in setting up the TAP Prerequisites.

## Run the Script

```shell
./scripts/download-and-install-cluster-essentials.sh
```

## What Did the Script Do?

This script downloads and installs [Cluster Essentials](https://docs.vmware.com/en/Cluster-Essentials-for-VMware-Tanzu/index.html) onto each AKS cluster. It uses the CLI for [Tanzu Network](https://network.tanzu.vmware.com/) (i.e. [pivnet](https://github.com/pivotal-cf/pivnet-cli)) to download the software by using a Tanzu Network account. The container images for Cluster Essentials are stored on Tanzu Registry. The credentials for Tanzu Network and Tanzu Registry are the same.

## Values Used From params.yaml

```yaml
tanzu_registry:
  hostname: "registry.tanzu.vmware.com"
  username: #! set
  password: #! set
```

## Go to Next Step

[Download and Install Tanzu CLI](./02-download-and-install-tanzu-cli.md)
