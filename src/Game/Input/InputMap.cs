using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace LifeForce.Input;

/// <summary>
/// Basic input abstraction combining keyboard and gamepad states.
/// Provides movement, firing, focus, and exit commands with room for future rebinding.
/// </summary>
public sealed class InputMap
{
    private KeyboardState _previousKeyboard;
    private KeyboardState _currentKeyboard;
    private GamePadState _previousGamePad;
    private GamePadState _currentGamePad;
    private readonly PlayerIndex _playerIndex = PlayerIndex.One;

    public void Update()
    {
        _previousKeyboard = _currentKeyboard;
        _previousGamePad = _currentGamePad;
        _currentKeyboard = Keyboard.GetState();
        _currentGamePad = GamePad.GetState(_playerIndex);
    }

    public Vector2 Movement
    {
        get
        {
            var direction = Vector2.Zero;

            if (IsKeyDown(_currentKeyboard, Keys.Left) || IsKeyDown(_currentKeyboard, Keys.A))
            {
                direction.X -= 1f;
            }

            if (IsKeyDown(_currentKeyboard, Keys.Right) || IsKeyDown(_currentKeyboard, Keys.D))
            {
                direction.X += 1f;
            }

            if (IsKeyDown(_currentKeyboard, Keys.Up) || IsKeyDown(_currentKeyboard, Keys.W))
            {
                direction.Y -= 1f;
            }

            if (IsKeyDown(_currentKeyboard, Keys.Down) || IsKeyDown(_currentKeyboard, Keys.S))
            {
                direction.Y += 1f;
            }

            direction += _currentGamePad.ThumbSticks.Left;
            direction.Y = -direction.Y; // MonoGame thumbsticks have inverted Y.

            if (direction.LengthSquared() > 1f)
            {
                direction.Normalize();
            }

            return direction;
        }
    }

    public bool FocusHeld => IsKeyDown(_currentKeyboard, Keys.LeftShift) || IsKeyDown(_currentKeyboard, Keys.RightShift) || _currentGamePad.IsButtonDown(Buttons.RightTrigger);

    public bool FireHeld => IsKeyDown(_currentKeyboard, Keys.Space) || _currentGamePad.IsButtonDown(Buttons.A) || _currentGamePad.IsButtonDown(Buttons.RightShoulder);

    public bool FirePressed => WasKeyJustPressed(Keys.Space) || WasButtonJustPressed(Buttons.A) || WasButtonJustPressed(Buttons.RightShoulder);

    public bool PausePressed => WasKeyJustPressed(Keys.Escape) || WasButtonJustPressed(Buttons.Start);

    public bool MenuConfirmPressed => WasKeyJustPressed(Keys.Enter) || WasButtonJustPressed(Buttons.A);

    public bool ExitPressed => WasKeyJustPressed(Keys.Q) || WasButtonJustPressed(Buttons.Back);

    public bool ToggleCrtPressed => WasKeyJustPressed(Keys.C) || WasButtonJustPressed(Buttons.Y);

    public bool IncreaseCrtPressed => WasKeyJustPressed(Keys.OemCloseBrackets) || WasButtonJustPressed(Buttons.DPadRight);

    public bool DecreaseCrtPressed => WasKeyJustPressed(Keys.OemOpenBrackets) || WasButtonJustPressed(Buttons.DPadLeft);

    private static bool IsKeyDown(KeyboardState state, Keys key) => state.IsKeyDown(key);

    private bool WasKeyJustPressed(Keys key) => _currentKeyboard.IsKeyDown(key) && !_previousKeyboard.IsKeyDown(key);

    private bool WasButtonJustPressed(Buttons button) => _currentGamePad.IsButtonDown(button) && !_previousGamePad.IsButtonDown(button);
}
