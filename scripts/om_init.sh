#!/usr/bin/env bash
source ~/.env.sh 
START_OPSMAN_DEPLOY_TIME=$(DATE)

$(cat <<-EOF >> ${HOME_DIR}/.env.sh
START_OPSMAN_DEPLOY_TIME="${START_OPSMAN_DEPLOY_TIME}"
EOF
)

pushd ${HOME_DIR}

cd ./pivotal-cf-terraforming-azure-*/
cd terraforming-pas
echo "checking opsman api ready"
until $(curl --output /dev/null --silent --head --fail -k -X GET "https://${PCF_OPSMAN_FQDN}/api/v0/info"); do
    printf '.'
    sleep 5
done
echo "done"

om --target ${PCF_OPSMAN_FQDN} --skip-ssl-validation \
configure-authentication --username ${PCF_OPSMAN_USERNAME} --password ${PCF_PIVNET_UAA_TOKEN} \
--decryption-passphrase ${PCF_PIVNET_UAA_TOKEN}

om --target ${PCF_OPSMAN_FQDN} --skip-ssl-validation \
--username ${PCF_OPSMAN_USERNAME} --password ${PCF_PIVNET_UAA_TOKEN} deployed-products

SSH_PRIVATE_KEY="$(terraform output -json ops_manager_ssh_private_key | jq .value)"
SSH_PUBLIC_KEY="$(terraform output ops_manager_ssh_public_key)"
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
pas-subnet: "${ENV_NAME}-virtual-network/${ENV_NAME}-services-subnet"
services-subnet: "${ENV_NAME}-virtual-network/${ENV_NAME}-services-subnet"
EOF

om --target ${PCF_OPSMAN_FQDN} --skip-ssl-validation \
--username ${PCF_OPSMAN_USERNAME} --password ${PCF_PIVNET_UAA_TOKEN} \
configure-director --config ${HOME_DIR}/director_config.yaml --vars-file ${HOME_DIR}/director_vars.yaml

until om --target ${PCF_OPSMAN_FQDN} --skip-ssl-validation \
--username ${PCF_OPSMAN_USERNAME} --password ${PCF_PIVNET_UAA_TOKEN} apply-changes;
do
  echo retrying
  sleep 1
done

om --target ${PCF_OPSMAN_FQDN} --skip-ssl-validation \
--username ${PCF_OPSMAN_USERNAME} --password ${PCF_PIVNET_UAA_TOKEN} deployed-products

popd
END_OPSMAN_DEPLOY_TIME=$(DATE)
$(cat <<-EOF >> ${HOME_DIR}/.env.sh
END_OPSMAN_DEPLOY_TIME="${END_OPSMAN_DEPLOY_TIME}"
EOF
)
echo Started BASE deployment at ${START_BASE_DEPLOY_TIME}
echo Fimnished BASE deployment at ${END_BASE_DEPLOY_TIME}
echo Started OPSMAN deployment at ${START_OPSMAN_DEPLOY_TIME}
echo Finished OPSMAN Deployment at ${END_OPSMAN_DEPLOY_TIME}