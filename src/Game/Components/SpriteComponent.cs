using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace LifeForce.Components;

/// <summary>
/// Holds texture and rendering metadata for an entity.
/// </summary>
public sealed class SpriteComponent
{
    public Texture2D? Texture { get; set; }
    public Rectangle? SourceRectangle { get; set; }
    public Color Tint { get; set; } = Color.White;
    public Vector2 Origin { get; set; } = Vector2.Zero;
    public float LayerDepth { get; set; } = 0f;
    public bool Visible { get; set; } = true;
}
