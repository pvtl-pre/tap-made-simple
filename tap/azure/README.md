# Tanzu Application Platform on Azure

This repo has scripts to deploy Tanzu Application Platform 1.1 to Azure.

## Goals and Audience

This repo is for Tanzu field team members to see how various components of Tanzu Application Platform come together to build a modern application platform. We will highlight the developer experience improvements with an eye towards operator control of the software supply chain. This could be delivered as a presentation and demo or it could be extended to include having the audience actually deploy the full solution on their own Azure subscription.

## Setup Tanzu Application Platform GUI catalog

Tanzu Application Platform GUI Blank Catalog from the Tanzu Application section of [Tanzu Network](https://network.tanzu.vmware.com/products/tanzu-application-platform/).
To install, navigate to Tanzu Network. Under the list of available files to download, there is a folder titled tap-gui-catalogs-latest. Inside that folder is a compressed archive titled Tanzu Application Platform GUI Blank Catalog. You must extract that catalog to the preceding Git repository of choice. This serves as the configuration location for your Organization’s Catalog inside Tanzu Application Platform GUI.

Example: https://github.com/pvtl-pre/tap-gui-catalogs

## Required CLIs

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [jq v1.6+](https://github.com/stedolan/jq) (to install use `brew` for Mac and `apt-get` for Linux)
- [pivnet](https://github.com/pivotal-cf/pivnet-cli)
- [yq v4.12+](https://github.com/mikefarah/yq) (to install use `brew` for Mac and `apt-get` for Linux)

NOTE: The Tanzu CLI (v0.10.0) and associated plugins will be installed as part of the deployment process.

## Setup Environment Variable for params.yaml

Set the PARAMS_YAML environment variable to the path of your `params.yaml` file. If you followed the recommendation, the value would be `local-config/params.yaml`, however you may choose otherwise. A sample `REDACTED-params.yaml` file is included in this directory, named REDACTED-params.yaml. It is recommended you copy this file and rename it to params.yaml and place it in the `local-config/` directory, and then start making your adjustments.  `local-config/` is included in the `.gitignore` so your version won't be included in an any future commits you have to the repo.

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
pivnet login --api-token='my-api-token'
```

## Execute the Deploy All Script

Now you can execute the following script to perform all of those tasks:

```bash
./scripts/deploy-all.sh
```

## DNS Records

There are some optional but recommended DNS records you should allocate if you decide to use these particular components:

- Cloud Native Runtimes (knative) - Allocate a wildcard subdomain for your developer’s applications. This is specified in the cnrs.domain_name key of the tap-values.yml configuration file that you input with the installation. This wildcard should be pointed at the external IP address of the tanzu-system-ingress’s envoy service. See Ingress Method for more information about tanzu-system-ingress.
- Tanzu Learning Center - Similar to Cloud Native Runtimes, allocate a wildcard subdomain for your workshops and content. This is specified in the learningcenter.ingressDomain key of the tap-values.yml configuration file that you input with the installation. This wildcard should be pointed at the external IP address of the tanzu-system-ingress’s envoy service.
- Tanzu Application Platform GUI - Should you decide to implement the shared ingress and include the Tanzu Application Platform GUI, allocate a fully Qualified Domain Name (FQDN) that can be pointed at the tanzu-system-ingress service. The default hostname consists of tap-gui plus an IngressDomain of your choice. For example, tap-gui.example.com.

### A Record Examples

In the namespace, tanzu-system-ingress, point A records to the service named envoy which will be of type LoadBalancer.

- *.cnrs.DOMAIN
- *.learningcenter.DOMAIN
- tap-gui.DOMAIN

## Tear Down

Execute the following script to tear down your environment.

```bash
./scripts/delete-all.sh
```