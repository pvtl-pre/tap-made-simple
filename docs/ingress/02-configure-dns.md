# Configure DNS

## Run the Script

```shell
./scripts/configure-dns.sh
```

## What Did the Script Do?

This script can either configure DNS via a DNS Host in Azure automatically, if one is setup and configured, or output the A Record information that will need to be created manually. Control over which path is taken is done by setting the value for `azure.dns.auto_configure`. If set to `true`, the values `azure.dns.dns_zone_name` and `azure.dns.resource_group` become required. Regardless of whether path is taken, wildcard A Records are required for each of the `ingress_domain` and `learning_center_ingress_domain` values for the Iterate, Run Clusters and View Clusters. Once completed, TAP GUI will be accessible via a browser. To get the fully qualified domain name (FQDN), run the command below. 

```shell
# NOTE: replace [view-cluster-name]
kubectl -n tap-gui get httprpoxy tap-gui --kubeconfig ./generated/kubeconfigs/[view-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
azure:
  dns:
    auto_configure: false
    dns_zone_name: #! set to the dns zone that will create A Records
    resource_group: #! set to the resource group that contains the dns zone
clusters:
  view_cluster:
    name: view-cluster #! name of the cluster to create
    ingress_domain: #! set to the ingress domain for View Cluster components (e.g. tap.example.com)
    learning_center_ingress_domain: #! set to the ingress domain for the Learning Center component (e.g. learningcenter.example.com)
  iterate_cluster:
    name: iterate-cluster #! name of the cluster to create
    ingress_domain: #! set to the ingress domain for iterate ingress objects (e.g. iterate.example.com)
  build_cluster:
    name: build-cluster #! name of the cluster to create
  run_clusters:
    - name: dev-cluster #! name of the cluster to create
      ingress_domain: #! set to the ingress domain for dev ingress objects (e.g. dev.example.com)
    - name: prod-cluster #! name of the cluster to create
      ingress_domain: #! set to the ingress domain for prod ingress objects (e.g. prod.example.com)
```

## Congrats

The Ingress steps are now complete.

## Go to Next Step

[Apply TAP GUI Auth](../tap-gui-configuration/01-apply-tap-gui-auth.md)
