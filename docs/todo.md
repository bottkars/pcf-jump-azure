#droplets

  cf_storage_account_name              = "${var.cf_storage_account_name}"
  cf_buildpacks_storage_container_name = "${var.cf_buildpacks_storage_container_name}"
  cf_droplets_storage_container_name   = "${var.cf_droplets_storage_container_name}"
  cf_packages_storage_container_name   = "${var.cf_packages_storage_container_name}"
  cf_resources_storage_container_name  = "${var.cf_resources_storage_container_name}"




```

for file in $(find ./ -name '*.yaml')
do
  mv $file $(echo "$file" | sed 's|.yaml|.yml|g')
done
```

dump

{
  "credential": {
    "type": "simple_credentials",
    "value": {
      "identity": "login",
      "password": "YepnFoxwr7fhE3elSgEXISN_raeSYtiA"
    }
  }
}
{
  "credential": {
    "type": "simple_credentials",
    "value": {
      "identity": "login",
      "password": "YepnFoxwr7fhE3elSgEXISN_raeSYtiA"
    }
  }
}


_credentials

{
  "credential": {
    "type": "simple_credentials",
    "value": {
      "identity": "login",
      "password": "YepnFoxwr7fhE3elSgEXISN_raeSYtiA"
    }
  }
}


pivnet download-product-files --product-slug='stemcells-ubuntu-xenial' --release-version='250.95' --product-file-id=469503