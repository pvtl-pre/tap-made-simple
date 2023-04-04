#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

CERT_PATH="generated/cert"
ITERATE_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.iterate_cluster.ingress_domain $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.view_cluster.ingress_domain $PARAMS_YAML)

mkdir -p $CERT_PATH

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

echo "DNS.1 = *.$ITERATE_CLUSTER_INGRESS_DOMAIN" >> $CERT_PATH/req.cnf

for ((i=0;i<$RUN_CLUSTER_COUNT;i++)); 
do
  RUN_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.run_clusters[$i].ingress_domain $PARAMS_YAML)

  echo "DNS.$((i+2)) = *.$RUN_CLUSTER_INGRESS_DOMAIN" >> $CERT_PATH/req.cnf
done

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $CERT_PATH/wildcard.key -config $CERT_PATH/req.cnf -out $CERT_PATH/wildcard.cer -sha256

export ENCODED_WILDCARD_CER=$(cat $CERT_PATH/wildcard.cer | base64)
export ENCODED_WILDCARD_KEY=$(cat $CERT_PATH/wildcard.key | base64)

yq e -i ".tls.cert_data = env(ENCODED_WILDCARD_CER)" $PARAMS_YAML
yq e -i ".tls.key_data = env(ENCODED_WILDCARD_KEY)" $PARAMS_YAML