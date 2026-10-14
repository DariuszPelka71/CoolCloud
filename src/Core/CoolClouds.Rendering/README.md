# CoolClouds.Rendering

Turns a cloud photo + a `LayerDocument` (from `CoolClouds.Contracts`) into a final image with SkiaSharp.

The same code runs:
- in the MAUI app for the live editor preview,
- in the Blazor app,
- on the backend if a creation ever needs re-rendering (e.g. platform-sized share images).

Planned types:
- `LayerRenderer` — draws sticker and stroke layers onto an `SKCanvas`.
- `OverlayLibrary` — loads assets from `assets/overlays`.
- `ShareImageRenderer` — crops/pads to 1200×675 (X), 1200×630 (Facebook), 1000×1500 (Pinterest).
