using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace LifeForce.Graphics;

/// <summary>
/// Builds simple procedural textures so the project ships without binary art assets.
/// </summary>
public static class TextureFactory
{
    /// <summary>
    /// Generates a repeating starfield tile with deterministic star placement.
    /// </summary>
    public static Texture2D CreateStarfield(GraphicsDevice device, int width = 96, int height = 96, int seed = 20250101)
    {
        if (width <= 0 || height <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(width), "Starfield dimensions must be positive.");
        }

        var texture = new Texture2D(device, width, height);
        var data = new Color[width * height];

        for (var i = 0; i < data.Length; i++)
        {
            data[i] = Color.Black;
        }

        var rng = new Random(seed);
        var starCount = Math.Max(32, width * height / 48);
        for (var i = 0; i < starCount; i++)
        {
            var x = rng.Next(width);
            var y = rng.Next(height);
            var brightness = 0.6f + (float)rng.NextDouble() * 0.4f;
            var tint = rng.Next(0, 3) switch
            {
                0 => new Color(brightness, brightness, brightness),
                1 => new Color(brightness, brightness * 0.8f, brightness),
                _ => new Color(brightness, brightness, brightness * 0.8f)
            };

            data[y * width + x] = tint;
        }

        texture.SetData(data);
        return texture;
    }

    /// <summary>
    /// Creates a minimalist 32x32 player ship sprite with a bright core and wing highlights.
    /// </summary>
    public static Texture2D CreatePlayer(GraphicsDevice device)
    {
        const int size = 32;
        var texture = new Texture2D(device, size, size);
        var data = new Color[size * size];
        var center = size / 2f;

        for (var y = 0; y < size; y++)
        {
            for (var x = 0; x < size; x++)
            {
                var dx = x - center + 0.5f;
                var dy = y - center + 0.5f;
                var distance = MathF.Sqrt(dx * dx + dy * dy);

                var index = y * size + x;
                var baseColor = Color.Transparent;

                if (distance < 3f)
                {
                    baseColor = new Color(1f, 1f, 1f, 1f);
                }
                else if (Math.Abs(dx) < 3f && Math.Abs(dy) < 10f)
                {
                    baseColor = new Color(0.8f, 0.9f, 1f, 1f);
                }
                else if (Math.Abs(dy) < 1.5f && dx > -1.5f && dx < 12f)
                {
                    baseColor = new Color(0.2f, 0.6f, 1f, 1f);
                }
                else if (dx > -12f && dx < -4f && Math.Abs(dy) < 6f)
                {
                    baseColor = new Color(0.05f, 0.3f, 0.9f, 1f) * (1f - Math.Abs(dy) / 6f);
                }

                data[index] = baseColor;
            }
        }

        texture.SetData(data);
        return texture;
    }

    /// <summary>
    /// Generates a simple glowing bullet quad.
    /// </summary>
    public static Texture2D CreateBullet(GraphicsDevice device)
    {
        const int size = 6;
        var texture = new Texture2D(device, size, size);
        var data = new Color[size * size];
        var center = (size - 1) / 2f;

        for (var y = 0; y < size; y++)
        {
            for (var x = 0; x < size; x++)
            {
                var dx = x - center;
                var dy = y - center;
                var distance = MathF.Sqrt(dx * dx + dy * dy);
                var intensity = MathHelper.Clamp(1f - distance / (size * 0.65f), 0f, 1f);
                data[y * size + x] = new Color(0.3f + 0.7f * intensity, 1f * intensity, 1f, intensity);
            }
        }

        texture.SetData(data);
        return texture;
    }
}
