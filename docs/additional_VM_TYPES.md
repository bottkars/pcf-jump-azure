# Adding Custom VM Types

Notes:
$HOME/om_pcf.env reflects your env file for opsman in format

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

create a list of vm types to be used using az vm list-sizes with query

```bash
F_TYPES=$(az vm list-sizes --location westus2 --query "[?contains(name,'Standard_F')]" | jq .[])
D_TYPES=$(az vm list-sizes --location westus2 --query "[?contains(name,'Standard_D')] | [?contains(name,'_v3')]" | jq .[])
(echo $D_TYPES $F_TYPES) | jq -s
```
delete previous custom types

```bash
om \
   --env $HOME/om_pcf.env \
   curl --path /api/v0/vm_types \
   --request DELETE
```

insert new custom vm types

```bash
om \
   --env $HOME/om_pcf.env \
   curl --path /api/v0/vm_types \
   --request PUT \
--data $(echo $D_TYPES $F_TYPES |  \
jq -sc '{"vm_types": [.[] | {"name": .name, "ram": .memoryInMb, "ephemeral_disk": .resourceDiskSizeInMb, "cpu": .numberOfCores}]}')

```

view the new types:

```bash
om --env $HOME/om_pcf.env  curl --path /api/v0/vm_types --request GET
```