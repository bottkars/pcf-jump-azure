#!/usr/bin/env bash
cd $1
source ${1}/.env.sh
MYSELF=$(basename $0)
mkdir -p ${LOG_DIR}
exec &> >(tee -a "${LOG_DIR}/${MYSELF}.$(date '+%Y-%m-%d-%H').log")
exec 2>&1
function retryop()
{
  retry=0
  max_retries=$2
  interval=$3
  while [ ${retry} -lt ${max_retries} ]; do
    echo "Operation: $1, Retry #${retry}"
    eval $1
    if [ $? -eq 0 ]; then
      echo "Successful"
      break
    else
      let retry=retry+1
      echo "Sleep $interval seconds, then retry..."
      sleep $interval
    fi
  done
  if [ ${retry} -eq ${max_retries} ]; then
    echo "Operation failed: $1"
    exit 1
  fi
}
START_OPSMAN_DEPLOY_TIME=$(date)
echo ${START_OPSMAN_DEPLOY_TIME} start opsman deployment
pushd ${HOME_DIR}


###  setting secret env from vault 


TOKEN=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -s -H Metadata:true | jq -r .access_token)

export TF_VAR_subscription_id=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2017-08-01" | jq -r .subscriptionId)
export TF_VAR_client_secret=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/AZURECLIENTSECRET?api-version=2016-10-01 -s -H "Authorization: Bearer ${TOKEN}" | jq -r .value)
export TF_VAR_client_id=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/AZURECLIENTID?api-version=2016-10-01 -s -H "Authorization: Bearer ${TOKEN}" | jq -r .value)
export TF_VAR_tenant_id=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/AZURETENANTID?api-version=2016-10-01 -s -H "Authorization: Bearer ${TOKEN}" | jq -r .value)
PIVNET_UAA_TOKEN=$(curl https://${AZURE_VAULT}.vault.azure.net/secrets/PIVNETUAATOKEN?api-version=2016-10-01 -H "Authorization: Bearer ${TOKEN}" | jq -r .value)

###

####ä##
source ${ENV_DIR}/pas.env
AUTHENTICATION_RESPONSE=$(curl \
  --fail \
  --data "{\"refresh_token\": \"${PIVNET_UAA_TOKEN}\"}" \
  https://network.pivotal.io/api/v2/authentication/access_tokens)

PIVNET_ACCESS_TOKEN=$(echo ${AUTHENTICATION_RESPONSE} | jq -r '.access_token')
# Get the release JSON for the PAS version you want to install:

RELEASE_JSON=$(curl \
    --fail \
    "https://network.pivotal.io/api/v2/products/${PRODUCT_SLUG}/releases/${RELEASE_ID}")

# ACCEPTING EULA

EULA_ACCEPTANCE_URL=$(echo ${RELEASE_JSON} |\
  jq -r '._links.eula_acceptance.href')

curl \
  --fail \
  --header "Authorization: Bearer ${PIVNET_ACCESS_TOKEN}" \
  --request POST \
  ${EULA_ACCEPTANCE_URL}

# GET TERRAFORM FOR PCF AZURE

DOWNLOAD_ELEMENT=$(echo ${RELEASE_JSON} |\
  jq -r '.product_files[] | select(.aws_object_key | contains("terraforming-azure"))')

FILENAME=$(echo ${DOWNLOAD_ELEMENT} |\
  jq -r '.aws_object_key | split("/") | last')

URL=$(echo ${DOWNLOAD_ELEMENT} |\
  jq -r '._links.download.href')

# download terraform

curl \
  --fail \
  --location \
  --output ${FILENAME} \
  --header "Authorization: Bearer ${PIVNET_ACCESS_TOKEN}" \
  ${URL}
sudo -S -u ${ADMIN_USERNAME} unzip ${FILENAME}
cd ./pivotal-cf-terraforming-azure-*/
cd terraforming-pas

PATCH_SERVER="https://raw.githubusercontent.com/bottkars/pcf-jump-azure/master/patches/"
wget -q ${PATCH_SERVER}modules/pas/dns.tf -O ../modules/pas/dns.tf
wget -q ${PATCH_SERVER}modules/pas/istiolb.tf -O ../modules/pas/istiolb.tf
wget -q ${PATCH_SERVER}modules/pas/outputs.tf -O ../modules/pas/outputs.tf
wget -q ${PATCH_SERVER}outputs.tf -O outputs.tf

 # preparation work for terraform
cat << EOF > terraform.tfvars
client_id             = "${AZURE_CLIENT_ID}"
client_secret         = "${AZURE_CLIENT_SECRET}"
subscription_id       = "${AZURE_SUBSCRIPTION_ID}"
tenant_id             = "${AZURE_TENANT_ID}"
env_name              = "${ENV_NAME}"
env_short_name        = "${ENV_SHORT_NAME}"
ops_manager_image_uri = "${OPS_MANAGER_IMAGE_URI}"
location              = "${LOCATION}"
dns_suffix            = "${PCF_DOMAIN_NAME}"
dns_subdomain         = "${PCF_SUBDOMAIN_NAME}"
ops_manager_private_ip = "${NET_16_BIT_MASK}.8.4"
pcf_infrastructure_subnet = "${NET_16_BIT_MASK}.8.0/26"
pcf_pas_subnet = "${NET_16_BIT_MASK}.0.0/22"
pcf_services_subnet = "${NET_16_BIT_MASK}.4.0/22"
pcf_virtual_network_address_space = ["${NET_16_BIT_MASK}.0.0/16"]
EOF
chmod 755 terraform.tfvars
chown ${ADMIN_USERNAME}.${ADMIN_USERNAME} terraform.tfvars
sudo -S -u ${ADMIN_USERNAME} terraform init
sudo -S -u ${ADMIN_USERNAME} terraform plan -out=plan
retryop "sudo -S -u ${ADMIN_USERNAME} terraform apply -auto-approve" 3 10

sudo -S -u ${ADMIN_USERNAME} terraform output ops_manager_ssh_private_key > ${HOME_DIR}/opsman
# sudo -S -u ${ADMIN_USERNAME} chmod 600 ${HOME_DIR}/opsman

# PCF_NETWORK=$(terraform output network_name)

## create network peerings

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
 
#####
cd ./pivotal-cf-terraforming-azure-*/
cd terraforming-pas

# istio patches
PATCH_SERVER="https://raw.githubusercontent.com/bottkars/pcf-jump-azure/master/patches/"
wget -q ${PATCH_SERVER}modules/pas/dns.tf -O ../modules/pas/dns.tf
wget -q ${PATCH_SERVER}modules/pas/istiolb.tf -O ../modules/pas/istiolb.tf
wget -q ${PATCH_SERVER}modules/pas/outputs.tf -O ../modules/pas/outputs.tf


AZURE_NAMESERVERS=$(terraform output env_dns_zone_name_servers)
SSH_PRIVATE_KEY="$(terraform output -json ops_manager_ssh_private_key | jq .value)"
SSH_PUBLIC_KEY="$(terraform output ops_manager_ssh_public_key)"
BOSH_DEPLOYED_VMS_SECURITY_GROUP_NAME="$(terraform output bosh_deployed_vms_security_group_name)"
PCF_OPSMAN_FQDN="$(terraform output ops_manager_dns)"
BOSH_STORAGE_ACCOUNT_NAME=$(terraform output bosh_root_storage_account)

echo "checking opsman api ready using the new fqdn ${PCF_OPSMAN_FQDN}, 
if the . keeps showing, check if ns record for ${PCF_SUBDOMAIN_NAME}.${PCF_DOMAIN_NAME} has 
${AZURE_NAMESERVERS}
as server entries"
until $(curl --output /dev/null --silent --head --fail -k -X GET "https://${PCF_OPSMAN_FQDN}/api/v0/info"); do
    printf '.'
    sleep 5
done
echo "done"


OM_ENV_FILE="${HOME_DIR}/om_${ENV_NAME}.env"
cat << EOF > ${OM_ENV_FILE}
---
target: ${PCF_OPSMAN_FQDN}
connect-timeout: 30          # default 5
request-timeout: 3600        # default 1800
skip-ssl-validation: true   # default false
username: ${PCF_OPSMAN_USERNAME}
password: ${PIVNET_UAA_TOKEN}
decryption-passphrase: ${PIVNET_UAA_TOKEN}
EOF


az login --service-principal \
  --username ${AZURE_CLIENT_ID} \
  --password ${AZURE_CLIENT_SECRET} \
  --tenant ${AZURE_TENANT_ID}

VNet1Id=$(az network vnet show \
  --resource-group ${JUMP_RG} \
  --name ${JUMP_VNET} \
  --query id --out tsv)

VNet2Id=$(az network vnet show \
  --resource-group ${ENV_NAME} \
  --name ${ENV_NAME}-virtual-network \
  --query id --out tsv)

az network vnet peering create --name PCF-Peer \
--remote-vnet-id ${VNet2Id} \
--resource-group ${JUMP_RG} \
--vnet-name ${JUMP_VNET} \
--allow-forwarded-traffic \
--allow-gateway-transit \
--allow-vnet-access

az network vnet peering create --name JUMP-Peer \
--remote-vnet-id ${VNet1Id} \
--resource-group ${ENV_NAME} \
--vnet-name ${ENV_NAME}-virtual-network \
--allow-forwarded-traffic \
--allow-gateway-transit \
--allow-vnet-access



om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
configure-authentication \
--decryption-passphrase ${PIVNET_UAA_TOKEN}  \
--username ${PCF_OPSMAN_USERNAME} \
--password ${PIVNET_UAA_TOKEN}

echo checking deployed products
om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
deployed-products

declare -a FILES=("${HOME_DIR}/${PCF_SUBDOMAIN_NAME}.${PCF_DOMAIN_NAME}.key" \
"${HOME_DIR}/fullchain.cer")
# are we first time ?!

for FILE in "${FILES[@]}"; do
    if [ ! -f $FILE ]; then
      if [ "${USE_SELF_CERTS}" = "TRUE" ]; then
        sudo -S -u ${ADMIN_USERNAME} ${SCRIPT_DIR}/create_self_certs.sh
      else  
        sudo -S -u ${ADMIN_USERNAME} ${SCRIPT_DIR}/create_certs.sh
      fi
    fi  
done
## did let´sencrypt just not work ?
for FILE in "${FILES[@]}"; do
    if [ ! -f $FILE ]; then
    echo "$FILE not found. running Create Self Certs "
    ${SCRIPT_DIR}/create_self_certs.sh
    fi
done


om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
update-ssl-certificate \
    --certificate-pem "$(cat ${HOME_DIR}/fullchain.cer)" \
    --private-key-pem "$(cat ${HOME_DIR}/${PCF_SUBDOMAIN_NAME}.${PCF_DOMAIN_NAME}.key)"

cd ${HOME_DIR}
cat << EOF > ${TEMPLATE_DIR}/director_vars.yml
subscription_id: ${AZURE_SUBSCRIPTION_ID}
tenant_id: ${AZURE_TENANT_ID}
client_id: ${AZURE_CLIENT_ID}
client_secret: ${AZURE_CLIENT_SECRET}
resource_group_name: ${ENV_NAME}
bosh_storage_account_name: ${BOSH_STORAGE_ACCOUNT_NAME}
default_security_group: ${ENV_NAME}-bosh-deployed-vms-security-group
ssh_public_key: ${SSH_PUBLIC_KEY}
ssh_private_key: ${SSH_PRIVATE_KEY}
ntp_servers_string: 'time.windows.com'
infrastructure-subnet: "${ENV_NAME}-virtual-network/${ENV_NAME}-infrastructure-subnet"
pas-subnet: "${ENV_NAME}-virtual-network/${ENV_NAME}-pas-subnet"
services-subnet: "${ENV_NAME}-virtual-network/${ENV_NAME}-services-subnet"
bosh_deployed_vms_security_group_name: ${BOSH_DEPLOYED_VMS_SECURITY_GROUP_NAME}
infrastructure_cidr: "${NET_16_BIT_MASK}.8.0/26"
infrastructure_range: "${NET_16_BIT_MASK}.8.1-${NET_16_BIT_MASK}.8.10"
infrastructure_gateway: "${NET_16_BIT_MASK}.8.1"
pas_cidr: "${NET_16_BIT_MASK}.0.0/22"
pas_range: "${NET_16_BIT_MASK}.0.1-${NET_16_BIT_MASK}.0.4"
pas_gateway: "${NET_16_BIT_MASK}.0.1"
services_cidr: "${NET_16_BIT_MASK}.4.0/22"
services_range: "${NET_16_BIT_MASK}.4.1-${NET_16_BIT_MASK}.4.4"
services_gateway: "${NET_16_BIT_MASK}.4.1"
fullchain: "$(cat ${HOME_DIR}/fullchain.cer | awk '{printf "%s\\r\\n", $0}')"
availability_mode: ${AVAILABILITY_MODE}
singleton_availability_zone: "${SINGLETON_ZONE}"
EOF



om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
 configure-director --config ${TEMPLATE_DIR}/director_config.yml --vars-file ${TEMPLATE_DIR}/director_vars.yml

retryop "om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
 apply-changes" 2 10


echo checking deployed products
om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
 deployed-products

popd
END_OPSMAN_DEPLOY_TIME=$(date)
echo ${END_OPSMAN_DEPLOY_TIME} finished opsman deployment
$(cat <<-EOF >> ${HOME_DIR}/.env.sh
PCF_OPSMAN_FQDN="${PCF_OPSMAN_FQDN}"
EOF
)

sudo mkdir -p /var/tempest/workspaces/default
sudo sh -c \
  "om --env "${HOME_DIR}/om_${ENV_NAME}.env"  \
    curl \
      --silent \
      --path "/api/v0/security/root_ca_certificate" |
        jq --raw-output '.root_ca_certificate_pem' \
          > /var/tempest/workspaces/default/root_ca_certificate"



echo Started BASE deployment at ${START_BASE_DEPLOY_TIME}
echo Fimnished BASE deployment at ${END_BASE_DEPLOY_TIME}
echo Started OPSMAN deployment at ${START_OPSMAN_DEPLOY_TIME}
echo Finished OPSMAN Deployment at ${END_OPSMAN_DEPLOY_TIME}

if [ "${PAS_AUTOPILOT}" = "TRUE" ]; then
    ${SCRIPT_DIR}/deploy_pas.sh --DO_NOT_APPLY_CHANGES -s
    ${SCRIPT_DIR}/deploy_tile.sh -t pivotal-mysql --DO_NOT_APPLY_CHANGES -s
    ${SCRIPT_DIR}/deploy_tile.sh -t p-rabbitmq --DO_NOT_APPLY_CHANGES -s
    ${SCRIPT_DIR}/deploy_tile.sh -t p-spring-services -s --APPLY_ALL
fi