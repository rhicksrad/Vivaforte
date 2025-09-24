using LifeForce.Components;
using LifeForce.Core;
using Microsoft.Xna.Framework;

namespace LifeForce.Systems;

/// <summary>
/// Integrates velocity into transform positions and constrains the player to the viewport.
/// </summary>
public sealed class MovementSystem
{
    private readonly Rectangle _playArea;

    public MovementSystem(Rectangle playArea)
    {
        _playArea = playArea;
    }

    public void Update(ComponentStore store, float dt)
    {
        foreach (var entity in store.With<TransformComponent, VelocityComponent>())
        {
            var transform = store.Get<TransformComponent>(entity);
            var velocity = store.Get<VelocityComponent>(entity);
            transform.Position += velocity.Velocity * dt;

            if (store.Has<PlayerTagComponent>(entity))
            {
                var halfSize = Vector2.Zero;
                if (store.TryGet(entity, out ColliderComponent? collider) && collider is not null)
                {
                    halfSize = collider.Size * 0.5f;
                }

                var min = new Vector2(_playArea.Left + halfSize.X, _playArea.Top + halfSize.Y);
                var max = new Vector2(_playArea.Right - halfSize.X, _playArea.Bottom - halfSize.Y);
                transform.Position = Vector2.Clamp(transform.Position, min, max);
            }
        }
    }
}
