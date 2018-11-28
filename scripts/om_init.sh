#!/usr/bin/env bash
 

om --target ${OM_HOSTNAME} --skip-ssl-validation \
configure-authentication --username opsman --password ${PCF_PIVNET_UAA_TOKEN} \
--decryption-passphrase ${PCF_PIVNET_UAA_TOKEN}

om --target ${OM_HOSTNAME} --skip-ssl-validation \
--username opsman --password ${PCF_PIVNET_UAA_TOKEN} deployed-products

DIRECTOR_CONFIGURATION_JSON=$(cat <<-EOF
{
"ntp_servers_string": "time.windows.com"
}
EOF
)

om --target ${OM_HOSTNAME} --skip-ssl-validation \
--username opsman --password ${PCF_PIVNET_UAA_TOKEN}  \
configure-director --director-configuration "${DIRECTOR_CONFIGURATION_JSON}"


IAAS_CONFIGURATION_JSON=$(cat <<-EOF
{
"subscription_id": "",
"tenant_id": "",
"client_id": "",
"client_secret": "",
"resource_group_name": "pcf",
"bosh_storage_account_name": "kbpcfdirector",
"default_security_group": "pcf-bosh-deployed-vms-security-group",
"ssh_public_key": "fake ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDS+LVNZPkfYqOPLyRvPNYpprBuWBQFWuMeEFK3JFuDyp0mwySBdMhRO4ufD8XZ84Ule+VCLipAHwXsQizJrL+1FOISPtmLY3PkaVz5TV4A/4o+hkPlM2N3XkxKo/qs+3rlDdjrnt7+/m9mP2brZ6BWrbYdpPCubH/gtkUER4g2vdxIanB0NCJ1oEihQIUja8CRd+TcXEudHJyF6Gui+R6KbYsfd2LU0ixy1czQTsQGexEccyI0fd2XOG9pVi1d7An9lyU9cOb9IGDwsenq8ulgjvB/JQthYjAtukTa3uW2aG1BCM7KBfHj17nEZ+15cuMi3epBFpUk1ykbvD0S6fOiLR798XfYvgLEnJuwAQqVi596myL/qkaDSrlCUry5vHFh77z+kn087SDzWo7Ta0AeuGOaaPCsbu471ZvGbV6x7RqU5IpQ+qanr0t4hUO1RcAm8LZNOCQ1Uc37P5CCbrMnqjlG5ILiQu0iI2bZqXLEIJUykAySpG635xuHHHf1utkiXX8j1hcCNPyqwnBhJ6nT3lB3aR1QP1icW//++8QyWp3KMWvDFicirq68hoyAfkPsDY5iiCZz1rVNTzMK1iYCgfrNTY75+lCg2rtyCenzM3evCieHjCEHdydZz97zqOoX/kTQ6xc11ztgTKrD4COwKuMX10aIzp/UbyKcpT3v6Q==",
"ssh_private_key": "${}"
}
EOF
)


om --target ${OM_HOSTNAME} --skip-ssl-validation \
--username opsman --password ${PCF_PIVNET_UAA_TOKEN} \
configure-director --iaas-configuration ${IAAS_CONFIGURATION_JSON}

NETWORKS_CONFIGURATION_JSON=$(cat <<-EOF
{
  "icmp_checks_enabled": false,
  "networks": [
    {
      "name": "pcf-infrastructure-subnet",
      "subnets": [
        {
          "iaas_identifier": "pcf-virtual-network/pcf-infrastructure-subnet",
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
          "iaas_identifier": "pcf-virtual-network/pcf-pas-subnet",
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
          "iaas_identifier": "pcf-virtual-network/pcf-services-subnet",
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

om --target ${OM_HOSTNAME} --skip-ssl-validation \
--username opsman --password ${PCF_PIVNET_UAA_TOKEN} configure-director \
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

om --target ${OM_HOSTNAME} --skip-ssl-validation \
--username opsman --password ${PCF_PIVNET_UAA_TOKEN} configure-director \
--network-assignment "${NETWORK_ASSIGNMENT_JSON}"

RESOURCE_CONFIGURATION_JSON=$(cat <<-EOF
{
    "compilation": {
    "instances": 8
}
}
EOF
)

om --target ${OM_HOSTNAME} --skip-ssl-validation \
--username opsman --password ${PCF_PIVNET_UAA_TOKEN} configure-director \
--resource-configuration "${RESOURCE_CONFIGURATION_JSON}"

om --target ${OM_HOSTNAME} --skip-ssl-validation \
--username opsman --password ${PCF_PIVNET_UAA_TOKEN} apply-changes 

om --target ${OM_HOSTNAME} --skip-ssl-validation \
--username opsman --password ${PCF_PIVNET_UAA_TOKEN} deployed-products
