#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

GENERATE_CERT=$(yq e .tls.generate $PARAMS_YAML)
VIEW_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.view_cluster.ingress_domain $PARAMS_YAML)
CERT_PATH="generated/cert"

mkdir -p $CERT_PATH

if [[ "$GENERATE_CERT" == true ]]; then
  if [[ -z $(yq e .tls.cert_data $PARAMS_YAML) ]] || [[ -z $(yq e .tls.key_data $PARAMS_YAML) ]]; then
    information "Generating self-signed wildcard cert"

    cat <<EOF > $CERT_PATH/req.cnf
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = US
ST = CA
O = VMware
localityName = Palo Alto
commonName = *.$VIEW_CLUSTER_INGRESS_DOMAIN
organizationalUnitName = Tanzu
emailAddress = employee@vmare.com
[v3_req]
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
EOF

    declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))

    for ((i=0;i<${#run_clusters[@]};i++)); 
    do
      RUN_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.run_clusters[$i].ingress_domain $PARAMS_YAML)

      echo "DNS.$((i+1)) = *.$RUN_CLUSTER_INGRESS_DOMAIN" >> $CERT_PATH/req.cnf
    done

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $CERT_PATH/wildcard.key -config $CERT_PATH/req.cnf -out $CERT_PATH/wildcard.cer -sha256
    
    export ENCODED_WILDCARD_CER=$(cat $CERT_PATH/wildcard.cer | base64)
    export ENCODED_WILDCARD_KEY=$(cat $CERT_PATH/wildcard.key | base64)

    yq e -i ".tls.cert_data = env(ENCODED_WILDCARD_CER)" $PARAMS_YAML
    yq e -i ".tls.key_data = env(ENCODED_WILDCARD_KEY)" $PARAMS_YAML
  else
    information "Skipping cert creation since cert_data and key_data have already been set"
  fi
else
  information "Skipped cert generation due to user providing cert"

  information "Getting cert details"

  echo $(yq e .tls.cert_data $PARAMS_YAML) | base64 --decode > $CERT_PATH/wildcard.cer
  echo $(yq e .tls.key_data $PARAMS_YAML) | base64 --decode > $CERT_PATH/wildcard.key
fi

information "Creating TLS secret yaml"

kubectl create secret tls wildcard -n tap-install --cert=$CERT_PATH/wildcard.cer --key=$CERT_PATH/wildcard.key --dry-run=client -o yaml > $CERT_PATH/tls-secret.yaml

information "Applying TLS secret on the View Cluster"

VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)

kubectl apply -f $CERT_PATH/tls-secret.yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG

declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))

for ((i=0;i<${#run_clusters[@]};i++)); 
do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  information "Applying TLS secret on Run Cluster '$RUN_CLUSTER_NAME'"

  kubectl apply -f $CERT_PATH/tls-secret.yaml --kubeconfig $RUN_CLUSTER_KUBECONFIG
done
