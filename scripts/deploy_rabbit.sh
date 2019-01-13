#!/usr/bin/env bash
exec > >(tee -i -a ~/deploy_rabbit.log)
exec 2>&1

source ~/.env.sh
export OM_TARGET=${PCF_OPSMAN_FQDN}
export OM_USERNAME=${PCF_OPSMAN_USERNAME}
export OM_PASSWORD="${PCF_PIVNET_UAA_TOKEN}"
START_RABBIT_DEPLOY_TIME=$(date)
$(cat <<-EOF >> ${HOME_DIR}/.env.sh
START_RABBIT_DEPLOY_TIME="${START_RABBIT_DEPLOY_TIME}"
EOF
)

source  ~/rabbit.env

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

DOWNLOAD_DIR_FULL=${DOWNLOAD_DIR}/${PRODUCT_SLUG}/${PCF_RABBIT_VERSION}
mkdir  -p ${DOWNLOAD_DIR_FULL}

curl \
  --fail \
  --header "Authorization: Bearer ${PIVNET_ACCESS_TOKEN}" \
  --request POST \
  ${EULA_ACCEPTANCE_URL}


# download product using om cli
echo $(date) start downloading RABBIT
om --skip-ssl-validation \
  download-product \
 --pivnet-api-token ${PCF_PIVNET_UAA_TOKEN} \
 --pivnet-file-glob "*.pivotal" \
 --pivnet-product-slug ${PRODUCT_SLUG} \
 --product-version ${PCF_RABBIT_VERSION} \
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

echo "creating storage account ${ENV_SHORT_NAME}rabbitbackup"

az login --service-principal \
  --username ${AZURE_CLIENT_ID} \
  --password ${AZURE_CLIENT_SECRET} \
  --tenant ${AZURE_TENANT_ID}

az storage account create --name ${ENV_SHORT_NAME}rabbitbackup \
--resource-group ${ENV_NAME} \
--sku Standard_LRS \
--location $LOCATION

RABBIT_STORAGE_KEY=$(az storage account keys list \
--account-name ${ENV_SHORT_NAME}rabbitbackup \
--resource-group ${ENV_NAME} \
--query "[0].{value:value}" \
--output tsv
)

az storage container create --name backup \
--account-name ${ENV_SHORT_NAME}rabbitbackup \
--account-key ${RABBIT_STORAGE_KEY}

cat << EOF > ~/rabbit_vars.yaml
product_name: ${PRODUCT_SLUG}
pcf_pas_network: pcf-pas-subnet
pcf_service_network: pcf-services-subnet
azure_storage_access_key: ${RABBIT_STORAGE_KEY}
azure_account: ${ENV_SHORT_NAME}rabbitbackup
global_recipient_email: ${PCF_NOTIFICATIONS_EMAIL}
blob_store_base_url: blob.core.windows.net
EOF

om --skip-ssl-validation \
  configure-product \
  -c rabbit.yaml -l rabbit_vars.yaml

om --skip-ssl-validation \
upload-stemcell \
--stemcell ${STEMCELL_FILENAME}
echo $(date) start apply ${PRODUCT_SLUG}
om --skip-ssl-validation \
apply-changes \
--product-name ${PRODUCT_SLUG}
echo $(date) end apply ${PRODUCT_SLUG}  