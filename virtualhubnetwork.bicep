@description('Name for the vnet to be created')
param vnetname string = 'hub-vnet'

@description('Name of the Network Security Group')
param nsgname string = 'hub-nsg'

@description('Addressspaces for the vnet to be created')
param addressprefixes array = [
  '10.0.0.0/16'
]

@description('Subnet CIDR for Azure Firewall')
param snfirewallprefix string = '10.0.0.0/24'

@description('Subnet CIDR for the Bastian Host')
param snbastionprefix string = '10.0.1.0/24'

@description('Subnet CIDR for Demo VM')
param sndemoprefix string = '10.0.2.0/24'

@description('Location variable')
var location = resourceGroup().location

@description('Network Securtiy Group to be added to the subnets')
resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: nsgname
  location: location
  properties: {
    securityRules: [

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
          name: 'AzureFirewallSubnet'
          properties: {
            addressPrefix: snfirewallprefix
          }
        }
        {
          name: 'AzureBastionSubnet' 
          properties: {
            addressPrefix: snbastionprefix
          }
        }
        {
          name: 'DemoSubnet' 
          properties: {
            addressPrefix: sndemoprefix
            networkSecurityGroup: {
              id: nsg.id
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
output snetFirewallId string = vnet.properties.subnets[0].id

@description('Subnet for Azure Bastion')
output snetBastionId string = vnet.properties.subnets[1].id

@description('Subnet to be used by DNS Servers')
output snetDemoId string = vnet.properties.subnets[2].id
