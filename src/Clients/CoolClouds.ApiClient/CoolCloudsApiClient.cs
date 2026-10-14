using System.Net.Http.Headers;
using System.Net.Http.Json;
using CoolClouds.Contracts;

namespace CoolClouds.ApiClient;

/// <summary>
/// One client for every app. Register it with a base address pointing at the API
/// (Dev Tunnel URL on a real phone, http://10.0.2.2:PORT on the Android emulator).
/// </summary>
public sealed class CoolCloudsApiClient(HttpClient http)
{
    public Task<UserProfileDto?> GetMeAsync(CancellationToken ct = default) =>
        http.GetFromJsonAsync<UserProfileDto>(ApiRoutes.Me, ct);

    public async Task<CreateUploadResponse> CreatePhotoUploadAsync(CreateUploadRequest request, CancellationToken ct = default)
    {
        var response = await http.PostAsJsonAsync(ApiRoutes.PhotoUploads, request, ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<CreateUploadResponse>(ct))!;
    }

    /// <summary>Uploads bytes straight to Blob Storage using the SAS URL (no API in between).</summary>
    public async Task UploadToBlobAsync(Uri sasUrl, Stream content, string contentType, CancellationToken ct = default)
    {
        using var blobClient = new HttpClient();
        using var body = new StreamContent(content);
        body.Headers.ContentType = new MediaTypeHeaderValue(contentType);

        using var request = new HttpRequestMessage(HttpMethod.Put, sasUrl) { Content = body };
        request.Headers.Add("x-ms-blob-type", "BlockBlob");

        var response = await blobClient.SendAsync(request, ct);
        response.EnsureSuccessStatusCode();
    }

    public async Task<SaveCreationResponse> SaveCreationAsync(SaveCreationRequest request, CancellationToken ct = default)
    {
        var response = await http.PostAsJsonAsync(ApiRoutes.Creations, request, ct);
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<SaveCreationResponse>(ct))!;
    }

    public async Task SetVisibilityAsync(Guid creationId, string visibility, CancellationToken ct = default)
    {
        var url = ApiRoutes.CreationVisibility.Replace("{id:guid}", creationId.ToString());
        var response = await http.PutAsJsonAsync(url, new SetVisibilityRequest(visibility), ct);
        response.EnsureSuccessStatusCode();
    }

    public Task<FeedPage?> GetFeedAsync(string sort = "newest", string? continuationToken = null, CancellationToken ct = default)
    {
        var url = $"{ApiRoutes.Feed}?sort={Uri.EscapeDataString(sort)}";
        if (continuationToken is not null)
            url += $"&continuationToken={Uri.EscapeDataString(continuationToken)}";
        return http.GetFromJsonAsync<FeedPage>(url, ct);
    }

    public async Task RateAsync(Guid creationId, int score, CancellationToken ct = default)
    {
        var url = ApiRoutes.CreationRatings.Replace("{id:guid}", creationId.ToString());
        var response = await http.PostAsJsonAsync(url, new RateCreationRequest(score), ct);
        response.EnsureSuccessStatusCode();
    }
}
