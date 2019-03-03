#!/usr/bin/env bash
source ~/.env.sh
cd ${HOME_DIR}
MYSELF=$(basename $0)
mkdir -p ${LOG_DIR}
exec &> >(tee -a "${LOG_DIR}/${MYSELF}.$(date '+%Y-%m-%d-%H').log")
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
    -a|--APPLY_ALL)
    APPLY_ALL=TRUE
    echo "APPLY ALL is ${NO_APPLY}"
    # shift # past value ia arg value
    ;;  
    -nodb|--DO_NOT_CREATE_SQLDB_INSTANCE)
    NO_SQLDB=TRUE
    echo "No SQL DB CREATION is ${NO_SQLDB}"
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
START_OSBA_DEPLOY_TIME=$(date)
$(cat <<-EOF >> ${HOME_DIR}/.env.sh
EOF
)

source ${ENV_DIR}/masb.env

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

DOWNLOAD_DIR_FULL=${DOWNLOAD_DIR}/${PRODUCT_SLUG}/${PCF_OSBA_VERSION}
mkdir  -p ${DOWNLOAD_DIR_FULL}

curl \
  --fail \
  --header "Authorization: Bearer ${PIVNET_ACCESS_TOKEN}" \
  --request POST \
  ${EULA_ACCEPTANCE_URL}


# download product using om cli
if  [ -z ${NO_DOWNLOAD} ] ; then
echo "$(date) start downloading ${PRODUCT_SLUG}"

om --skip-ssl-validation \
  download-product \
 --pivnet-api-token ${PCF_PIVNET_UAA_TOKEN} \
 --pivnet-file-glob "*.pivotal" \
 --pivnet-product-slug ${PRODUCT_SLUG} \
 --product-version ${PCF_OSBA_VERSION} \
 --output-directory ${DOWNLOAD_DIR_FULL}
echo "$(date) end downloading ${PRODUCT_SLUG}"
else 
echo "ignoring download by user "
fi

TARGET_FILENAME=$(cat ${DOWNLOAD_DIR_FULL}/download-file.json | jq -r '.product_path')
# Import the tile to Ops Manager.
echo "$(date) start uploading ${PRODUCT_SLUG}"
om --skip-ssl-validation \
  --request-timeout 3600 \
  upload-product \
  --product ${TARGET_FILENAME}

echo "$(date) end uploading ${PRODUCT_SLUG}"

    # 1. Find the version of the product that was imported.
PRODUCTS=$(om --skip-ssl-validation \
  available-products \
    --format json)

VERSION=$(echo ${PRODUCTS} |\
  jq --arg product_name ${PRODUCT_SLUG} -r 'map(select(.name==$product_name)) | first | .version')


# 2.  Stage using om cli
echo "$(date) start staging ${PRODUCT_SLUG}"
om --skip-ssl-validation \
  stage-product \
  --product-name ${PRODUCT_SLUG} \
  --product-version ${VERSION}
echo "$(date) end staging ${PRODUCT_SLUG}" 


om --skip-ssl-validation \
assign-stemcell \
--product ${PRODUCT_SLUG} \
--stemcell latest

echo "$(date) start creating ${ENV_SHORT_NAME}sql"

az login --service-principal \
  --username ${AZURE_CLIENT_ID} \
  --password ${AZURE_CLIENT_SECRET} \
  --tenant ${AZURE_TENANT_ID}

if  [ -z ${NO_SQLDB} ] ; then
    MY_SQLDB_SERVER=$(az sql server create \
    --admin-password $PCF_PIVNET_UAA_TOKEN \
    --admin-user sqladmin \
    --location ${LOCATION} \
    --name ${ENV_SHORT_NAME}sql \
    --resource-group ${ENV_NAME})
                     

    while [[ $(az sql server show \
            --name ${ENV_SHORT_NAME}sql \
            --resource-group ${ENV_NAME} \
            --out tsv \
            --query state) != 'Ready' ]]; do
        echo "SQL still not finished provisioning. Trying again in 20 seconds."
        sleep 20
        if [[ $(az sql server show \
            --name ${ENV_SHORT_NAME}sql \
            --resource-group ${ENV_NAME} \
            --out tsv \
            --query provisioningState) == 'failed' ]]; then
            echo "SQL Provisioning failed."
            exit 1
        fi
    done
    echo "sql provisioned."
    echo "$(date) end creating ${ENV_SHORT_NAME}sql"
    echo "$(date) creating Dadabase masb${ENV_SHORT_NAME}sql"
    az sql db create \
    --resource-group ${ENV_NAME} \
    --server ${ENV_SHORT_NAME}sql \
    --resource-group ${ENV_NAME} \
    --name masb${ENV_SHORT_NAME}sql
    echo "$(date) end creating Dadabase masb${ENV_SHORT_NAME}sql"
else
MY_SQLDB_SERVER=$(az sql server show \
        --name ${ENV_SHORT_NAME}sql \
        --resource-group ${ENV_NAME})
fi


cat << EOF > ${TEMPLATE_DIR}/masb_vars.yaml
product_name: ${PRODUCT_SLUG}
pcf_pas_network: pcf-pas-subnet
azure_subscription_id: ${AZURE_SUBSCRIPTION_ID}
azure_tenant_id: ${AZURE_TENANT_ID}
azure_client_id: ${AZURE_CLIENT_ID}
azure_client_secret: ${AZURE_CLIENT_SECRET}
azure_broker_database_server: ${ENV_SHORT_NAME}sql.database.windows.net
azure_broker_database_name: masb${ENV_SHORT_NAME}sql
azure_broker_database_password: ${PCF_PIVNET_UAA_TOKEN}
azure_broker_database_encryption_key: $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
EOF

om --skip-ssl-validation \
  configure-product \
  -c ${TEMPLATE_DIR}/masb.yaml -l ${TEMPLATE_DIR}/masb_vars.yaml

echo "$(date) start apply ${PRODUCT_SLUG}"

if  [ ! -z ${NO_APPLY} ] ; then
echo "No Product Apply"
elif [ ! -z ${APPLY_ALL} ] ; then
echo "APPLY_ALL"
om --skip-ssl-validation \
  apply-changes
else 
echo "APPLY Product"
om --skip-ssl-validation \
  apply-changes \
  --product-name ${PRODUCT_SLUG}
fi
echo "$(date) end apply ${PRODUCT_SLUG}"