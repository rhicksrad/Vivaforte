using System;
using System.Collections.Generic;
using LifeForce.Components;
using LifeForce.Core;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace LifeForce.Systems;

/// <summary>
/// Updates enemy movement behaviours and handles turret firing logic.
/// </summary>
public sealed class EnemySystem
{
    private readonly ComponentStore _store;
    private readonly Texture2D _bulletTexture;
    private readonly Random _rng;
    private readonly Rectangle _playArea;
    private readonly List<Entity> _toRemove = new();

    public EnemySystem(ComponentStore store, Texture2D bulletTexture, Random rng, Rectangle playArea)
    {
        _store = store;
        _bulletTexture = bulletTexture;
        _rng = rng;
        _playArea = playArea;
    }

    public void Update(float dt, Vector2 playerPosition)
    {
        _toRemove.Clear();

        foreach (var entity in _store.With<EnemyComponent, TransformComponent>())
        {
            var enemy = _store.Get<EnemyComponent>(entity);
            var transform = _store.Get<TransformComponent>(entity);
            var velocity = _store.TryGet(entity, out VelocityComponent? vel) && vel is not null
                ? vel
                : CreateVelocity(entity);

            switch (enemy.Behavior)
            {
                case EnemyBehavior.Chaser:
                    UpdateChaser(enemy, transform, velocity, playerPosition);
                    break;
                case EnemyBehavior.Turret:
                    UpdateTurret(enemy, transform, playerPosition, dt);
                    velocity.Velocity = Vector2.Zero;
                    break;
                case EnemyBehavior.Formation:
                    UpdateFormation(enemy, transform, velocity, dt);
                    break;
            }

            if (transform.Position.X < _playArea.Left - 160f || transform.Position.Y > _playArea.Bottom + 200f || transform.Position.Y < _playArea.Top - 200f)
            {
                _toRemove.Add(entity);
            }
        }

        foreach (var entity in _toRemove)
        {
            _store.DestroyEntity(entity);
        }
    }

    private static void UpdateChaser(EnemyComponent enemy, TransformComponent transform, VelocityComponent velocity, Vector2 playerPosition)
    {
        var toPlayer = playerPosition - transform.Position;
        if (toPlayer.LengthSquared() < 1f)
        {
            velocity.Velocity = Vector2.Zero;
            return;
        }

        toPlayer.Normalize();
        velocity.Velocity = toPlayer * enemy.Speed;
    }

    private void UpdateTurret(EnemyComponent enemy, TransformComponent transform, Vector2 playerPosition, float dt)
    {
        enemy.FireCooldown -= dt;
        if (enemy.FireCooldown > 0f)
        {
            return;
        }

        var toPlayer = playerPosition - transform.Position;
        if (toPlayer.LengthSquared() < 16f)
        {
            enemy.FireCooldown = 1f / MathF.Max(enemy.FireRate, 0.1f);
            return;
        }

        toPlayer.Normalize();
        SpawnEnemyBullet(transform.Position + toPlayer * 12f, toPlayer * 520f, enemy.BulletTint);
        var cadenceVariance = 0.15f + (float)_rng.NextDouble() * 0.2f;
        enemy.FireCooldown = cadenceVariance + 1f / MathF.Max(enemy.FireRate, 0.2f);
    }

    private static void UpdateFormation(EnemyComponent enemy, TransformComponent transform, VelocityComponent velocity, float dt)
    {
        enemy.FormationAnchor.X -= enemy.Speed * dt;
        enemy.FormationPhase += enemy.FormationFrequency * dt;
        var sine = MathF.Sin(enemy.FormationPhase + enemy.FormationOffset.Y) * enemy.FormationAmplitude;
        var target = enemy.FormationAnchor + new Vector2(enemy.FormationOffset.X, sine);
        var desired = target - transform.Position;
        velocity.Velocity = desired * 4.2f;
    }

    private VelocityComponent CreateVelocity(Entity entity)
    {
        var velocity = new VelocityComponent();
        _store.Add(entity, velocity);
        return velocity;
    }

    private void SpawnEnemyBullet(Vector2 origin, Vector2 velocity, Color tint)
    {
        var bulletEntity = _store.CreateEntity();
        var transform = new TransformComponent
        {
            Position = origin,
            Scale = Vector2.One
        };
        var sprite = new SpriteComponent
        {
            Texture = _bulletTexture,
            Origin = new Vector2(_bulletTexture.Width / 2f, _bulletTexture.Height / 2f),
            Tint = tint
        };
        var bulletVelocity = new VelocityComponent
        {
            Velocity = velocity
        };
        var direction = velocity;
        if (direction.LengthSquared() > 0f)
        {
            direction.Normalize();
        }
        var bullet = new BulletComponent
        {
            Direction = direction,
            Speed = velocity.Length(),
            Lifetime = 4.5f,
            Age = 0f,
            FromPlayer = false
        };

        _store.Add(bulletEntity, transform);
        _store.Add(bulletEntity, sprite);
        _store.Add(bulletEntity, bulletVelocity);
        _store.Add(bulletEntity, bullet);
    }
}
