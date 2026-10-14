namespace CoolClouds.Domain.Entities;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string Email { get; set; }
    public required string DisplayName { get; set; }

    /// <summary>Self-declared or inferred; minors get the most conservative settings.</summary>
    public bool IsMinor { get; set; }

    public SubscriptionStatus SubscriptionStatus { get; set; } = SubscriptionStatus.Free;
    public DateTimeOffset? SubscriptionExpiresAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    public List<ExternalLogin> ExternalLogins { get; set; } = [];
    public List<CloudPhoto> CloudPhotos { get; set; } = [];
    public List<Creation> Creations { get; set; } = [];

    public bool HasActiveSubscription(DateTimeOffset now) =>
        SubscriptionStatus == SubscriptionStatus.Active
        && (SubscriptionExpiresAt is null || SubscriptionExpiresAt > now);
}

/// <summary>One row per identity provider linked to a user (supports account linking).</summary>
public class ExternalLogin
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public LoginProvider Provider { get; set; }
    public required string ProviderUserId { get; set; }

    public User? User { get; set; }
}
