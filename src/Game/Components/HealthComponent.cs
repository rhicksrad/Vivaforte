namespace LifeForce.Components;

/// <summary>
/// Tracks hit points for simple HUD reporting and invulnerability windows.
/// </summary>
public sealed class HealthComponent
{
    public int Current { get; set; }
    public int Max { get; set; }
    public float InvulnerabilityDuration { get; set; }
    public float InvulnerabilityTimer { get; set; }

    public bool IsInvulnerable => InvulnerabilityTimer > 0f;
}
