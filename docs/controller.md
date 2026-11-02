# Controller setup

Tested with a DualSense only.

1. Start the game through Steam, so the pad is visible to it.
2. In `Documents/Assetto Corsa/cfg/controls.ini` inside the prefix, set:

   ```ini
   INPUT_METHOD=X360
   ```

3. Optional but recommended for a gamepad: install [Advanced Gamepad Assist](https://github.com/adam10603/AC-Advanced-Gamepad-Assist). Copy its files into the game folder, then set this in `Documents/Assetto Corsa/cfg/extension/gamepad_fx.ini`:

   ```ini
   [JOYPAD_ASSIST]
   ENABLED=1
   IMPLEMENTATION=Advanced Gamepad Assist
   ```

On the test machine, the pad reached the game as a raw HID device, and Custom Shaders Patch's gamepad support handled it from there. A separate XInput test run outside Steam didn't see any pad.
