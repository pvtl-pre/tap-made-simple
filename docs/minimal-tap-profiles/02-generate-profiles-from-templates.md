# Generate Profiles From Templates

## Run the Script

```shell
./scripts/generate-profiles-from-templates.sh
```

## What Did the Script Do?

This script generates individual TAP profiles for the 4 types of clusters roles: iterate, build, run and view. They are built from profile templates located in `profole-templates` directory with values coming from `./generated/params.yaml`. Once combined, the resulting profiles are stored in `./generated/profiles` as `[cluster-name]-cluster.yaml`. These generated profiles will eventually be deployed to their corresponding clusters. Additional layers of functionality will be added to the generated profiles as more steps are taken. Consequently, the profile templates are purposefully minimalistic and while deployable, TAP would not be considered useable at this stage.

### Iterate Profile

The only required fields for a minimal [Iterate Profile](../../profile-templates/iterate.yaml) are having an ingress domain and a container registry.

### Build Profile

The only required fields for a minimal [Build Profile](../../profile-templates/build.yaml) are having a container registry.

### Run Profile

The only required fields for a minimal [Run Profile](../../profile-templates/run.yaml) are having an ingress domain.

### View Profile

The only required fields for a minimal [View Profile](../../profile-templates/view.yaml) are having an ingress domain and service_type for TAP GUI.

## Values Used From params.yaml

```yaml
  view_cluster:
    name: view-cluster #! name of the cluster to create
    ingress_domain: #! set to the ingress domain for View Cluster components (e.g. tap.example.com)
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

## Go to Next Step

[Apply View Profile](./03-apply-view-profile.md)
