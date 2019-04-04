

cd ./pivotal-cf-terraforming-azure-*/
cd terraforming-pas


PATCH_SERVER="https://raw.githubusercontent.com/bottkars/pcf-jump-azure/master/patches/"
wget -q ${PATCH_SERVER}modules/pas/dns.tf -O ../modules/pas/dns.tf
wget -q ${PATCH_SERVER}modules/pas/istiolb.tf -O ../modules/pas/istiolb.tf
wget -q ${PATCH_SERVER}modules/pas/outputs.tf -O ../modules/pas/outputs.tf
wget -q ${PATCH_SERVER}outputs.tf -O outputs.tf

terraform apply -target=module.pas.azurerm_lb_rule.istio-health-rule  --auto-approve
terraform apply -target=module.pas.azurerm_lb_rule.istio-http-rule  --auto-approve
terraform apply -target=module.pas.azurerm_lb_rule.istio-https-rule  --auto-approve
terraform apply -target=module.pas.azurerm_dns_a_record.istio  --auto-approve


