# Database

Azure SQL in the cloud, SQL Server in Docker locally (started by Aspire).

- **Schema** is owned by EF Core migrations in
  `src/Core/CoolClouds.Infrastructure/Persistence/Migrations` (see that project's README).
- **Seed data** lives here in `seed/` and runs after migrations.

Tables (from the data model in `docs/system-design.md`):
`Users`, `ExternalLogins`, `CloudPhotos`, `Annotations`, `Creations`, `Ratings`,
`Tags`, `CreationTags`, `ModerationResults`.

Indexes to add with the first migration:
- `Creations (Visibility, ModerationStatus, CreatedAt DESC)` — newest feed
- `Creations (Visibility, ModerationStatus, AverageRating DESC)` — top-rated feed
- `Creations (ShareSlug)` unique — share links
- `Ratings (CreationId, UserId)` unique — one rating per user per creation
- `ExternalLogins (Provider, ProviderUserId)` unique — login lookup
