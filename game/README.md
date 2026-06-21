# Quantum Collider Godot Project

Godot engine version is pinned to `../engine/Godot_v4.6.2-stable_win64.exe`.

## Verification

Open the editor:

```powershell
..\\engine\\Godot_v4.6.2-stable_win64.exe --path .
```

Run the GdUnit4 smoke suite headlessly:

```powershell
..\\scripts\\run_gdunit.ps1
```

The script writes GdUnit4 reports to `user://gdunit-reports` with a small
history cap, so generated reports do not accumulate under `res://reports/`.
