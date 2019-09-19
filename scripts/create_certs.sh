#!/usr/bin/env bash
source ~/.env.sh
cd ${HOME_DIR}
MYSELF=$(basename $0)
mkdir -p ${LOG_DIR}
exec &> >(tee -a "${LOG_DIR}/${MYSELF}.$(date '+%Y-%m-%d-%H').log")
exec 2>&1

git clone https://github.com/Neilpang/acme.sh.git ./acme.sh

METADATA=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2017-08-01")
export AZUREDNS_SUBSCRIPTIONID=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2017-08-01" | jq -r .subscriptionId)
export AZUREDNS_TENANTID=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/AZURETENANTID?api-version=2016-10-01 -s -H "Authorization: Bearer ${TOKEN}" | jq -r .value)
export AZUREDNS_APPID=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/AZURECLIENTID?api-version=2016-10-01 -s -H "Authorization: Bearer ${TOKEN}" | jq -r .value)
export AZUREDNS_CLIENTSECRET=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/AZURECLIENTSECRET?api-version=2016-10-01 -s -H "Authorization: Bearer ${TOKEN}" | jq -r .value)


DOMAIN="${PCF_SUBDOMAIN_NAME}.${PCF_DOMAIN_NAME}"
./acme.sh/acme.sh --issue \
 --dns dns_azure \
 --dnssleep 10 \
 --force \
 --debug \
 -d ${DOMAIN} \
 -d pcf.${DOMAIN} \
 -d harbor.${DOMAIN} \
 -d *.sys.${DOMAIN} \
 -d *.apps.${DOMAIN} \
 -d *.mesh.apps.${DOMAIN} \
 -d *.login.sys.${DOMAIN} \
 -d *.uaa.sys.${DOMAIN} \
 -d *.pks.${DOMAIN}

cp ${HOME_DIR}/.acme.sh/${DOMAIN}/${DOMAIN}.key ${HOME_DIR}
cp ${HOME_DIR}/.acme.sh/${DOMAIN}/fullchain.cer ${HOME_DIR}
cp ${HOME_DIR}/.acme.sh/${DOMAIN}/ca.cer ${HOME_DIR}/${DOMAIN}.ca.crt