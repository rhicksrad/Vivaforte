using System;
using System.Collections.Generic;
using LifeForce.Components;
using LifeForce.Core;
using Microsoft.Xna.Framework;

namespace LifeForce.Systems;

/// <summary>
/// Resolves projectile and body collisions between the player and enemies.
/// </summary>
public sealed class CollisionSystem
{
    private readonly ComponentStore _store;
    private readonly Rectangle _playArea;
    private readonly List<Entity> _destroyedBullets = new();
    private readonly List<Entity> _destroyedEnemies = new();

    public CollisionSystem(ComponentStore store, Rectangle playArea)
    {
        _store = store;
        _playArea = playArea;
    }

    public CollisionUpdate Update(float dt, Entity playerEntity)
    {
        foreach (var entity in _store.With<HealthComponent>())
        {
            var health = _store.Get<HealthComponent>(entity);
            if (health.InvulnerabilityTimer > 0f)
            {
                health.InvulnerabilityTimer = MathF.Max(0f, health.InvulnerabilityTimer - dt);
            }
        }

        var scoreDelta = 0;
        var playerHit = false;
        HealthComponent? playerHealth = null;
        ColliderComponent? playerCollider = null;
        TransformComponent? playerTransform = null;

        if (playerEntity.IsValid)
        {
            _store.TryGet(playerEntity, out playerHealth);
            _store.TryGet(playerEntity, out playerCollider);
            _store.TryGet(playerEntity, out playerTransform);
        }

        _destroyedBullets.Clear();
        _destroyedEnemies.Clear();

        var playerBounds = GetBounds(playerTransform, playerCollider);

        foreach (var bulletEntity in _store.With<BulletComponent, TransformComponent>())
        {
            var bullet = _store.Get<BulletComponent>(bulletEntity);
            var transform = _store.Get<TransformComponent>(bulletEntity);
            if (!_playArea.Contains(transform.Position))
            {
                continue;
            }

            if (bullet.FromPlayer)
            {
                scoreDelta += ProcessPlayerBullet(bulletEntity, transform);
            }
            else if (playerHealth is not null && playerCollider is not null && !playerHealth.IsInvulnerable)
            {
                var bounds = GetBounds(transform, 8f);
                if (bounds.Intersects(playerBounds))
                {
                    ApplyDamage(playerHealth, 1);
                    playerHit = true;
                    _destroyedBullets.Add(bulletEntity);
                }
            }
        }

        if (playerHealth is not null && playerCollider is not null && !playerHealth.IsInvulnerable)
        {
            foreach (var enemyEntity in _store.With<EnemyComponent, ColliderComponent>())
            {
                if (!_store.TryGet(enemyEntity, out TransformComponent? enemyTransform) || enemyTransform is null)
                {
                    continue;
                }

                var bounds = GetBounds(enemyTransform, _store.Get<ColliderComponent>(enemyEntity));
                if (bounds.Intersects(playerBounds))
                {
                    ApplyDamage(playerHealth, 1);
                    playerHit = true;
                    _destroyedEnemies.Add(enemyEntity);
                }
            }
        }

        foreach (var bulletEntity in _destroyedBullets)
        {
            _store.DestroyEntity(bulletEntity);
        }

        foreach (var enemyEntity in _destroyedEnemies)
        {
            if (_store.TryGet(enemyEntity, out EnemyComponent? enemy) && enemy is not null)
            {
                scoreDelta += enemy.ScoreValue;
            }

            _store.DestroyEntity(enemyEntity);
        }

        return new CollisionUpdate(scoreDelta, playerHit);
    }

    private int ProcessPlayerBullet(Entity bulletEntity, TransformComponent bulletTransform)
    {
        var bounds = GetBounds(bulletTransform, 8f);
        foreach (var enemyEntity in _store.With<EnemyComponent, ColliderComponent>())
        {
            if (!_store.TryGet(enemyEntity, out TransformComponent? enemyTransform) || enemyTransform is null)
            {
                continue;
            }

            var enemyBounds = GetBounds(enemyTransform, _store.Get<ColliderComponent>(enemyEntity));
            if (!bounds.Intersects(enemyBounds))
            {
                continue;
            }

            var health = _store.Get<HealthComponent>(enemyEntity);
            if (health.InvulnerabilityTimer > 0f)
            {
                continue;
            }

            ApplyDamage(health, 1);
            _destroyedBullets.Add(bulletEntity);

            if (health.Current <= 0)
            {
                _destroyedEnemies.Add(enemyEntity);
            }

            return 0;
        }

        return 0;
    }

    private static void ApplyDamage(HealthComponent health, int amount)
    {
        health.Current = Math.Max(0, health.Current - amount);
        health.InvulnerabilityTimer = health.InvulnerabilityDuration;
    }

    private static Rectangle GetBounds(TransformComponent? transform, ColliderComponent? collider)
    {
        if (transform is null || collider is null)
        {
            return Rectangle.Empty;
        }

        var half = collider.Size * 0.5f;
        return new Rectangle(
            (int)(transform.Position.X - half.X),
            (int)(transform.Position.Y - half.Y),
            (int)collider.Size.X,
            (int)collider.Size.Y);
    }

    private static Rectangle GetBounds(TransformComponent? transform, float radius)
    {
        if (transform is null)
        {
            return Rectangle.Empty;
        }

        var size = (int)(radius * 2f);
        return new Rectangle(
            (int)(transform.Position.X - radius),
            (int)(transform.Position.Y - radius),
            size,
            size);
    }
}

public readonly record struct CollisionUpdate(int ScoreDelta, bool PlayerHit);
