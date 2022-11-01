#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

export KUBECONFIG=$(yq e .azure.kubeconfig $PARAMS_YAML)
INSTALL_REGISTRY_HOSTNAME=$(yq e .tap_install.registry.hostname $PARAMS_YAML)
INSTALL_REGISTRY_USERNAME=$(yq e .tap_install.registry.username $PARAMS_YAML)
INSTALL_REGISTRY_PASSWORD=$(yq e .tap_install.registry.password $PARAMS_YAML)
INSTALL_DEV_NAMESPACE=$(yq e .tap_install.dev_namespace $PARAMS_YAML)

echo "## Add read/write registry credentials to the developer namespace"

tanzu secret registry add registry-credentials --server $INSTALL_REGISTRY_HOSTNAME --username $INSTALL_REGISTRY_USERNAME --password $INSTALL_REGISTRY_PASSWORD --namespace $INSTALL_DEV_NAMESPACE

echo "## Authorize the service account to the developer namespace ($INSTALL_DEV_NAMESPACE)"

cat <<EOF | kubectl -n $INSTALL_DEV_NAMESPACE apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: tap-registry
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
  - name: tap-registry
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
    name: system:authenticated
    apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $INSTALL_DEV_NAMESPACE-permit-app-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: app-viewer-cluster-access
subjects:
  - kind: Group
    name: system:authenticated
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
    name: system:authenticated
    apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $INSTALL_DEV_NAMESPACE-permit-app-editor
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: app-editor-cluster-access
subjects:
  - kind: Group
    name: system:authenticated
    apiGroup: rbac.authorization.k8s.io
EOF
