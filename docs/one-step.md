# One Step Deployment

This deployment option will build everything in order to get up and running with Tanzu Application Platform (TAP). A single script that calls all the scripts included in the step-by-step guide will need to be executed.

## Setup Environment Variable for params.yaml

Configuration is stored in a file called `params.yaml`. A sample redacted version of this file is included in the root directory and named `REDACTED-params.yaml`. It is recommended a copy of this file, renamed to `params.yaml`, is placed in a directory called `local-config`. Make adjustments to this copy. Set an environment variable called `PARAMS_YAML` to the relative path to `params.yaml`. If following the recommendation, the value would be `local-config/params.yaml`.

```shell
# Update the path from the default if a different params.yaml file name or location is used
export PARAMS_YAML=local-config/params.yaml
```

Ensure that a copy of `params.yaml` indicates the Jumpbox OS. Either `MacOS` or `Linux`.

## Deploy All Script

After having entered in values in the `params.yaml` file, run:

```shell
./scripts/deploy-all.sh
```

The output of the `deploy-all.sh` script will either prompt for manual DNS record creation for the View, Iterate and each Run Cluster or auto configure it.

## Manual DNS Record Creation

After the completion of the `deploy-all.sh` script, DNS records must be updated. An example of the script output is below, which contains the DNS records that will be needed.

```shell
##############################################################################
To proceed, register the wildcard DNS record with the following details:
##############################################################################

Domain Name: *.subdomain.example.com
IP Address: 240.1.1.1

Domain Name: *.subdomain.example.com
IP Address: 240.1.1.2

Domain Name: *.subdomain.example.com
IP Address: 240.1.1.3

Domain Name: *.subdomain.example.com
IP Address: 240.1.1.4
```

## Automatic DNS Record Creation

After the completion of the `deploy-all.sh` script, multiple DNS records will be automatically. In order for this to occur, a DNS Zone must be created in Azure DNS for the domain used as `ingress_domain` for the clusters in `params.yaml`. Finally, set the `params.yaml` Azure section to the following:

```yaml
azure:
  dns:
    auto_configure: true
    dns_zone_name: example.com
    resource_group: example
```

## Tear Down

Execute the following script to tear down the environment. It will delete the Azure resource group but not undo any automatic DNS changes that may have been made.

```shell
./scripts/delete-all.sh
```
