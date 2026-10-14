#!/usr/bin/env bash
# Generates the template-based projects (API, Functions, MAUI, Blazor, Aspire, tests),
# adds NuGet packages at their current versions, wires project references and the solution.
# Safe to re-run: projects that already exist are skipped.
set -euo pipefail

cd "$(dirname "$0")/.."

command -v dotnet >/dev/null || { echo ".NET SDK not found. Install .NET 10 first (see docs/dev-setup.md)." >&2; exit 1; }

echo "==> Installing project templates"
dotnet new install Aspire.ProjectTemplates >/dev/null

new_project() { # template path
  local name; name="$(basename "$2")"
  if [[ -f "$2/$name.csproj" ]]; then echo "    skip $name (exists)"; return; fi
  echo "    new  $name ($1)"
  dotnet new "$1" -n "$name" -o "$2" >/dev/null
}

echo "==> Generating projects"
new_project webapi                 src/Backend/CoolClouds.Api
new_project maui                   src/Clients/CoolClouds.Mobile
new_project blazorwasm             src/Clients/CoolClouds.Web
new_project aspire-servicedefaults src/Aspire/CoolClouds.ServiceDefaults
new_project aspire-apphost         src/Aspire/CoolClouds.AppHost
new_project xunit                  tests/CoolClouds.Domain.Tests
new_project xunit                  tests/CoolClouds.Api.Tests

FUNC_DIR=src/Backend/CoolClouds.Functions
if [[ ! -f "$FUNC_DIR/CoolClouds.Functions.csproj" ]]; then
  if command -v func >/dev/null; then
    echo "    new  CoolClouds.Functions (func init)"
    (cd "$FUNC_DIR" && func init --worker-runtime dotnet-isolated --target-framework net10.0 >/dev/null)
  else
    echo "WARNING: Azure Functions Core Tools (func) not found: skipping CoolClouds.Functions. Install it and re-run." >&2
  fi
fi

echo "==> Adding NuGet packages"
add_packages() { local p="$1"; shift; for pkg in "$@"; do dotnet add "$p" package "$pkg" >/dev/null; done; }
add_packages src/Core/CoolClouds.Infrastructure Microsoft.EntityFrameworkCore.SqlServer Microsoft.EntityFrameworkCore.Design Azure.Storage.Blobs Azure.AI.ContentSafety
add_packages src/Core/CoolClouds.Rendering SkiaSharp
add_packages src/Backend/CoolClouds.Api Aspire.Microsoft.EntityFrameworkCore.SqlServer Aspire.Azure.Storage.Blobs Microsoft.AspNetCore.Authentication.JwtBearer
add_packages src/Aspire/CoolClouds.AppHost Aspire.Hosting.SqlServer Aspire.Hosting.Azure.Storage Aspire.Hosting.Azure.Functions
add_packages src/Clients/CoolClouds.Mobile SkiaSharp.Views.Maui.Controls CommunityToolkit.Mvvm
add_packages tests/CoolClouds.Api.Tests Microsoft.AspNetCore.Mvc.Testing
if [[ -f "$FUNC_DIR/CoolClouds.Functions.csproj" ]]; then
  add_packages "$FUNC_DIR" Microsoft.Azure.Functions.Worker.Extensions.Storage.Blobs Aspire.Azure.Storage.Blobs
fi

echo "==> Wiring project references"
DOMAIN=src/Core/CoolClouds.Domain/CoolClouds.Domain.csproj
CONTRACTS=src/Core/CoolClouds.Contracts/CoolClouds.Contracts.csproj
INFRA=src/Core/CoolClouds.Infrastructure/CoolClouds.Infrastructure.csproj
RENDER=src/Core/CoolClouds.Rendering/CoolClouds.Rendering.csproj
CLIENT=src/Clients/CoolClouds.ApiClient/CoolClouds.ApiClient.csproj
DEFAULTS=src/Aspire/CoolClouds.ServiceDefaults/CoolClouds.ServiceDefaults.csproj
API=src/Backend/CoolClouds.Api/CoolClouds.Api.csproj
FUNC=$FUNC_DIR/CoolClouds.Functions.csproj

add_refs() { local p="$1"; shift; local refs=(); for r in "$@"; do [[ -f "$r" ]] && refs+=("$r"); done; [[ ${#refs[@]} -gt 0 ]] && dotnet add "$p" reference "${refs[@]}" >/dev/null || true; }
add_refs src/Backend/CoolClouds.Api    "$DOMAIN" "$CONTRACTS" "$INFRA" "$RENDER" "$DEFAULTS"
[[ -f "$FUNC" ]] && add_refs "$FUNC_DIR" "$DOMAIN" "$INFRA" "$RENDER" "$DEFAULTS"
add_refs src/Clients/CoolClouds.Mobile "$CONTRACTS" "$CLIENT" "$RENDER"
add_refs src/Clients/CoolClouds.Web    "$CONTRACTS" "$CLIENT" "$RENDER"
add_refs src/Aspire/CoolClouds.AppHost "$API" "$FUNC"
add_refs tests/CoolClouds.Domain.Tests "$DOMAIN" "$INFRA"
add_refs tests/CoolClouds.Api.Tests    "$API"

echo "==> Writing AppHost wiring"
rm -f src/Aspire/CoolClouds.AppHost/Program.cs
cp scripts/templates/AppHost.cs src/Aspire/CoolClouds.AppHost/AppHost.cs

echo "==> Creating solution"
if ! ls CoolClouds.sln* >/dev/null 2>&1; then dotnet new sln -n CoolClouds >/dev/null; fi
SLN="$(ls CoolClouds.sln* | head -n1)"
find src tests -name '*.csproj' -print0 | while IFS= read -r -d '' proj; do dotnet sln "$SLN" add "$proj" >/dev/null; done

echo
echo "Done. Open $SLN in your IDE, or run:"
echo "  dotnet run --project src/Aspire/CoolClouds.AppHost"
