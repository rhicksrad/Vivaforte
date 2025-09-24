using System.Collections.Generic;
using System.Runtime.InteropServices;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace LifeForce.Systems;

/// <summary>
/// Scrolls a repeating starfield texture across multiple parallax layers.
/// </summary>
public sealed class ParallaxSystem
{
    private readonly Texture2D _texture;
    private readonly List<ParallaxLayer> _layers = new();
    private readonly Point _viewportSize;

    public ParallaxSystem(Texture2D texture, Point viewportSize)
    {
        _texture = texture;
        _viewportSize = viewportSize;

        _layers.Add(new ParallaxLayer(60f, 1.0f, Color.White * 0.7f));
        _layers.Add(new ParallaxLayer(120f, 1.2f, Color.White * 0.4f));
        _layers.Add(new ParallaxLayer(30f, 0.8f, Color.White * 0.9f));
    }

    public void Update(float dt)
    {
        foreach (ref var layer in CollectionsMarshal.AsSpan(_layers))
        {
            layer.OffsetX += layer.Speed * dt;
            var tileWidth = _texture.Width * layer.Scale;
            if (tileWidth <= 0f)
            {
                continue;
            }

            layer.OffsetX %= tileWidth;
        }
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        foreach (var layer in _layers)
        {
            var tileWidth = (int)(_texture.Width * layer.Scale);
            var tileHeight = (int)(_texture.Height * layer.Scale);
            if (tileWidth <= 0 || tileHeight <= 0)
            {
                continue;
            }

            var tilesX = _viewportSize.X / tileWidth + 2;
            var tilesY = _viewportSize.Y / tileHeight + 2;

            for (var y = 0; y < tilesY; y++)
            {
                for (var x = 0; x < tilesX; x++)
                {
                    var drawPosition = new Vector2(-layer.OffsetX + x * tileWidth, y * tileHeight);
                    spriteBatch.Draw(_texture, drawPosition, null, layer.Tint, 0f, Vector2.Zero, layer.Scale, SpriteEffects.None, 0f);
                }
            }
        }
    }

    private struct ParallaxLayer
    {
        public float Speed;
        public float Scale;
        public float OffsetX;
        public Color Tint;

        public ParallaxLayer(float speed, float scale, Color tint)
        {
            Speed = speed;
            Scale = scale;
            Tint = tint;
            OffsetX = 0f;
        }
    }
}
