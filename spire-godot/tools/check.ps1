param(
    [switch]$UI, [switch]$UIOnly, [switch]$Import, [switch]$VerifyRunner,
    [switch]$Exhaustive, [switch]$ListOnly, [switch]$Impact, [switch]$KeepGoing,
    [switch]$Changed, [string]$Since = '', [string]$ChangedList = '',
    [string]$RerunFailed = '', [string[]]$Screenshots = @(),
    [string[]]$Suite = @('runner', 'architecture'), [string[]]$UISuite = @('home'),
    [ValidateRange(1,3600)][int]$TimeoutSeconds = 300
)
$ErrorActionPreference = 'Stop'
$Suite = @($Suite | ForEach-Object { $_ -split ',' } | Select-Object -Unique)
$UISuite = @($UISuite | ForEach-Object { $_ -split ',' } | Select-Object -Unique)
if ($RerunFailed) {
    foreach ($option in @('Suite','UISuite','UI','UIOnly','Impact','Exhaustive')) {
        if ($PSBoundParameters.ContainsKey($option)) { throw "-RerunFailed cannot be combined with -$option." }
    }
    $previousPath = if (Test-Path -LiteralPath $RerunFailed -PathType Container) { Join-Path $RerunFailed 'summary.json' } else { $RerunFailed }
    $previous = Get-Content -LiteralPath $previousPath -Raw | ConvertFrom-Json
    if ($previous.schema -ne 1 -or $previous.status -eq 'plan') { throw 'Expected a completed check summary, not a plan.' }
    if ($previous.status -eq 'passed') { throw 'The previous check already passed; select a new scope explicitly.' }
    $Suite = @($previous.rules.retry)
    $UISuite = @($previous.ui.retry)
    if (-not $ListOnly) { $VerifyRunner = $VerifyRunner -or $previous.verify_runner }
    if ($Suite.Count + $UISuite.Count -eq 0) {
        if ($VerifyRunner) { $Suite = @('runner') } else { throw 'No failed or unfinished suites to rerun.' }
    }
    $UIOnly = $Suite.Count -eq 0
    $UI = $UISuite.Count -gt 0
    $Exhaustive = $previous.exhaustive
    $Impact = $previous.impact -and -not $previous.rules.scope_resolved -and -not $UIOnly
    Write-Output 'RERUN: failed/unfinished suites only; this is not a full-project pass.'
}
if ($UI -and -not $UIOnly -and $PSBoundParameters.ContainsKey('Suite') -and -not $PSBoundParameters.ContainsKey('UISuite')) {
    throw 'Use -UISuite with targeted -UI; use -UIOnly for window checks alone.'
}
if ($UIOnly -and $PSBoundParameters.ContainsKey('Suite')) {
    throw '-UIOnly does not run -Suite; select window checks with -UISuite.'
}
if ($PSBoundParameters.ContainsKey('UISuite') -and -not ($UI -or $UIOnly)) {
    throw '-UISuite requires -UI or -UIOnly; window checks would otherwise be skipped.'
}
if ($ListOnly -and ($Import -or $VerifyRunner)) { throw '-ListOnly cannot be combined with -Import or -VerifyRunner.' }
if ($UIOnly -and $Impact) { throw '-Impact applies to rule suites; UI suites are selected explicitly.' }
# Route mode: the change set decides the scope, so an explicit scope is a conflict.
$routeMode = [bool]($Changed -or $ChangedList)
if ($Since -and -not $Changed) { throw '-Since requires -Changed.' }
if ($Changed -and $ChangedList) { throw '-Changed and -ChangedList are mutually exclusive.' }
if ($routeMode -and $RerunFailed) { throw '-RerunFailed cannot be combined with -Changed or -ChangedList.' }
if ($routeMode) {
    foreach ($option in @('Suite','UISuite','UI','UIOnly','Impact')) {
        if ($PSBoundParameters.ContainsKey($option)) { throw "-Changed/-ChangedList cannot be combined with -$option." }
    }
}
$gameDirectory = Split-Path -Parent $PSScriptRoot
$repoRoot = ''
$routeFiles = @()
$declaredNone = @('docs/','release/','.zcode/','spire-godot/build/','spire-godot/.godot/')
function Test-DeclaredNone {
    param([string]$Path)
    foreach ($prefix in $declaredNone) { if ($Path.StartsWith($prefix)) { return $true } }
    if ($Path -match '^[^/]+\.md$') { return $true }
    return $Path -in @('README.md','AGENTS.md','.gitignore','LICENSE','ASSET_RIGHTS.md')
}
if ($routeMode) {
    $repoRoot = (& git -C $gameDirectory rev-parse --show-toplevel)
    if ($LASTEXITCODE -ne 0 -or -not $repoRoot) { throw 'Cannot locate the repository root with git.' }
    $repoRoot = $repoRoot.Trim().Replace('\','/')
    if ($Changed) {
        $base = if ($Since) { $Since } else { 'HEAD' }
        $tracked = @(& git -C $repoRoot -c core.quotepath=false diff --name-only $base)
        if ($LASTEXITCODE -ne 0) { throw "git diff failed for base $base." }
        $untracked = @(& git -C $repoRoot -c core.quotepath=false ls-files --others --exclude-standard)
        if ($LASTEXITCODE -ne 0) { throw 'git ls-files failed for the untracked change set.' }
        $routeFiles = @($tracked + $untracked | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    } else {
        $routeFiles = @(Get-Content -LiteralPath $ChangedList | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and -not $_.StartsWith('#') })
    }
    # Ambiguous git lines are rejected instead of guessed (renames, quoted paths).
    $ambiguous = @($routeFiles | Where-Object { $_ -match '"' -or $_ -match '=>' -or $_ -match "`t" })
    if ($ambiguous.Count -gt 0) { throw "Ambiguous change-set line(s): $($ambiguous -join ', '). Use -ChangedList with explicit module paths." }
    # Strip one leading "./" only: TrimStart('./') would also eat the dot of paths
    # like .zcode/skills/repo-ops/SKILL.md and turn declared-none into an error.
    $routeFiles = @($routeFiles | ForEach-Object { $_.Replace('\','/') } | ForEach-Object { if ($_.StartsWith('./')) { $_.Substring(2) } else { $_ } } | Sort-Object -Unique)
    if ($routeFiles.Count -eq 0) { throw 'The change set is empty; committed changes need -Changed -Since <ref> (default base is HEAD).' }
    foreach ($file in $routeFiles) {
        if ($file.StartsWith('spire-godot/')) { continue }
        if (Test-DeclaredNone $file) { continue }
        throw "Path is outside spire-godot/: $file. That is not source; use -ChangedList with explicit module paths."
    }
}
. (Join-Path $PSScriptRoot 'find-godot.ps1')
$engine = Find-SpireGodot -Console
$buildDirectory = Join-Path $gameDirectory 'build'
[IO.Directory]::CreateDirectory($buildDirectory) | Out-Null
[IO.File]::Open((Join-Path $buildDirectory '.gdignore'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite).Dispose()
$checkRunId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff') + '-' + $PID
$checkDirectory = Join-Path $buildDirectory ('checks/' + $checkRunId)
[IO.Directory]::CreateDirectory($checkDirectory) | Out-Null
Write-Output ('CHECK LOGS: ' + $checkDirectory)

# Record source stability, never reuse PASS from a previous source version.
function Get-SourceFingerprint {
    $entries = [Collections.Generic.List[string]]::new()
    foreach ($directory in @('core','data','ui','tests','content','assets','tools')) {
        Get-ChildItem -LiteralPath (Join-Path $gameDirectory $directory) -File -Recurse | Where-Object {
            $_.Extension -in @('.gd','.json','.tscn','.tres','.svg','.png','.webp','.ps1','.py')
        } | ForEach-Object {
            $relative = $_.FullName.Substring($gameDirectory.Length + 1)
            $entries.Add($relative + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)
        }
    }
    Get-ChildItem -LiteralPath $gameDirectory -File | Where-Object { $_.Extension -in @('.godot','.gd','.tscn','.tres') } | ForEach-Object {
        $entries.Add($_.Name + ':' + (Get-FileHash -LiteralPath $_.FullName).Hash)
    }
    $bytes = [Text.Encoding]::UTF8.GetBytes((($entries | Sort-Object) -join "`n"))
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','') } finally { $sha.Dispose() }
}

function Get-PhaseSummary {
    param([string]$Name, [string[]]$Requested, [bool]$Enabled)
    $logPath = Join-Path $checkDirectory ('check-' + $Name + '.log')
    $output = if (Test-Path -LiteralPath $logPath) { [IO.File]::ReadAllText($logPath) } else { '' }
    $scope = [regex]::Match($output, '(?m)^(?:RULE|UI) SCOPE: ([^\r\n]+)')
    $selected = if (-not $Enabled) { @() } elseif ($scope.Success) { @($scope.Groups[1].Value -split ',') } else { @($Requested) }
    $passed = @(); $failed = @()
    foreach ($result in [regex]::Matches($output, '(?m)^SUITE RESULT: (\S+) (PASS|FAIL)')) {
        if ($result.Groups[2].Value -eq 'PASS') { $passed += $result.Groups[1].Value } else { $failed += $result.Groups[1].Value }
    }
    foreach ($start in [regex]::Matches($output, '(?m)^SUITE START: (\S+)')) {
        $nameValue = $start.Groups[1].Value
        if ($nameValue -notin $passed -and $nameValue -notin $failed) { $failed += $nameValue }
    }
    $unrun = @($selected | Where-Object { $_ -notin $passed -and $_ -notin $failed })
    $retry = @($selected | Where-Object { $_ -notin $passed })
    $complete = $output -match '(?m)^(?:UI )?PASS: \d+ assertions\s*$'
    if ($Enabled -and -not $complete -and $retry.Count -eq 0 -and -not $ListOnly) { $retry = @($selected) }
    return [ordered]@{ selected=@($selected); passed=@($passed); failed=@($failed); unrun=@($unrun); retry=@($retry); scope_resolved=$scope.Success; complete=$complete; log=$logPath }
}

# Every engine process is owned by this invocation; never stop an interactive game.
function Invoke-CheckEngine {
    param([string]$Log, [string[]]$Arguments, [int]$LimitSeconds = $TimeoutSeconds)
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $engine
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.Arguments = ((@('--path', $gameDirectory, '--log-file', $Log) + $Arguments) | ForEach-Object {
        '"' + $_.Replace('"', '\"') + '"'
    }) -join ' '
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        [void]$process.Start()
        if (-not $process.WaitForExit($LimitSeconds * 1000)) {
            $process.Kill()
            $process.WaitForExit()
            throw [TimeoutException]::new("Godot check exceeded ${LimitSeconds}s. See $Log")
        }
        return $process.ExitCode
    } finally {
        $process.Dispose()
    }
}

function Invoke-SpireCheck {
    param([string]$Name, [string[]]$EngineArguments, [string]$Expected = '')
    $checkLog = Join-Path $checkDirectory ('check-' + $Name + '.log')
    [IO.File]::WriteAllText($checkLog, '')
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $checkExit = Invoke-CheckEngine -Log $checkLog -Arguments $EngineArguments
    $output = [IO.File]::ReadAllText($checkLog)
    $output -split '\r?\n' | Where-Object { $_ -match '^(RULE |UI SCOPE:|SUITE RESULT:|SAMPLES |PASS:|UI PASS:|FAIL:|UI FAIL:|PLAN ONLY:)' -or ($ListOnly -and $_ -match '^  \S+ \[') } | Write-Output
    if ($checkExit -ne 0 -or $output -match '(?m)^\s*(?:USER )?(?:SCRIPT |PARSE )?ERROR:') {
        $output -split '\r?\n' | Where-Object { $_ -match '^\s*(?:USER )?(?:SCRIPT |PARSE )?ERROR:' } | Select-Object -First 3 | Write-Output
        throw "Godot $Name check failed (exit=$checkExit). See $checkLog"
    }
    if ($Expected -and $output -notmatch $Expected) { throw "Godot $Name check did not finish. See $checkLog" }
    Write-Output ('CHECK {0}: {1:N2}s' -f $Name, $timer.Elapsed.TotalSeconds)
}

$beforeFingerprint = Get-SourceFingerprint
$exitCode = 0
$failureMessage = ''
$routeSummary = $null
$gateResults = $null
$planOnly = [bool]($routeMode -and $ListOnly)
try {
    if ($routeMode) {
        # Plan host first: it prints the ROUTE lines and writes the plan JSON that
        # decides both phases. No test host starts before the plan is accepted, and
        # the ROUTE lines are the review surface for every default decision.
        $routeListPath = Join-Path $checkDirectory 'changed-files.txt'
        [IO.File]::WriteAllLines($routeListPath, $routeFiles, [Text.UTF8Encoding]::new($false))
        $routePlanPath = Join-Path $checkDirectory 'route-plan.json'
        $routeLogPath = Join-Path $checkDirectory 'check-route.log'
        $routeArguments = @('--headless', '--script', 'res://tests/route_plan.gd', '--', ('--files=' + $routeListPath), ('--plan=' + $routePlanPath))
        if ($ListOnly) { $routeArguments += '--list-only' }
        $routeExit = Invoke-CheckEngine -Log $routeLogPath -Arguments $routeArguments
        $routeOutput = [IO.File]::ReadAllText($routeLogPath)
        $routeOutput -split '\r?\n' | Where-Object { $_ -match '^(ROUTE |PLAN ONLY:)' } | Write-Output
        if ($routeExit -ne 0 -or -not (Test-Path -LiteralPath $routePlanPath)) { throw "Route plan refused the change set (exit=$routeExit). See $routeLogPath" }
        $plan = Get-Content -LiteralPath $routePlanPath -Raw | ConvertFrom-Json
        $Suite = @($plan.rules | Where-Object { $_ })
        $UISuite = @($plan.ui | Where-Object { $_ })
        $UI = $UISuite.Count -gt 0
        $UIOnly = $Suite.Count -eq 0
        $routeSummary = [ordered]@{ mode=$plan.mode; since=$Since; files_count=@($plan.files).Count; files_sha256=$plan.files_sha256
            index_digest=$plan.index_digest; rules=@($plan.rules); ui=@($plan.ui); gates=@($plan.gates); unmapped=@($plan.unmapped)
            default_files=@($plan.default_files); blind_files=@($plan.blind_files); defect_hits=@($plan.defect_hits)
            widen=@($plan.widen); widen_candidates=@($plan.widen_candidates); milestone=@($plan.milestone); notes=@($plan.notes)
            declared_none=@($plan.declared_none); plan=$routePlanPath; log=$routeLogPath }
    }
    if (-not $planOnly -and ($Import -or -not (Test-Path -LiteralPath (Join-Path $gameDirectory '.godot')))) {
        Invoke-SpireCheck -Name 'import' -EngineArguments @('--headless', '--editor', '--quit')
    }
    if (-not $planOnly -and -not $UIOnly) {
        $arguments = @('--headless', '--script', 'res://tests/test_game.gd', '--', ('--suite=' + ($Suite -join ',')))
        if ($Impact) { $arguments += '--impact' }
        if ($Exhaustive) { $arguments += '--exhaustive' }
        if ($KeepGoing) { $arguments += '--keep-going' }
        if ($ListOnly) { $arguments += '--list-only' }
        $expected = if ($ListOnly) { '(?m)^PLAN ONLY: no rule tests executed$' } else { '(?m)^PASS: \d+ assertions\s*$' }
        Invoke-SpireCheck -Name 'rules' -EngineArguments $arguments -Expected $expected
    }
    if (-not $planOnly -and ($UI -or $UIOnly)) {
        $arguments = @('--script', 'res://tests/ui_smoke.gd', '--', ('--ui-suite=' + ($UISuite -join ',')))
        if ($KeepGoing) { $arguments += '--keep-going' }
        if ($Screenshots.Count -gt 0) { $arguments += ('--screenshots=' + ($Screenshots -join ',')) }
        if ($ListOnly) { $arguments = @('--headless') + $arguments + @('--list-only') }
        $expected = if ($ListOnly) { '(?m)^PLAN ONLY: no UI tests executed$' } else { '(?m)^UI PASS: \d+ assertions\s*$' }
        Invoke-SpireCheck -Name 'ui' -EngineArguments $arguments -Expected $expected
    }
    if ($routeMode -and -not $planOnly -and @($plan.gates) -contains 'content') {
        # The content gate is its own phase (contract §10-9): its exit code and log are
        # recorded in summary.route.gate_results and are not rule/UI conclusions.
        $gateLog = Join-Path $checkDirectory 'check-content.log'
        $gateOutput = ''
        $gateExit = 1
        try {
            $gateOutput = (& (Get-Process -Id $PID).Path -NoProfile -File (Join-Path $PSScriptRoot 'check-content.ps1') 2>&1 | Out-String)
            $gateExit = $LASTEXITCODE
        } catch {
            $gateOutput = [string]$_.Exception.Message
            $gateExit = 1
        }
        [IO.File]::WriteAllText($gateLog, $gateOutput)
        $gateOutput -split '\r?\n' | Where-Object { $_ -match '^CONTENT ' } | Write-Output
        $gateResults = [ordered]@{ content = [ordered]@{ passed = ($gateExit -eq 0); exit = $gateExit; log = $gateLog } }
        if ($gateExit -ne 0) { $exitCode = 1; Write-Output 'ROUTE GATE FAILED: content (see the log above)' }
    }
if ($VerifyRunner) {
    $checkShell = (Get-Process -Id $PID).Path
    foreach ($selectionProbe in @(
        @{ Name='ui-only-rule-scope'; Arguments=@('-UIOnly','-Suite','runner','-ListOnly'); Message='-UIOnly does not run -Suite' },
        @{ Name='inactive-ui-scope'; Arguments=@('-UISuite','home','-ListOnly'); Message='-UISuite requires -UI or -UIOnly' }
    )) {
        $probeArguments = $selectionProbe.Arguments
        # A rejected invocation writes its reason to stderr and exits 1. Capture both
        # explicitly: with ErrorActionPreference=Stop a native command's stderr would
        # otherwise surface here as a terminating error instead of probe evidence.
        try {
            $probeOutput = (& $checkShell -NoProfile -File $PSCommandPath @probeArguments 2>&1 | Out-String)
            $probeExit = $LASTEXITCODE
        } catch {
            $probeOutput = [string]$_.Exception.Message
            $probeExit = 1
        }
        [IO.File]::WriteAllText((Join-Path $checkDirectory ('check-negative-' + $selectionProbe.Name + '.log')), $probeOutput)
        if ($probeExit -eq 0 -or -not $probeOutput.Contains($selectionProbe.Message) -or $probeOutput.Contains('CHECK LOGS:')) {
            throw "Inactive test selection was not rejected before engine startup: $($selectionProbe.Name)"
        }
        Write-Output "CHECK negative-$($selectionProbe.Name): ignored scope rejected before engine startup"
    }
    $timeoutDetected = $false
    try {
        Invoke-CheckEngine -Log (Join-Path $checkDirectory 'check-negative-timeout.log') -Arguments @('--headless', '--script', 'res://tests/hang_probe.gd') -LimitSeconds 1 | Out-Null
    } catch [TimeoutException] {
        $timeoutDetected = $true
    }
    if (-not $timeoutDetected) { throw 'Timeout probe failed to stop an unfinished process.' }
    Write-Output 'CHECK negative-timeout: unfinished process stopped after 1s'

    foreach ($probeName in @('rules', 'ui')) {
        $probeScript = if ($probeName -eq 'rules') { 'res://tests/test_game.gd' } else { 'res://tests/ui_smoke.gd' }
        $probeLog = Join-Path $checkDirectory ('check-negative-' + $probeName + '.log')
        [IO.File]::WriteAllText($probeLog, '')
        $probeExit = Invoke-CheckEngine -Log $probeLog -Arguments @('--headless', '--script', $probeScript, '--', '--suite=runner', '--probe-runtime-error')
        $probeOutput = [IO.File]::ReadAllText($probeLog)
        if ($probeExit -eq 0 -or $probeOutput -match '(?m)^(?:UI )?PASS:' -or $probeOutput -notmatch 'deliberate_missing_test_key' -or $probeOutput -notmatch '(?m)^(?:UI )?FAIL:') {
            throw "Runtime-error detection probe failed: $probeName. See $probeLog"
        }
        Write-Output "CHECK negative-${probeName}: correctly rejected intentional runtime error, no false PASS"
    }
    # Isolation probes: the first selected suite fails by assertion, by a real
    # script error, or by a failed load; the later suite must still run and report.
    foreach ($isolation in @(
        @{ Name='negative-isolation-assertion'; Probe='--probe-suite-failure'; Runtime=$false; KeepGoing=$false },
        @{ Name='negative-isolation-assertion-keepgoing'; Probe='--probe-suite-failure'; Runtime=$false; KeepGoing=$true },
        @{ Name='negative-isolation-runtime'; Probe='--probe-suite-runtime-error'; Runtime=$true; KeepGoing=$false },
        @{ Name='negative-isolation-load'; Probe='--probe-suite-load-failure'; Runtime=$true; KeepGoing=$false }
    )) {
        $probeName = $isolation.Name
        $probeLog = Join-Path $checkDirectory ('check-' + $probeName + '.log')
        $probeArguments = @('--headless', '--script', 'res://tests/test_game.gd', '--', '--suite=runner,tower', $isolation.Probe)
        if ($isolation.KeepGoing) { $probeArguments += '--keep-going' }
        $probeExit = Invoke-CheckEngine -Log $probeLog -Arguments $probeArguments
        $probe = Get-PhaseSummary -Name $probeName -Requested @('runner','tower') -Enabled $true
        if ($probeExit -eq 0 -or $probe.failed -notcontains 'runner' -or $probe.complete) { throw "Isolation probe was not rejected: $probeName" }
        if ($probe.passed -notcontains 'tower' -or $probe.unrun.Count -ne 0 -or ($probe.retry -join ',') -ne 'runner') {
            throw "Isolation probe did not run the later suite or lost its retry report: $probeName"
        }
        $probeText = [IO.File]::ReadAllText($probeLog)
        if ($isolation.Runtime -and $probeText -notmatch '(?m)^SUITE RUNTIME: runner [1-9]') { throw "Isolation probe missed the runtime annotation: $probeName" }
        if ($probeName -eq 'negative-isolation-load' -and $probeText -notmatch '(?m)^SUITE LOAD FAILED: runner$') { throw 'Load-failure probe missed SUITE LOAD FAILED.' }
        Write-Output "CHECK ${probeName}: failed suite isolated, later suites completed"
    }
    # UI-side isolation: the fixture errors after an await inside the module coroutine,
    # so the probe also proves the await returns control instead of hanging.
    $uiIsolationLog = Join-Path $checkDirectory 'check-negative-isolation-ui.log'
    $uiIsolationExit = Invoke-CheckEngine -Log $uiIsolationLog -Arguments @('--script', 'res://tests/ui_smoke.gd', '--', '--ui-suite=localization,home', '--probe-module-runtime-error')
    $uiIsolation = Get-PhaseSummary -Name 'negative-isolation-ui' -Requested @('localization','home') -Enabled $true
    if ($uiIsolationExit -eq 0 -or $uiIsolation.failed -notcontains 'localization' -or $uiIsolation.passed -notcontains 'home' -or $uiIsolation.complete) {
        throw 'UI isolation probe did not isolate the failing module.'
    }
    if ($uiIsolation.unrun.Count -ne 0 -or ($uiIsolation.retry -join ',') -ne 'localization') { throw 'UI isolation probe lost the later module or its retry report.' }
    if ([IO.File]::ReadAllText($uiIsolationLog) -notmatch '(?m)^SUITE RUNTIME: localization [1-9]') { throw 'UI isolation probe missed the runtime annotation.' }
    Write-Output 'CHECK negative-isolation-ui: failed module isolated, later modules completed'
    # Route probes (§7-1): the plan is the review surface, so these pin the decisions
    # the plan host must make for the pinned example change sets (contract §6-G3).
    foreach ($routeProbe in @(
        @{ Name='route-ui-only'; Files=@('spire-godot/ui/main.gd')
           Must=@('(?m)^ROUTE ROW: spire-godot/ui/main\.gd -> rules=\(none\) ui=\S+ \[signals=symbol_ui\]\r?$', '(?m)^ROUTE RULE SCOPE: \(none\)\r?$') },
        @{ Name='route-content'; Files=@('spire-godot/content/packs/abandoned_storeroom.json')
           Must=@('(?m)^ROUTE DEFAULT: spire-godot/content/packs/abandoned_storeroom\.json \(blind, closure=spire-godot/content/\)\r?$', '(?m)^ROUTE UI SCOPE: \(none\)\r?$', '(?m)^ROUTE GATE: content ') },
        @{ Name='route-save'; Files=@('spire-godot/core/save_store.gd')
           Must=@('(?m)^ROUTE CORE APPEND: spire-godot/core/save_store\.gd \+= architecture,persistence,runner ', 'signals=preload', '(?m)^ROUTE RULE SCOPE: architecture,runner,persistence\r?$', '(?m)^ROUTE UI SCOPE: encyclopedia,home_persistence,home,persistence\r?$') },
        @{ Name='route-snapshot-domain'; Files=@('spire-godot/core/snapshot.gd')
           Must=@('(?m)^ROUTE ROW: spire-godot/core/snapshot\.gd .*\[signals=domain,core-append\]\r?$', '(?m)^ROUTE RULE SCOPE: architecture,runner,persistence\r?$') },
        @{ Name='route-blind-closure'; Files=@('spire-godot/core/tool_rules.gd')
           Must=@('(?m)^ROUTE DEFAULT: spire-godot/core/tool_rules\.gd \(blind, closure=spire-godot/core/\)\r?$', '(?m)^ROUTE BLIND: spire-godot/core/tool_rules\.gd \(BLIND_BY_DESIGN: ', '(?m)^ROUTE RULE SCOPE: (?!.*normal_play).*\r?$') },
        @{ Name='route-unmapped-fail-closed'; Files=@('spire-godot/newdir/x.gd')
           Must=@('(?m)^ROUTE UNMAPPED: spire-godot/newdir/x\.gd \(no index edge and no closure; fail-closed to all-dev \+ all-dev-ui\)\r?$', '(?m)^ROUTE MILESTONE: declared baseline,normal_play; deducted in this plan: ') },
        @{ Name='route-declared-none'; Files=@('docs/check-routing.md')
           Must=@('(?m)^ROUTE NONE: docs/check-routing\.md \(outside the source fingerprint; no suites, never a pass\)\r?$', '(?m)^ROUTE RULE SCOPE: \(none\)\r?$') }
    )) {
        $probeName = $routeProbe.Name
        $probeListPath = Join-Path $checkDirectory ('probe-' + $probeName + '.txt')
        [IO.File]::WriteAllLines($probeListPath, $routeProbe.Files, [Text.UTF8Encoding]::new($false))
        $probeOutput = ''
        $probeExit = 1
        try {
            $probeOutput = (& $checkShell -NoProfile -File $PSCommandPath -ChangedList $probeListPath -ListOnly 2>&1 | Out-String)
            $probeExit = $LASTEXITCODE
        } catch {
            $probeOutput = [string]$_.Exception.Message
            $probeExit = 1
        }
        [IO.File]::WriteAllText((Join-Path $checkDirectory ('check-' + $probeName + '.log')), $probeOutput)
        if ($probeExit -ne 0) { throw "Route probe did not produce a usable plan: $probeName" }
        foreach ($pattern in $routeProbe.Must) {
            if ($probeOutput -notmatch $pattern) { throw "Route probe missed an expected plan line: $probeName / $pattern" }
        }
        Write-Output "CHECK ${probeName}: plan decisions verified"
    }
    # -ListOnly must equal the executed scope: compare the plan with the real run.
    $scopeListPath = Join-Path $checkDirectory 'probe-route-scope-matches.txt'
    [IO.File]::WriteAllLines($scopeListPath, @('spire-godot/tests/runner_cases.gd'), [Text.UTF8Encoding]::new($false))
    $scopeOutput = ''
    $scopeExit = 1
    try {
        $scopeOutput = (& $checkShell -NoProfile -File $PSCommandPath -ChangedList $scopeListPath 2>&1 | Out-String)
        $scopeExit = $LASTEXITCODE
    } catch {
        $scopeOutput = [string]$_.Exception.Message
        $scopeExit = 1
    }
    [IO.File]::WriteAllText((Join-Path $checkDirectory 'check-route-scope-matches.log'), $scopeOutput)
    if ($scopeExit -ne 0) { throw 'Route scope probe: the routed runner run did not finish green.' }
    $scopeSummaryPath = [regex]::Match($scopeOutput, '(?m)^SUMMARY: (.+)$').Groups[1].Value.Trim()
    if (-not $scopeSummaryPath) { throw 'Route scope probe: no summary.json was reported.' }
    $scopeSummary = Get-Content -LiteralPath $scopeSummaryPath -Raw | ConvertFrom-Json
    if ((@($scopeSummary.route.rules) -join ',') -ne (@($scopeSummary.rules.selected) -join ',')) { throw 'Route scope probe: the planned rule scope differs from the executed rule scope.' }
    if ((@($scopeSummary.route.ui) -join ',') -ne (@($scopeSummary.ui.selected) -join ',')) { throw 'Route scope probe: the planned UI scope differs from the executed UI scope.' }
    if ($scopeSummary.status -ne 'passed' -or $scopeSummary.route.mode -ne 'changed') { throw "Route scope probe: unexpected status or mode ($($scopeSummary.status)/$($scopeSummary.route.mode))." }
    Write-Output 'CHECK route-scope-matches: the planned scope equals the executed scope'
}

} catch {
    $exitCode = 1
    $failureMessage = $_.Exception.Message
    Write-Output $failureMessage
} finally {
    $afterFingerprint = Get-SourceFingerprint
    $rules = Get-PhaseSummary -Name rules -Requested $Suite -Enabled (-not $UIOnly)
    $window = Get-PhaseSummary -Name ui -Requested $UISuite -Enabled ([bool]($UI -or $UIOnly))
    $changed = $beforeFingerprint -ne $afterFingerprint
    if ($changed -and -not $ListOnly) {
        $exitCode = 1
        $rules.retry = @($rules.selected); $window.retry = @($window.selected)
        Write-Output 'SOURCE CHANGED: results belong to a moving workspace; rerun after edits settle.'
    }
    $status = if ($ListOnly -and $exitCode -eq 0) { 'plan' } elseif ($changed -and -not $ListOnly) { 'source_changed' } elseif ($exitCode -eq 0) { 'passed' } else { 'failed' }
    if ($routeSummary) {
        $routeSummary['gate_results'] = $gateResults
    }
    $summary = [ordered]@{ schema=1; status=$status; error=$failureMessage; impact=[bool]$Impact; exhaustive=[bool]($Exhaustive -or 'all' -in $Suite); verify_runner=[bool]$VerifyRunner; before=$beforeFingerprint; after=$afterFingerprint; rules=$rules; ui=$window; route=$routeSummary }
    $summaryPath = Join-Path $checkDirectory 'summary.json'
    [IO.File]::WriteAllText($summaryPath, ($summary | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    Write-Output ('SUMMARY: ' + $summaryPath)
    if ($exitCode -ne 0) { Write-Output ('.\tools\check.ps1 -RerunFailed "' + $checkDirectory + '"') }
}
exit $exitCode
