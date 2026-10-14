# Infrastructure (Bicep)

Deploys the Azure resources for one environment.

```bash
az login
az group create -n rg-coolclouds-dev -l polandcentral
az deployment group create -g rg-coolclouds-dev \
  -f infra/main.bicep -p environmentName=dev sqlAdminPassword='<strong password>'
```

| Module | Resources |
| --- | --- |
| `modules/monitoring.bicep` | Log Analytics workspace, Application Insights |
| `modules/storage.bicep` | Storage account + `originals`, `thumbnails`, `creations` containers |
| `modules/sql.bicep` | Azure SQL server + database |
| `modules/appservice.bicep` | App Service plan + API web app |

Still to add as the project grows: Function App, Content Safety, Service Bus,
Notification Hubs, Front Door/CDN, Key Vault.
