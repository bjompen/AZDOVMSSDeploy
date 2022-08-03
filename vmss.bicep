@description('The name of the VMSS.')
param name string

@description('The location for resources.')
param location string = resourceGroup().location

@description('The nameprefix of the vmss images.')
param vmssNamePrefix string = name

@description('Admin username.')
param adminUsername string = 'vmssadmin'

@description('Public SSH key.')
param sshPubKey string

@description('SubnetID to connect to.')
param subnetId string

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2022-03-01' = {
  name: name
  location: location
  sku: {
    capacity: 0
    name: 'Standard_DS1_v2'
    tier: 'standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    upgradePolicy: {
      mode: 'Manual'
    }
    platformFaultDomainCount: 1
    scaleInPolicy: {
      forceDeletion: true
      rules: [
        'Default'
      ]
    }
    virtualMachineProfile: {
      extensionProfile: {
        extensions: [
          {
            name: 'Microsoft.Azure.DevOps.Pipelines.Agent'
            properties: {
              autoUpgradeMinorVersion: true
              publisher: 'Microsoft.VisualStudio.Services'
              type: 'TeamServicesAgentLinux'
              typeHandlerVersion: '1.22'
              settings: {
                  isPipelinesAgent: true
                  agentFolder: '/agent'
                  agentDownloadUrl: 'https://vstsagentpackage.azureedge.net/agent/2.206.1/vsts-agent-linux-x64-2.206.1.tar.gz'
                  #disable-next-line no-hardcoded-env-urls
                  enableScriptDownloadUrl: 'https://vstsagenttools.blob.core.windows.net/tools/ElasticPools/Linux/13/enableagent.sh'
              }
            }
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
      osProfile: {
        computerNamePrefix: vmssNamePrefix
        adminUsername: adminUsername
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                keyData: sshPubKey
                path: '/home/${adminUsername}/.ssh/authorized_keys'
              }
            ]
          }
        }
      }
      storageProfile: {
        imageReference: {
          publisher: 'canonical'
          offer: '0001-com-ubuntu-server-focal'
          sku: '20_04-lts-gen2'
          version: 'latest'
        }
        osDisk: {
          osType: 'Linux'
          createOption: 'FromImage'
        }
      }
      networkProfile: {
        networkInterfaceConfigurations:[
          {
            name: '${name}-nic01'
            properties: {
              primary: true
              enableAcceleratedNetworking: true 
              ipConfigurations: [
                {
                  name: '${name}ipconfig'
                  properties: {
                    primary: true
                    subnet: {
                      id: subnetId
                    }
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}

output managedIdentity string = vmss.identity.principalId
