targetScope = 'subscription'

@description('Name for the Resource Group to deploy the sample')
param rgName string 

@description('Location for the sample Resources')
param location string 

@description('DR Location for the sample Resources')
param drlocation string 

@description('Adminusername for all VMs')
param adminUser string = 'azureuser'

@description('Adminpassword for all VMs')
@secure()
param adminPassword string

var hubVnetName = 'hub-vnet'

resource demorg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

resource drdemorg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${rgName}-ASR'
  location: drlocation
}

@description('Module to deploy virtual hub network for the sample environment')
module vnethub 'virtualhubnetwork.bicep' = {
  scope: demorg
  name: 'VirtualHubNetworkDeployment'
  params: {
    vnetname: hubVnetName
  }
}

@description('Module to deploy virtual  network for the Spoke 1 sample environment')
module vnetspoke1 'virtualnetwork.bicep' = {
  scope: demorg
  name: 'VirtualSpoke1NetworkDeployment'
  params: {
    vnetname: 'spoke1-vnet'
    location: location 
  }
}

@description('Module to deploy virtual  network for the Spoke 2 sample environment')
module vnetspoke2 'virtualnetwork.bicep' = {
  scope: drdemorg
  name: 'VirtualSpoke2NetworkDeployment'
  params: {
    vnetname: 'spoke1-vnet-asr'
    addressprefixes: [
      '10.2.0.0/16'
    ]
    sntier1prefix: '10.2.1.0/24'
    sntier2prefix: '10.2.2.0/24'
    location: drlocation 
  }
}

@description('Enable Peerings')
module peeringhub2spoke1 'virtualnetworkpeering.bicep' =  {
  scope: demorg
  name: 'PeeringHub2Spoke1Deployment'
  params: {
    peeringName: 'PeeringHub2Spoke1'
    localVirtualNetworkName: vnethub.outputs.vnetName
    remoteVirtualNetworkId: vnetspoke1.outputs.vnet
  }
}
module peeringhub2spoke2 'virtualnetworkpeering.bicep' =  {
  scope: demorg
  name: 'PeeringHub2Spoke2Deployment'
  params: {
    peeringName: 'PeeringHub2Spoke2'
    localVirtualNetworkName: vnethub.outputs.vnetName
    remoteVirtualNetworkId: vnetspoke2.outputs.vnet
  }
}
module peeringspoke1hub 'virtualnetworkpeering.bicep' =  {
  scope: demorg
  name: 'PeeringSpoke1HubDeployment'
  params: {
    peeringName: 'PeeringSpoke1Hub'
    localVirtualNetworkName: vnetspoke1.outputs.vnetName
    remoteVirtualNetworkId: vnethub.outputs.vnet
  }
}
module peeringspoke2hub 'virtualnetworkpeering.bicep' =  {
  scope: drdemorg
  name: 'PeeringSpoke2HubDeployment'
  params: {
    peeringName: 'PeeringSpoke2Hub'
    localVirtualNetworkName: vnetspoke2.outputs.vnetName
    remoteVirtualNetworkId: vnethub.outputs.vnet
  }
}

@description('Module to deploy Azure Bastion to connect to the VMs')
module bastion 'bastion.bicep' =  {
  scope: demorg
  name: 'BastionDeployment'
  params: {
    subnetId: vnethub.outputs.snetBastionId
  }
}


@description('Public IP for the Azure Firewall')
module firewallpip 'publicip.bicep' =  {
  scope: demorg
  name: 'FirewallPiPDeployment'
  params: {
    location: location
    name: 'az-firewall-pip'
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    zones: [
      1
      2
      3
    ]
  }
}

@description('Module to deploy Azure Firewall')
module firewall 'azurefirewall.bicep' =  {
  scope: demorg
  name: 'FirewallDeployment'
  params: {
    name: 'az-firewall'
    location: location
    ipConfigurations: [
      {
        name: 'ipConfig1'
        publicIPAddressResourceId: firewallpip.outputs.resourceId
        subnetResourceId: vnethub.outputs.snetFirewallId 
      }
    ]
    networkRuleCollections: [
      {
        name: 'allowAll'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'netRule1'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '10.0.0.0/14'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '*'
              ]
            }
          ]
        }
      }
    ]
  }
}


@description('Module to deploy the VMs')
module vmdemo'virtualmachine.bicep' =  {
  scope: demorg
  dependsOn: [
    firewall
  ]
  name: 'VMDemoHubDeployment'
  params: {
    vmName: 'vm-demo'
    adminUser: adminUser
    adminPassword: adminPassword
    subnetId: vnethub.outputs.snetDemoId
    privateIPAddress: '10.0.2.10'
  }
}


@description('Module to deploy the VMs')
module vm1 'virtualmachine.bicep' =  {
  scope: demorg
  dependsOn: [
    firewall
    peeringhub2spoke1
    peeringspoke1hub
  ]
  name: 'VM1Spoke1Deployment'
  params: {
    vmName: 'vm1'
    adminUser: adminUser
    adminPassword: adminPassword
    subnetId: vnetspoke1.outputs.snetTier1Id
    privateIPAddress: '10.1.1.11'
  }
}

@description('Module to deploy the VMs')
module vm2 'virtualmachine.bicep' =  {
  scope: demorg
  dependsOn: [
    firewall
    peeringhub2spoke1
    peeringspoke1hub
  ]
  name: 'VM2Spoke1Deployment'
  params: {
    vmName: 'vm2'
    adminUser: adminUser
    adminPassword: adminPassword
    subnetId: vnetspoke1.outputs.snetTier1Id
    privateIPAddress: '10.1.1.12'
  }
}

@description('Module to deploy the VMs')
module vm3 'virtualmachine.bicep' =  {
  scope: demorg
  dependsOn: [
    firewall
    peeringhub2spoke1
    peeringspoke1hub
  ]
  name: 'VM3Spoke1Deployment'
  params: {
    vmName: 'vm3'
    adminUser: adminUser
    adminPassword: adminPassword
    subnetId: vnetspoke1.outputs.snetTier2Id
    privateIPAddress: '10.1.2.11'
  }
}

@description('Module to deploy the VMs')
module vm4 'virtualmachine.bicep' =  {
  scope: demorg
  dependsOn: [
    firewall
    peeringhub2spoke1
    peeringspoke1hub
  ]

  name: 'VM4Spoke1Deployment'
  params: {
    vmName: 'vm4'
    adminUser: adminUser
    adminPassword: adminPassword
    subnetId: vnetspoke1.outputs.snetTier2Id
    privateIPAddress: '10.1.2.12'
  }
}

@description('Module to deploy the Recovery Service Vault')
module asr 'recoveryservicesvault.bicep' =  {
  scope: drdemorg
  name: 'RSVDeployment'
  params: {
    name: 'demo-vault'
    location: drlocation
  }
}

