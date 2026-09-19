# Shared packaging guard for the content pack root constant. Content packs are excluded from the
# Windows PCK and copied beside the executable, so exporting with the development constant ships a
# package that cannot load its packs. The packaging scripts assert the value their platform needs
# before exporting; the constant is never flipped automatically.
function Assert-SpirePacksRoot {
    param([Parameter(Mandatory)][string]$GameDirectory, [Parameter(Mandatory)][string]$Expected)
    $file = Join-Path $GameDirectory 'core/content_catalog.gd'
    if (-not (Test-Path -LiteralPath $file)) { throw ('Content catalog is missing: ' + $file) }
    $match = [regex]::Match((Get-Content -LiteralPath $file -Raw), '(?m)^const\s+PACKS_ROOT\s*:?=\s*"([^"]*)"')
    if (-not $match.Success) { throw ('PACKS_ROOT is not declared in ' + $file) }
    $actual = $match.Groups[1].Value
    if ($actual -ceq $Expected) { return }
    throw ('Content packs would not load: PACKS_ROOT is "' + $actual + '" in ' + $file + '. This export needs "' + $Expected + '"; change that line to: const PACKS_ROOT := "' + $Expected + '"')
}
