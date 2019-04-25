# Adding Custom VM Types

## Create a OM Env file :
$HOME/om_pcf.env reflects your env file for opsman in format:

```yaml
target: https://opsmanfqdn
connect-timeout: 30          # default 5
request-timeout: 1800        # default 1800
skip-ssl-validation: true   # default false
# client-id: myclient # use client/secret or username/password
# client-secret: Password123!
username: opsman
password: Password123!
# decryption-passphrase:
```

## Create VM Lists from your Azure region

create a list of vm types to be used using az vm list-sizes with query (JMESpath does not allow a multi filter expression, so pultiple calls and piped filters ) 
Make sure to target your Region

```bash
F_TYPES=$(az vm list-sizes --location westus2 --query "[?contains(name,'Standard_F')]" | jq .[])
DSV2_TYPES=$(az vm list-sizes --location westus2 --query "[?contains(name,'Standard_DS')] | [?contains(name,'_v2')]" | jq .[])
DSV3_TYPES=$(az vm list-sizes --location westus2 --query "[?contains(name,'Standard_D')] | [?contains(name,'s_v3')]" | jq .[])
```
## get and store existing vm types from OPSMAN
get current vm Types:

```
EXISTING_TYPES=$(om --env $HOME/om_pcf.env \
curl --path /api/v0/vm_types  \
--request GET | jq .vm_types[])
```


## delete previous custom types from opsman

```bash
om \
   --env $HOME/om_pcf.env \
   curl --path /api/v0/vm_types \
   --request DELETE
```

## insert new custom vm types 
... and eventuallay add EXISTING_TYPES if needed

```bash
om \
   --env $HOME/om_pcf.env \
   curl --path /api/v0/vm_types \
   --request PUT \
--data $(echo $DSV2_TYPES $DSV3_TYPES $F_TYPES |  \
jq -sc '{"vm_types": [.[] | {"name": .name, "ram": .memoryInMb, "ephemeral_disk": .resourceDiskSizeInMb, "cpu": .numberOfCores}]}')

```

## view the new types:

```bash
om --env $HOME/om_pcf.env  curl --path /api/v0/vm_types --request GET
```
## Notes: 
You may want to use Isolation Segements / Tile Replication to create new instances of Availability Sets with NEW vm Types

### Example: replicate pas win:
```
./replicator-linux --name "PASWin2" --path injectded --output injected-1
om --env om_pcf.env upload-product  --product ./injected-1
```
configure the new tile to use new vm Types
