using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace LifeForce.Graphics;

/// <summary>
/// Utility methods for rendering primitive shapes with a sprite batch.
/// </summary>
public static class Primitives
{
    private static Texture2D? _pixel;

    private static void EnsurePixel(GraphicsDevice device)
    {
        if (_pixel != null)
        {
            return;
        }

        _pixel = new Texture2D(device, 1, 1, false, SurfaceFormat.Color);
        _pixel.SetData(new[] { Color.White });
    }

    public static void DrawRectangle(SpriteBatch spriteBatch, Rectangle rectangle, Color color, float thickness = 1f)
    {
        EnsurePixel(spriteBatch.GraphicsDevice);
        spriteBatch.Draw(_pixel!, new Rectangle(rectangle.Left, rectangle.Top, rectangle.Width, (int)Math.Max(1, thickness)), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rectangle.Left, rectangle.Bottom - (int)Math.Max(1, thickness), rectangle.Width, (int)Math.Max(1, thickness)), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rectangle.Left, rectangle.Top, (int)Math.Max(1, thickness), rectangle.Height), color);
        spriteBatch.Draw(_pixel!, new Rectangle(rectangle.Right - (int)Math.Max(1, thickness), rectangle.Top, (int)Math.Max(1, thickness), rectangle.Height), color);
    }

    public static void DrawLine(SpriteBatch spriteBatch, Vector2 start, Vector2 end, Color color, float thickness = 1f)
    {
        EnsurePixel(spriteBatch.GraphicsDevice);
        var direction = end - start;
        var length = direction.Length();
        var angle = (float)Math.Atan2(direction.Y, direction.X);
        spriteBatch.Draw(_pixel!, start, null, color, angle, Vector2.Zero, new Vector2(length, thickness), SpriteEffects.None, 0f);
    }
}
