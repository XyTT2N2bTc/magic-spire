param([string]$Path = '')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'find-godot.ps1')
$gameDirectory = Split-Path -Parent $PSScriptRoot
$engine = Find-SpireGodot -Console
$arguments = @('--headless', '--path', $gameDirectory, '--script', 'res://tools/check_content.gd', '--')
if ($Path) {
    $resolvedContentPath = (Resolve-Path -LiteralPath $Path).Path
    $arguments += '--content-dir=' + $resolvedContentPath
}
& $engine @arguments
exit $LASTEXITCODE
