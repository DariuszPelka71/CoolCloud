# Overlay library (guided mode stickers)

Face-part assets that guided mode scales, rotates and places on the cloud at the tapped point.

```
overlays/
├─ eyes/
├─ noses/
├─ mouths/
├─ ears/
└─ manifest.json   # asset id, feature type, anchor point, premium flag
```

Guidelines:
- SVG preferred (scales cleanly); otherwise PNG with transparency, at least 512 px.
- Set the anchor point (normalized 0-1) to where the user's tap should land, e.g. the pupil center for an eye.
- Assets marked `premium: true` are part of the paid overlay packs.
