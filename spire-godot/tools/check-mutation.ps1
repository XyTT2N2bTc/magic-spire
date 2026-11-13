param(
    [string[]]$Check = @(),
    [switch]$All,
    [ValidateRange(1,3600)][int]$TimeoutSeconds = 600
)
# Sensitivity evidence for the named checks: for one entry of tests/mutations.json (schema 2: a
# judgment name maps to a non-empty array of clause entries), apply the entry's declared edits in
# order, delegate its rules/UI/recipe phase to check.ps1, require that named check to redden in the
# target phase's original log and summary -- on a line that also carries the entry's `expect`
# substring when one is declared -- then restore the file byte-for-byte. Any failure -- an edit
# anchor not unique at its step, suite green, suite failed without a matching error line, restore
# hash mismatch -- makes the whole invocation exit non-zero.
#
# The table's find/replace strings use \n; each anchor and each injected text are expanded to the
# target file's own line ending (CRLF here) so matching and writing stay byte-exact. The sequential
# apply-and-count algorithm here is the same one tests/architecture_cases.gd::mutation_anchor_report
# carries for the static side (different languages, names are kept in step in both comments).
#
# This tool mutates tracked source for the duration of one suite run. Run it with one engine
# process at a time and never concurrently with another gate.
#
# Each run binds itself to the commit it verified: a RUN IDENTITY block (same shape as
# check.ps1's recipe phase) is written to build/mutations/<runId>/identity.txt at run start.
# `worktree unchanged` in the summary only means the porcelain status did not change across
# the run -- it never means the worktree was clean; cleanliness is read from head + dirty.
$ErrorActionPreference = 'Stop'
$Check = @($Check | ForEach-Object { $_ -split ',' } | Where-Object { $_ } | Select-Object -Unique)
if ($All -and $Check.Count -gt 0) { throw '-All and -Check are mutually exclusive.' }
if (-not $All -and $Check.Count -eq 0) { throw 'Select entries with -All or -Check <name>[#<clause>].' }
. (Join-Path $PSScriptRoot 'find-godot.ps1')
$gameDirectory = Split-Path -Parent $PSScriptRoot
$repositoryRoot = Split-Path -Parent $gameDirectory
$engine = Find-SpireGodot -Console
$tablePath = Join-Path $gameDirectory 'tests/mutations.json'
$table = [IO.File]::ReadAllText($tablePath, [Text.UTF8Encoding]::new($false)) | ConvertFrom-Json
if ($table.schema -ne 2) { throw 'tests/mutations.json: unexpected schema (expected 2).' }
$names = @($table.mutations.PSObject.Properties.Name)
if ($names.Count -eq 0) { throw 'tests/mutations.json: no entries.' }
foreach ($name in $names) {
    if ($table.mutations.$name -isnot [array]) { throw ('tests/mutations.json: ' + $name + ' is not an entry array (schema 2).') }
}
$selected = [Collections.Generic.List[object]]::new()
if ($All) {
    foreach ($name in $names) { foreach ($row in @($table.mutations.$name)) { $selected.Add(@{ name = $name; row = $row }) } }
} else {
    foreach ($token in $Check) {
        $parts = @($token -split '#', 2)
        $name = $parts[0]
        if ($name -notin $names) { throw ('Unknown mutation entry: ' + $name) }
        $rows = @($table.mutations.$name)
        if ($parts.Count -eq 1) {
            foreach ($row in $rows) { $selected.Add(@{ name = $name; row = $row }) }
            continue
        }
        $clause = $parts[1]
        $match = @($rows | Where-Object { [string]$_.clause -eq $clause })
        if ($match.Count -eq 0) { throw ('Unknown mutation clause: ' + $token) }
        if ($match.Count -gt 1) { throw ('Ambiguous mutation clause (declared more than once): ' + $token) }
        $selected.Add(@{ name = $name; row = $match[0] })
    }
}
$entryCount = 0
foreach ($name in $names) { $entryCount += @($table.mutations.$name).Count }
$runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff') + '-' + $PID
$runDirectory = Join-Path $gameDirectory ('build/mutations/' + $runId)
[IO.Directory]::CreateDirectory($runDirectory) | Out-Null
Write-Output ('MUTATION LOGS: ' + $runDirectory)
Write-Output ('MUTATION TABLE: ' + $entryCount + ' entry(ies) in ' + $names.Count + ' judgment(s); this run selects ' + $selected.Count + '.')
$statusEntries = [string[]]@(git -C $repositoryRoot status --porcelain)
$statusBefore = ($statusEntries -join "`n")
$head = 'unavailable'
try { $head = ((git -C $repositoryRoot rev-parse HEAD) | Select-Object -First 1).Trim() } catch {}
$identity = [Collections.Generic.List[string]]::new()
$identity.Add('RUN IDENTITY')
$identity.Add('head=' + $head)
$identity.Add('started=' + [DateTime]::Now.ToString('yyyy-MM-ddTHH:mm:sszzz'))
$identity.Add('dirty=' + $statusEntries.Count)
$identity.AddRange($statusEntries)
[IO.File]::WriteAllLines((Join-Path $runDirectory 'identity.txt'), $identity, [Text.UTF8Encoding]::new($false))
$identity | Write-Output
$timer = [Diagnostics.Stopwatch]::StartNew()
$rows = [Collections.Generic.List[object]]::new()

function Get-MutationExecution {
    param($Row)
    $execution = if ($Row.PSObject.Properties.Name -contains 'execution') { [string]$Row.execution } else { 'rules' }
    if ($execution -notin @('rules','ui','recipe')) { throw ('Unknown mutation execution: ' + $execution) }
    if ($execution -eq 'recipe' -and [string]$Row.suite -ne 'recipe') { throw 'Recipe execution requires suite=recipe.' }
    return $execution
}

function Invoke-MutationCheck {
    param([string]$Execution, [string]$Suite)
    $arguments = @('-NoProfile','-File',(Join-Path $PSScriptRoot 'check.ps1'),'-TimeoutSeconds',[string]$TimeoutSeconds)
    switch ($Execution) {
        'rules' { $arguments += @('-Suite',$Suite) }
        'ui' { $arguments += @('-UIOnly','-UISuite',$Suite) }
        'recipe' { $arguments += @('-Suite','recipe') }
    }
    # check.ps1 owns the only phase routing, engine argv and process timeout lifecycle.
    $output = (& (Get-Process -Id $PID).Path @arguments 2>&1 | Out-String)
    $code = $LASTEXITCODE
    Write-Host $output
    $found = [regex]::Match($output,'(?m)^SUMMARY: ([^\r\n]+)')
    if (-not $found.Success) { throw ('Child check did not publish a summary (exit=' + $code + ').') }
    return @{ exit=$code; summary=$found.Groups[1].Value.Trim() }
}

function Get-EditCount {
    param([string]$Text, [string]$Needle)
    if (-not $Needle) { return 0 }
    $count = 0; $index = 0
    while (($index = $Text.IndexOf($Needle, $index, [StringComparison]::Ordinal)) -ge 0) { $count++; $index += $Needle.Length }
    return $count
}

# Applies one entry's edits to $Text in order and returns @{ text; counts }: `counts` holds the
# occurrence count of each normalized find at the step it is applied. A step whose count is not
# exactly one is not applied (later steps are still counted against the same text), so the caller
# can fail the entry while the count sequence stays comparable to the static side. This is the
# same sequential count/apply algorithm as tests/architecture_cases.gd::mutation_anchor_report
# (different language, same order and same per-step rule; keep the two in step by name).
function Invoke-MutationEditPlan {
    param([string]$Text, $Edits)
    $newline = if ($Text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $counts = [Collections.Generic.List[int]]::new()
    foreach ($edit in $Edits) {
        if (-not ($edit.find -is [string]) -or -not ($edit.replace -is [string])) { throw 'edit is missing find/replace.' }
        $find = $edit.find -replace "`r?`n", $newline
        $replace = $edit.replace -replace "`r?`n", $newline
        if ($find -ceq $replace) { throw 'edit has identical find and replace.' }
        $count = Get-EditCount -Text $Text -Needle $find
        $counts.Add($count)
        if ($count -eq 1) { $Text = $Text.Replace($find, $replace) }
    }
    return @{ text = $Text; counts = $counts.ToArray() }
}

foreach ($selection in $selected) {
    $name = [string]$selection.name
    $row = $selection.row
    $result = [ordered]@{ name = $name; file = [string]$row.file; suite = [string]$row.suite; red = $false; restored = $false; hash = ''; reason = ''; seconds = 0.0; log = '' }
    $entryTimer = [Diagnostics.Stopwatch]::StartNew()
    $mutated = $false
    $original = $null
    $originalHash = ''
    $path = ''
    try {
        $clause = [string]$row.clause
        if (-not $clause) { throw 'entry is missing clause.' }
        $result.name = $name + '#' + $clause
        $edits = @($row.edits)
        if (-not $row.file -or -not $row.suite -or $edits.Count -eq 0) { throw 'entry is missing file/suite/a non-empty edits list.' }
        $expect = if ($row.PSObject.Properties.Name -contains 'expect') { [string]$row.expect } else { '' }
        if (-not $expect -and @($table.mutations.$name).Count -gt 1) { throw 'a judgment with several entries must declare expect on every entry.' }
        $execution = Get-MutationExecution -Row $row
        $path = Join-Path $gameDirectory ([string]$row.file)
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw ('target file not found: ' + $row.file) }
        $original = [IO.File]::ReadAllBytes($path)
        $originalHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        $hasBom = $original.Length -ge 3 -and $original[0] -eq 0xEF -and $original[1] -eq 0xBB -and $original[2] -eq 0xBF
        $text = [Text.Encoding]::UTF8.GetString($original, $(if ($hasBom) { 3 } else { 0 }), $original.Length - $(if ($hasBom) { 3 } else { 0 }))
        $originalText = $text
        $plan = Invoke-MutationEditPlan -Text $originalText -Edits $edits
        $badStep = -1
        for ($index = 0; $index -lt $plan.counts.Count; $index++) { if ($plan.counts[$index] -ne 1) { $badStep = $index; break } }
        if ($badStep -ge 0) { throw ('edit ' + ($badStep + 1) + ' anchor must occur exactly once in ' + $row.file + ' at the step it is applied; found ' + $plan.counts[$badStep]) }
        if ($plan.text -ceq $originalText) { throw 'mutation left the file unchanged.' }
        $text = [string]$plan.text
        $bytes = [Text.Encoding]::UTF8.GetBytes($text)
        if ($hasBom) { [IO.File]::WriteAllBytes($path, [byte[]](@(0xEF, 0xBB, 0xBF) + $bytes)) } else { [IO.File]::WriteAllBytes($path, $bytes) }
        $mutated = $true
        $run = Invoke-MutationCheck -Execution $execution -Suite ([string]$row.suite)
        $summary = [IO.File]::ReadAllText($run.summary) | ConvertFrom-Json
        Write-Output ('MUTATION CHILD SUMMARY: ' + $run.summary + '; execution=' + $execution)
        if ($run.exit -eq 0 -or $summary.status -ne 'failed' -or $summary.before -ne $summary.after) { throw 'Child check must fail without changing source during execution.' }
        if ($summary.docs.status -ne 'passed') { throw 'Document phase failure is not target mutation RED.' }
        $stage = $summary.$execution
        $log = [string]$stage.log
        $result.log = $log
        if (-not $log -or -not (Test-Path -LiteralPath $log)) { throw 'Target phase did not publish its original log.' }
        $output = [IO.File]::ReadAllText($log)
        if ($output -match 'SOURCE CHANGED:|Failed to read the root certificate store|SCRIPT ERROR:|PARSE ERROR:|ObjectDB instances were leaked|resources still in use') { throw 'Target phase contains a source/environment/loading/runtime failure, not a judgment RED.' }
        $errorLines = @($output -split '\r?\n' | Where-Object { $_ -match '^\s*(?:stderr: )?(?:USER )?ERROR:' -and $_.Contains($name) })
        if ($errorLines.Count -eq 0) { throw ('No target error names the mutated check ' + $name + '.') }
        if ($expect -and @($errorLines | Where-Object { $_.Contains($expect) }).Count -eq 0) { throw ('No target error names the mutated check ' + $name + ' and contains the declared expect "' + $expect + '".') }
        if ($execution -eq 'recipe') {
            if ($stage.seed -ne 7 -or $stage.commits -ne 60 -or $stage.stop -ne 'cap' -or $stage.exit -eq 0) { throw 'Recipe did not finish its unchanged 60-commit input cap with a failed assertion.' }
            if ($output -notmatch '(?m)^RECIPE DRIVER .*seed=7 cap=60 style=trade window=1600x900\s*$' -or $output -notmatch '(?m)^RECIPE seed=7 commits=60 steps=\d+ stop=cap\s*$' -or $output -notmatch '(?m)^UI FAIL: \d+ assertions\s*$' -or $output -notmatch '(?m)^F3 OBSERVER RESTORED true\s*$') { throw 'Recipe target identity/completion/failure/restore markers are incomplete.' }
        } else {
            $started = $output -match ('(?m)^SUITE START: ' + [regex]::Escape([string]$row.suite) + '\s*$')
            $failed = $output -match ('(?m)^SUITE RESULT: ' + [regex]::Escape([string]$row.suite) + ' FAIL\s*$')
            if (-not $started -or -not $failed -or [string]$row.suite -notin $stage.failed) { throw 'Target suite never completed with its named FAIL result.' }
            if ($execution -eq 'ui' -and $output -notmatch '(?m)^UI FAIL: \d+ assertions\s*$') { throw 'UI completion failure marker is missing.' }
        }
        $result.red = $true
    } catch {
        $result.reason = $_.Exception.Message
    } finally {
        if ($mutated) {
            [IO.File]::WriteAllBytes($path, $original)
            $restoredHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
            $result.restored = $restoredHash -eq $originalHash
            if (-not $result.restored) { $result.reason = 'restore hash mismatch: ' + $restoredHash + ' != ' + $originalHash }
        }
        $entryTimer.Stop()
        $result.seconds = [math]::Round($entryTimer.Elapsed.TotalSeconds, 1)
        $result.hash = if ($originalHash) { $originalHash.Substring(0, [Math]::Min(12,$originalHash.Length)) } else { '' }
        $rows.Add($result)
    }
    $verdict = if ($result.red -and $result.restored) { 'RED' } else { 'FAILED' }
    $detail = if ($result.reason) { ' -- ' + $result.reason } else { '' }
    Write-Output ('MUTATION ' + $result.name + ' [' + $result.file + ']: ' + $verdict + ' exit-red=' + $result.red + ' restored=' + $result.restored + ' sha256=' + $result.hash + ' ' + $result.seconds + 's' + $detail)
    if ($result.log) { Write-Output ('  log: ' + $result.log) }
}
$timer.Stop()
$statusAfter = (@(git -C $repositoryRoot status --porcelain) -join "`n")
$clean = $statusAfter -eq $statusBefore
if (-not $clean) { Write-Output 'MUTATION RESIDUE: git status changed across the run; inspect the worktree.' }
$good = @($rows | Where-Object { $_.red -and $_.restored }).Count
Write-Output ('MUTATION SUMMARY: ' + $good + '/' + $rows.Count + ' entr(ies) reddened the named check and restored byte-for-byte; worktree unchanged=' + $clean + ' (pre-dirty=' + $statusEntries.Count + '); elapsed ' + [math]::Round($timer.Elapsed.TotalSeconds, 1) + 's')
if ($good -ne $rows.Count -or -not $clean) { exit 1 }
exit 0
