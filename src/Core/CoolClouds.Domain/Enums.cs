namespace CoolClouds.Domain;

public enum SubscriptionStatus
{
    Free,
    Active,
    Expired,
    Cancelled
}

public enum LoginProvider
{
    Email,
    Google,
    Apple,
    Facebook
}

public enum ModerationStatus
{
    /// <summary>Uploaded, automated check not finished yet. Never shown publicly.</summary>
    Pending,
    Clear,
    FlaggedForReview,
    Blocked
}

public enum ModerationDecision
{
    Clear,
    FlaggedForReview,
    Blocked
}

public enum ModerationSource
{
    Automated,
    HumanReview
}

public enum ModerationCategory
{
    Sexual,
    Violence,
    Hate,
    SelfHarm
}

public enum FeatureType
{
    Eye,
    Nose,
    Mouth,
    Ear,
    Eyebrow,
    Other
}

public enum TagKind
{
    /// <summary>User/community-facing, used for browsing and search.</summary>
    Descriptive,
    /// <summary>Internal, used only for the publish/block decision.</summary>
    Safety
}

public enum TagSource
{
    Automated,
    Owner
}

public enum Visibility
{
    Private,
    /// <summary>Shareable via link, not listed in the public feed.</summary>
    Unlisted,
    Public
}
