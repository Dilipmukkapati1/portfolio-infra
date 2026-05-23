param location string
param namePrefix string
param uniqueSuffix string
param enableFreeTier bool
param ownerEmail string

var accountName = take('${namePrefix}cosmos${uniqueSuffix}', 44)
var databaseName = 'portfolio'

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: accountName
  location: location
  tags: {
    owner: ownerEmail
    project: 'portfolio'
  }
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    enableFreeTier: enableFreeTier
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmosAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

var containers = [
  'households'
  'members'
  'accounts'
  'transactions'
  'holdings'
  'taxProfiles'
  'scenarios'
  'projectionRuns'
  'integrationTokens'
  'syncState'
  'webhookEvents'
]

resource containerResources 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = [for name in containers: {
  parent: database
  name: name
  properties: {
    resource: {
      id: name
      partitionKey: {
        paths: ['/householdId']
        kind: 'Hash'
      }
    }
  }
}]

output accountName string = cosmosAccount.name
output accountId string = cosmosAccount.id
output endpoint string = cosmosAccount.properties.documentEndpoint
output databaseName string = databaseName
