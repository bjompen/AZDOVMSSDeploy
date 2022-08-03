@description('The name of the vnet.')
param name string

@description('The location for resources.')
param location string = resourceGroup().location

param addressPrefixes array = [
  '10.1.0.0/16'
]

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [
      {
        name: '${name}-subnet'
        properties: {
          addressPrefix: '10.1.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: '${name}-nsg'
  location: location
}

// Declairing subnet as resource prevents it from beeing re-deployable! 
// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/scenarios-virtual-networks#configure-subnets-by-using-the-subnets-property

output subnetId string = vnet.properties.subnets[0].id
