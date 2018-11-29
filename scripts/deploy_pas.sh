#!/usr/bin/env bash

source ~/.env
PRODUCT_SLUG="elastic-runtime"
RELEASE_ID="latest"

PCF_KEY_PEM=$(cat ${PCF_SUBDOMAIN_NAME}.${PCF_DOMAIN_NAME}.key | awk '{printf "%s\\r\\n", $0}')
PCF_CERT_PEM=$(cat ${PCF_SUBDOMAIN_NAME}.${PCF_DOMAIN_NAME}.cert | awk '{printf "%s\\r\\n", $0}')
PCF_CREDHUB_KEY="01234567890123456789"
PCF_OPSMAN_USER=opsman
PRODUCT_NAME=cf


#Authenticate pivnet 

PIVNET_ACCESS_TOKEN=$(curl \
  --fail \
  --header "Content-Type: application/json" \
  --data "{\"refresh_token\": \"${PCF_PIVNET_UAA_TOKEN}\"}" \
  https://network.pivotal.io/api/v2/authentication/access_tokens |\
    jq -r '.access_token')

# release by slug
RELEASE_JSON=$(curl \
  --fail \
  "https://network.pivotal.io/api/v2/products/${PRODUCT_SLUG}/releases/${RELEASE_ID}")
# eula acceptance link
EULA_ACCEPTANCE_URL=$(echo ${RELEASE_JSON} |\
  jq -r '._links.eula_acceptance.href')


# eula acceptance
curl \
  --fail \
  --header "Authorization: Bearer ${PIVNET_ACCESS_TOKEN}" \
  --request POST \
  ${EULA_ACCEPTANCE_URL}
#  Extract the product file details for the tile we want to download. This can typically be identified by an object key ending with .pivotal. From here we can identify a URL for the download and a suitable target filename.



DOWNLOAD_ELEMENT=$(echo ${RELEASE_JSON} |\
  jq -r '.product_files[] | select(.aws_object_key | contains("elastic-runtime/cf-2.3"))')




TARGET_FILENAME=$(echo ${DOWNLOAD_ELEMENT} |\
  jq -r '.aws_object_key | split("/") | last')

URL=$(echo ${DOWNLOAD_ELEMENT} |\
  jq -r '._links.download.href')


curl \
  --fail \
  --location \
  --output ${TARGET_FILENAME} \
  --header "Authorization: Bearer ${PIVNET_ACCESS_TOKEN}" \
  ${URL}  



# Import the tile to Ops Manager.

om \
  --username ${PCF_OPSMAN_USER} \
  --password ${PCF_OPSMAN_ADMIN_PASSWD} \
  --target ${PCF_OPSMAN_FQDN} \
  --skip-ssl-validation \
  upload-product \
    --product ${TARGET_FILENAME}

    # 1. Find the version of the product that was imported.
PRODUCTS=$(om \
  --username ${PCF_OPSMAN_USER} \
  --password ${PCF_OPSMAN_ADMIN_PASSWD} \
  --target ${PCF_OPSMAN_FQDN} \
  --skip-ssl-validation \
  available-products \
    --format json)

VERSION=$(echo ${PRODUCTS} |\
  jq --arg product_name ${PRODUCT_NAME} -r 'map(select(.name==$product_name)) | first | .version')

# 2.  Stage using om cli

om \
  --username ${PCF_OPSMAN_USER} \
  --password ${PCF_OPSMAN_ADMIN_PASSWD} \
  --target ${PCF_OPSMAN_FQDN} \
  --skip-ssl-validation \
  stage-product \
    --product-name ${PRODUCT_NAME} \
    --product-version ${VERSION}

cat << EOF > vars.yaml
pcf_pas_network: ${PCF_PAS_NETWORK} 
pcf_system_domain: ${PCF_SYSTEM_DOMAIN}
pcf_apps_domain: ${PCF_APPS_DOMAIN}
pcf_notifications_email: ${PCF_NOTIFICATIONS_EMAIL}
pcf_cert_pem: "${PCF_CERT_PEM}"
pcf_key_pem: "${PCF_KEY_PEM}"
pcf_credhub_key: "${PCF_CREDHUB_KEY}"
EOF

om \
  --username ${PCF_OPSMAN_USER} \
  --password ${PCF_OPSMAN_ADMIN_PASSWD} \
  --target ${PCF_OPSMAN_FQDN} \
  --skip-ssl-validation \
  configure-product \
    -c pas.yaml -l vars.yaml \
    --product-name ${PRODUCT_NAME}
###
om \
  --username ${PCF_OPSMAN_USER} \
  --password ${PCF_OPSMAN_ADMIN_PASSWD} \
  --target ${PCF_OPSMAN_FQDN} \
  --skip-ssl-validation \
  apply-changes \
    --product-name ${PRODUCT_NAME}
















  

