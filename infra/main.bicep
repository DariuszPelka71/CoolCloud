targetScope = 'resourceGroup'

@description('Short environment name, e.g. dev, test, prod.')
param environmentName string

param location string = resourceGroup().location

param sqlAdminLogin string = 'coolcloudsadmin'

@secure()
param sqlAdminPassword string

var suffix = uniqueString(resourceGroup().id, environmentName)
var tags = {
  app: 'coolclouds'
  env: environmentName
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    name: 'coolclouds-${environmentName}'
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    name: 'stcc${environmentName}${take(suffix, 8)}'
    tags: tags
  }
}

module sql 'modules/sql.bicep' = {
  name: 'sql'
  params: {
    location: location
    serverName: 'sql-coolclouds-${environmentName}-${take(suffix, 6)}'
    databaseName: 'coolclouds'
    adminLogin: sqlAdminLogin
    adminPassword: sqlAdminPassword
    tags: tags
  }
}

module api 'modules/appservice.bicep' = {
  name: 'api'
  params: {
    location: location
    planName: 'plan-coolclouds-${environmentName}'
    appName: 'app-coolclouds-api-${environmentName}-${take(suffix, 6)}'
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    tags: tags
  }
}

output apiUrl string = api.outputs.url
output storageAccountName string = storage.outputs.name
output sqlServerFqdn string = sql.outputs.fqdn
