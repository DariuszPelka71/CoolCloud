# Cool Clouds

Photograph clouds, mark landmarks (eyes, nose, mouth...), and turn them into characters.
iOS + Android (.NET MAUI), Web (Blazor WebAssembly), ASP.NET Core API and Azure Functions on Azure.

- System design: [docs/system-design.md](docs/system-design.md)
- Dev environment setup: [docs/dev-setup.md](docs/dev-setup.md)

## Repository layout

```
CoolCloud/
├─ src/
│  ├─ Aspire/
│  │  ├─ CoolClouds.AppHost          # Starts API, Functions, Azurite, SQL locally + dashboard
│  │  └─ CoolClouds.ServiceDefaults  # Shared telemetry, health checks, resilience
│  ├─ Backend/
│  │  ├─ CoolClouds.Api              # ASP.NET Core Web API (+ server-rendered share pages)
│  │  └─ CoolClouds.Functions        # Azure Functions: thumbnails, moderation, notifications
│  ├─ Core/
│  │  ├─ CoolClouds.Domain           # Entities: User, CloudPhoto, Creation, Rating, ...
│  │  ├─ CoolClouds.Contracts        # DTOs + layer model shared by API and all clients
│  │  ├─ CoolClouds.Infrastructure   # EF Core (Azure SQL), Blob Storage, Content Safety
│  │  └─ CoolClouds.Rendering        # SkiaSharp compositing, shared by mobile/web/backend
│  └─ Clients/
│     ├─ CoolClouds.ApiClient        # Typed HTTP client used by Mobile and Web
│     ├─ CoolClouds.Mobile           # .NET MAUI app (iOS, Android, Windows for testing)
│     └─ CoolClouds.Web              # Blazor WebAssembly app
├─ tests/
│  ├─ CoolClouds.Domain.Tests
│  └─ CoolClouds.Api.Tests
├─ database/                         # Seed data and database notes (migrations live in Infrastructure)
├─ infra/                            # Azure infrastructure as code (Bicep)
├─ assets/overlays/                  # Sticker library: eyes, noses, mouths, ears
├─ scripts/                          # scaffold.ps1 / scaffold.sh
├─ docs/
└─ .github/workflows/                # CI
```

## Getting started

Prerequisites: see [docs/dev-setup.md](docs/dev-setup.md) (.NET 10 SDK, MAUI workload, Docker Desktop,
Azure Functions Core Tools).

The projects that depend on NuGet packages and templates (API, Functions, MAUI, Blazor, Aspire, tests)
are generated on your machine so you get the current package versions:

```powershell
# Windows
./scripts/scaffold.ps1
```
```bash
# macOS / Linux
./scripts/scaffold.sh
```

Then start everything locally (Docker Desktop must be running):

```bash
dotnet run --project src/Aspire/CoolClouds.AppHost
```

The Aspire dashboard opens in your browser and shows the API, Functions, Azurite and SQL Server,
with traces of each request.

Run the mobile app separately from Visual Studio (Android emulator or Windows target).

## Dependency rules

- `Domain` depends on nothing.
- `Contracts` depends on nothing (it is shared with clients, keep it light).
- `Infrastructure` → `Domain`.
- `Api` / `Functions` → `Domain`, `Contracts`, `Infrastructure`, `ServiceDefaults`.
- `Mobile` / `Web` → `Contracts`, `ApiClient`, `Rendering`. Clients never reference `Infrastructure`.
