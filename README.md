# ASHVAULT: The Last Flame — Android Tower Defense Prototype

This is an original, asset-free Godot 4 prototype. It is a playable first slice, not a finished commercial game or an APK yet.

## Prototype features
- Dark Indian-inspired fantasy battlefield with a winding route and fortress.
- Three base towers: Ember, Gale, and Rune.
- Three fusion results: Stormforge, Soulflame, and Voidroot.
- Enemy waves, fast enemies, heavy enemies, gold, lives, rewards, and defeat/restart flow.
- Procedural shapes and effects, so no third-party art is required to test the mechanics.
- Mouse and touch input support.

## Controls
1. Choose Ember, Gale, or Rune from the bottom bar.
2. Tap a glowing build pad to place a tower.
3. Place two different base towers.
4. Tap the first tower, then the second tower to fuse them. Fusion costs 50 gold.
5. Tap Start Wave to send enemies along the route.

## Run on a computer
1. Install Godot 4.3 or a compatible Godot 4 release.
2. Open `project.godot` in Godot.
3. Press F6 or F5 to run the main scene/project.

## Export to Android APK
1. Install the Android SDK and Java SDK supported by your chosen Godot release.
2. In Godot, open Editor Settings > Export > Android and set the SDK paths.
3. Install the Android export templates from Godot's editor.
4. Use Project > Export, add an Android preset, and export a debug APK.
5. Install the APK on an Android device and test touch input, screen scaling, and performance.

The exact export setup can vary by Godot version and operating system. This source bundle has not been compiled or device-tested in this environment.

## Next development stages
1. Replace procedural placeholder art with a coherent original asset pack.
2. Add proper enemy classes, attack telegraphs, tower range indicators, upgrade choices, and boss logic.
3. Add level selection, persistent progression, audio, settings, and tutorial flow.
4. Profile on a real Android phone and adjust layout for aspect ratios and touch targets.
