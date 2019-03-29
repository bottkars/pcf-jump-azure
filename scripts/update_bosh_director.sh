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
    NO_DOWNLOAD="$2"
    echo $NO_DOWNLOAD
    # shift # past value
    ;;
    -d|--DO_NOT_APPLY_CHANGES)
    NO_APPLY="$2"
    echo $NO_APPLY
    ## shift # past value
    ;;    
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
shift
done

export OM_TARGET=${PCF_OPSMAN_FQDN}
export OM_USERNAME=${PCF_OPSMAN_USERNAME}
export OM_PASSWORD="${PCF_PIVNET_UAA_TOKEN}"
EXPORT_FILE=${HOME_DIR}/$(uuidgen)
om --skip-ssl-validation \
    export-installation --output-file ${EXPORT_FILE}

export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
--name ${ENV_SHORT_NAME}opsmanager --resource-group ${ENV_NAME})
export OPSMAN_IMAGE_VERSION=2.4-build.171

export OPSMAN_IMAGE_URI=https://opsmanagerwesteurope.blob.core.windows.net/images/ops-manager-${OPSMAN_IMAGE_VERSION}.vhd

AZURE_STORAGE_ENDPOINT=$(az storage account show --name ${ENV_SHORT_NAME}opsmanager \
 --resource-group ${ENV_NAME} \
  --query '[primaryEndpoints.blob]' --output tsv)
OPSMAN_LOCAL_IMAGE=${AZURE_STORAGE_ENDPOINT}opsmanagerimage/opsman-image-${OPSMAN_IMAGE_VERSION}.vhd

az storage blob copy start --source-uri $OPSMAN_IMAGE_URI \
 --destination-container opsmanagerimage \
 --destination-blob opsman-image-${OPSMAN_IMAGE_VERSION}.vhd



echo "Querying Blob Copy Status"
while [ $(az storage blob show \
 --name opsman-image-${OPSMAN_IMAGE_VERSION}.vhd\
 --container-name opsmanagerimage \
 --query '[properties.copy.status]' --output tsv) != "success" ]
do
printf '.'
sleep 5
done

az vm delete --name ${ENV_NAME}-ops-manager-vm \
  --resource-group ${ENV_NAME} -y

az image create --resource-group ${ENV_NAME} \
--name ${OPSMAN_IMAGE_VERSION} \
--source ${OPSMAN_LOCAL_IMAGE} \
--location ${LOCATION} \
--os-type Linux


az vm create --name ${ENV_NAME}-ops-manager-vm  --resource-group ${ENV_NAME} \
 --location ${LOCATION} \
 --nics ${ENV_NAME}-ops-manager-nic \
 --image ${OPSMAN_IMAGE_VERSION} \
 --os-disk-name ${OPSMAN_IMAGE_VERSION}-osdisk \
 --admin-username ubuntu \
 --os-disk-size-gb 127 \
 --size Standard_DS2_v2 \
 --storage-sku StandardSSD_LRS \
 --ssh-key-value ${HOME_DIR}/.ssh/authorized_keys

 om --skip-ssl-validation \
    --decryption-passphrase $PCF_PIVNET_UAA_TOKEN \
    import-installation --installation $EXPORT_FILE