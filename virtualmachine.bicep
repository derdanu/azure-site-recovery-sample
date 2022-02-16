@description('Name of the  VM')
param vmName string = 'vm'

@description('Admin username')
param adminUser string

@description('Admin password')
@secure()
param adminPassword string

@description('VM IP')
param privateIPAddress string

@description('The size of the VM')
param vmSize string = 'Standard_B2s'

@description('The subnet to assign the dnsserver to.')
param subnetId string

@description('Name for the NIC')
var networkInterfaceName = 'nic-${vmName}'

@description('Location Variable')
var location = resourceGroup().location

@description('Type for the OS Disk')
var osDiskType = 'Standard_LRS'


@description('VMs NIC')
resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAddress: privateIPAddress
          privateIPAllocationMethod: 'Static'
        }
      }
    ]
  }
}

@description('Resolver VM to showcase the different resolution behaviours')
resource forwardervm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUser
      adminPassword: adminPassword
      customData: loadFileAsBase64('cloud-init.yaml')
    }
  }
}

