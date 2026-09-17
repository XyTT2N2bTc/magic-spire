param([switch]$Write)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'find-godot.ps1')
$gameDirectory = Split-Path -Parent $PSScriptRoot
$engine = Find-SpireGodot -Console
[IO.Directory]::CreateDirectory((Join-Path $gameDirectory 'build')) | Out-Null
$logPath = Join-Path $gameDirectory ('build/check-index-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff') + '.log')
$arguments = @('--headless', '--path', $gameDirectory, '--log-file', $logPath, '--script', 'res://tools/build_check_index.gd', '--')
$arguments += if ($Write) { '--write' } else { '--verify' }
# Own the child process explicitly: the gate must not read a half-written log.
$startInfo = [Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $engine
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.Arguments = (($arguments | ForEach-Object { '"' + $_.Replace('"', '\"') + '"' }) -join ' ')
$process = [Diagnostics.Process]::new()
$process.StartInfo = $startInfo
$exitCode = 1
try {
    [void]$process.Start()
    if (-not $process.WaitForExit(300 * 1000)) { $process.Kill(); $process.WaitForExit(); throw 'Index check exceeded 300s.' }
    $exitCode = $process.ExitCode
} finally {
    $process.Dispose()
}
if (Test-Path -LiteralPath $logPath) {
    Get-Content -LiteralPath $logPath | Where-Object { $_ -match '^CHECK INDEX ' } | Write-Output
}
Write-Output ('CHECK INDEX MODE: ' + $(if ($Write) { 'write (frozen index overwritten)' } else { 'verify (zero drift, exit code 0/1)' }))
Write-Output ('CHECK INDEX LOG: ' + $logPath)
exit $exitCode
