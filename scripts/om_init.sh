#!/usr/bin/env bash
source ~/.env.sh 
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

DIRECTOR_CONFIGURATION_JSON=$(cat <<-EOF
{
"ntp_servers_string": "time.windows.com"
}
EOF
)

om --target ${PCF_OPSMAN_FQDN} --skip-ssl-validation \
--username ${PCF_OPSMAN_USERNAME} --password ${PCF_PIVNET_UAA_TOKEN}  \
configure-director --director-configuration "${DIRECTOR_CONFIGURATION_JSON}"

SSH_PRIVATE_KEY="$(terraform output -json ops_manager_ssh_private_key | jq .value)"
SSH_PUBLIC_KEY="$(terraform output ops_manager_ssh_public_key)"
IAAS_CONFIGURATION_JSON=$(cat <<-EOF
{
"subscription_id": "${AZURE_SUBSCRIPTION_ID}",
"tenant_id": "${AZURE_TENANT_ID}",
"client_id": "${AZURE_CLIENT_ID}",
"client_secret": "${AZURE_CLIENT_SECRET}",
"resource_group_name": "${ENV_NAME}",
"bosh_storage_account_name": "${ENV_SHORT_NAME}director",
"default_security_group": "${ENV_NAME}-bosh-deployed-vms-security-group",
"ssh_public_key": "${SSH_PUBLIC_KEY}",
"ssh_private_key": ${SSH_PRIVATE_KEY}
}
EOF
)

echo "${IAAS_CONFIGURATION_JSON}"
om --target ${PCF_OPSMAN_FQDN} --skip-ssl-validation \
--username ${PCF_OPSMAN_USERNAME} --password ${PCF_PIVNET_UAA_TOKEN} \
configure-director --iaas-configuration "${IAAS_CONFIGURATION_JSON}"

NETWORKS_CONFIGURATION_JSON=$(cat <<-EOF
{
  "icmp_checks_enabled": false,
  "networks": [
    {
      "name": "pcf-infrastructure-subnet",
      "subnets": [
        {
          "iaas_identifier": "${ENV_NAME}-virtual-network/${ENV_NAME}-infrastructure-subnet",
          "cidr": "10.0.8.0/24",
          "reserved_ip_ranges": "10.0.8.0-10.0.8.4",
          "dns": "168.63.129.16",
          "gateway": "10.0.8.1",
        }
      ]
    },
    {
      "name": "pcf-pas-subnet",
      "subnets": [
        {
          "iaas_identifier": "${ENV_NAME}-virtual-network/${ENV_NAME}-pas-subnet",
          "cidr": "10.0.0.0/22",
          "reserved_ip_ranges": "10.0.0.0-10.0.0.4",
          "dns": "168.63.129.16",
          "gateway": "10.0.0.1",
        }
      ]
    },
    {
      "name": "pcf-services-subnet",
      "service_network": true,
      "subnets": [
        {
          "iaas_identifier": "${ENV_NAME}-virtual-network/${ENV_NAME}-services-subnet",
          "cidr": "10.0.4.0/22",
          "reserved_ip_ranges": "10.0.4.0-10.0.4.4",
          "dns": "168.63.129.16",
          "gateway": "10.0.4.1",
        }
      ]
    }
  ]
}
EOF
)

om --target ${PCF_OPSMAN_FQDN} --skip-ssl-validation \
--username ${PCF_OPSMAN_USERNAME} --password ${PCF_PIVNET_UAA_TOKEN} configure-director \
--networks-configuration "${NETWORKS_CONFIGURATION_JSON}"

# Bosh Director Instance Placement

NETWORK_ASSIGNMENT_JSON=$(cat <<-EOF
{
  "network": {
    "name": "pcf-infrastructure-subnet"
  }
}
EOF
)

om --target ${PCF_OPSMAN_FQDN} --skip-ssl-validation \
--username ${PCF_OPSMAN_USERNAME} --password ${PCF_PIVNET_UAA_TOKEN} configure-director \
--network-assignment "${NETWORK_ASSIGNMENT_JSON}"

RESOURCE_CONFIGURATION_JSON=$(cat <<-EOF
{
    "compilation": {
    "instances": 8
}
}
EOF
)

om --target ${PCF_OPSMAN_FQDN} --skip-ssl-validation \
--username ${PCF_OPSMAN_USERNAME} --password ${PCF_PIVNET_UAA_TOKEN} configure-director \
--resource-configuration "${RESOURCE_CONFIGURATION_JSON}"

until om --target ${PCF_OPSMAN_FQDN} --skip-ssl-validation \
--username ${PCF_OPSMAN_USERNAME} --password ${PCF_PIVNET_UAA_TOKEN} apply-changes;
do
  echo retrying
  sleep 1
done



om --target ${PCF_OPSMAN_FQDN} --skip-ssl-validation \
--username ${PCF_OPSMAN_USERNAME} --password ${PCF_PIVNET_UAA_TOKEN} deployed-products

popd