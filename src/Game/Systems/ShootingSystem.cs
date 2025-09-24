using System;
using LifeForce.Components;
using LifeForce.Core;
using LifeForce.Input;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace LifeForce.Systems;

/// <summary>
/// Spawns deterministic projectile patterns for player-controlled entities.
/// </summary>
public sealed class ShootingSystem
{
    private readonly ComponentStore _store;
    private readonly Texture2D _bulletTexture;
    private readonly Random _rng;
    private readonly float _fireInterval;
    private float _cooldown;

    public ShootingSystem(ComponentStore store, Texture2D bulletTexture, Random rng, float shotsPerSecond = 6f)
    {
        _store = store;
        _bulletTexture = bulletTexture;
        _rng = rng;
        _fireInterval = 1f / Math.Max(shotsPerSecond, 0.001f);
    }

    public void Update(InputMap input, float dt)
    {
        _cooldown -= dt;

        if (!input.FireHeld)
        {
            return;
        }

        if (_cooldown > 0f)
        {
            return;
        }

        foreach (var entity in _store.With<PlayerTagComponent, TransformComponent>())
        {
            var transform = _store.Get<TransformComponent>(entity);
            SpawnBullet(transform.Position);
        }

        _cooldown = _fireInterval;
    }

    private void SpawnBullet(Vector2 origin)
    {
        var variance = ((float)_rng.NextDouble() - 0.5f) * 0.1f;
        var direction = new Vector2(1f, variance);
        direction.Normalize();

        var bulletEntity = _store.CreateEntity();
        var bulletTransform = new TransformComponent
        {
            Position = origin + new Vector2(24f, 0f),
            Rotation = 0f,
            Scale = Vector2.One
        };
        var bulletSprite = new SpriteComponent
        {
            Texture = _bulletTexture,
            Origin = new Vector2(_bulletTexture.Width / 2f, _bulletTexture.Height / 2f),
            Tint = Color.Cyan
        };
        var bulletVelocity = new VelocityComponent
        {
            Velocity = direction * 900f
        };
        var bulletComponent = new BulletComponent
        {
            Direction = direction,
            Speed = 900f,
            Lifetime = 2.5f,
            Age = 0f
        };

        _store.Add(bulletEntity, bulletTransform);
        _store.Add(bulletEntity, bulletSprite);
        _store.Add(bulletEntity, bulletVelocity);
        _store.Add(bulletEntity, bulletComponent);
    }
}
