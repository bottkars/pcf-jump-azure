#!/usr/bin/env bash
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

START_BASE_DEPLOY_TIME=$(date)
echo ${START_BASE_DEPLOY_TIME} starting base deployment
echo "Installing jq"
retryop "apt-get update && apt-get install -y jq" 10 30

function get_setting() {
  key=$1
  local value=$(echo $settings | jq ".$key" -r)
  echo $value
}

custom_data_file="/var/lib/cloud/instance/user-data.txt"
settings=$(cat ${custom_data_file})
ADMIN_USERNAME=$(get_setting ADMIN_USERNAME)
AZURE_CLIENT_ID=$(get_setting AZURE_CLIENT_ID)
AZURE_CLIENT_SECRET=$(get_setting AZURE_CLIENT_SECRET)
AZURE_SUBSCRIPTION_ID=$(get_setting AZURE_SUBSCRIPTION_ID)
AZURE_TENANT_ID=$(get_setting AZURE_TENANT_ID)
PIVNET_UAA_TOKEN=$(get_setting PIVNET_UAA_TOKEN)
ENV_NAME=$(get_setting ENV_NAME)
ENV_SHORT_NAME=$(get_setting ENV_SHORT_NAME)
OPS_MANAGER_IMAGE_URI=$(get_setting OPS_MANAGER_IMAGE_URI)
LOCATION=$(get_setting LOCATION)
PCF_DOMAIN_NAME=$(get_setting PCF_DOMAIN_NAME)
PCF_SUBDOMAIN_NAME=$(get_setting PCF_SUBDOMAIN_NAME)
PCF_OPSMAN_USERNAME=$(get_setting PCF_OPSMAN_USERNAME)
PCF_NOTIFICATIONS_EMAIL=$(get_setting PCF_NOTIFICATIONS_EMAIL)
PAS_AUTOPILOT=$(get_setting PAS_AUTOPILOT)
PCF_PAS_VERSION=$(get_setting PCF_PAS_VERSION)
NET_16_BIT_MASK=$(get_setting NET_16_BIT_MASK)
DOWNLOAD_DIR="/datadisks/disk1"
SMTP_ADDRESS=$(get_setting SMTP_ADDRESS)
SMTP_IDENTITY=$(get_setting SMTP_IDENTITY)
SMTP_PASSWORD=$(get_setting SMTP_PASSWORD)
SMTP_FROM=$(get_setting SMTP_FROM)
SMTP_PORT=$(get_setting SMTP_PORT)
SMTP_STARTTLS=$(get_setting SMTP_STARTTLS)
USE_SELF_CERTS=$(get_setting USE_SELF_CERTS)
JUMP_RG=$(get_setting JUMP_RG)
JUMP_VNET=$(get_setting JUMP_VNET)
PAS_EDITION=$(get_setting PAS_EDITION)
AVAILABILITY_MODE=$(get_setting AVAILABILITY_MODE)


HOME_DIR="/home/${ADMIN_USERNAME}"
LOG_DIR="${HOME_DIR}/conductor/logs"
SCRIPT_DIR="${HOME_DIR}/conductor/scripts"
LOG_DIR="${HOME_DIR}/conductor/logs"
ENV_DIR="${HOME_DIR}/conductor/env"
TEMPLATE_DIR="${HOME_DIR}/conductor/templates"


sudo -S -u ${ADMIN_USERNAME} mkdir -p ${TEMPLATE_DIR}
sudo -S -u ${ADMIN_USERNAME} mkdir -p ${SCRIPT_DIR}
sudo -S -u ${ADMIN_USERNAME} mkdir -p ${ENV_DIR}
sudo -S -u ${ADMIN_USERNAME} mkdir -p ${LOG_DIR}



cp *.sh ${SCRIPT_DIR}
chown ${ADMIN_USERNAME}.${ADMIN_USERNAME} ${SCRIPT_DIR}/*.sh
chmod 755 ${SCRIPT_DIR}/*.sh
chmod +X ${SCRIPT_DIR}/*.sh

cp *.yaml ${TEMPLATE_DIR}
chown ${ADMIN_USERNAME}.${ADMIN_USERNAME} ${TEMPLATE_DIR}/*.yaml
chmod 755 ${TEMPLATE_DIR}/*.yaml

cp *.env ${ENV_DIR}
chown ${ADMIN_USERNAME}.${ADMIN_USERNAME} ${ENV_DIR}/*.env
chmod 755 ${ENV_DIR}/*.env

${SCRIPT_DIR}/vm-disk-utils-0.1.sh

chown ${ADMIN_USERNAME}.${ADMIN_USERNAME} ${DOWNLOAD_DIR}
chmod -R 755 ${DOWNLOAD_DIR}

if [[ "${PCF_PAS_VERSION}" > "2.4.99" ]] && [[ "${AVAILABILITY_MODE}" == "availability_zones" ]] 
 then
  echo "Applying  Availability Zones Based Config"
  ZONES_LIST="['zone-1', 'zone-2', 'zone-3']"
  ZONES_MAP="[name: 'zone-1', name: 'zone-2', name: 'zone-3']"
  SINGLETON_ZONE="zone-1"
  AVAILABILITY_MODE=availability_zones
  
elif [[ "${PCF_PAS_VERSION}" > "2.4.99" ]] && [[ "${AVAILABILITY_MODE}" == "availability_sets" ]]
  then
  ZONES_LIST="Availability Sets"
  SINGLETON_ZONE="Availability Sets"
  AVAILABILITY_MODE=availability_sets
else
  echo "Applying Availability Sets Based Config"
  ZONES="'null'"
  SINGLETON_ZONE="'null'"
  AVAILABILITY_MODE=availability_sets
fi

$(cat <<-EOF > ${HOME_DIR}/.env.sh
#!/usr/bin/env bash
ADMIN_USERNAME="${ADMIN_USERNAME}"
AZURE_CLIENT_SECRET="${AZURE_CLIENT_SECRET}"
AZURE_CLIENT_ID="${AZURE_CLIENT_ID}"
AZURE_TENANT_ID="${AZURE_TENANT_ID}"
AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID}"
PIVNET_UAA_TOKEN="${PIVNET_UAA_TOKEN}"
ENV_NAME="${ENV_NAME}"
ENV_SHORT_NAME="${ENV_SHORT_NAME}"
OPS_MANAGER_IMAGE_URI="${OPS_MANAGER_IMAGE_URI}"
LOCATION="${LOCATION}"
PCF_DOMAIN_NAME="${PCF_DOMAIN_NAME}"
PCF_SUBDOMAIN_NAME="${PCF_SUBDOMAIN_NAME}"
HOME_DIR="${HOME_DIR}"
PCF_OPSMAN_USERNAME="${PCF_OPSMAN_USERNAME}"
PCF_NOTIFICATIONS_EMAIL="${PCF_NOTIFICATIONS_EMAIL}"
PAS_AUTOPILOT="${PAS_AUTOPILOT}"
PCF_PAS_VERSION="${PCF_PAS_VERSION}"
NET_16_BIT_MASK="${NET_16_BIT_MASK}"
DOWNLOAD_DIR="${DOWNLOAD_DIR}"
SMTP_ADDRESS="${SMTP_ADDRESS}"
SMTP_IDENTITY="${SMTP_IDENTITY}"
SMTP_PASSWORD="${SMTP_PASSWORD}"
SMTP_FROM="${SMTP_FROM}"
SMTP_PORT="${SMTP_PORT}"
SMTP_STARTTLS="${SMTP_STARTTLS}"
PAS_EDITION="${PAS_EDITION}"
USE_SELF_CERTS="${USE_SELF_CERTS}"
LOG_DIR=${LOG_DIR}
ENV_DIR=${ENV_DIR}
SCRIPT_DIR=${SCRIPT_DIR}
TEMPLATE_DIR=${TEMPLATE_DIR}
JUMP_RG=${JUMP_RG}
JUMP_VNET=${JUMP_VNET}
ZONES_LIST="${ZONES_LIST}"
ZONES_MAP="${ZONES_MAP}"
SINGLETON_ZONE=${SINGLETON_ZONE}
AVAILABILITY_MODE=${AVAILABILITY_MODE}
EOF
)
chmod 600 ${HOME_DIR}/.env.sh
chown ${ADMIN_USERNAME}.${ADMIN_USERNAME} ${HOME_DIR}/.env.sh

sudo apt-get install apt-transport-https lsb-release software-properties-common -y
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv \
     --keyserver packages.microsoft.com \
     --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF

sudo apt install software-properties-common 
sudo add-apt-repository ppa:tmate.io/archive --yes
sudo apt update

retryop "sudo apt -y install azure-cli unzip tmate" 10 30


retryop "sudo apt -y install ruby ruby-dev gcc build-essential g++" 10 30
sudo gem install cf-uaac

wget -O terraform.zip https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip && \
  unzip terraform.zip && \
  sudo mv terraform /usr/local/bin

wget -O om https://github.com/pivotal-cf/om/releases/download/1.1.0/om-linux && \
  chmod +x om && \
  sudo mv om /usr/local/bin/

wget -O bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-5.5.0-linux-amd64 && \
  chmod +x bosh && \
  sudo mv bosh /usr/local/bin/

wget -O /tmp/bbr https://github.com/cloudfoundry-incubator/bosh-backup-and-restore/releases/download/v1.4.0/bbr-1.4.0-linux-amd64 && \
    chmod +x bbr && \
  sudo mv /tmp/bbr /usr/local/bin/
# get pivnet UAA TOKEN

cd ${HOME_DIR}
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


END_BASE_DEPLOY_TIME=$(date)
echo ${END_BASE_DEPLOY_TIME} end base deployment
$(cat <<-EOF >> ${HOME_DIR}/.env.sh
EOF
)
echo "Base install finished, now initializing opsman, see logfiles in ${LOG_DIR}"
su ${ADMIN_USERNAME} -c "nohup ${SCRIPT_DIR}/om_init.sh ${HOME_DIR} >/dev/null 2>&1 &"
