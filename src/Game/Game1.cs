using System;
using System.Collections.Generic;
using LifeForce.Components;
using LifeForce.Core;
using LifeForce.Graphics;
using LifeForce.Input;
using LifeForce.Systems;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace LifeForce;

public class Game1 : Game
{
    private enum GameState
    {
        Start,
        Playing,
        Paused,
        GameOver
    }

    private readonly GraphicsDeviceManager _graphics;
    private SpriteBatch? _spriteBatch;

    private readonly ComponentStore _store = new();
    private readonly InputMap _inputMap = new();
    private readonly Random _rng = new(20250214);

    private const float CrtIntensityMin = 0f;
    private const float CrtIntensityMax = 1.5f;
    private const float CrtIntensityStep = 0.1f;

    private GameState _state = GameState.Start;
    private float _stateTimer = 0f;

    private bool _crtEnabled = true;
    private float _crtIntensity = 0.75f;

    private Texture2D? _starTexture;
    private Texture2D? _playerTexture;
    private Texture2D? _bulletTexture;
    private Texture2D? _pixelTexture;
    private SpriteFont? _font;
    private Effect? _crtEffect;

    private ParallaxSystem? _parallaxSystem;
    private InputSystem? _inputSystem;
    private MovementSystem? _movementSystem;
    private ShootingSystem? _shootingSystem;
    private BulletSystem? _bulletSystem;
    private EnemyWaveSystem? _enemyWaveSystem;
    private EnemySystem? _enemySystem;
    private CollisionSystem? _collisionSystem;
    private readonly RenderSystem _renderSystem = new();
    private HUDSystem? _hudSystem;

    private Entity _playerEntity = Entity.Invalid;
    private float _fpsDisplay = 60f;
    private int _score = 0;
    private Rectangle _playArea;

    public Game1()
    {
        _graphics = new GraphicsDeviceManager(this)
        {
            PreferredBackBufferWidth = 1600,
            PreferredBackBufferHeight = 900,
            SynchronizeWithVerticalRetrace = true
        };

        IsMouseVisible = true;
        IsFixedTimeStep = true;
        TargetElapsedTime = TimeSpan.FromSeconds(1.0 / 60.0);
        Content.RootDirectory = "Content";
    }

    protected override void Initialize()
    {
        Window.Title = "lifeforce-2025-mg";
        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);

        var starTexture = TextureFactory.CreateStarfield(GraphicsDevice);
        var playerTexture = TextureFactory.CreatePlayer(GraphicsDevice);
        var bulletTexture = TextureFactory.CreateBullet(GraphicsDevice);
        var enemyFighterTexture = TextureFactory.CreateEnemyFighter(GraphicsDevice);
        var enemyTurretTexture = TextureFactory.CreateEnemyTurret(GraphicsDevice);
        var font = Content.Load<SpriteFont>("Fonts/Arcade");
        _crtEffect = TryLoadEffect("Shaders/CRT");

        _pixelTexture = new Texture2D(GraphicsDevice, 1, 1);
        _pixelTexture.SetData(new[] { Color.White });

        _starTexture = starTexture;
        _playerTexture = playerTexture;
        _bulletTexture = bulletTexture;
        _font = font;

        ApplyCrtSettings();

        _playArea = new Rectangle(0, 0, _graphics.PreferredBackBufferWidth, _graphics.PreferredBackBufferHeight);

        _parallaxSystem = new ParallaxSystem(starTexture, new Point(_graphics.PreferredBackBufferWidth, _graphics.PreferredBackBufferHeight));
        _inputSystem = new InputSystem();
        _movementSystem = new MovementSystem(_playArea);
        _shootingSystem = new ShootingSystem(_store, bulletTexture, _rng);
        _enemyWaveSystem = new EnemyWaveSystem(_store, enemyFighterTexture, enemyTurretTexture, _rng, _playArea);
        _enemySystem = new EnemySystem(_store, bulletTexture, _rng, _playArea);
        _bulletSystem = new BulletSystem(_store, new Rectangle(-256, -256, _graphics.PreferredBackBufferWidth + 512, _graphics.PreferredBackBufferHeight + 512));
        _collisionSystem = new CollisionSystem(_store, _playArea);
        _hudSystem = new HUDSystem(font);

        ResetWorld();
        ChangeState(GameState.Start);
    }

    private void CreatePlayer()
    {
        if (_playerTexture is null)
        {
            throw new InvalidOperationException("Player texture not loaded.");
        }

        _playerEntity = _store.CreateEntity();
        var transform = new TransformComponent
        {
            Position = new Vector2(_graphics.PreferredBackBufferWidth * 0.2f, _graphics.PreferredBackBufferHeight * 0.5f),
            Scale = Vector2.One
        };
        var sprite = new SpriteComponent
        {
            Texture = _playerTexture,
            Origin = new Vector2(_playerTexture.Width / 2f, _playerTexture.Height / 2f),
            Tint = Color.White
        };
        var velocity = new VelocityComponent();
        var collider = new ColliderComponent { Size = new Vector2(_playerTexture.Width, _playerTexture.Height) };
        var health = new HealthComponent { Current = 3, Max = 3, InvulnerabilityDuration = 1.2f };

        _store.Add(_playerEntity, transform);
        _store.Add(_playerEntity, sprite);
        _store.Add(_playerEntity, velocity);
        _store.Add(_playerEntity, collider);
        _store.Add(_playerEntity, health);
        _store.Add(_playerEntity, new PlayerTagComponent());
    }

    protected override void Update(GameTime gameTime)
    {
        var dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
        if (dt <= 0f)
        {
            dt = 1f / 60f;
        }

        var fpsInstant = 1f / dt;
        _fpsDisplay = MathHelper.Lerp(_fpsDisplay, fpsInstant, 0.1f);

        _inputMap.Update();
        HandlePostProcessingInput();

        if (_inputMap.ExitPressed)
        {
            Exit();
            return;
        }

        _stateTimer += dt;

        _parallaxSystem?.Update(dt);

        switch (_state)
        {
            case GameState.Start:
                if (_inputMap.MenuConfirmPressed)
                {
                    StartNewGame();
                }

                break;
            case GameState.Playing:
                if (_inputMap.PausePressed)
                {
                    ChangeState(GameState.Paused);
                    break;
                }

                if (UpdateGameplay(dt))
                {
                    return;
                }

                if (!PlayerAlive())
                {
                    ChangeState(GameState.GameOver);
                }

                break;
            case GameState.Paused:
                if (_inputMap.PausePressed)
                {
                    ChangeState(GameState.Playing);
                }
                else if (_inputMap.MenuConfirmPressed)
                {
                    StartNewGame();
                }

                break;
            case GameState.GameOver:
                if (_inputMap.MenuConfirmPressed)
                {
                    StartNewGame();
                }

                break;
        }

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.Black);

        if (_spriteBatch is null)
        {
            return;
        }

        ApplyCrtSettings();
        _spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend, SamplerState.PointClamp, null, null, _crtEffect);

        _parallaxSystem?.Draw(_spriteBatch);
        _renderSystem.Draw(_store, _spriteBatch);

        if (_state == GameState.Playing)
        {
            var lives = GetPlayerLives();
            _hudSystem?.Draw(_spriteBatch, _fpsDisplay, lives, _score);
        }

        DrawOverlay(_spriteBatch);

        _spriteBatch.End();

        base.Draw(gameTime);
    }

    private bool UpdateGameplay(float dt)
    {
        _inputSystem?.Update(_store, _inputMap, dt);

        if (_inputSystem?.ExitRequested == true)
        {
            Exit();
            return true;
        }

        _enemyWaveSystem?.Update(dt);

        var playerPosition = GetPlayerPosition();
        _enemySystem?.Update(dt, playerPosition);

        _movementSystem?.Update(_store, dt);
        _shootingSystem?.Update(_inputMap, dt);
        _bulletSystem?.Update(dt);

        if (_collisionSystem is not null)
        {
            var collision = _collisionSystem.Update(dt, _playerEntity);
            if (collision.ScoreDelta != 0)
            {
                _score = Math.Max(0, _score + collision.ScoreDelta);
            }
        }

        UpdatePlayerInvulnerabilityVisuals();
        return false;
    }

    private bool PlayerAlive()
    {
        if (_playerEntity.IsValid && _store.TryGet(_playerEntity, out HealthComponent? health) && health is not null)
        {
            return health.Current > 0;
        }

        return false;
    }

    private void ResetWorld()
    {
        _playerEntity = Entity.Invalid;
        _store.Clear();
        CreatePlayer();
        ResetPlayerVisuals();
        _score = 0;
        _shootingSystem?.Reset();
        _enemyWaveSystem?.Reset();
    }

    private void StartNewGame()
    {
        ResetWorld();
        ChangeState(GameState.Playing);
    }

    private void ChangeState(GameState newState)
    {
        _state = newState;
        _stateTimer = 0f;
    }

    private void HandlePostProcessingInput()
    {
        var changed = false;

        if (_inputMap.ToggleCrtPressed)
        {
            _crtEnabled = !_crtEnabled;
            changed = true;
        }

        if (_inputMap.IncreaseCrtPressed)
        {
            _crtIntensity = MathHelper.Clamp(_crtIntensity + CrtIntensityStep, CrtIntensityMin, CrtIntensityMax);
            changed = true;
        }

        if (_inputMap.DecreaseCrtPressed)
        {
            _crtIntensity = MathHelper.Clamp(_crtIntensity - CrtIntensityStep, CrtIntensityMin, CrtIntensityMax);
            changed = true;
        }

        if (changed)
        {
            ApplyCrtSettings();
        }
    }

    private void ApplyCrtSettings()
    {
        if (_crtEffect is null)
        {
            return;
        }

        var intensity = _crtEnabled ? MathHelper.Clamp(_crtIntensity, CrtIntensityMin, CrtIntensityMax) : 0f;
        _crtEffect.Parameters["CRTIntensity"]?.SetValue(intensity);
        _crtEffect.Parameters["TextureSize"]?.SetValue(new Vector2(_graphics.PreferredBackBufferWidth, _graphics.PreferredBackBufferHeight));
    }

    private void DrawOverlay(SpriteBatch spriteBatch)
    {
        if (_font is null || _state == GameState.Playing)
        {
            return;
        }

        var viewport = GraphicsDevice.Viewport;

        if (_pixelTexture is not null)
        {
            var alpha = _state == GameState.Start ? 0.55f : 0.7f;
            var rectangle = new Rectangle(0, 0, viewport.Width, viewport.Height);
            spriteBatch.Draw(_pixelTexture, rectangle, Color.Black * alpha);
        }

        var lines = new List<(string text, Color color)>();

        switch (_state)
        {
            case GameState.Start:
                lines.Add(("LIFEFORCE 2025", Color.Cyan));
                lines.Add(("Press Enter / A to launch", GetPulseColor(Color.White, Color.Cyan)));
                lines.Add(("Move with WASD or Left Stick · Fire with Space / A", Color.White));
                lines.Add(("Hold Shift / Right Trigger to focus movement", Color.White));
                break;
            case GameState.Paused:
                lines.Add(("Paused", Color.Cyan));
                lines.Add(("Press Esc / Start to resume", Color.White));
                lines.Add(("Press Enter / A to restart from the hangar", Color.White));
                break;
            case GameState.GameOver:
                lines.Add(("Game Over", Color.Crimson));
                lines.Add(("Press Enter / A to try again", GetPulseColor(Color.White, Color.OrangeRed)));
                break;
        }

        var crtStatus = $"CRT {( _crtEnabled ? "ON" : "OFF")} · Intensity {_crtIntensity:0.0}";
        lines.Add((crtStatus, Color.White));
        lines.Add(("Press C / Y to toggle CRT · [ / ] or D-Pad Left/Right adjust", Color.White));
        lines.Add(("Press Q or Back to exit", Color.White));

        var totalHeight = lines.Count * _font.LineSpacing;
        var startY = viewport.Height * 0.5f - totalHeight * 0.5f;
        var y = startY;

        foreach (var (text, color) in lines)
        {
            DrawCenteredString(spriteBatch, text, y, color);
            y += _font.LineSpacing;
        }
    }

    private Color GetPulseColor(Color baseColor, Color highlight)
    {
        var pulse = 0.5f + 0.5f * MathF.Sin(_stateTimer * 4f);
        return Color.Lerp(baseColor, highlight, pulse);
    }

    private void DrawCenteredString(SpriteBatch spriteBatch, string text, float y, Color color)
    {
        if (_font is null)
        {
            return;
        }

        var viewport = GraphicsDevice.Viewport;
        var size = _font.MeasureString(text);
        var position = new Vector2(viewport.Width * 0.5f - size.X * 0.5f, y);
        var shadowOffset = new Vector2(2f, 2f);
        spriteBatch.DrawString(_font, text, position + shadowOffset, Color.Black * 0.6f);
        spriteBatch.DrawString(_font, text, position, color);
    }

    private int GetPlayerLives()
    {
        if (_playerEntity.IsValid && _store.TryGet(_playerEntity, out HealthComponent? health) && health is not null)
        {
            return health.Current;
        }

        return 3;
    }

    private Vector2 GetPlayerPosition()
    {
        if (_playerEntity.IsValid && _store.TryGet(_playerEntity, out TransformComponent? transform) && transform is not null)
        {
            return transform.Position;
        }

        return new Vector2(_graphics.PreferredBackBufferWidth * 0.5f, _graphics.PreferredBackBufferHeight * 0.5f);
    }

    private void ResetPlayerVisuals()
    {
        if (!_playerEntity.IsValid)
        {
            return;
        }

        if (_store.TryGet(_playerEntity, out SpriteComponent? sprite) && sprite is not null)
        {
            sprite.Tint = Color.White;
        }

        if (_store.TryGet(_playerEntity, out HealthComponent? health) && health is not null)
        {
            health.InvulnerabilityTimer = 0f;
        }
    }

    private void UpdatePlayerInvulnerabilityVisuals()
    {
        if (!_playerEntity.IsValid)
        {
            return;
        }

        if (!_store.TryGet(_playerEntity, out SpriteComponent? sprite) || sprite is null)
        {
            return;
        }

        if (!_store.TryGet(_playerEntity, out HealthComponent? health) || health is null)
        {
            return;
        }

        if (health.InvulnerabilityTimer > 0f)
        {
            var pulse = 0.5f + 0.5f * MathF.Sin(_stateTimer * 12f);
            sprite.Tint = Color.Lerp(Color.White, Color.Cyan, pulse);
        }
        else
        {
            sprite.Tint = Color.White;
        }
    }

    private Effect? TryLoadEffect(string assetName)
    {
        try
        {
            return Content.Load<Effect>(assetName);
        }
        catch (Microsoft.Xna.Framework.Content.ContentLoadException)
        {
            return null;
        }
    }
}
