# Cool Clouds — System Design

## 1. Product Overview

Users photograph clouds, mark "landmarks" on the photo (eye, nose, ear, mouth, etc.),
and the app overlays a face/features to turn the cloud into a recognizable character
(pet, person, creature). Creations can stay private or be published to a public
gallery where others browse and rate them.

**Platforms:** iOS, Android, Web (shared login)
**Monetization:** Freemium — ads for free tier, ~$2/month subscription removes ads
and unlocks extras (higher-res export, unlimited saves, exclusive overlay packs)
**Backend preference:** C# / Azure

---

## 2. Recommended Tech Stack

Since you already know C#, this stack maximizes code reuse and keeps you in one
language end-to-end:

| Layer | Recommendation | Why |
|---|---|---|
| iOS + Android | **.NET MAUI** | Single C# codebase for both mobile platforms; native performance; can still drop to platform-specific code where needed |
| Web | **Blazor WebAssembly** (or React if you want a more mainstream web hiring pool later) | Reuse C# models/validation/business logic between web and mobile |
| Image composition | **SkiaSharp** | Cross-platform 2D graphics engine that works in MAUI, Blazor, and backend — same compositing code everywhere |
| Backend API | **ASP.NET Core Web API** | Your existing C# skillset, first-class Azure support |
| Background processing | **Azure Functions (C#)** or a **.NET Worker Service** | Thumbnailing, moderation, notifications |

**Alternative (more effort, more polish):** native Swift (iOS) + Kotlin (Android) +
React (web), with ASP.NET Core backend. Better native UX, but three client
codebases to maintain instead of two.

---

## 3. High-Level Architecture

```mermaid
flowchart TB
    subgraph Clients
        iOS[iOS App - MAUI]
        And[Android App - MAUI]
        Web[Web App - Blazor]
    end

    subgraph Azure Front Door / CDN
        CDN[CDN - image delivery]
    end

    subgraph API
        API[ASP.NET Core Web API<br/>Azure App Service]
    end

    subgraph Identity
        B2C[Azure AD B2C<br/>email + social login]
    end

    subgraph Storage
        Blob[(Azure Blob Storage<br/>originals/thumbs/composites)]
        SQL[(Azure SQL Database<br/>users, photos, ratings)]
    end

    subgraph Async
        Queue[Azure Service Bus / Queue]
        Func[Azure Functions<br/>thumbnail, moderation, notify]
        Mod[Azure AI Content Safety]
        Notif[Azure Notification Hubs]
    end

    iOS --> API
    And --> API
    Web --> API
    iOS -.login.-> B2C
    And -.login.-> B2C
    Web -.login.-> B2C
    API --> SQL
    API -->|SAS token upload| Blob
    Blob -->|blob trigger| Queue
    Queue --> Func
    Func --> Mod
    Func --> Blob
    Func --> SQL
    Func --> Notif
    CDN --> Blob
    iOS -.images.-> CDN
    And -.images.-> CDN
    Web -.images.-> CDN
```

---

## 4. Client Apps

- **Auth — social/federated login:** Azure AD B2C acts as the identity broker
  in front of your app, so you don't implement each provider's login flow
  yourself — you configure B2C to trust them and it hands your API a standard
  token regardless of which one the user picked. Practical notes per provider:
  - **Google** — straightforward, widely used, good default option.
  - **Sign in with Apple** — if you offer *any* third-party social login on
    iOS (Google, Facebook, etc.), Apple's App Store guidelines require you to
    also offer Sign in with Apple as an equally prominent option. Plan for
    this from day one on iOS rather than retrofitting it.
  - **Facebook** — supported, though Facebook's own login review process can
    be slower to set up than Google/Apple.
  - Email/password as a fallback for users who don't want to use a social
    account.
  - **Account linking:** if a user signs up with Google using
    `d.pelka7@gmail.com` and later logs in with Apple using the same email,
    decide whether to treat those as the same account (link) or separate
    accounts. Most apps link by verified email — Azure AD B2C supports this
    via custom policies, but it's worth deciding explicitly rather than
    hitting it as a surprise in production.
- **Upload flow:** client asks the API for a short-lived SAS token, then uploads
  the photo directly to Blob Storage (keeps large files off your API servers).
- **Annotation editor — hybrid mode:**
  - **Guided mode (AI-assisted):** user taps a point and labels it ("nose",
    "eye", "ear"...). The system then draws/places the feature automatically.
    Two ways to implement the "drawing" part, worth prototyping both:
    - *Sticker/asset approach* — a curated library of face-part SVGs/PNGs is
      auto-scaled, rotated, and positioned at the tapped point. Fast, cheap,
      completely predictable, and trivial to moderate (nothing novel is ever
      generated). Recommended for MVP.
    - *Generative approach* — call an image model (e.g. via Azure OpenAI) to
      paint a feature that blends into the cloud's texture at that point.
      Looks more natural but costs more per request, is slower, and — since
      it generates novel imagery — needs the *same* moderation pass as any
      user upload before it's even shown back to the user.
  - **Freehand mode:** user draws directly on the photo. Genuinely harder on
    a phone (finger vs. fine detail) — lean on pinch-to-zoom, larger touch
    targets, and undo/redo to make it usable. On web, freehand with a
    mouse/trackpad/stylus is much more natural, so expect web to be the
    stronger canvas for this mode.
  - **Key implementation point:** store annotations/drawings as structured
    *layer* data (asset id + position/rotation/scale, or vector path points
    for freehand strokes) rather than baking straight to pixels. That's what
    lets guided-mode output be handed to the user for manual touch-up
    afterward — both modes write to the same layer model, just via different
    input methods.
- **Compositing:** rendered client-side with SkiaSharp for instant preview
  (it supports layered vector content on all your target platforms), then the
  final rendered image is uploaded as a new "Creation" separate from the
  original cloud photo. A single `CloudPhoto` can have many `Creation`s —
  useful since a user might try several faces on the same cloud.

---

## 5. Backend Services (ASP.NET Core on Azure)

| Service | Responsibility |
|---|---|
| `Users` API | Profile, subscription status |
| `CloudPhotos` API | Upload metadata, SAS token issuance, listing |
| `Creations` API | Save/list annotated compositions, public/private toggle |
| `Feed` API | Paginated public gallery, sort by recency/rating |
| `Ratings` API | Submit/aggregate ratings, cached average score |
| `Subscriptions` webhook handler | Apple/Google/Stripe receipt validation |
| Background Functions | Thumbnail generation, content moderation, push notifications |

Host the API on **Azure App Service** to start (simple, autoscaling); move to
**Azure Container Apps** later if you split into more granular microservices.

---

## 6. Data Model (simplified)

```
User
 ├─ id, email, displayName
 └─ subscriptionStatus, subscriptionExpiresAt

ExternalLogin  (many-to-one: User <-> ExternalLogin, supports linked accounts)
 ├─ id, userId
 ├─ provider (google | apple | facebook | email)
 └─ providerUserId

CloudPhoto
 ├─ id, ownerId, blobUrl, thumbnailUrl
 ├─ uploadedAt, moderationStatus
 └─ isPublic

Annotation
 ├─ id, cloudPhotoId
 ├─ type (eye/nose/ear/mouth/...)
 └─ x, y, width, height, rotation   (normalized 0-1)

Creation
 ├─ id, cloudPhotoId, ownerId
 ├─ resultBlobUrl, createdAt
 ├─ title, tags
 └─ isPublic, moderationStatus

Rating
 ├─ id, creationId, userId, score, createdAt

Tag
 ├─ id, name, kind (descriptive | safety)

CreationTag  (many-to-many: Creation <-> Tag)
 ├─ creationId, tagId, source (automated | owner)

ModerationResult
 ├─ id, creationId (or cloudPhotoId)
 ├─ category (sexual, violence, hate, self-harm, ...)
 ├─ severityScore, source (automated | human-review)
 └─ decision (blocked | flagged-for-review | clear), createdAt
```

`CloudPhoto` is always the original, untouched source image. `Creation` rows
are the derived, annotated versions — a single `CloudPhoto` can have several
`Creation`s (different faces tried on the same cloud). When browsing, pair
them in the UI as "original + variations" rather than showing creations in
isolation.

---

## 7. Core User Flows

**Upload → Annotate → Publish**
1. User picks/takes a photo → app requests SAS token → uploads to Blob Storage.
2. Blob trigger fires a Function → generates thumbnail → runs Azure AI Content
   Safety check → updates `CloudPhoto.moderationStatus`.
3. User opens editor, places landmark annotations, previews composite live via
   SkiaSharp.
4. On save, composite image uploads as a `Creation`; user toggles public/private.
5. If public, it enters moderation again before appearing in the public feed
   (never trust user-submitted content blindly if it's going to be visible to
   others).

**Browsing & Rating**
- Public feed paginated, sortable by newest/top-rated.
- Rating writes go through the API, average score recalculated (cache in the
  `Creation` row to avoid aggregating on every read).

---

## 8. Content Moderation & Privacy

Given minors can use the app, treat owner-level moderation as one layer, not
the only line of defense. The system itself needs to be able to block
disallowed content regardless of what the owner wants — self-review is a UX
step, not a safety control.

**Three layers, in order:**

1. **Automated screening (mandatory, non-bypassable).** Every upload — both
   the original `CloudPhoto` and every `Creation` — runs through **Azure AI
   Content Safety** on upload. It returns severity scores per category
   (sexual, violence, hate, self-harm, etc.), stored as `ModerationResult`
   rows. Anything over the disallowed threshold — sexual content especially —
   is hard-blocked from ever becoming public. This check cannot be turned off
   by a user setting; it runs the same way for every account. If a
   generative-AI overlay is used (see section 4), its *output* goes through
   this same check before the user even sees it.

2. **Owner review (opt-in publish step).** Before a `Creation` can be toggled
   public, show the owner its auto-detected tags. If it's clear, the owner
   decides public/private and can add their own descriptive tags (funny,
   spooky, cute, animal, portrait, etc.) for browsing/search. If it's flagged,
   publishing simply isn't offered until the offending element is removed —
   the owner isn't asked to "approve" disallowed content, only to fix it.

3. **Community + human review (safety net).** A **report/flag** button on
   every public creation feeds a moderator queue for edge cases the automated
   pass didn't catch or that the model is uncertain about. Track this
   separately (`source: human-review` on `ModerationResult`) so you can audit
   how often automation gets overruled in either direction.

**Tagging taxonomy** — keep two kinds of tags distinct:
- *Descriptive tags* (`kind: descriptive`) — user/community-facing, used for
  browsing and search (funny, spooky, animal, portrait...).
- *Safety tags* (`kind: safety`) — internal, used only for the
  publish/block decision, not necessarily shown to end users.

**Because minors may use the app:**
- The sexual-content threshold should be zero-tolerance and cannot be
  loosened by any account setting.
- Consider whether an account can self-declare as a minor (or you infer it),
  and if so default it to the most conservative publishing/browsing settings
  — e.g. no browsing of anything still in the human-review queue.
- Keep an audit trail (`ModerationResult` history) — for content-safety
  incidents involving minors, you'll want a clear record of what was
  detected, when, and what action was taken.

**Privacy:**
- Since real faces might get referenced/drawn on top of a cloud, avoid
  features that let users tag or identify real named individuals in public
  posts.
- Standard GDPR/CCPA basics: account deletion cascades to owned photos and
  creations, data export on request.
- If minors are a confirmed user segment, check whether COPPA (US) or
  equivalent regional rules require parental consent flows for account
  creation — worth a legal consult before launch, not just an engineering
  decision.

---

## 9. Monetization

- Use a cross-platform subscription layer like **RevenueCat** wrapping
  StoreKit (iOS), Google Play Billing (Android), and Stripe (web) — this
  avoids reimplementing receipt validation three times.
- Free tier: shows ads via **Google AdMob** (mobile) and **Google Ad Manager**
  (web).
- $2/month tier: removes ads, unlocks higher-res exports, unlimited saved
  creations, maybe exclusive overlay packs.
- Webhook handler in your API updates `User.subscriptionStatus` when
  RevenueCat/Stripe events fire — this is your source of truth, not the
  client.

---

## 10. Sharing to Social Media (Twitter/X, Facebook, Pinterest)

**Two ways to implement this — start with the first:**

1. **Native share sheet (recommended for MVP).** Use each platform's built-in
   share intent — iOS `UIActivityViewController`, Android `Intent.ACTION_SEND`,
   and the **Web Share API** on browsers that support it (fallback to
   platform-specific share links on web, e.g. `twitter.com/intent/tweet`,
   `facebook.com/sharer`, Pinterest's `pinterest.com/pin/create/button`). The
   post itself happens through the user's own logged-in Twitter/Facebook/
   Pinterest app or session — you never touch their credentials, and there's
   no OAuth app-review process to go through. This gets you 90% of the value
   for a fraction of the effort.
2. **Direct in-app posting via platform APIs (later enhancement).** Lets
   users post without leaving the app, but each platform requires its own
   OAuth flow, its own app registration, and — for Facebook in particular —
   an app review process before you're allowed to publish on a user's behalf.
   Worth doing only once you have traction and want to remove friction from
   the sharing flow.

**Important technical gotcha:** social crawlers (Twitter's, Facebook's,
Pinterest's link-preview bots) don't execute JavaScript. If the web app is a
Blazor WebAssembly SPA, those crawlers won't see any `og:image`/`twitter:card`
meta tags rendered client-side, and shared links will preview as blank. You
need a small **server-rendered landing page per Creation**
(`coolclouds.app/c/{shareSlug}`), served as plain HTML with the meta tags
baked in server-side — a lightweight ASP.NET Core minimal API/Razor Page is
enough for just this route, even if the rest of the web app is a SPA. That
page shows the image plus a "Made with Cool Clouds — try it yourself" call to
action, which doubles as a growth loop.

**Per-platform image sizing** — generate (or crop on the fly via the CDN)
platform-appropriate renditions rather than sharing one fixed size:
| Platform | Recommended aspect |
|---|---|
| Twitter/X | ~1200×675 (16:9) |
| Facebook | ~1200×630 |
| Pinterest | Taller, ~1000×1500 (2:3) — Pinterest strongly favors vertical pins |

**Moderation still applies to shared content.** A `Creation` shouldn't be
externally shareable unless it's already cleared the automated Content Safety
check from section 8 — regardless of whether the user has toggled it "public"
in the in-app gallery. It's reasonable to support "shareable via link, but
not listed in the public feed" as its own state (similar to an
unlisted/private Google Doc link) — just make sure the safety gate applies
uniformly to both, not only to the public-feed path.

**Data model addition:**
```
Creation
 ├─ ... (existing fields)
 ├─ shareSlug        (public, unguessable id used in share URLs)
 └─ shareCount        (per-platform breakdown optional, for growth metrics)
```

---

## 11. Azure Services Mapping

| Need | Azure Service |
|---|---|
| API hosting | App Service (later: Container Apps) |
| Relational data | Azure SQL Database |
| Image storage | Blob Storage |
| Global image delivery | Azure CDN / Front Door |
| Async processing | Azure Functions + Service Bus/Queue Storage |
| Auth | Azure AD B2C |
| Content moderation | Azure AI Content Safety |
| Push notifications | Azure Notification Hubs |
| Monitoring | Application Insights |

Cost tip: at small scale, Blob Storage + a Basic/Standard App Service tier +
Azure SQL Basic/Standard tier will be cheap (roughly tens of dollars/month).
The Functions + Content Safety calls scale with usage, so cost tracks growth
rather than being a fixed overhead.

---

## 12. Suggested MVP Roadmap

1. **Phase 1 — Core loop:** upload cloud photo, annotate, composite, save
   privately. Single platform first (pick mobile or web) to validate the
   editing UX before building the rest.
2. **Phase 2 — Social:** public toggle, public feed, ratings, moderation
   pipeline, native share-sheet sharing to Twitter/Facebook/Pinterest (this
   is cheap to add once you have a shareable landing page).
3. **Phase 3 — Monetization:** subscriptions + ads.
4. **Phase 4 — Expand platforms:** bring the second/third client online, push
   notifications, overlay packs as premium content, direct in-app posting via
   platform APIs if the native share sheet isn't converting well enough.

---

### Resolved decisions (for reference)
- **Drawing mode:** hybrid — guided tap-to-place (sticker assets or AI-generated,
  see section 4) plus manual freehand touch-up, with freehand expected to work
  better on web than mobile.
- **Moderation strictness:** zero-tolerance automated blocking (especially
  sexual content) as a non-bypassable gate, layered with owner review before
  publish and community reporting after (see section 8).
- **Minors:** allowed to use the app, which is why the moderation gate can't
  be optional or owner-controlled alone.

### Still open
- Sticker-asset library vs. generative AI for guided mode — worth prototyping
  both before committing (see section 4 trade-offs).
- Whether "shareable via link" content needs its own review flow distinct
  from "public in the gallery" content (see section 10).
- COPPA/GDPR-for-minors — needs a legal consult, not just an engineering
  decision.
