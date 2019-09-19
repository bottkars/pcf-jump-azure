
#!/usr/bin/env bash
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--HOME)
    HOME_DIR="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if  [ -z ${HOME_DIR} ] ; then
 echo "Please specify HOME DIR -h|--HOME"
 exit 1
fi 

cd ${HOME_DIR}
source ${HOME_DIR}/.env.sh



echo checking deployed products
om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
 deployed-products

om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
 delete-installation --force 

om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
 apply-changes


cd ./pivotal-cf-terraforming-azure-*/
cd terraforming-pas

####### login with client and pave infra
TOKEN=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -s -H Metadata:true | jq -r .access_token)
export TF_VAR_subscription_id=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2017-08-01" | jq -r .subscriptionId)
export TF_VAR_client_secret=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/AZURECLIENTSECRET?api-version=2016-10-01 -s -H "Authorization: Bearer ${TOKEN}" | jq -r .value)
export TF_VAR_client_id=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/AZURECLIENTID?api-version=2016-10-01 -s -H "Authorization: Bearer ${TOKEN}" | jq -r .value)
export TF_VAR_tenant_id=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/AZURETENANTID?api-version=2016-10-01 -s -H "Authorization: Bearer ${TOKEN}" | jq -r .value)

 # preparation work for terraform
terraform destroy

