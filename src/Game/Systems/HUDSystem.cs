using System.Globalization;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace LifeForce.Systems;

/// <summary>
/// Renders simple HUD information such as FPS, lives, and score.
/// </summary>
public sealed class HUDSystem
{
    private readonly SpriteFont _font;
    private readonly Vector2 _origin = new(12f, 12f);

    public HUDSystem(SpriteFont font)
    {
        _font = font;
    }

    public void Draw(SpriteBatch spriteBatch, float fps, int lives, int score)
    {
        var fpsText = $"FPS: {fps.ToString("0", CultureInfo.InvariantCulture)}";
        var livesText = $"Lives: {lives}";
        var scoreText = $"Score: {score}";

        var position = _origin;
        DrawShadowed(spriteBatch, fpsText, position);
        position.Y += _font.LineSpacing;
        DrawShadowed(spriteBatch, livesText, position);
        position.Y += _font.LineSpacing;
        DrawShadowed(spriteBatch, scoreText, position);
    }

    private void DrawShadowed(SpriteBatch spriteBatch, string text, Vector2 position)
    {
        var shadowOffset = new Vector2(1f, 1f);
        spriteBatch.DrawString(_font, text, position + shadowOffset, Color.Black * 0.6f);
        spriteBatch.DrawString(_font, text, position, Color.White);
    }
}
