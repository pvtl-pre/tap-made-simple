#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

export KUBECONFIG=$(yq e .azure.kubeconfig $PARAMS_YAML)
INSTALL_REGISTRY_HOSTNAME=$(yq e .azure.acr_name $PARAMS_YAML)
INSTALL_REGISTRY_USERNAME=$(yq e .azure.acr_username $PARAMS_YAML)
INSTALL_REGISTRY_PASSWORD=$(yq e .azure.acr_password $PARAMS_YAML)
INSTALL_DEV_NAMESPACE=$(yq e .tap_install.dev_namespace $PARAMS_YAML)
TAP_REGISTRY_SECRET_NAME=$(yq e .tap_install.registry_secret $PARAMS_YAML)
SCAN_POLICY=$(yq e .tap_values.scanning.source.policy $PARAMS_YAML)

echo "## Add read/write registry credentials to the developer namespace"

tanzu secret registry add registry-credentials --server $INSTALL_REGISTRY_HOSTNAME --username $INSTALL_REGISTRY_USERNAME --password $INSTALL_REGISTRY_PASSWORD --namespace $INSTALL_DEV_NAMESPACE

echo "## Authorize the service account to the developer namespace ($INSTALL_DEV_NAMESPACE)"

cat <<EOF | kubectl -n $INSTALL_DEV_NAMESPACE apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $TAP_REGISTRY_SECRET_NAME
  annotations:
    secretgen.carvel.dev/image-pull-secret: ""
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: e30K
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
secrets:
  - name: registry-credentials
imagePullSecrets:
  - name: registry-credentials
  - name: $TAP_REGISTRY_SECRET_NAME
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default-permit-deliverable
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: deliverable
subjects:
  - kind: ServiceAccount
    name: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: default-permit-workload
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: workload
subjects:
  - kind: ServiceAccount
    name: default
EOF

echo "## Authorize the all users (system:authenticated) to the developer namespace ($INSTALL_DEV_NAMESPACE)"

cat <<EOF | kubectl -n $INSTALL_DEV_NAMESPACE apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-permit-app-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: app-viewer
subjects:
  - kind: Group
    name: GROUP-FOR-APP-VIEWER
    apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: YOUR-NAMESPACE-permit-app-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: app-viewer-cluster-access
subjects:
  - kind: Group
    name: GROUP-FOR-APP-VIEWER
    apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-permit-app-editor
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: app-editor
subjects:
  - kind: Group
    name: GROUP-FOR-APP-EDITOR
    apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: YOUR-NAMESPACE-permit-app-editor
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: app-editor-cluster-access
subjects:
  - kind: Group
    name: GROUP-FOR-APP-EDITOR
    apiGroup: rbac.authorization.k8s.io
EOF

echo "## Create a scan policy to the developer namespace ($INSTALL_DEV_NAMESPACE)"

cat <<EOF | kubectl -n $INSTALL_DEV_NAMESPACE apply -f -
apiVersion: scanning.apps.tanzu.vmware.com/v1beta1
kind: ScanPolicy
metadata:
  name: $SCAN_POLICY
  labels:
    'app.kubernetes.io/part-of': 'enable-in-gui'
spec:
  regoFile: |
    package main

    # Accepted Values: "Critical", "High", "Medium", "Low", "Negligible", "UnknownSeverity"
    notAllowedSeverities := ["Critical", "High", "UnknownSeverity"]
    ignoreCves := []

    contains(array, elem) = true {
      array[_] = elem
    } else = false { true }

    isSafe(match) {
      severities := { e | e := match.ratings.rating.severity } | { e | e := match.ratings.rating[_].severity }
      some i
      fails := contains(notAllowedSeverities, severities[i])
      not fails
    }

    isSafe(match) {
      ignore := contains(ignoreCves, match.id)
      ignore
    }

    deny[msg] {
      comps := { e | e := input.bom.components.component } | { e | e := input.bom.components.component[_] }
      some i
      comp := comps[i]
      vulns := { e | e := comp.vulnerabilities.vulnerability } | { e | e := comp.vulnerabilities.vulnerability[_] }
      some j
      vuln := vulns[j]
      ratings := { e | e := vuln.ratings.rating.severity } | { e | e := vuln.ratings.rating[_].severity }
      not isSafe(vuln)
      msg = sprintf("CVE %s %s %s", [comp.name, vuln.id, ratings])
    }
EOF

echo "## Create an ootb_supply_chain_testing_scanning pipeline ($INSTALL_DEV_NAMESPACE)"

cat <<EOF | kubectl -n $INSTALL_DEV_NAMESPACE apply -f -
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: developer-defined-tekton-pipeline
  labels:
    apps.tanzu.vmware.com/pipeline: test      # (!) required
spec:
  params:
    - name: source-url                        # (!) required
    - name: source-revision                   # (!) required
  tasks:
    - name: test
      params:
        - name: source-url
          value: \$(params.source-url)
        - name: source-revision
          value: \$(params.source-revision)
      taskSpec:
        params:
          - name: source-url
          - name: source-revision
        steps:
          - name: test
            image: gradle
            script: |-
              cd \`mktemp -d\`
              wget -qO- \$(params.source-url) | tar xvz -m
              ./mvnw test
EOF
