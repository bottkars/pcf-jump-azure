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

METADATA=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2017-08-01")
custom_data_file="/var/lib/cloud/instance/user-data.txt"
settings=$(cat ${custom_data_file})
AZURE_VAULT=$(get_setting AZURE_VAULT)
ADMIN_USERNAME=$(get_setting ADMIN_USERNAME)
AZURE_SUBSCRIPTION_ID=$(echo $METADATA | jq -r .subscriptionId)
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

cp *.yml ${TEMPLATE_DIR}
chown ${ADMIN_USERNAME}.${ADMIN_USERNAME} ${TEMPLATE_DIR}/*.yml
chmod 755 ${TEMPLATE_DIR}/*.yml

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
AZURE_VAULT=${AZURE_VAULT}
ADMIN_USERNAME="${ADMIN_USERNAME}"
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
# ...first add the Cloud Foundry Foundation public key and package repository to your system
wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
echo "deb https://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
sudo wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | sudo  apt-key add -
sudo echo "deb http://apt.starkandwayne.com stable main" | sudo  tee /etc/apt/sources.list.d/starkandwayne.list
# ...then, update your local package index, then finally install the cf CLI
sudo apt update

retryop "sudo apt -y install azure-cli unzip tmate cf-cli om" 10 30


retryop "sudo apt -y install ruby ruby-dev gcc build-essential g++" 10 30
sudo gem install cf-uaac

wget -O terraform.zip https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip && \
  unzip terraform.zip && \
  sudo mv terraform /usr/local/bin



wget -O bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-6.0.0-linux-amd64 && \
  chmod +x bosh && \
  sudo mv bosh /usr/local/bin/

wget -O /tmp/bbr https://github.com/cloudfoundry-incubator/bosh-backup-and-restore/releases/download/v1.5.2/bbr-1.5.2-linux-amd64 && \
    chmod +x /tmp/bbr && \
  sudo mv /tmp/bbr /usr/local/bin/
# get pivnet UAA TOKEN

cd ${HOME_DIR}

$(cat <<-EOF >> ${HOME_DIR}/.env.sh
EOF
)
echo "Base install finished, now initializing opsman, see logfiles in ${LOG_DIR}"
su ${ADMIN_USERNAME} -c "nohup ${SCRIPT_DIR}/om_init.sh ${HOME_DIR} >/dev/null 2>&1 &"
