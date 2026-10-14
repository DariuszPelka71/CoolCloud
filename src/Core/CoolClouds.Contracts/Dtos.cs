namespace CoolClouds.Contracts;

// ---- Upload flow: client asks for a short-lived SAS URL, then uploads straight to Blob Storage.

public sealed record CreateUploadRequest(string FileName, string ContentType, long SizeBytes);

public sealed record CreateUploadResponse(Guid CloudPhotoId, Uri UploadUrl, DateTimeOffset ExpiresAt);

public sealed record CloudPhotoDto(
    Guid Id,
    Uri? ImageUrl,
    Uri? ThumbnailUrl,
    string ModerationStatus,
    DateTimeOffset UploadedAt);

// ---- Creations

public sealed record SaveCreationRequest(
    Guid CloudPhotoId,
    string? Title,
    LayerDocument Layers);

public sealed record SaveCreationResponse(Guid CreationId, Uri ResultUploadUrl, DateTimeOffset ExpiresAt);

public sealed record SetVisibilityRequest(string Visibility); // Private | Unlisted | Public

public sealed record CreationDto(
    Guid Id,
    Guid CloudPhotoId,
    string? Title,
    Uri? ImageUrl,
    string Visibility,
    string ModerationStatus,
    double AverageRating,
    int RatingCount,
    IReadOnlyList<string> Tags,
    string? ShareUrl,
    DateTimeOffset CreatedAt);

// ---- Feed and ratings

public sealed record FeedPage(IReadOnlyList<CreationDto> Items, string? ContinuationToken);

public sealed record RateCreationRequest(int Score);

// ---- Users

public sealed record UserProfileDto(
    Guid Id,
    string DisplayName,
    bool HasActiveSubscription,
    DateTimeOffset? SubscriptionExpiresAt);
