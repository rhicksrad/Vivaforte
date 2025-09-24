using System;
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
    private readonly GraphicsDeviceManager _graphics;
    private SpriteBatch? _spriteBatch;

    private readonly ComponentStore _store = new();
    private readonly InputMap _inputMap = new();
    private readonly Random _rng = new(20250214);

    private Texture2D? _starTexture;
    private Texture2D? _playerTexture;
    private Texture2D? _bulletTexture;
    private SpriteFont? _font;
    private Effect? _crtEffect;

    private ParallaxSystem? _parallaxSystem;
    private InputSystem? _inputSystem;
    private MovementSystem? _movementSystem;
    private ShootingSystem? _shootingSystem;
    private BulletSystem? _bulletSystem;
    private readonly RenderSystem _renderSystem = new();
    private HUDSystem? _hudSystem;

    private Entity _playerEntity = Entity.Invalid;
    private float _fpsDisplay = 60f;
    private int _score = 0;

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
        var font = Content.Load<SpriteFont>("Fonts/Arcade");
        _crtEffect = TryLoadEffect("Shaders/CRT");

        _starTexture = starTexture;
        _playerTexture = playerTexture;
        _bulletTexture = bulletTexture;
        _font = font;

        _parallaxSystem = new ParallaxSystem(starTexture, new Point(_graphics.PreferredBackBufferWidth, _graphics.PreferredBackBufferHeight));
        _inputSystem = new InputSystem();
        _movementSystem = new MovementSystem(new Rectangle(0, 0, _graphics.PreferredBackBufferWidth, _graphics.PreferredBackBufferHeight));
        _shootingSystem = new ShootingSystem(_store, bulletTexture, _rng);
        _bulletSystem = new BulletSystem(_store, new Rectangle(-256, -256, _graphics.PreferredBackBufferWidth + 512, _graphics.PreferredBackBufferHeight + 512));
        _hudSystem = new HUDSystem(font);

        CreatePlayer();
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
        var health = new HealthComponent { Current = 3, Max = 3 };

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

        _parallaxSystem?.Update(dt);
        _inputSystem?.Update(_store, _inputMap, dt);

        if (_inputSystem?.ExitRequested == true)
        {
            Exit();
            return;
        }

        _movementSystem?.Update(_store, dt);
        _shootingSystem?.Update(_inputMap, dt);
        _bulletSystem?.Update(dt);

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.Black);

        if (_spriteBatch is null)
        {
            return;
        }

        _spriteBatch.Begin(SpriteSortMode.Deferred, BlendState.AlphaBlend, SamplerState.PointClamp, null, null, _crtEffect);

        _parallaxSystem?.Draw(_spriteBatch);
        _renderSystem.Draw(_store, _spriteBatch);

        var lives = GetPlayerLives();
        _hudSystem?.Draw(_spriteBatch, _fpsDisplay, lives, _score);

        _spriteBatch.End();

        base.Draw(gameTime);
    }

    private int GetPlayerLives()
    {
        if (_playerEntity.IsValid && _store.TryGet(_playerEntity, out HealthComponent? health) && health is not null)
        {
            return health.Current;
        }

        return 3;
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
