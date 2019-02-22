#!/usr/bin/env bash
source ~/.env.sh
cd ${HOME_DIR}
MYSELF=$(basename $0)
mkdir -p ${LOG_DIR}
exec &> >(tee -a "${LOG_DIR}/${MYSELF}.$(date '+%Y-%m-%d-%H').log")
exec 2>&1

export OM_TARGET=${PCF_OPSMAN_FQDN}
export OM_USERNAME=${PCF_OPSMAN_USERNAME}
export OM_PASSWORD="${PCF_PIVNET_UAA_TOKEN}"

function getstemcell()
{
SLUG_ID=$1
FAMILY=$2 
DOWNLOAD_DIR=$3
PCF_PIVNET_UAA_TOKEN=$4  
echo "SLUG_ID $SLUG_ID"
echo "FAMILY $FAMILY"

PRODUCT_FILES=$(curl https://network.pivotal.io/api/v2/products/$SLUG_ID/releases \
| jq -r --arg family "$FAMILY" '[.releases[]| (select(.version | contains($family)))._links.product_files.href][0]')

echo "query product files"
PRODUCT=$(curl $PRODUCT_FILES)
PRODUCT_ID=$(echo $PRODUCT \
 | jq -r '.product_files[] | (select(.aws_object_key | contains("hyper"))).id')
PRODUCT_VERSION=$(echo $PRODUCT \
 | jq -r '.product_files[] | (select(.aws_object_key | contains("hyper"))).file_version')
AWS_FILENAME=$(echo $PRODUCT \
 | jq -r '.product_files[] | (select(.aws_object_key | contains("hyper"))).aws_object_key')

PRODUCT_FILENAME=$(basename $AWS_FILENAME)

echo "PRODUCT VERSION $PRODUCT_VERSION"
STEMCELL_DIR=$DOWNLOAD_DIR/stemcells/${PRODUCT_VERSION}
mkdir -p $STEMCELL_DIR
echo $STEMCELL_DIR
om --skip-ssl-validation \
download-product \
--pivnet-api-token $PCF_PIVNET_UAA_TOKEN \
--pivnet-file-glob "bosh-stemcell-${PRODUCT_VERSION}-azure-hyperv-*-go_agent.tgz" \
--pivnet-product-slug $SLUG_ID \
--product-version ${PRODUCT_VERSION} \
--output-directory $STEMCELL_DIR

STEMCELL_FILENAME=$(cat $STEMCELL_DIR/download-file.json | jq -r '.product_path')

echo "renaming $STEMCELL_FILENAME to $DOWNLOAD_DIR/$PRODUCT_FILENAME"
cp -n $STEMCELL_FILENAME $DOWNLOAD_DIR/$PRODUCT_FILENAME

om --skip-ssl-validation \
upload-stemcell \
--floating=false \
--stemcell $DOWNLOAD_DIR/$PRODUCT_FILENAME

}

getstemcell 233 170 $DOWNLOAD_DIR $PCF_PIVNET_UAA_TOKEN
getstemcell 233 97 $DOWNLOAD_DIR $PCF_PIVNET_UAA_TOKEN
# getstemcell 82 3586 $DOWNLOAD_DIR $PCF_PIVNET_UAA_TOKEN
