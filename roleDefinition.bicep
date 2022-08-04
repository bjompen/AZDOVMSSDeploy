param principalId string

resource Contributor 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(subscription().id, principalId)
  properties: {
    roleDefinitionId: Contributor.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
