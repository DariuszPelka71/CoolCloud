namespace CoolClouds.Domain.Entities;

public class Tag
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string Name { get; set; }
    public TagKind Kind { get; set; }
}

public class CreationTag
{
    public Guid CreationId { get; set; }
    public Guid TagId { get; set; }
    public TagSource Source { get; set; }

    public Creation? Creation { get; set; }
    public Tag? Tag { get; set; }
}

/// <summary>Audit trail of every automated and human moderation decision.</summary>
public class ModerationResult
{
    public Guid Id { get; set; } = Guid.NewGuid();

    // Exactly one of these is set.
    public Guid? CreationId { get; set; }
    public Guid? CloudPhotoId { get; set; }

    public ModerationCategory Category { get; set; }
    public int SeverityScore { get; set; }
    public ModerationSource Source { get; set; }
    public ModerationDecision Decision { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
