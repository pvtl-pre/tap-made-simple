# Prep Azure Objects

This is the first step and there are many to follow and lots of things to discuss.

## Setup Environment Variable for params.yaml

Set the PARAMS_YAML environment variable to the path of your `params.yaml` file. If you followed the recommendation, the value would be `local-config/params.yaml`, however you may choose otherwise. A sample `REDACTED-params.yaml` file is included in this directory, named REDACTED-params.yaml. It is recommended you copy this file and rename it to params.yaml and place it in the `local-config/` directory, and then start making your adjustments. `local-config/` is included in the `.gitignore` so your version won't be included in any future commits you have to the repo.

```shell
# Update the path from the default if you have a different params.yaml file name or location.
export PARAMS_YAML=local-config/params.yaml
```

Ensure that your copy of `params.yaml` indicates your Jumpbox OS: OSX or Linux

## Run the Script

After having entered in values in your `params.yaml` file, we'll run:

```shell
./scripts/01-prep-azure-objects.sh
```

## What Did the Script Do?

First a quick note on something that happens before all of the scripts are run, which is `./scripts/set-env.sh` is run first. It adds a function to display steps more vividly but more importantly, it makes a copy of `params.yaml` and puts it into a `generated` directory. Some of the subsequent scripts will need to modify the `params.yaml` file so making a copy of it and editing the `./generated/params.yaml` version keeps your copy clean.

This script creates an Azure Resource Group.

## Values Used From params.yaml

```yaml
azure:
  resource_group: tap
  location: centralus
```

## Go to Next Step

[Deploy Azure Container Registry](./02-deploy-azure-container-registry.md)
