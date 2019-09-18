#!/usr/bin/env bash
source ~/.env.sh

cd ${HOME_DIR}
MYSELF=$(basename $0)
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -n|--NO_DOWNLOAD)
    NO_DOWNLOAD=TRUE
    echo "No download is ${NO_DOWNLOAD}"
    #shift # past value if  arg value
    ;;
    -d|--DO_NOT_APPLY_CHANGES)
    NO_APPLY=TRUE
    echo "No APPLY is ${NO_APPLY}"
    #shift # past value ia arg value
    ;;
    -a|--APPLY_ALL)
    APPLY_ALL=TRUE
    echo "APPLY ALL is ${APPLY_ALL}"
    #shift # past value ia arg value
    ;;
    -t|--TILE)
    TILE="$2"
    echo "TILE IS ${TILE}"
    shift # past value ia arg value
    ;;
    -s|--LOAD_STEMCELL)
    LOAD_STEMCELL=TRUE
    echo "LOAD_STEMCELL IS ${LOAD_STEMCELL}"
    #shift # past value ia arg value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    #shift # past argument
    ;;
esac
shift
done
set -- "${POSITIONAL[@]}" # restore positional parameters

TILES="apm \
p-spring-cloud-services \
p-spring-cloud-services-3 \
pivotal-mysql \
p-rabbitmq \
p-healthwatch \
kubernetes-service-manager \
pas-windows \
pivotal_single_sign-on_service \
p-isolation-segment \ 
"

if [[ " ${TILES} " =~ " $TILE " ]] 
 then
 echo "Starting deployment of ${TILE}"
else
 echo "mandatory '-t | --TILE <tile>' was not used or ${TILE} not one of '${TILES}'"
 exit 1
fi

mkdir -p ${LOG_DIR}
exec &> >(tee -a "${LOG_DIR}/${TILE}.$(date '+%Y-%m-%d-%H-%M-%S').log")
exec 2>&1


echo $(date) start deploy ${TILE}

source ${ENV_DIR}/${TILE}.env
## get pivnet token from vault
TOKEN=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -s -H Metadata:true | jq -r .access_token)
PIVNET_UAA_TOKEN=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/PIVNETUAATOKEN?api-version=2016-10-01 -H "Authorization: Bearer ${TOKEN}" | jq -r .value)
#Authenticate pivnet 


echo "retrieving pivnet access token from refresh token"

PIVNET_ACCESS_TOKEN=$(curl \
  --fail \
  --header "Content-Type: application/json" \
  --data "{\"refresh_token\": \"${PIVNET_UAA_TOKEN}\"}" \
  https://network.pivotal.io/api/v2/authentication/access_tokens |\
    jq -r '.access_token')

echo "retrieving EULA Acceptance Link for ${PRODUCT_SLUG}"

RELEASE_JSON=$(curl \
  --header "Authorization: Bearer ${PIVNET_ACCESS_TOKEN}" \
  --fail \
  "https://network.pivotal.io/api/v2/products/${PRODUCT_SLUG}/releases/${RELEASE_ID}")
# eula acceptance link
EULA_ACCEPTANCE_URL=$(echo ${RELEASE_JSON} |\
  jq -r '._links.eula_acceptance.href')

echo "accepting EULA Acceptance for ${PRODUCT_SLUG}"

curl \
  --fail \
  --header "Authorization: Bearer ${PIVNET_ACCESS_TOKEN}" \
  --request POST \
  ${EULA_ACCEPTANCE_URL}

DOWNLOAD_DIR_FULL=${DOWNLOAD_DIR}/${PRODUCT_SLUG}/${PCF_VERSION}
mkdir  -p ${DOWNLOAD_DIR_FULL}

### start downloader
if  [ -z ${NO_DOWNLOAD} ] ; then
echo $(date) start downloading ${PRODUCT_SLUG}

om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
  download-product \
 --pivnet-api-token ${PIVNET_UAA_TOKEN} \
 --pivnet-file-glob "*.pivotal" \
 --pivnet-product-slug ${PRODUCT_SLUG} \
 --product-version ${PCF_VERSION} \
 --output-directory ${DOWNLOAD_DIR_FULL}

echo $(date) end downloading ${PRODUCT_SLUG}
### download specials
  case ${TILE} in
      kubernetes-service-manager)
        echo $(date) start downloading Bazaar CLI
        om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
        download-product \
        --pivnet-api-token ${PIVNET_UAA_TOKEN} \
        --pivnet-file-glob "bazaar*.linux" \
        --pivnet-product-slug ${PRODUCT_SLUG} \
        --product-version ${PCF_VERSION} \
        --output-directory ${HOME_DIR}

        echo $(date) end downloading Bazaar CLI
        chmod +x ./bazaar-${PCF_VERSION}.linux
        chown ${ADMIN_USERNAME}.${ADMIN_USERNAME} ./bazaar-${PCF_VERSION}.linux
        sudo cp ./bazaar-${PCF_VERSION}.linux /usr/local/bin/bazaar
        ;;
    pks)
        echo $(date) start downloading PKS CLI
        om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
        download-product \
        --pivnet-api-token ${PIVNET_UAA_TOKEN} \
        --pivnet-file-glob "pks-linux-amd64*" \
        --pivnet-product-slug ${PRODUCT_SLUG} \
        --product-version ${PCF_VERSION} \
        --output-directory ${HOME_DIR}

        echo $(date) end downloading PKS CLI
        chmod +x ./pivotal-container-service-*pks-linux-amd*
        chown ${ADMIN_USERNAME}.${ADMIN_USERNAME} ./pivotal-container-service-*pks-linux-amd*
        sudo cp ./pivotal-container-service-*pks-linux-amd* /usr/local/bin/pks

        echo $(date) start downloading kubectl
        om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
        download-product \
        --pivnet-api-token ${PIVNET_UAA_TOKEN} \
        --pivnet-file-glob "kubectl-linux-amd64*" \
        --pivnet-product-slug ${PRODUCT_SLUG} \
        --product-version ${PCF_VERSION} \
        --output-directory ${HOME_DIR}

        chmod +x ./pivotal-container-service-*kubectl-linux-amd64*
        chown ${ADMIN_USERNAME}.${ADMIN_USERNAME} ./pivotal-container-service-*kubectl-linux-amd64*
        sudo cp ./pivotal-container-service-*kubectl-linux-amd64* /usr/local/bin/kubectl
        ;;
	pas-windows)
        echo $(date) start downloading win injector
        om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
        download-product \
        --pivnet-api-token ${PIVNET_UAA_TOKEN} \
        --pivnet-file-glob "winfs-injector*" \
        --pivnet-product-slug ${PRODUCT_SLUG} \
        --product-version ${PCF_VERSION} \
        --output-directory ${HOME_DIR}

        unzip -o ${HOME}/*winfs-injector*.zip

        chmod +x ${HOME}/winfs-injector-linux

        echo $(date) start downloading tile replicator
        om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
        download-product \
        --pivnet-api-token ${PIVNET_UAA_TOKEN} \
        --pivnet-file-glob "replicator*" \
        --pivnet-product-slug ${PRODUCT_SLUG} \
        --product-version ${PCF_VERSION} \
        --output-directory ${HOME_DIR}

        unzip -o ${HOME}/replicator*.zip

        chmod +x ${HOME}/replicator-linux

        TARGET_FILENAME=$(cat ${DOWNLOAD_DIR_FULL}/download-file.json | jq -r '.product_path')
        INJECTED_FILENAME=injectded
        ${HOME}/winfs-injector-linux --input-tile ${TARGET_FILENAME} \
          --output-tile ${INJECTED_FILENAME}


         
	;;
esac  
else
echo ignoring download by user
fi
### end downloader
case ${PRODUCT_SLUG} in
    p-compliance-scanner)
    PRODUCT=scanner
    ;;
    kubernetes-service-manager)
    PRODUCT=ksm
    ;;
    apm)
    PRODUCT=apmPostgres
    ;;
    *)
    PRODUCT=${PRODUCT_SLUG}
    ;;
esac
#### tile configuration starts here
case ${TILE} in
apm)
  if  [ ! -z ${LOAD_STEMCELL} ] ; then
    echo "calling stemmcell_loader for LOADING Stemcells"
    $SCRIPT_DIR/stemcell_loader.sh -s 170
  fi
  cat << EOF > ${TEMPLATE_DIR}/${TILE}_vars.yml
product_name: ${PRODUCT}
pcf_pas_network: pcf-pas-subnet
singleton_zone: ${SINGLETON_ZONE}
zones_map: ${ZONES_MAP}
zones_list: ${ZONES_LIST}
EOF
;;
pas-windows)
  if  [ ! -z ${LOAD_STEMCELL} ] ; then
    echo "calling stemmcell_loader for LOADING Stemcells"
    $SCRIPT_DIR/stemcell_loader.sh -i 151 -s 2019.2
  fi
  cat << EOF > ${TEMPLATE_DIR}/${TILE}_vars.yml
product_name: ${PRODUCT}
pcf_pas_network: pcf-pas-subnet
singleton_zone: ${SINGLETON_ZONE}
zones_map: ${ZONES_MAP}
zones_list: ${ZONES_LIST}
EOF
;;
p-isolation-segment)
  if  [ ! -z ${LOAD_STEMCELL} ] ; then
    echo "calling stemmcell_loader for LOADING Stemcells"
    $SCRIPT_DIR/stemcell_loader.sh -s 250
  fi
PCF_KEY_PEM=$(cat ${HOME_DIR}/${PCF_SUBDOMAIN_NAME}.${PCF_DOMAIN_NAME}.key | awk '{printf "%s\\r\\n", $0}')
PCF_CERT_PEM=$(cat ${HOME_DIR}/fullchain.cer | awk '{printf "%s\\r\\n", $0}')  
  cat << EOF > ${TEMPLATE_DIR}/${TILE}_vars.yml
product_name: ${PRODUCT}
pcf_pas_network: pcf-pas-subnet
singleton_zone: ${SINGLETON_ZONE}
pcf_cert_pem: "${PCF_CERT_PEM}"
pcf_key_pem: "${PCF_KEY_PEM}"
zones_map: ${ZONES_MAP}
zones_list: ${ZONES_LIST}
EOF
;;
  pivotal-mysql)
      if  [ ! -z ${LOAD_STEMCELL} ] ; then
        echo "calling stemmcell_loader for LOADING Stemcells"
        $SCRIPT_DIR/stemcell_loader.sh -s 170
      fi
    echo "creating storage account ${ENV_SHORT_NAME}mysqlbackup"
    ####### login with client and pave infra
    TOKEN=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -s -H Metadata:true | jq -r .access_token)
    AZURE_SUBSCRIPTION_ID=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2017-08-01" | jq -r .subscriptionId)
    AZURE_CLIENT_SECRET=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/AZURECLIENTSECRET?api-version=2016-10-01 -s -H "Authorization: Bearer ${TOKEN}" | jq -r .value)
    AZURE_CLIENT_ID=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/AZURECLIENTID?api-version=2016-10-01 -s -H "Authorization: Bearer ${TOKEN}" | jq -r .value)
    AZURE_TENANT_ID=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/AZURETENANTID?api-version=2016-10-01 -s -H "Authorization: Bearer ${TOKEN}" | jq -r .value)
    az login --service-principal \
      --username ${AZURE_CLIENT_ID} \
      --password ${AZURE_CLIENT_SECRET} \
      --tenant ${AZURE_TENANT_ID}

    az storage account create --name ${ENV_SHORT_NAME}mysqlbackup \
    --resource-group ${ENV_NAME} \
    --sku Standard_LRS \
    --location $LOCATION

    MYSQL_STORAGE_KEY=$(az storage account keys list \
    --account-name ${ENV_SHORT_NAME}mysqlbackup \
    --resource-group ${ENV_NAME} \
    --query "[0].{value:value}" \
    --output tsv
    )

    az storage container create --name backup \
    --account-name ${ENV_SHORT_NAME}mysqlbackup \
    --account-key ${MYSQL_STORAGE_KEY}

    cat << EOF > ${TEMPLATE_DIR}/${TILE}_vars.yml
product_name: ${PRODUCT_SLUG}
pcf_pas_network: pcf-pas-subnet
pcf_service_network: pcf-services-subnet
azure_storage_access_key: ${MYSQL_STORAGE_KEY}
azure_account: ${ENV_SHORT_NAME}mysqlbackup
global_recipient_email: ${PCF_NOTIFICATIONS_EMAIL}
blob_store_base_url: blob.core.windows.net
singleton_zone: ${SINGLETON_ZONE}
zones_map: ${ZONES_MAP}
zones_list: ${ZONES_LIST}
EOF
  ;;
p-healthwatch)
if  [ ! -z ${LOAD_STEMCELL} ] ; then
  echo "calling stemmcell_loader for LOADING Stemcells"
  $SCRIPT_DIR/stemcell_loader.sh -s 170
fi
cat << EOF > ${TEMPLATE_DIR}/${TILE}_vars.yml
product_name: ${PRODUCT_SLUG}
pcf_pas_network: pcf-pas-subnet
pcf_service_network: pcf-services-subnet
singleton_zone: ${SINGLETON_ZONE}
zones_map: ${ZONES_MAP}
zones_list: ${ZONES_LIST}
opsman_enable_url: https://${PCF_OPSMAN_FQDN}
EOF
;;  
p-spring-cloud-services)
  if  [ ! -z ${LOAD_STEMCELL} ] ; then
    echo "calling stemmcell_loader for LOADING Stemcells"
    $SCRIPT_DIR/stemcell_loader.sh -s 97
  fi
  cat << EOF > ${TEMPLATE_DIR}/${TILE}_vars.yml
product_name: ${PRODUCT_SLUG}
pcf_pas_network: pcf-pas-subnet
singleton_zone: ${SINGLETON_ZONE}
zones_map: ${ZONES_MAP}
zones_list: ${ZONES_LIST}
EOF
;;
p-spring-cloud-services-3)
  if  [ ! -z ${LOAD_STEMCELL} ] ; then
    echo "calling stemmcell_loader for LOADING Stemcells"
    $SCRIPT_DIR/stemcell_loader.sh -s 233
  fi
  cat << EOF > ${TEMPLATE_DIR}/${TILE}_vars.yml
product_name: ${PRODUCT_SLUG}
pcf_pas_network: pcf-pas-subnet
singleton_zone: ${SINGLETON_ZONE}
zones_map: ${ZONES_MAP}
zones_list: ${ZONES_LIST}
EOF
;;
p-rabbitmq)
if  [ ! -z ${LOAD_STEMCELL} ] ; then
  echo "calling stemmcell_loader for LOADING Stemcells"
  $SCRIPT_DIR/stemcell_loader.sh -s 97
fi
cat << EOF > ${TEMPLATE_DIR}/${TILE}_vars.yml
product_name: ${PRODUCT_SLUG}
pcf_pas_network: pcf-pas-subnet
pcf_service_network: pcf-services-subnet
server_admin_password: ${PIVNET_UAA_TOKEN}
singleton_zone: ${SINGLETON_ZONE}
zones_map: ${ZONES_MAP}
zones_list: ${ZONES_LIST}
EOF
;;
pivotal_single_sign-on_service)
if  [ ! -z ${LOAD_STEMCELL} ] ; then
  echo "calling stemmcell_loader for LOADING Stemcells"
  $SCRIPT_DIR/stemcell_loader.sh -s 97
fi
PRODUCT=Pivotal_Single_Sign-On_Service
cat << EOF > ${TEMPLATE_DIR}/${TILE}_vars.yml
product_name: ${PRODUCT}
pcf_pas_network: pcf-pas-subnet
pcf_service_network: pcf-services-subnet
server_admin_password: ${PIVNET_UAA_TOKEN}
singleton_zone: ${SINGLETON_ZONE}
zones_map: ${ZONES_MAP}
zones_list: ${ZONES_LIST}
EOF
;;
kubernetes-service-manager)
cat << EOF > ${TEMPLATE_DIR}/${TILE}_vars.yml
product_name: ${PRODUCT}
pcf_pas_network: pcf-pas-subnet
pcf_service_network: pcf-services-subnet
singleton_zone: ${SINGLETON_ZONE}
zones_map: ${ZONES_MAP}
zones_list: ${ZONES_LIST}
EOF
;;
esac

if  [ ! -z ${INJECTED_FILENAME} ] ; then
om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
  --request-timeout 3600 \
  upload-product \
  --product ${INJECTED_FILENAME}
else
TARGET_FILENAME=$(cat ${DOWNLOAD_DIR_FULL}/download-file.json | jq -r '.product_path')
# Import the tile to Ops Manager.
echo $(date) start uploading ${PRODUCT_SLUG}
om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
  --request-timeout 3600 \
  upload-product \
  --product ${TARGET_FILENAME}
fi
echo $(date) end uploading ${PRODUCT_SLUG}

    # 1. Find the version of the product that was imported.
PRODUCTS=$(om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
  available-products \
    --format json)



VERSION=$(echo ${PRODUCTS} |\
  jq --arg product_name ${PRODUCT} -r 'map(select(.name==$product_name)) | first | .version')
if [[ -z "$VERSION" ]] ||  [[ "$VERSION" == "null" ]];then
  echo "EMPTY Product Version"
  exit 1
fi

PRODUCT_NAME=$(echo ${PRODUCTS} |\
  jq --arg product_name ${PRODUCT} -r 'map(select(.name==$product_name)) | first | .name')

if [[ -z "$PRODUCT_NAME" ]] ||  [[ "$PRODUCT_NAME" == "null" ]];then
  echo "EMPTY Product Name"
  exit 1
fi

# 2.  Stage using om cli
echo $(date) start staging ${PRODUCT_SLUG}
om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
  stage-product \
  --product-name ${PRODUCT_NAME} \
  --product-version ${VERSION}
echo $(date) end staging ${PRODUCT_SLUG}

om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
assign-stemcell \
--product ${PRODUCT_NAME} \
--stemcell latest

om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
  configure-product \
  -c ${TEMPLATE_DIR}/${TILE}.yml -l ${TEMPLATE_DIR}/${TILE}_vars.yml

case ${TILE} in
    pks)
    if  [ ! -z ${WAVEFRONT}  ]; then
    om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
      configure-product \
      -c ${TEMPLATE_DIR}/wavefront.yml -l ${TEMPLATE_DIR}/${TILE}_vars.yml
    fi
esac


echo $(date) start apply ${PRODUCT_SLUG}

if  [ ! -z ${NO_APPLY} ] ; then
echo "No Product Apply"
elif [ ! -z ${APPLY_ALL} ] ; then
echo "APPLY_ALL"
om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
  apply-changes \
  --skip-unchanged-products
else
echo "APPLY Product ${PRODUCT_NAME}"
om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
  apply-changes \
  --product-name ${PRODUCT_NAME}
fi

echo "checking deployed products"
om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
 deployed-products
echo $(date) end apply ${PRODUCT_SLUG}