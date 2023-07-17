# Prep Azure Objects

This is the first step in setting up the Azure infrastructure but before that can be done, some prep work needs to be completed.

## Setup Environment Variable for params.yaml

Configuration is stored in a file called `params.yaml`. A sample redacted version of this file is included in the root directory and named `REDACTED-params.yaml`. It is recommended a copy of this file, renamed to `params.yaml`, is placed in a directory called `local-config`. Make adjustments to this copy. Set an environment variable called `PARAMS_YAML` to the relative path to `params.yaml`. If following the recommendation, the value would be `local-config/params.yaml`.

```shell
# Update the path from the default if a different params.yaml file name or location is used
export PARAMS_YAML=local-config/params.yaml
```

Ensure that a copy of `params.yaml` indicates the Jumpbox OS. Either `MacOS` or `Linux`.

## Run the Script

After having entered in values in the `params.yaml` file, run:

```shell
./scripts/01-prep-azure-objects.sh
```

## What Did the Script Do?

First a quick note on something that happens before all of the scripts are run, which is `./scripts/set-env.sh` is run first. It adds a function to display steps more vividly but more importantly, it makes a copy of `params.yaml` and puts it into a `generated` directory. Some of the subsequent scripts will need to modify the `params.yaml` file so making a copy of it and editing the `./generated/params.yaml` version keeps it clean.

This script creates an Azure Resource Group.

## Values Used From params.yaml

```yaml
azure:
  resource_group: tap
  location: centralus
```

## Go to Next Step

[Deploy Azure Container Registry](./02-deploy-azure-container-registry.md)
