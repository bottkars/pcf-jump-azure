```yaml
  .properties.credhub_key_encryption_passwords:
    value:
    - name: default
      provider: internal
      key:
        secret: ((pcf_credhub_key))
      primary: true
```

```yaml
  .properties.credhub_internal_provider_keys:
    value:
    - name: default
      key:
       secret: ((pcf_credhub_key))
      primary:
        value: true
```
