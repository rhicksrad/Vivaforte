namespace LifeForce.Components;

/// <summary>
/// Tracks hit points for simple HUD reporting.
/// </summary>
public sealed class HealthComponent
{
    public int Current { get; set; }
    public int Max { get; set; }
}
