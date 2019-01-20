#!/usr/bin/env bash
source ~/.env.sh
cd ${HOME_DIR}
mkdir -p ${HOME_DIR}/logs
exec &> >(tee -a "${HOME_DIR}/logs/$0.$(date '+%Y-%m-%d-%H').log")
exec 2>&1
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -n|--NO_DOWNLOAD)
    NO_DOWNLOAD=TRUE
    echo "No download is ${NO_DOWNLOAD}"
    # shift # past value if  arg value
    ;;
    -d|--DO_NOT_APPLY_CHANGES)
    NO_APPLY=TRUE
    echo "No APPLY is ${NO_APPLY}"
    # shift # past value ia arg value
    ;;    
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
shift
done
set -- "${POSITIONAL[@]}" # restore positional parameters

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
if  [ -z ${NO_DOWNLOAD} ] ; then
echo $(date) start downloading ${PRODUCT_SLUG}
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
else 
echo ignoring download by user 
fi

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


cat << EOF > ${HOME_DIR}/rabbit_vars.yaml
product_name: ${PRODUCT_SLUG}
pcf_pas_network: pcf-pas-subnet
pcf_service_network: pcf-services-subnet
server_admin_password: ${PCF_PIVNET_UAA_TOKEN}
EOF

om --skip-ssl-validation \
  configure-product \
  -c ${HOME_DIR}/rabbit.yaml -l ${HOME_DIR}/rabbit_vars.yaml

om --skip-ssl-validation \
upload-stemcell \
--stemcell ${STEMCELL_FILENAME}

echo $(date) start apply ${PRODUCT_SLUG}

if  [ -z ${NO_APPLY} ] ; then
om --skip-ssl-validation \
  apply-changes \
  --product-name ${PRODUCT_SLUG}
else
echo "No Product Apply"
fi
echo $(date) end apply ${PRODUCT_SLUG}
