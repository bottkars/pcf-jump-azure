#!/bin/bash

AZ_SUBSCRIPTION=b57a203e-adf0-4ceb-96a6-bfb05928bb20


az cloud set --name AzureCloud 

az login
az group create --name pcf-jumpnet --location westeurope


VM=$(az vm create   \
--resource-group pcf-jumpnet   \
--name jumpbox   \
--image UbuntuLTS   \
--admin-username ubuntu   \
--data-disk-sizes-gb 200   \
--generate-ssh-keys   \
--vnet-address-prefix 10.30.0/16 \
--subnet-address-prefix 10.30.0.0/16 \
--private-ip-address 10.30.0.10 )


ssh ubuntu@'az vm list-ip-addresses \
               -n jumpbox \
               --query [0].virtualMachine.network.publicIpAddresses[0].ipAddress \
               -o tsv'
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
  



az account set --subscription "${AZ_SUBSCRIPTION}"



  
az-automation \
  --account pcf-azure \
  --identifier-uri http://pcf.pcfazure.labbuildr.com \
  --display-name pcf-azure \
  --credential-output-file pcf-azure.tfvars