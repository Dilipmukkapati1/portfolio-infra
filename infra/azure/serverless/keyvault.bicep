param location string
param namePrefix string
param uniqueSuffix string
param ownerEmail string

@description('Enable purge protection in prod')
param enablePurgeProtection bool = false

var keyVaultName = take('${namePrefix}-kv-${uniqueSuffix}', 24)

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: {
    owner: ownerEmail
    project: 'portfolio'
  }
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: enablePurgeProtection
  }
}

output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
