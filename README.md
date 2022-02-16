# azure-site-recovery-sample
## Deployment
``az deployment sub create --location westeurope --template-file main.bicep --parameters @parameters.json
``
## Resources
| Name | Vnet | Subnet | IP |
| ---- | ---- | ------ | -- |
| Demo VM | hub-vnet | DemoSubnet | 10.0.2.10 |
| VM1 | spoke1-vnet | Tier1Subnet | 10.1.1.11 |
| VM2 | spoke1-vnet | Tier1Subnet | 10.1.1.12 |
| VM3 | spoke1-vnet | Tier2Subnet | 10.1.2.11 |
| VM4 | spoke1-vnet | Tier2Subnet | 10.1.2.12 |