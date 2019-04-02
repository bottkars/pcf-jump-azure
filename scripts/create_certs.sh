#!/usr/bin/env bash
source ~/.env.sh
cd ${HOME_DIR}
MYSELF=$(basename $0)
mkdir -p ${LOG_DIR}
exec &> >(tee -a "${LOG_DIR}/${MYSELF}.$(date '+%Y-%m-%d-%H').log")
exec 2>&1

git clone https://github.com/Neilpang/acme.sh.git ./acme.sh

export AZUREDNS_SUBSCRIPTIONID=${AZURE_SUBSCRIPTION_ID}
export AZUREDNS_TENANTID=${AZURE_TENANT_ID}
export AZUREDNS_APPID=${AZURE_CLIENT_ID}
export AZUREDNS_CLIENTSECRET=${AZURE_CLIENT_SECRET}
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