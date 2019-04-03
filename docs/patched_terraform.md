

cd ./pivotal-cf-terraforming-azure-*/
cd terraforming-pas


PATCH_SERVER="https://raw.githubusercontent.com/bottkars/pcf-jump-azure/testing/patches/"
wget -q ${PATCH_SERVER}modules/pas/dns.tf -O ../modules/pas/dns.tf
wget -q ${PATCH_SERVER}modules/pas/istiolb.tf -O ../modules/pas/istiolb.tf
wget -q ${PATCH_SERVER}modules/pas/outputs.tf -O ../modules/pas/outputs.tf
terraform apply -target=azurerm_subnet.lb_services --auto-approve




terraform apply -target=module.pas.azurerm_dns_a_record.istio

terraform apply -target=module.pas.azurerm_lb_backend_address_pool.istio-backend-pool
terraform apply -target=module.pas.azurerm_lb_probe.istio-http-probe
terraform apply -target=module.pas.azurerm_lb_rule.istio-health-rule
terraform apply -target=module.pas.azurerm_lb_rule.istio-http-rule
terraform apply -target=module.pas.azurerm_lb_rule.istio-https-rule
terraform apply -target=module.pas.azurerm_public_ip.istio-lb-public-ip


