@description('Environment name: dev or prod')
param environmentName string

@description('Owner email for resource tags')
param ownerEmail string = 'owner@example.com'

@description('Azure region')
param location string = resourceGroup().location

@description('Enable Cosmos DB free tier (lifetime, one per subscription)')
param cosmosEnableFreeTier bool = true

var namePrefix = 'pf-${environmentName}'
var uniqueSuffix = uniqueString(resourceGroup().id)

module appInsights 'appinsights.bicep' = {
  name: 'appinsights'
  params: {
    location: location
    namePrefix: namePrefix
    ownerEmail: ownerEmail
  }
}

module keyVault 'keyvault.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    namePrefix: namePrefix
    uniqueSuffix: uniqueSuffix
    ownerEmail: ownerEmail
  }
}

module cosmos 'cosmos.bicep' = {
  name: 'cosmos'
  params: {
    location: location
    namePrefix: namePrefix
    uniqueSuffix: uniqueSuffix
    enableFreeTier: cosmosEnableFreeTier
    ownerEmail: ownerEmail
  }
}

module storage 'storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    namePrefix: namePrefix
    uniqueSuffix: uniqueSuffix
    ownerEmail: ownerEmail
  }
}

module functionApp 'functionapp.bicep' = {
  name: 'functionapp'
  params: {
    location: location
    namePrefix: namePrefix
    uniqueSuffix: uniqueSuffix
    ownerEmail: ownerEmail
    appInsightsConnectionString: appInsights.outputs.connectionString
    keyVaultName: keyVault.outputs.keyVaultName
    cosmosEndpoint: cosmos.outputs.endpoint
    cosmosDatabaseName: cosmos.outputs.databaseName
    storageAccountName: storage.outputs.storageAccountName
    storageAccountId: storage.outputs.storageAccountId
  }
}

module staticWebApp 'staticwebapp.bicep' = {
  name: 'staticwebapp'
  params: {
    location: location
    namePrefix: namePrefix
    uniqueSuffix: uniqueSuffix
    ownerEmail: ownerEmail
    apiUrl: functionApp.outputs.functionAppUrl
  }
}

module batch 'batch.bicep' = {
  name: 'batch'
  params: {
    location: location
    namePrefix: namePrefix
    uniqueSuffix: uniqueSuffix
    ownerEmail: ownerEmail
  }
}

// RBAC: assign Function App MI "Key Vault Secrets User" on KV and Cosmos Data Contributor after deploy.
// See docs/keyvault-secrets.md for az role assignment commands.

output keyVaultName string = keyVault.outputs.keyVaultName
output functionAppPrincipalId string = functionApp.outputs.principalId
output cosmosEndpoint string = cosmos.outputs.endpoint
output functionAppName string = functionApp.outputs.functionAppName
output functionAppUrl string = functionApp.outputs.functionAppUrl
output staticWebAppName string = staticWebApp.outputs.staticWebAppName
output staticWebAppHostname string = staticWebApp.outputs.defaultHostname
output storageAccountName string = storage.outputs.storageAccountName
output batchAccountName string = batch.outputs.batchAccountName
output appInsightsInstrumentationKey string = appInsights.outputs.instrumentationKey
