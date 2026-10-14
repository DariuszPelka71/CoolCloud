param location string
param serverName string
param databaseName string
param adminLogin string

@secure()
param adminPassword string

param tags object

resource server 'Microsoft.Sql/servers@2021-11-01' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    minimalTlsVersion: '1.2'
  }
}

// Lets Azure services (App Service, Functions) reach the server.
resource allowAzure 'Microsoft.Sql/servers/firewallRules@2021-11-01' = {
  parent: server
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource database 'Microsoft.Sql/servers/databases@2021-11-01' = {
  parent: server
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

output fqdn string = server.properties.fullyQualifiedDomainName
