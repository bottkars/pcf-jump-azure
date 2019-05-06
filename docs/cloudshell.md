```bash
gcloud dns --project=pa-kbott record-sets transaction start --zone=labbuildr

gcloud dns --project=pa-kbott record-sets transaction add \
ns1-07.azure-dns.com. \
ns2-07.azure-dns.net. \
ns3-07.azure-dns.org. \
ns4-07.azure-dns.info. \
ns1-03.azure-dns.com. \
ns2-03.azure-dns.net. \
ns3-03.azure-dns.org. \
ns4-03.azure-dns.info. \
ns1-09.azure-dns.com. \
ns2-09.azure-dns.net. \
ns3-09.azure-dns.org. \
ns4-09.azure-dns.info. \
ns4-01.azure-dns.info. \
ns4-02.azure-dns.info. \
ns4-04.azure-dns.info. \
ns4-05.azure-dns.info. \
ns4-06.azure-dns.info. \
ns4-08.azure-dns.info. \
ns4-10.azure-dns.info. \
ns1-01.azure-dns.com. \
ns1-02.azure-dns.com. \
ns1-04.azure-dns.com. \
ns1-05.azure-dns.com. \
ns1-06.azure-dns.com. \
ns1-08.azure-dns.com. \
ns1-10.azure-dns.com. \
ns2-01.azure-dns.net. \
ns2-02.azure-dns.net. \
ns2-04.azure-dns.net. \
ns2-06.azure-dns.net. \
ns2-05.azure-dns.net. \
ns2-08.azure-dns.net. \
ns2-10.azure-dns.net. \
ns3-01.azure-dns.org. \
ns3-02.azure-dns.org. \
ns3-04.azure-dns.org. \
ns3-05.azure-dns.org. \
ns3-06.azure-dns.org. \
ns3-08.azure-dns.org. \
ns3-10.azure-dns.org. \
 --name=pcfgitazure.labbuildr.com. --ttl=300 --type=NS --zone=labbuildr

gcloud dns --project=pa-kbott record-sets transaction execute --zone=labbuildr
```
