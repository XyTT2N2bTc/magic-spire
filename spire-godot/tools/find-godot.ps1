function Find-SpireGodot {
    param([switch]$Console)
    $found = @()
    if ($env:GODOT_BIN -and (Test-Path -LiteralPath $env:GODOT_BIN -PathType Leaf)) {
        $found += $env:GODOT_BIN
    }
    foreach ($commandName in @('godot', 'godot4')) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) { $found += $command.Source }
    }
    $downloads = Join-Path $env:USERPROFILE 'Downloads'
    if (Test-Path -LiteralPath $downloads) {
        $folders = @(Get-ChildItem -LiteralPath $downloads -Directory -Filter 'Godot*' -ErrorAction SilentlyContinue)
        foreach ($folder in $folders) {
            $found += @(Get-ChildItem -LiteralPath $folder.FullName -File -Filter 'Godot*_win64*.exe' | Select-Object -ExpandProperty FullName)
        }
        $found += @(Get-ChildItem -LiteralPath $downloads -File -Filter 'Godot*_win64*.exe' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
    }
    if ($found.Count -eq 0) { throw 'Godot 4 was not found. Set GODOT_BIN to your Godot executable or open project.godot in Godot 4.' }
    $chosen = @($found | Where-Object { ($_ -like '*_console.exe') -eq [bool]$Console })
    if ($chosen.Count -gt 0) { return $chosen[0] }
    return $found[0]
}
