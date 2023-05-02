# Tanzu Application Platform Made Simple

This repo has scripts to deploy Tanzu Application Platform 1.4 to Azure.

## Goals and Audience

This repo is for Tanzu field team members to see how various components of Tanzu Application Platform come together to build a modern application platform. We will highlight the developer experience improvements with an eye towards operator control of the software supply chain. This could be delivered as a presentation and demo or it could be extended to include having the audience actually deploy the full solution on their own Azure subscription.

## Setup Tanzu Application Platform GUI catalog

Tanzu Application Platform GUI Blank Catalog from the Tanzu Application section of [Tanzu Network](https://network.tanzu.vmware.com/products/tanzu-application-platform/).
To install, navigate to Tanzu Network. Under the list of available files to download, there is a folder titled tap-gui-catalogs-latest. Inside that folder is a compressed archive titled Tanzu Application Platform GUI Blank Catalog. You must extract that catalog to the preceding Git repository of choice. This serves as the configuration location for your Organization’s Catalog inside Tanzu Application Platform GUI.

Example: https://github.com/pvtl-pre/tap-catalogs

## Required CLIs, Plugins and Accounts

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Carvel](https://carvel.dev/)
- [helm](https://helm.sh/docs/intro/install/) (to install use `brew` for Mac and `apt-get` for Linux)
- [jq v1.6+](https://github.com/stedolan/jq) (to install use `brew` for Mac and `apt-get` for Linux)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [pivnet](https://github.com/pivotal-cf/pivnet-cli)
- [yq v4.12+](https://github.com/mikefarah/yq) (to install use `brew` for Mac and `apt-get` for Linux)

Additionally, you will need a [Tanzu Network account](https://network.tanzu.vmware.com/). For this account, you will need to accept any Tanzu Application Platform EULAs and create a UAA API TOKEN (i.e. refresh token).

NOTE: The Tanzu CLI and associated plugins will be installed as part of the deployment process.

## Setup Environment Variable for params.yaml

Set the PARAMS_YAML environment variable to the path of your `params.yaml` file. If you followed the recommendation, the value would be `local-config/params.yaml`, however you may choose otherwise. A sample `REDACTED-params.yaml` file is included in this directory, named REDACTED-params.yaml. It is recommended you copy this file and rename it to params.yaml and place it in the `local-config/` directory, and then start making your adjustments. `local-config/` is included in the `.gitignore` so your version won't be included in an any future commits you have to the repo.

```bash
# Update the the path from the default if you have a different params.yaml file name or location.
export PARAMS_YAML=local-config/params.yaml
```

Ensure that your copy of `params.yaml` indicates your Jumpbox OS: OSX or Linux

## Configure the Azure CLI

Ensure the `az` CLI is installed and configured. The deploy all script will use `az` to deploy an Azure Container Registry and Azure Kubernetes Service cluster.

## Configure the Pivnet CLI

Log into VMware Tanzu Network via the pivnet CLI.

```bash
pivnet login --api-token='MY-API-TOKEN'
```

## (Optional) Register Catalog Entities

Static configuration of catalog entities can be done by configuring your copy of `params.yaml` to include locations. Example, yet functional, locations are shown below and are preconfigured.

```yaml
tap_gui:
  catalog:
    locations:
      - type: url
        target: https://github.com/pvtl-pre/tap-catalogs/blob/main/yelb-catalog/catalog-info.yaml
      - type: url
        target: https://github.com/pvtl-pre/tanzu-java-web-app/blob/main/catalog/catalog-info.yaml
      - type: url
        target: https://github.com/pvtl-pre/python-function/blob/main/catalog/catalog-info.yaml
```

## (Optional) GitHub Authentication

In order to use GitHub to authenticate, a GitHub [OAuth App](https://docs.github.com/en/developers/apps/building-oauth-apps/creating-an-oauth-app) will need to be created. The `Homepage URL` would be your TAP GUI FQDN (e.g. https://tap-gui.subdomain.example.com). The `Authorization callback URL` would be https://tap-gui.subdomain.example.com/api/auth/github/handler/frame. Once created, a Client ID and Client Secret will need to be generated.

Configure your copy of `params.yaml` to include the additional `environment` and `providers` sections.

```yaml
tap_gui:
  auth:
    allowGuestAccess: true
    environment: development
    providers:
      github:
        development:
          clientId: CLIENT-ID
          clientSecret: CLIENT-SECRET
```

## Execute the Deploy All Script

Now you can execute the following script to perform all of those tasks:

```bash
./scripts/deploy-all.sh
```

The output of the `deploy-all.sh` script will either prompt for manual DNS record creation for the view, iterate and each run cluster or auto configure it for you.

### Manual DNS Record Creation

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

### Automatic DNS Record Creation

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

```bash
./scripts/delete-all.sh
```