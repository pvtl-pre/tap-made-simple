# Tanzu Application Platform Made Simple

This repo has scripts to deploy Tanzu Application Platform (TAP) 1.4 to Azure.

## Goals and Audience

This repo is for Tanzu field team members to see how various components of TAP come together to build a modern application platform. The developer experience improvements will be highlighted with an eye towards operator control of the software supply chain. This could be delivered as a presentation and demo or it could be extended to include having the audience actually deploy the full solution on their own Azure subscription.

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
- [git](https://git-scm.com/download/)
- [helm](https://helm.sh/docs/intro/install/) (to install use `brew` for Mac and `apt-get` for Linux)
- [jq v1.6+](https://github.com/stedolan/jq) (to install use `brew` for Mac and `apt-get` for Linux)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [pivnet](https://github.com/pivotal-cf/pivnet-cli)
- [yq v4.12+](https://github.com/mikefarah/yq) (to install use `brew` for Mac and `apt-get` for Linux)

A [Tanzu Network account](https://network.tanzu.vmware.com/) is required. Any TAP EULAs will need to be accepted and a UAA API TOKEN (i.e. refresh token) will need to be created.

An git repo with permissions to push is required for the gitops. All commits to the repo will be reset to it's initial state during the delete process. As such, there must be an inital commit to revert to.

NOTE: The Tanzu CLI and associated plugins will be installed as part of the deployment process.

## Configure the Azure CLI

Ensure the `az` CLI is installed and configured. The deploy all script will use `az` to deploy an Azure Container Registry and Azure Kubernetes Service clusters.

## Configure the Pivnet CLI

Log into VMware Tanzu Network via the pivnet CLI.

```shell
pivnet login --api-token='MY-API-TOKEN'
```

## Deployment Options

There are two options for deployment. [Deploy everything all at once](./docs/one-step.md) to get an environment up and running as quickly as possible or a [step by step guide](./docs/step-by-step.md) can be run through in order to learn how the component parts of TAP are constructed.
