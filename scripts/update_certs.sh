#!/usr/bin/env bash
source ~/.env.sh
MYSELF=$(basename $0)
echo "this is the certs updater"
om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
update-ssl-certificate \
    --certificate-pem "$(cat ${HOME_DIR}/fullchain.cer)" \
    --private-key-pem "$(cat ${HOME_DIR}/${PCF_SUBDOMAIN_NAME}.${PCF_DOMAIN_NAME}.key)"

cat << EOF > ${TEMPLATE_DIR}/director_certs_vars.yml
fullchain: "$(cat ${HOME_DIR}/fullchain.cer | awk '{printf "%s\\r\\n", $0}')"
EOF

om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
   configure-director \
   --config ${TEMPLATE_DIR}/director_certs.yml \
   --vars-file ${TEMPLATE_DIR}/director_certs_vars.yml



PCF_KEY_PEM=$(cat ${HOME_DIR}/${PCF_SUBDOMAIN_NAME}.${PCF_DOMAIN_NAME}.key | awk '{printf "%s\\r\\n", $0}')
PCF_CERT_PEM=$(cat ${HOME_DIR}/fullchain.cer | awk '{printf "%s\\r\\n", $0}')


cat << EOF > ${TEMPLATE_DIR}/pas_certs_vars.yml
pcf_cert_pem: "${PCF_CERT_PEM}"
pcf_key_pem: "${PCF_KEY_PEM}"
EOF

om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
  configure-product \
  -c ${TEMPLATE_DIR}/pas_certs.yml \
  -l ${TEMPLATE_DIR}/pas_certs_vars.yml

om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
  apply-changes  