# One Step Deployment

This deployment option will build everything for you so you can be up and running with Tanzu Application Platform (TAP). You will execute a single script that calls all the scripts included in the step-by-step guide.

## Setup Environment Variable for params.yaml

Set the PARAMS_YAML environment variable to the path of your `params.yaml` file. If you followed the recommendation, the value would be `local-config/params.yaml`, however you may choose otherwise. A sample `REDACTED-params.yaml` file is included in this directory, named REDACTED-params.yaml. It is recommended you copy this file and rename it to params.yaml and place it in the `local-config/` directory, and then start making your adjustments. `local-config/` is included in the `.gitignore` so your version won't be included in any future commits you have to the repo.

```shell
# Update the path from the default if you have a different params.yaml file name or location.
export PARAMS_YAML=local-config/params.yaml
```

Ensure that your copy of `params.yaml` indicates your Jumpbox OS: MacOS or Linux

## Deploy All Script

You can execute the following script to perform all of those tasks:

```shell
./scripts/deploy-all.sh
```

The output of the `deploy-all.sh` script will either prompt for manual DNS record creation for the View, Iterate and each Run Cluster or auto configure it for you.

## Manual DNS Record Creation

After the completion of the `deploy-all.sh` script, you must update your DNS records. An example of the script output is below which contains the DNS records you will need.

```shell
##############################################################################
To proceed, you must register the wildcard DNS record with the following details:
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

Execute the following script to tear down your environment.

```shell
./scripts/delete-all.sh
```
