# Quantum Collider Godot Project

Godot engine version is pinned to `../engine/Godot_v4.6.2-stable_win64.exe`.

## Verification

Open the editor:

```powershell
..\\engine\\Godot_v4.6.2-stable_win64.exe --path .
```

Run the GdUnit4 smoke suite headlessly:

```powershell
..\\engine\\Godot_v4.6.2-stable_win64_console.exe --path . --headless -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```
