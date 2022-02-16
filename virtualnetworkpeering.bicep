param localVirtualNetworkName string
param remoteVirtualNetworkId string
param peeringName string

resource hubspoke1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: '${localVirtualNetworkName}/${peeringName}'
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: remoteVirtualNetworkId
    }
    useRemoteGateways: false
  }
}

