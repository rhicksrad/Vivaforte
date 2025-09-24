namespace LifeForce.Core;

/// <summary>
/// Represents a lightweight identifier for entities stored in the ECS component store.
/// </summary>
public readonly record struct Entity(int Id)
{
    public static readonly Entity Invalid = new(-1);
    public bool IsValid => Id > 0;
}
