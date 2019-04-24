##!/usr/bin/env bash
source ~/.env.sh
cd ${HOME_DIR}
MYSELF=$(basename $0)
mkdir -p ${LOG_DIR}
exec &> >(tee -a "${LOG_DIR}/${MYSELF}.$(date '+%Y-%m-%d-%H').log")
exec 2>&1
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -s|--STEMCELL_VERSION)
    STEMCELL_VER=$2
    echo "Stemcell Version ${STEMCELL_VER}"
    shift # past value ia arg value
    ;; 
    -i|--SLUG_ID)
    SLUG_ID=$2
    echo "Slug ID ${SLUG_ID}"
    shift # past value ia arg value
    ;;        
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
shift
done
set -- "${POSITIONAL[@]}" # restore positional parameters
if  [ -z ${STEMCELL_VER} ] ; then
 STEMCELL_VER=170.45
 echo "Defaulting to Stemcell to ${STEMCELL_VER}"
fi
if  [ -z ${SLUG_ID} ] ; then
 SLUG_ID=233
 echo "Defaulting to Stemcell to ${STEMCELL_VER}"
fi
SLUG_IDS="233 \
151 \
82 \
"

if [[ " ${SLUG_IDS} " =~ " $SLUG_ID " ]] 
 then
 echo "Downloading ${SLUG_ID}"
else
 echo "mandatory '-i | --SLUG_ID <slugid>' was not used or <slugisd not one of '${SLUG_IDS}'"
 exit 1
fi




function getstemcell()
{
SLUG_ID=$1
FAMILY=$2 
DOWNLOAD_DIR=$3
PIVNET_UAA_TOKEN=$4  
echo "SLUG_ID $SLUG_ID"
echo "FAMILY $FAMILY"

PIVNET_ACCESS_TOKEN=$(curl \
  --fail \
  --header "Content-Type: application/json" \
  --data "{\"refresh_token\": \"${PIVNET_UAA_TOKEN}\"}" \
  https://network.pivotal.io/api/v2/authentication/access_tokens |\
    jq -r '.access_token')


RELEASES=$(curl \
  --fail \
  --header "Authorization: Bearer ${PIVNET_ACCESS_TOKEN}" \
  https://network.pivotal.io/api/v2/products/$SLUG_ID/releases \
| jq -r --arg family "$FAMILY" '[.releases[]| (select(.version | contains($family)))._links][0]')


EULA_ACCEPTANCE_URL=$(echo $RELEASES | jq -r .eula_acceptance[])

echo "Accepting EULA for 250 Stemmcell Family"
curl \
  --fail \
  --header "Authorization: Bearer ${PIVNET_ACCESS_TOKEN}" \
  --request POST \
  ${EULA_ACCEPTANCE_URL}


PRODUCT_FILES=$(echo $RELEASES | jq -r .product_files[])



echo "query product files"
PRODUCT=$(curl --header "Authorization: Bearer ${PIVNET_ACCESS_TOKEN}" $PRODUCT_FILES)
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
om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
download-product \
--pivnet-api-token $PIVNET_UAA_TOKEN \
--pivnet-file-glob "*-stemcell-${PRODUCT_VERSION}-azure-hyperv-*-go_agent.tgz" \
--pivnet-product-slug $SLUG_ID \
--product-version ${PRODUCT_VERSION} \
--output-directory $STEMCELL_DIR

STEMCELL_FILENAME=$(cat $STEMCELL_DIR/download-file.json | jq -r '.product_path')

#echo "renaming $STEMCELL_FILENAME to $DOWNLOAD_DIR/$PRODUCT_FILENAME"
#cp -n $STEMCELL_FILENAME $DOWNLOAD_DIR/$PRODUCT_FILENAME

om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
upload-stemcell \
--floating=true \
--stemcell $STEMCELL_DIR/$PRODUCT_FILENAME

}

getstemcell ${SLUG_ID} ${STEMCELL_VER} $DOWNLOAD_DIR $PIVNET_UAA_TOKEN
# getstemcell 233 97 $DOWNLOAD_DIR $PIVNET_UAA_TOKEN
# getstemcell 82 3586 $DOWNLOAD_DIR $PIVNET_UAA_TOKEN
