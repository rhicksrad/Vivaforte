using Microsoft.Xna.Framework;

namespace LifeForce.Components;

/// <summary>
/// Stores instantaneous velocity for integration in the movement system.
/// </summary>
public sealed class VelocityComponent
{
    public Vector2 Velocity { get; set; } = Vector2.Zero;
}
