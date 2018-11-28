#!/usr/bin/env bash

function retryop()
{
  retry=0
  max_retries=10
  interval=30
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

echo "Installing jq"
retryop "apt-get update && apt-get install -y jq"

function get_setting() {
  key=$1
  local value=$(echo $settings | jq ".$key" -r)
  echo $value
}

custom_data_file="/var/lib/cloud/instance/user-data.txt"
settings=$(cat ${custom_data_file})
client_id=$(get_setting AZURE_CLIENT_ID)
client_secret=$(get_setting AZURE_CLIENT_SECRET)
username=$(get_setting ADMIN_USERNAME)
subscription=$(get_setting AZURE_SUBSCRIPTION_ID)
tenant=$(get_setting AZURE_TENANT_ID)
home_dir="/home/${username}"

cat << EOF > ${home_dir}/.env.sh
#!/bin/bash
ADMIN_USERNAME=${username}
AZURE_CLIENT_SECRET=${client_secret}
AZURE_CLIENT_ID=${client_id}
AZURE_TENANT_ID=${tenant}
AZURE_SUBSCRIPTION_ID=${subscription}
EOF
chmod 600 ${home_dir}/.env.sh
chown ${username}.${username} ${home_dir}/.env.sh

cp * ${home_dir}

sudo apt-get install apt-transport-https lsb-release software-properties-common -y
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv \
     --keyserver packages.microsoft.com \
     --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF

sudo apt-get update

sudo apt-get install azure-cli && sudo apt --yes install unzip && sudo apt --yes install jq

wget -O terraform.zip https://releases.hashicorp.com/terraform/0.11.8/terraform_0.11.8_linux_amd64.zip && \
  unzip terraform.zip && \
  sudo mv terraform /usr/local/bin

wget -O om https://github.com/pivotal-cf/om/releases/download/0.44.0/om-linux && \
  chmod +x om && \
  sudo mv om /usr/local/bin/

wget -O bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-5.3.1-linux-amd64 && \
  chmod +x bosh && \
  sudo mv bosh /usr/local/bin/

wget -O /tmp/bbr.tar https://github.com/cloudfoundry-incubator/bosh-backup-and-restore/releases/download/v1.2.8/bbr-1.2.8.tar && \
  tar xvC /tmp/ -f /tmp/bbr.tar && \
  sudo mv /tmp/releases/bbr /usr/local/bin/
  