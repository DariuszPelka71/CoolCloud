using CoolClouds.Domain;

namespace CoolClouds.Infrastructure.Moderation;

/// <summary>
/// Maps Azure AI Content Safety severity scores (0-7) to a decision.
/// These thresholds apply to every account and cannot be changed by user settings.
/// Sexual content is zero-tolerance because minors use the app.
/// </summary>
public static class ModerationPolicy
{
    public static ModerationDecision Decide(ModerationCategory category, int severity) => category switch
    {
        ModerationCategory.Sexual when severity > 0 => ModerationDecision.Blocked,
        _ when severity >= 4 => ModerationDecision.Blocked,
        _ when severity >= 2 => ModerationDecision.FlaggedForReview,
        _ => ModerationDecision.Clear
    };

    /// <summary>The strictest decision across all categories wins.</summary>
    public static ModerationStatus Combine(IEnumerable<ModerationDecision> decisions)
    {
        var worst = decisions.DefaultIfEmpty(ModerationDecision.Clear).Max();
        return worst switch
        {
            ModerationDecision.Blocked => ModerationStatus.Blocked,
            ModerationDecision.FlaggedForReview => ModerationStatus.FlaggedForReview,
            _ => ModerationStatus.Clear
        };
    }
}
