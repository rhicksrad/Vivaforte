using Microsoft.Xna.Framework;

namespace LifeForce.Components;

/// <summary>
/// Stores world-space location, rotation, and scale.
/// </summary>
public sealed class TransformComponent
{
    public Vector2 Position { get; set; } = Vector2.Zero;
    public float Rotation { get; set; } = 0f;
    public Vector2 Scale { get; set; } = Vector2.One;
}
