using System;
using LifeForce.Components;
using LifeForce.Core;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace LifeForce.Systems;

/// <summary>
/// Drives the spawning of enemy waves with escalating difficulty.
/// </summary>
public sealed class EnemyWaveSystem
{
    private readonly ComponentStore _store;
    private readonly Texture2D _fighterTexture;
    private readonly Texture2D _turretTexture;
    private readonly Random _rng;
    private readonly Rectangle _playArea;

    private float _timeSinceLastWave;
    private float _nextWaveDelay = 4.5f;
    private int _waveIndex;

    public EnemyWaveSystem(ComponentStore store, Texture2D fighterTexture, Texture2D turretTexture, Random rng, Rectangle playArea)
    {
        _store = store;
        _fighterTexture = fighterTexture;
        _turretTexture = turretTexture;
        _rng = rng;
        _playArea = playArea;
    }

    public void Reset()
    {
        _timeSinceLastWave = 0f;
        _waveIndex = 0;
        _nextWaveDelay = 4.5f;
    }

    public void Update(float dt)
    {
        _timeSinceLastWave += dt;
        if (_timeSinceLastWave < _nextWaveDelay)
        {
            return;
        }

        SpawnWave();
        _timeSinceLastWave = 0f;
        _waveIndex++;
        _nextWaveDelay = MathF.Max(1.8f, 4.5f - _waveIndex * 0.35f);
    }

    private void SpawnWave()
    {
        var roll = _waveIndex % 3;
        switch (roll)
        {
            case 0:
                SpawnChaserWave();
                break;
            case 1:
                SpawnTurretScreen();
                break;
            default:
                SpawnFormationWave();
                break;
        }
    }

    private void SpawnChaserWave()
    {
        var count = 3 + _waveIndex / 2;
        for (var i = 0; i < count; i++)
        {
            var spawnY = MathHelper.Lerp(_playArea.Top + 80f, _playArea.Bottom - 80f, (float)_rng.NextDouble());
            var spawnX = _playArea.Right + 80f + i * 40f;
            CreateEnemy(new Vector2(spawnX, spawnY), EnemyBehavior.Chaser, _fighterTexture, Color.OrangeRed, speed: 160f + _waveIndex * 8f, scoreValue: 125);
        }
    }

    private void SpawnTurretScreen()
    {
        var rows = 2 + _waveIndex / 3;
        var columns = 2;
        var spacing = new Vector2(96f, 140f);
        var baseX = _playArea.Right - 200f;
        var baseY = _playArea.Top + 160f;

        for (var r = 0; r < rows; r++)
        {
            for (var c = 0; c < columns; c++)
            {
                var offset = new Vector2(-c * spacing.X, r * spacing.Y);
                var spawn = new Vector2(baseX, baseY) + offset;
                CreateEnemy(spawn, EnemyBehavior.Turret, _turretTexture, Color.Crimson, fireRate: 1.5f + _waveIndex * 0.1f, scoreValue: 200);
            }
        }
    }

    private void SpawnFormationWave()
    {
        var fighters = 5 + _waveIndex;
        var start = new Vector2(_playArea.Right + 60f, _playArea.Top + 140f + (float)_rng.NextDouble() * (_playArea.Height - 280f));
        var spacingX = -48f;
        var spacingY = 22f;

        for (var i = 0; i < fighters; i++)
        {
            var column = i % 5;
            var row = i / 5;
            var offset = new Vector2(column * spacingX, row * spacingY);
            var formationOffset = new Vector2(offset.X, row * 0.8f);
            var enemy = CreateEnemy(start + offset, EnemyBehavior.Formation, _fighterTexture, Color.Goldenrod, speed: 120f, scoreValue: 90);
            enemy.FormationAnchor = start;
            enemy.FormationOffset = formationOffset;
            enemy.FormationAmplitude = 30f + row * 8f;
            enemy.FormationFrequency = 1.5f + column * 0.2f;
            enemy.FormationPhase = (float)_rng.NextDouble() * MathF.Tau;
        }
    }

    private EnemyComponent CreateEnemy(Vector2 spawnPosition, EnemyBehavior behavior, Texture2D texture, Color tint, float speed = 140f, float fireRate = 1.5f, int scoreValue = 100)
    {
        var entity = _store.CreateEntity();
        var transform = new TransformComponent
        {
            Position = spawnPosition,
            Scale = Vector2.One
        };
        var sprite = new SpriteComponent
        {
            Texture = texture,
            Origin = new Vector2(texture.Width / 2f, texture.Height / 2f),
            Tint = tint
        };
        var collider = new ColliderComponent
        {
            Size = new Vector2(texture.Width, texture.Height) * 0.75f
        };
        var health = new HealthComponent
        {
            Current = behavior == EnemyBehavior.Turret ? 4 : 2,
            Max = behavior == EnemyBehavior.Turret ? 4 : 2,
            InvulnerabilityDuration = 0.1f
        };
        var enemy = new EnemyComponent
        {
            Behavior = behavior,
            Speed = speed,
            FireRate = fireRate,
            FireCooldown = 0.4f + (float)_rng.NextDouble() * 0.6f,
            BulletTint = tint,
            ScoreValue = scoreValue
        };

        _store.Add(entity, transform);
        _store.Add(entity, sprite);
        _store.Add(entity, collider);
        _store.Add(entity, health);
        _store.Add(entity, enemy);
        _store.Add(entity, new VelocityComponent());
        return enemy;
    }
}
