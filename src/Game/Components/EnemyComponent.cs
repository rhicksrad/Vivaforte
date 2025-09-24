using Microsoft.Xna.Framework;

namespace LifeForce.Components;

/// <summary>
/// Marks an entity as an enemy and stores behaviour specific state.
/// </summary>
public sealed class EnemyComponent
{
    public EnemyBehavior Behavior { get; set; } = EnemyBehavior.Chaser;
    public float Speed { get; set; } = 140f;
    public float FireRate { get; set; } = 1.0f;
    public float FireCooldown { get; set; }
    public int ScoreValue { get; set; } = 100;
    public Color BulletTint { get; set; } = Color.OrangeRed;

    public Vector2 FormationAnchor { get; set; }
    public Vector2 FormationOffset { get; set; }
    public float FormationAmplitude { get; set; } = 40f;
    public float FormationFrequency { get; set; } = 1.5f;
    public float FormationPhase { get; set; }
}

public enum EnemyBehavior
{
    Chaser,
    Turret,
    Formation
}
