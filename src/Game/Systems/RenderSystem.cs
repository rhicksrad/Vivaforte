using System.Collections.Generic;
using LifeForce.Components;
using LifeForce.Core;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace LifeForce.Systems;

/// <summary>
/// Draws all visible sprite components using a shared sprite batch.
/// </summary>
public sealed class RenderSystem
{
    private readonly List<(SpriteComponent sprite, TransformComponent transform)> _drawList = new();

    public void Draw(ComponentStore store, SpriteBatch spriteBatch)
    {
        _drawList.Clear();

        foreach (var entity in store.With<SpriteComponent, TransformComponent>())
        {
            var sprite = store.Get<SpriteComponent>(entity);
            if (sprite.Texture is null || !sprite.Visible)
            {
                continue;
            }

            var transform = store.Get<TransformComponent>(entity);
            _drawList.Add((sprite, transform));
        }

        _drawList.Sort((a, b) => a.sprite.LayerDepth.CompareTo(b.sprite.LayerDepth));

        foreach (var (sprite, transform) in _drawList)
        {
            spriteBatch.Draw(
                sprite.Texture!,
                transform.Position,
                sprite.SourceRectangle,
                sprite.Tint,
                transform.Rotation,
                sprite.Origin,
                transform.Scale,
                SpriteEffects.None,
                sprite.LayerDepth);
        }
    }
}
