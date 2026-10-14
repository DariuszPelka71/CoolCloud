namespace CoolClouds.Domain.Entities;

/// <summary>The original, untouched cloud photo. A photo can have many creations.</summary>
public class CloudPhoto
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OwnerId { get; set; }

    /// <summary>Blob name inside the "originals" container (not a full URL, so the CDN host can change).</summary>
    public required string BlobName { get; set; }
    public string? ThumbnailBlobName { get; set; }

    public DateTimeOffset UploadedAt { get; set; } = DateTimeOffset.UtcNow;
    public ModerationStatus ModerationStatus { get; set; } = ModerationStatus.Pending;

    public User? Owner { get; set; }
    public List<Annotation> Annotations { get; set; } = [];
    public List<Creation> Creations { get; set; } = [];
}

/// <summary>A landmark the user placed on the photo. Coordinates are normalized 0-1.</summary>
public class Annotation
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CloudPhotoId { get; set; }
    public FeatureType Type { get; set; }

    public float X { get; set; }
    public float Y { get; set; }
    public float Width { get; set; }
    public float Height { get; set; }
    public float Rotation { get; set; }

    public CloudPhoto? CloudPhoto { get; set; }
}
