# Tanzu Application Platform Made Simple

This repo has scripts to deploy Tanzu Application Platform (TAP) 1.4 to Azure.

## Goals and Audience

This repo is for Tanzu field team members to see how various components of TAP come together to build a modern application platform. We will highlight the developer experience improvements with an eye towards operator control of the software supply chain. This could be delivered as a presentation and demo or it could be extended to include having the audience actually deploy the full solution on their own Azure subscription.

## Deployed Azure Resources

All required Azure infrastructure required for TAP to function will deployed prior to installation. These Azure resources include the following:

- A single Resource Group
- Azure Container Registry
- Azure Kubernetes Clusters with [Cluster Essentials](https://docs.vmware.com/en/Cluster-Essentials-for-VMware-Tanzu/index.html) installed
  - View cluster
  - Iterate cluster
  - Build cluster
  - One or more Run clusters
- Public Load Balancers

## Required CLIs, Plugins and Accounts

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Carvel](https://carvel.dev/)
- [helm](https://helm.sh/docs/intro/install/) (to install use `brew` for Mac and `apt-get` for Linux)
- [jq v1.6+](https://github.com/stedolan/jq) (to install use `brew` for Mac and `apt-get` for Linux)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [pivnet](https://github.com/pivotal-cf/pivnet-cli)
- [yq v4.12+](https://github.com/mikefarah/yq) (to install use `brew` for Mac and `apt-get` for Linux)

Additionally, you will need a [Tanzu Network account](https://network.tanzu.vmware.com/). For this account, you will need to accept any TAP EULAs and create a UAA API TOKEN (i.e. refresh token).

NOTE: The Tanzu CLI and associated plugins will be installed as part of the deployment process.

## Configure the Azure CLI

Ensure the `az` CLI is installed and configured. The deploy all script will use `az` to deploy an Azure Container Registry and Azure Kubernetes Service clusters.

## Configure the Pivnet CLI

Log into VMware Tanzu Network via the pivnet CLI.

```bash
pivnet login --api-token='MY-API-TOKEN'
```

## Deployment Options

There are two options for deployment. You can [deploy everything all at once](./docs/one-step.md) to get an environment up and running as quickly as possible or you can run through a [step by step guide](./docs/step-by-step.md) in order to learn how the component parts of TAP are constructed.
