using Microsoft.Xna.Framework;

namespace LifeForce.Components;

/// <summary>
/// Defines projectile behaviour such as direction, speed, and lifespan.
/// </summary>
public sealed class BulletComponent
{
    public Vector2 Direction { get; set; } = Vector2.UnitX;
    public float Speed { get; set; } = 800f;
    public float Lifetime { get; set; } = 2.0f;
    public float Age { get; set; }
    public bool FromPlayer { get; set; } = true;
}
