param([switch]$Editor, [switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'find-godot.ps1')
$gameDirectory = Split-Path -Parent $PSScriptRoot
try {
    $engine = Find-SpireGodot
    if ($CheckOnly) { Write-Output $engine; exit 0 }
    $launchArguments = @('--path', ('"' + $gameDirectory + '"'))
    if ($Editor) { $launchArguments += '--editor' }
    # Detach standard handles from the launcher; the game's own GUI stays visible.
    $startInfo = New-Object Diagnostics.ProcessStartInfo
    $startInfo.FileName = $engine
    $startInfo.Arguments = $launchArguments -join ' '
    $startInfo.WorkingDirectory = $gameDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $gameProcess = [Diagnostics.Process]::Start($startInfo)
    $gameProcess.Dispose()
} catch {
    if ($CheckOnly) { throw }
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($_.Exception.Message, '游戏启动失败') | Out-Null
    exit 1
}
