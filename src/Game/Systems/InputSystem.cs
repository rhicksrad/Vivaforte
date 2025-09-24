using LifeForce.Components;
using LifeForce.Core;
using LifeForce.Input;
using Microsoft.Xna.Framework;

namespace LifeForce.Systems;

/// <summary>
/// Applies player intent to velocity components and raises exit requests.
/// </summary>
public sealed class InputSystem
{
    private readonly float _normalSpeed;
    private readonly float _focusMultiplier;

    public InputSystem(float normalSpeed = 420f, float focusMultiplier = 0.4f)
    {
        _normalSpeed = normalSpeed;
        _focusMultiplier = focusMultiplier;
    }

    public bool ExitRequested { get; private set; }

    public void Update(ComponentStore store, InputMap input, float dt)
    {
        _ = dt;
        ExitRequested = input.ExitPressed;

        var movement = input.Movement;
        var speed = _normalSpeed * (input.FocusHeld ? _focusMultiplier : 1f);
        var velocity = movement * speed;

        foreach (var entity in store.With<PlayerTagComponent, VelocityComponent>())
        {
            var velocityComponent = store.Get<VelocityComponent>(entity);
            velocityComponent.Velocity = velocity;
        }
    }
}
