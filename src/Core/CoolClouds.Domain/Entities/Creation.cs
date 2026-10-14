namespace CoolClouds.Domain.Entities;

/// <summary>An annotated, composited version of a <see cref="CloudPhoto"/>.</summary>
public class Creation
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CloudPhotoId { get; set; }
    public Guid OwnerId { get; set; }

    public required string ResultBlobName { get; set; }

    /// <summary>Layer data as JSON (see CoolClouds.Contracts.Layers) so the creation stays editable.</summary>
    public required string LayersJson { get; set; }

    public string? Title { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    public Visibility Visibility { get; set; } = Visibility.Private;
    public ModerationStatus ModerationStatus { get; set; } = ModerationStatus.Pending;

    /// <summary>Public, unguessable id used in share URLs (/c/{ShareSlug}).</summary>
    public string? ShareSlug { get; set; }
    public int ShareCount { get; set; }

    /// <summary>Cached aggregate so the feed doesn't recalculate on every read.</summary>
    public double AverageRating { get; set; }
    public int RatingCount { get; set; }

    public CloudPhoto? CloudPhoto { get; set; }
    public User? Owner { get; set; }
    public List<Rating> Ratings { get; set; } = [];
    public List<CreationTag> Tags { get; set; } = [];
    public List<ModerationResult> ModerationResults { get; set; } = [];

    /// <summary>
    /// The safety gate: content is visible to anyone but the owner (feed or share link)
    /// only after it has cleared automated moderation. Owner settings cannot bypass this.
    /// </summary>
    public bool CanBeSeenByOthers =>
        Visibility != Visibility.Private && ModerationStatus == ModerationStatus.Clear;

    public void AddRating(int score)
    {
        if (score is < 1 or > 5)
            throw new ArgumentOutOfRangeException(nameof(score), "Score must be between 1 and 5.");

        AverageRating = ((AverageRating * RatingCount) + score) / (RatingCount + 1);
        RatingCount++;
    }
}

public class Rating
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CreationId { get; set; }
    public Guid UserId { get; set; }
    public int Score { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
