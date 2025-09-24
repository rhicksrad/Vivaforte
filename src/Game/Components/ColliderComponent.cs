using Microsoft.Xna.Framework;

namespace LifeForce.Components;

/// <summary>
/// Basic axis-aligned collider used for bounding constraints.
/// </summary>
public sealed class ColliderComponent
{
    public Vector2 Size { get; set; } = Vector2.Zero;
}
