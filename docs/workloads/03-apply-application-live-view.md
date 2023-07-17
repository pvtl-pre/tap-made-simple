# Apply Application Live View

## Run the Script

```shell
./scripts/apply-application-live-view.sh
```

## What Did the Script Do?

This script applies the application live view feature to the Iterate, Build, Run and View Clusters. There are multiple ytt overlays depending on which cluster it is being applied to.

| Cluster  	| Conventions Overlay | Connector Overlay | Backend Overlay |
|---    	|---        	      |---	              |---	            |
| Iterate  	| X  	              | X  	              |   	            |
| Build  	| X  	              |   	              |   	            |
| Run  	    |   	              | X  	              |   	            |
| View  	|   	              |   	              | X  	            |

### Conventions Overlay

The ytt overlay [application-live-view-conventions.yaml](../../profile-overlays/application-live-view-conventions.yaml) is simplistic and uses no values.

### Connector Overlay

The ytt overlay [application-live-view-connector.yaml](../../profile-overlays/application-live-view-connector.yaml) is configured to connect to the application live view backend. It prepends a subdomain of `appliveview` to the `clusters.view_cluster.ingress_domain` value.

### Backend Overlay

The ytt overlay [application-live-view-backend.yaml](../../profile-overlays/application-live-view-backend.yaml) is simplistic and uses no values.

```shell
# NOTE: replace [iterate-cluster-name]
tanzu package installed get appliveview-connector -n tap-install --kubeconfig ./generated/kubeconfigs/[iterate-cluster-name].yaml
tanzu package installed get appliveview-conventions -n tap-install --kubeconfig ./generated/kubeconfigs/[iterate-cluster-name].yaml

# NOTE: replace [build-cluster-name]
tanzu package installed get appliveview-conventions -n tap-install --kubeconfig ./generated/kubeconfigs/[build-cluster-name].yaml

# NOTE: replace [run-cluster-name]
tanzu package installed get appliveview-connector -n tap-install --kubeconfig ./generated/kubeconfigs/[run-cluster-name].yaml

# NOTE: replace [view-cluster-name]
tanzu package installed get appliveview -n tap-install --kubeconfig ./generated/kubeconfigs/[view-cluster-name].yaml
```

## Values Used From params.yaml

```yaml
clusters:
  view_cluster:
    name: view-cluster #! name of the cluster to create
  iterate_cluster:
    name: iterate-cluster #! name of the cluster to create
  build_cluster:
    name: build-cluster #! name of the cluster to create
  run_clusters:
    - name: dev-cluster #! name of the cluster to create
    - name: prod-cluster #! name of the cluster to create
```

## Go to Next Step

[Apply Java Workload](./04-apply-java-workload.md)
