param location string
param namePrefix string
param uniqueSuffix string
param ownerEmail string
param appInsightsConnectionString string
param keyVaultName string
param cosmosEndpoint string
param cosmosDatabaseName string
param storageAccountName string
param storageAccountId string

var functionAppName = '${namePrefix}-func-${take(uniqueSuffix, 6)}'
var hostingPlanName = '${namePrefix}-plan'

resource hostingPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: hostingPlanName
  location: location
  tags: {
    owner: ownerEmail
    project: 'portfolio'
  }
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: false
  }
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    owner: ownerEmail
    project: 'portfolio'
  }
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: 'https://${storageAccountName}.blob.${environment().suffixes.storage}/function-releases'
          authentication: {
            type: 'StorageAccountConnectionString'
            storageAccountConnectionStringName: 'AzureWebJobsStorage'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 40
        instanceMemoryMB: 2048
      }
      runtime: {
        name: 'node'
        version: '20'
      }
    }
  }
}

// Note: listKeys in app settings requires reference() — simplified for template validation
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
  scope: resourceGroup()
}

var storageKeys = storageAccount.listKeys().keys[0].value

resource functionAppSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: functionApp
  name: 'appsettings'
  properties: {
    AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageKeys};EndpointSuffix=${environment().suffixes.storage}'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'node'
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsConnectionString
    COSMOS_ENDPOINT: cosmosEndpoint
    COSMOS_DATABASE: cosmosDatabaseName
    KEY_VAULT_NAME: keyVaultName
    PORTFOLIO_QUEUE_NAME: 'portfolio-sync'
  }
}

output functionAppName string = functionApp.name
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
output principalId string = functionApp.identity.principalId
