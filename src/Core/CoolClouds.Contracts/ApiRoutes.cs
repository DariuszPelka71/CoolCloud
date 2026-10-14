namespace CoolClouds.Contracts;

/// <summary>Single source of truth for route paths, used by the API and the ApiClient.</summary>
public static class ApiRoutes
{
    public const string Root = "/api/v1";

    public const string Me = Root + "/me";

    public const string Photos = Root + "/photos";
    public const string PhotoUploads = Photos + "/uploads";

    public const string Creations = Root + "/creations";
    public const string CreationVisibility = Creations + "/{id:guid}/visibility";
    public const string CreationRatings = Creations + "/{id:guid}/ratings";
    public const string CreationReports = Creations + "/{id:guid}/reports";

    public const string Feed = Root + "/feed";

    public const string SubscriptionWebhook = Root + "/webhooks/subscriptions";

    /// <summary>Server-rendered share page with Open Graph tags (not under /api).</summary>
    public const string SharePage = "/c/{slug}";
}
