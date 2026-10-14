#!/usr/bin/env pwsh
# Generates the template-based projects (API, Functions, MAUI, Blazor, Aspire, tests),
# adds NuGet packages at their current versions, wires project references and the solution.
# Safe to re-run: projects that already exist are skipped.

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $root

function Test-Command($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }

if (-not (Test-Command dotnet)) { throw '.NET SDK not found. Install .NET 10 first (see docs/dev-setup.md).' }

Write-Host '==> Installing project templates' -ForegroundColor Cyan
dotnet new install Aspire.ProjectTemplates | Out-Null

function New-Project($template, $path, [string[]]$extra = @()) {
    $name = Split-Path $path -Leaf
    if (Test-Path (Join-Path $path "$name.csproj")) { Write-Host "    skip $name (exists)"; return }
    Write-Host "    new  $name ($template)"
    dotnet new $template -n $name -o $path @extra | Out-Null
}

Write-Host '==> Generating projects' -ForegroundColor Cyan
New-Project webapi                 'src/Backend/CoolClouds.Api'
New-Project maui                   'src/Clients/CoolClouds.Mobile'
New-Project blazorwasm             'src/Clients/CoolClouds.Web'
New-Project aspire-servicedefaults 'src/Aspire/CoolClouds.ServiceDefaults'
New-Project aspire-apphost         'src/Aspire/CoolClouds.AppHost'
New-Project xunit                  'tests/CoolClouds.Domain.Tests'
New-Project xunit                  'tests/CoolClouds.Api.Tests'

$functionsPath = 'src/Backend/CoolClouds.Functions'
if (-not (Test-Path "$functionsPath/CoolClouds.Functions.csproj")) {
    if (Test-Command func) {
        Write-Host '    new  CoolClouds.Functions (func init)'
        Push-Location $functionsPath
        func init --worker-runtime dotnet-isolated --target-framework net10.0 | Out-Null
        Pop-Location
    } else {
        Write-Warning 'Azure Functions Core Tools (func) not found: skipping CoolClouds.Functions. Install it and re-run.'
    }
}

Write-Host '==> Adding NuGet packages' -ForegroundColor Cyan
function Add-Packages($project, [string[]]$packages) {
    foreach ($p in $packages) { dotnet add $project package $p | Out-Null }
}
Add-Packages 'src/Core/CoolClouds.Infrastructure' @('Microsoft.EntityFrameworkCore.SqlServer', 'Microsoft.EntityFrameworkCore.Design', 'Azure.Storage.Blobs', 'Azure.AI.ContentSafety')
Add-Packages 'src/Core/CoolClouds.Rendering' @('SkiaSharp')
Add-Packages 'src/Backend/CoolClouds.Api' @('Aspire.Microsoft.EntityFrameworkCore.SqlServer', 'Aspire.Azure.Storage.Blobs', 'Microsoft.AspNetCore.Authentication.JwtBearer')
Add-Packages 'src/Aspire/CoolClouds.AppHost' @('Aspire.Hosting.SqlServer', 'Aspire.Hosting.Azure.Storage', 'Aspire.Hosting.Azure.Functions')
Add-Packages 'src/Clients/CoolClouds.Mobile' @('SkiaSharp.Views.Maui.Controls', 'CommunityToolkit.Mvvm')
Add-Packages 'tests/CoolClouds.Api.Tests' @('Microsoft.AspNetCore.Mvc.Testing')
if (Test-Path "$functionsPath/CoolClouds.Functions.csproj") {
    Add-Packages $functionsPath @('Microsoft.Azure.Functions.Worker.Extensions.Storage.Blobs', 'Aspire.Azure.Storage.Blobs')
}

Write-Host '==> Wiring project references' -ForegroundColor Cyan
function Add-Refs($project, [string[]]$refs) {
    $existing = $refs | Where-Object { Test-Path $_ }
    if ($existing) { dotnet add $project reference @existing | Out-Null }
}
$domain   = 'src/Core/CoolClouds.Domain/CoolClouds.Domain.csproj'
$contract = 'src/Core/CoolClouds.Contracts/CoolClouds.Contracts.csproj'
$infra    = 'src/Core/CoolClouds.Infrastructure/CoolClouds.Infrastructure.csproj'
$render   = 'src/Core/CoolClouds.Rendering/CoolClouds.Rendering.csproj'
$client   = 'src/Clients/CoolClouds.ApiClient/CoolClouds.ApiClient.csproj'
$defaults = 'src/Aspire/CoolClouds.ServiceDefaults/CoolClouds.ServiceDefaults.csproj'
$api      = 'src/Backend/CoolClouds.Api/CoolClouds.Api.csproj'
$func     = "$functionsPath/CoolClouds.Functions.csproj"

Add-Refs 'src/Backend/CoolClouds.Api'        @($domain, $contract, $infra, $render, $defaults)
if (Test-Path $func) { Add-Refs $functionsPath @($domain, $infra, $render, $defaults) }
Add-Refs 'src/Clients/CoolClouds.Mobile'     @($contract, $client, $render)
Add-Refs 'src/Clients/CoolClouds.Web'        @($contract, $client, $render)
Add-Refs 'src/Aspire/CoolClouds.AppHost'     @($api, $func)
Add-Refs 'tests/CoolClouds.Domain.Tests'     @($domain, $infra)
Add-Refs 'tests/CoolClouds.Api.Tests'        @($api)

Write-Host '==> Writing AppHost wiring' -ForegroundColor Cyan
$appHostDir = 'src/Aspire/CoolClouds.AppHost'
Remove-Item "$appHostDir/Program.cs" -ErrorAction SilentlyContinue
Copy-Item 'scripts/templates/AppHost.cs' "$appHostDir/AppHost.cs" -Force

Write-Host '==> Creating solution' -ForegroundColor Cyan
if (-not (Get-ChildItem -Filter 'CoolClouds.sln*' -ErrorAction SilentlyContinue)) {
    dotnet new sln -n CoolClouds | Out-Null
}
$sln = (Get-ChildItem -Filter 'CoolClouds.sln*' | Select-Object -First 1).Name
Get-ChildItem -Path src, tests -Recurse -Filter *.csproj | ForEach-Object {
    dotnet sln $sln add $_.FullName | Out-Null
}

Write-Host ''
Write-Host "Done. Open $sln in Visual Studio, or run:" -ForegroundColor Green
Write-Host '  dotnet run --project src/Aspire/CoolClouds.AppHost'
