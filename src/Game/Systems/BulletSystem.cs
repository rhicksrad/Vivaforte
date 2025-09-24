using System.Collections.Generic;
using LifeForce.Components;
using LifeForce.Core;
using Microsoft.Xna.Framework;

namespace LifeForce.Systems;

/// <summary>
/// Advances projectile lifetimes and removes them once expired or outside the playfield.
/// </summary>
public sealed class BulletSystem
{
    private readonly ComponentStore _store;
    private readonly Rectangle _bounds;
    private readonly List<Entity> _pendingRemoval = new();

    public BulletSystem(ComponentStore store, Rectangle bounds)
    {
        _store = store;
        _bounds = bounds;
    }

    public void Update(float dt)
    {
        _pendingRemoval.Clear();

        foreach (var entity in _store.With<BulletComponent, TransformComponent>())
        {
            var bullet = _store.Get<BulletComponent>(entity);
            bullet.Age += dt;

            var transform = _store.Get<TransformComponent>(entity);
            if (bullet.Age >= bullet.Lifetime || !_bounds.Contains(transform.Position))
            {
                _pendingRemoval.Add(entity);
            }
        }

        foreach (var entity in _pendingRemoval)
        {
            _store.DestroyEntity(entity);
        }
    }
}
