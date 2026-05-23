param location string
param namePrefix string
param uniqueSuffix string
param ownerEmail string
param apiUrl string

var swaName = '${namePrefix}-web-${take(uniqueSuffix, 6)}'

resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' = {
  name: swaName
  location: location
  tags: {
    owner: ownerEmail
    project: 'portfolio'
  }
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    repositoryUrl: ''
    branch: ''
    buildProperties: {
      appLocation: '/'
      apiLocation: ''
      outputLocation: 'out'
    }
  }
}

output staticWebAppName string = staticWebApp.name
output defaultHostname string = staticWebApp.properties.defaultHostname
