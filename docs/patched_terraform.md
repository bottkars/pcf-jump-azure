

cd ./pivotal-cf-terraforming-azure-*/
cd terraforming-pas


PATCH_SERVER="https://raw.githubusercontent.com/bottkars/pcf-jump-azure/testing/patches/"
wget -q ${PATCH_SERVER}modules/pas/dns.tf -O ../modules/pas/dns.tf
wget -q ${PATCH_SERVER}modules/pas/istiolb.tf -O ../modules/pas/istiolb.tf
wget -q ${PATCH_SERVER}modules/pas/outputs.tf -O ../modules/pas/outputs.tf
terraform apply -target=azurerm_subnet.lb_services --auto-approve

