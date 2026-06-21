$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$godotExe = Join-Path $repoRoot "engine\Godot_v4.6.2-stable_win64_console.exe"
$projectDir = Join-Path $repoRoot "game"

& $godotExe `
	--path $projectDir `
	--headless `
	-s res://addons/gdUnit4/bin/GdUnitCmdTool.gd `
	-a res://tests `
	--ignoreHeadlessMode `
	-rd user://gdunit-reports `
	-rc 3

exit $LASTEXITCODE
