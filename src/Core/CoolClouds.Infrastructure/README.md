# CoolClouds.Infrastructure

Everything that talks to Azure. Used by the API and Functions, never by clients.

| Folder | Contents |
| --- | --- |
| `Persistence/` | `CoolCloudsDbContext` (EF Core, Azure SQL), entity configurations, `Migrations/` |
| `Storage/` | Blob containers (`originals`, `thumbnails`, `creations`), SAS URL issuing |
| `Moderation/` | Azure AI Content Safety client, thresholds, writing `ModerationResult` rows |

## EF Core migrations

```bash
dotnet ef migrations add Initial \
  --project src/Core/CoolClouds.Infrastructure \
  --startup-project src/Backend/CoolClouds.Api \
  --output-dir Persistence/Migrations
```

Install the tool once with `dotnet tool install --global dotnet-ef`.
