param name string
param location string

resource rsv 'Microsoft.RecoveryServices/vaults@2016-06-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}
}
