# Download and Install Tanzu CLI

## Run the Script

```shell
./scripts/download-and-install-tanzu-cli.sh
```

## What Did the Script Do?

This script downloads and installs the Tanzu CLI and related plugins onto the machine your are running the scripts. Only Linux and MacOS machines are supported and configured by the value `jumpbox_os`.

## Values Used From params.yaml

```yaml
jumpbox_os: Linux #! default is Linux; other values: MacOS
```

## Go to Next Step

[Add TAP Package Repository](../minimal-tap-profiles/01-add-tap-package-repository.md)
