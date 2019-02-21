#!/usr/bin/env bash
cd $1
source .env.sh
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
$(cat <<-EOF >> ${HOME_DIR}/.env.sh
START_OPSMAN_DEPLOY_TIME="${START_OPSMAN_DEPLOY_TIME}"
EOF
)

pushd ${HOME_DIR}

cd ./pivotal-cf-terraforming-azure-*/
cd terraforming-pas
AZURE_NAMESERVERS=$(terraform output env_dns_zone_name_servers)
SSH_PRIVATE_KEY="$(terraform output -json ops_manager_ssh_private_key | jq .value)"
SSH_PUBLIC_KEY="$(terraform output ops_manager_ssh_public_key)"
BOSH_DEPLOYED_VMS_SECURITY_GROUP_NAME="$(terraform output bosh_deployed_vms_security_group_name)"
PCF_OPSMAN_FQDN="$(terraform output ops_manager_dns)"

echo "checking opsman api ready using the new fqdn ${PCF_OPSMAN_FQDN}, 
if the . keeps showing, check if ns record for ${PCF_SUBDOMAIN_NAME}.${PCF_DOMAIN_NAME} has 
${AZURE_NAMESERVERS}
as server entries"
until $(curl --output /dev/null --silent --head --fail -k -X GET "https://${PCF_OPSMAN_FQDN}/api/v0/info"); do
    printf '.'
    sleep 5
done
echo "done"
export OM_TARGET=${PCF_OPSMAN_FQDN}
export OM_USERNAME=${PCF_OPSMAN_USERNAME}
export OM_PASSWORD="${PCF_PIVNET_UAA_TOKEN}"

om --skip-ssl-validation \
configure-authentication \
--decryption-passphrase ${PCF_PIVNET_UAA_TOKEN}

echo checking deployed products
om --skip-ssl-validation \
deployed-products

cd ${HOME_DIR}
cat << EOF > director_vars.yaml
subscription_id: ${AZURE_SUBSCRIPTION_ID}
tenant_id: ${AZURE_TENANT_ID}
client_id: ${AZURE_CLIENT_ID}
client_secret: ${AZURE_CLIENT_SECRET}
resource_group_name: ${ENV_NAME}
bosh_storage_account_name: ${ENV_SHORT_NAME}director
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
EOF

om --skip-ssl-validation \
 configure-director --config ${HOME_DIR}/director_config.yaml --vars-file ${HOME_DIR}/director_vars.yaml

retryop "om --skip-ssl-validation apply-changes" 2 10


echo checking deployed products
om --skip-ssl-validation \
 deployed-products

popd
END_OPSMAN_DEPLOY_TIME=$(date)
echo ${END_OPSMAN_DEPLOY_TIME} finished opsman deployment
$(cat <<-EOF >> ${HOME_DIR}/.env.sh
PCF_OPSMAN_FQDN="${PCF_OPSMAN_FQDN}"
END_OPSMAN_DEPLOY_TIME="${END_OPSMAN_DEPLOY_TIME}"
EOF
)

sudo mkdir -p /var/tempest/workspaces/default
sudo sh -c \
  "om \
    --skip-ssl-validation \
    --target ${PCF_OPSMAN_FQDN} \
    --username opsman \
    --password ${PCF_PIVNET_UAA_TOKEN} \
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
    if [ "${USE_SELF_CERTS}" = "TRUE" ]; then
      ${SCRIPT_DIR}/create_self_certs.sh
    else  
      ${SCRIPT_DIR}/create_certs.sh
    fi
    ${SCRIPT_DIR}/deploy_pas.sh --DO_NOT_APPLY_CHANGES
    ${SCRIPT_DIR}/deploy_mysql.sh --DO_NOT_APPLY_CHANGES
    ${SCRIPT_DIR}/deploy_rabbit.sh --DO_NOT_APPLY_CHANGES
    ${SCRIPT_DIR}/deploy_spring.sh
fi