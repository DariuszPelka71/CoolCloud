# Cool Clouds — Dev Environment Setup

_As of 2026-10-14_

## Key constraint: you need a Mac for iOS

Building and running the iOS app requires a Mac. Apple only allows iOS apps to be compiled with Xcode, which runs only on macOS.

| Setup | How it works |
| --- | --- |
| Mac only | Everything in this guide runs on one machine. |
| Windows PC + Mac | Write code in Visual Studio on Windows; it connects over the network to a Mac (even a small Mac mini) that does the iOS builds. |
| Windows only, for now | Start with Android and the backend; add iOS once a Mac is available. |

## Core development tools

- **.NET SDK 10** (current long-term support version), then the MAUI workload: `dotnet workload install maui`
- **Editor on Windows:** Visual Studio 2026 with the ".NET Multi-platform App UI", "ASP.NET and web development" and "Azure development" workloads.
- **Editor on Mac:** Visual Studio for Mac is discontinued. Use VS Code with the C# Dev Kit and .NET MAUI extensions, or JetBrains Rider (paid, strong MAUI support).
- **Git**, plus a GitHub or Azure DevOps account.

## Mobile tooling

- **Xcode** from the Mac App Store, then `xcode-select --install`. Use the Xcode version your MAUI release requires.
- **Android SDK and emulator**, installed through Visual Studio or Android Studio.
- **Real devices (iPhone and Android phone) if possible.** Simulators can't take camera photos, and the camera is central to the app.

| Account | Cost | Needed for |
| --- | --- | --- |
| Apple Developer Program | $99/year | TestFlight, push notifications, Sign in with Apple, App Store (free provisioning works for limited on-device testing) |
| Google Play Console | $25 one-time | Publishing to Google Play |

## Running the Azure backend locally

Most of the backend runs on your machine through emulators, so you can see everything working together before deploying.

| Azure service | Local tool |
| --- | --- |
| Blob Storage / Queues | Azurite emulator, plus Azure Storage Explorer to browse files |
| Azure SQL | SQL Server in Docker (requires Docker Desktop) |
| Azure Functions | Azure Functions Core Tools (`func`) |
| Service Bus | Service Bus emulator (Docker) |
| Content Safety, login | No emulator: create real, free or low-cost Azure resources |

- **Azure CLI** (`az`) and an **Azure account**. The free tier with starter credit is enough at first.
- **.NET Aspire (strongly recommended).** One command starts the API, Functions, Azurite, SQL and Service Bus together. Its dashboard traces each request from the phone through the API, into storage and on to the Function.

## Connecting the phone to the local API

A physical iPhone can't reach `localhost` on your computer.

- **Dev Tunnels** (built into Visual Studio, or the `devtunnel` CLI) give your local API a public HTTPS address the phone can call.
- **Android emulator** reaches your machine at `10.0.2.2`.
- **Testing the API without the app:** `.http` files in Visual Studio or VS Code, or Bruno / Postman.

## Testing iOS from Windows

There is no iPhone simulator for Windows; Apple's simulator runs only on macOS. Options, cheapest first:

| Option | What you get | Catch |
| --- | --- | --- |
| MAUI Windows desktop target | Same code running as a Windows app; tests screens, logic and API calls | Doesn't look exactly like iOS |
| Android emulator | Real phone-style experience on Windows | Android, not iOS |
| Hot Restart | Deploy to a physical iPhone over USB, no Mac | Not in Visual Studio 2026, only VS 2022 (17.14); needs iTunes + Apple Developer account; .NET icon/launch screen; can't build for release |
| Cloud Mac (MacinCloud, AWS EC2 Mac, Scaleway) | Full iOS builds via Pair to Mac; iOS simulator shown in a window on Windows | Monthly/hourly rental cost |
| Used Mac mini | Same as cloud Mac, on your own network | One-time hardware cost (needed anyway for App Store publishing) |

**Plan:** build Phase 1 on Windows using the Windows and Android targets. Add a Mac (rented or a used Mac mini) when polishing the iOS experience and preparing for TestFlight.

Sources: [Microsoft Learn – Hot Restart](https://learn.microsoft.com/en-us/dotnet/maui/ios/hot-restart) · [DEV Community – Hot Restart not in VS 2026](https://dev.to/biozal/hot-restart-for-ios-is-not-included-in-visual-studio-2026-what-net-maui-developers-need-to-know-28n8)

## Design doc correction: login provider

Azure AD B2C is no longer sold to new customers; Microsoft stopped new sign-ups in May 2025. Its replacement, **Microsoft Entra External ID**, supports the same Google, Apple, Facebook and email logins. Update sections 3, 4 and 11 of the system design before building the login flow.

## Install checklist and first milestone

- [ ] .NET SDK 10 + MAUI workload
- [ ] Visual Studio 2026 (Windows) or VS Code / Rider (Mac)
- [ ] Git
- [ ] Xcode + command line tools (Mac)
- [ ] Android SDK + emulator
- [ ] Docker Desktop
- [ ] Azurite + Azure Storage Explorer
- [ ] Azure Functions Core Tools
- [ ] Azure CLI + Azure account
- [ ] .NET Aspire
- [ ] Dev Tunnels
- [ ] Apple Developer account (when testing on iPhone beyond the free limits)

**First milestone:** one solution with a MAUI app, an ASP.NET Core API and an Aspire host. Get one photo uploaded from the phone into Azurite before adding anything else.
