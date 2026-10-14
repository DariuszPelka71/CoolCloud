param location string

@maxLength(24)
param name string

param tags object

resource account 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: account
  name: 'default'
}

// Originals, thumbnails and composited creations. All private: clients get SAS URLs or go through the CDN.
resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [for c in ['originals', 'thumbnails', 'creations']: {
  parent: blobService
  name: c
  properties: { publicAccess: 'None' }
}]

output name string = account.name
