#!/usr/bin/env bash
exec > >(tee -i -a ~/deploy_spring.log)
exec 2>&1

source ~/.env.sh
export OM_TARGET=${PCF_OPSMAN_FQDN}
export OM_USERNAME=${PCF_OPSMAN_USERNAME}
export OM_PASSWORD="${PCF_PIVNET_UAA_TOKEN}"
START_SPRING_DEPLOY_TIME=$(date)
$(cat <<-EOF >> ${HOME_DIR}/.env.sh
START_SPRING_DEPLOY_TIME="${START_SPRING_DEPLOY_TIME}"
EOF
)

source  ~/spring.env

PIVNET_ACCESS_TOKEN=$(curl \
  --fail \
  --header "Content-Type: application/json" \
  --data "{\"refresh_token\": \"${PCF_PIVNET_UAA_TOKEN}\"}" \
  https://network.pivotal.io/api/v2/authentication/access_tokens |\
    jq -r '.access_token')

RELEASE_JSON=$(curl \
  --header "Authorization: Bearer ${PIVNET_ACCESS_TOKEN}" \
  --fail \
  "https://network.pivotal.io/api/v2/products/${PRODUCT_SLUG}/releases/${RELEASE_ID}")
# eula acceptance link
EULA_ACCEPTANCE_URL=$(echo ${RELEASE_JSON} |\
  jq -r '._links.eula_acceptance.href')

DOWNLOAD_DIR_FULL=${DOWNLOAD_DIR}/${PRODUCT_SLUG}/${PCF_SPRING_VERSION}
mkdir  -p ${DOWNLOAD_DIR_FULL}

curl \
  --fail \
  --header "Authorization: Bearer ${PIVNET_ACCESS_TOKEN}" \
  --request POST \
  ${EULA_ACCEPTANCE_URL}


# download product using om cli
echo $(date) start downloading SPRING
om --skip-ssl-validation \
  download-product \
 --pivnet-api-token ${PCF_PIVNET_UAA_TOKEN} \
 --pivnet-file-glob "*.pivotal" \
 --pivnet-product-slug ${PRODUCT_SLUG} \
 --product-version ${PCF_SPRING_VERSION} \
 --stemcell-iaas azure \
 --download-stemcell \
 --output-directory ${DOWNLOAD_DIR_FULL}

echo $(date) end downloading ${PRODUCT_SLUG}

TARGET_FILENAME=$(cat ${DOWNLOAD_DIR_FULL}/download-file.json | jq -r '.product_path')
STEMCELL_FILENAME=$(cat ${DOWNLOAD_DIR_FULL}/download-file.json | jq -r '.stemcell_path')

# Import the tile to Ops Manager.
echo $(date) start uploading ${PRODUCT_SLUG}
om --skip-ssl-validation \
  --request-timeout 3600 \
  upload-product \
  --product ${TARGET_FILENAME}

echo $(date) end uploading ${PRODUCT_SLUG}

    # 1. Find the version of the product that was imported.
PRODUCTS=$(om --skip-ssl-validation \
  available-products \
    --format json)

VERSION=$(echo ${PRODUCTS} |\
  jq --arg product_name ${PRODUCT_SLUG} -r 'map(select(.name==$product_name)) | first | .version')


# 2.  Stage using om cli
echo $(date) start staging ${PRODUCT_SLUG} 
om --skip-ssl-validation \
  stage-product \
  --product-name ${PRODUCT_SLUG} \
  --product-version ${VERSION}
echo $(date) end staging ${PRODUCT_SLUG} 

cat << EOF > ${HOME_DIR}/spring_vars.yaml
product_name: ${PRODUCT_SLUG}
pcf_pas_network: pcf-pas-subnet
EOF

om --skip-ssl-validation \
  configure-product \
  -c ${HOME_DIR}/spring.yaml -l ${HOME_DIR}/spring_vars.yaml

om --skip-ssl-validation \
upload-stemcell \
--stemcell ${STEMCELL_FILENAME}
echo $(date) start apply ${PRODUCT_SLUG}
om --skip-ssl-validation \
apply-changes \
--product-name ${PRODUCT_SLUG}
echo $(date) end apply ${PRODUCT_SLUG}  