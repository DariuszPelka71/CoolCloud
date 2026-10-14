using System.Text.Json.Serialization;

namespace CoolClouds.Contracts;

/// <summary>
/// Annotations and drawings are stored as layers, never baked straight into pixels,
/// so guided-mode output can be touched up by hand afterwards.
/// All coordinates are normalized 0-1 relative to the photo.
/// </summary>
[JsonPolymorphic(TypeDiscriminatorPropertyName = "kind")]
[JsonDerivedType(typeof(StickerLayer), "sticker")]
[JsonDerivedType(typeof(StrokeLayer), "stroke")]
public abstract record Layer(Guid Id, int ZIndex);

/// <summary>A face-part asset from the overlay library placed on the photo (guided mode).</summary>
public sealed record StickerLayer(
    Guid Id,
    int ZIndex,
    string AssetId,
    float X,
    float Y,
    float Scale,
    float Rotation) : Layer(Id, ZIndex);

/// <summary>A freehand stroke.</summary>
public sealed record StrokeLayer(
    Guid Id,
    int ZIndex,
    IReadOnlyList<PointF> Points,
    string Color,
    float Width) : Layer(Id, ZIndex);

public readonly record struct PointF(float X, float Y);

public sealed record LayerDocument(int Version, IReadOnlyList<Layer> Layers)
{
    public const int CurrentVersion = 1;
}
