@description('Name for the vnet to be created')
param vnetname string = 'spoke-vnet'

@description('Name of the Network Security Group')
param nsgname string = 'spoke-nsg-${location}'

@description('Name of the Network Security Group')
param udrname string = 'spoke-udr-${location}'

@description('Addressspaces for the vnet to be created')
param addressprefixes array = [
  '10.1.0.0/16'
]

@description('Subnet CIDR for Tier 1 Workloads')
param sntier1prefix string = '10.1.1.0/24'

@description('Subnet CIDR for Tier 2 Workloads')
param sntier2prefix string = '10.1.2.0/24'

@description('Location variable')
param location string = 'westeurope'

@description('Network Securtiy Group to be added to the subnets')
resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: nsgname
  location: location
  properties: {
    securityRules: [

    ]
  }
}

resource udr 'Microsoft.Network/routeTables@2021-05-01' = {
  name: udrname
  location: location
  properties: {
    routes: [
      {
        name: 'force_to_firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: '10.0.0.4'
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

@description('Virtual network for sample environment')
resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: vnetname
  location: location
  properties: {
      addressSpace: {
        addressPrefixes: addressprefixes
      }
      subnets: [
        {
          name: 'Tier1Subnet' 
          properties: {
            addressPrefix: sntier1prefix
            networkSecurityGroup: {
              id: nsg.id
            }
            routeTable: {
              id: udr.id 
            }
          }
        }
        {
          name: 'Tier2Subnet' 
          properties: {
            addressPrefix: sntier2prefix
            networkSecurityGroup: {
              id: nsg.id
            } 
            routeTable: {
              id: udr.id 
            }
          }
        }
      ]
  }
}

@description('Output vnet Name to be used by other modules')
output vnetName string = vnet.name

@description('Output vnet ID to be used by other modules')
output vnet string = vnet.id

@description('Subnet for the Resolver VM')
output snetTier1Id string = vnet.properties.subnets[0].id

@description('Subnet for Azure Bastion')
output snetTier2Id string = vnet.properties.subnets[1].id

