# Add TAP Package Repository

## Run the Script

```shell
./scripts/add-tap-package-repository.sh
```

## What Did the Script Do?

This script installs the TAP package repository on all of the AKS clusters. The TAP package repository serves as a reference to all of the TAP packages that could be installed. An optional yet recommended path would be relocate the TAP packages (i.e. container images) from Tanzu Registry to ACR. TAP package repository would then refer to ACR for installation of TAP packages. This process is used for production level deployments and causes deployment times to increase significantly. Consequently, relocation of images was skipped.

## Values Used From params.yaml

```yaml
tanzu_registry:
  hostname: "registry.tanzu.vmware.com"
  username: #! set
  password: #! set
```

## Go to Next Step

[Generate Profiles From Templates](./02-generate-profiles-from-templates.md)
