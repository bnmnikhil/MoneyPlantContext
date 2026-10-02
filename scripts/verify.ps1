[CmdletBinding()]
param(
    [ValidateSet("changed", "fast", "frontend", "backend", "broker", "integration", "ui", "all")]
    [string]$Scope = "changed",

    [ValidatePattern("^[a-z0-9][a-z0-9-]*$")]
    [string]$Broker,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspace = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$frontend = Join-Path $workspace "frontend"
$backend = Join-Path $workspace "tradestack"
$mavenWrapper = Join-Path $backend "mvnw.cmd"
$steps = [System.Collections.Generic.List[object]]::new()

function Quote-Argument {
    param([string]$Value)

    if ($Value -match '[\s,]') {
        return '"' + $Value.Replace('"', '\"') + '"'
    }
    return $Value
}

function Format-Command {
    param(
        [string]$Executable,
        [string[]]$Arguments
    )

    $parts = @((Quote-Argument $Executable))
    $parts += $Arguments | ForEach-Object { Quote-Argument $_ }
    return $parts -join " "
}

function Add-CommandStep {
    param(
        [string]$Name,
        [string]$WorkingDirectory,
        [string]$Executable,
        [string[]]$Arguments,
        [string]$Reason
    )

    if (@($steps | ForEach-Object Name) -contains $Name) {
        return
    }

    $steps.Add([pscustomobject]@{
        Name = $Name
        WorkingDirectory = $WorkingDirectory
        Executable = $Executable
        Arguments = $Arguments
        Reason = $Reason
        SkipReason = $null
        Reproduce = Format-Command $Executable $Arguments
    }) | Out-Null
}

function Add-SkipStep {
    param(
        [string]$Name,
        [string]$Reason
    )

    if (@($steps | ForEach-Object Name) -contains $Name) {
        return
    }

    $steps.Add([pscustomobject]@{
        Name = $Name
        WorkingDirectory = $workspace
        Executable = $null
        Arguments = @()
        Reason = $Reason
        SkipReason = $Reason
        Reproduce = "n/a"
    }) | Out-Null
}

function Add-DiffChecks {
    param([string[]]$Repositories)

    foreach ($repository in $Repositories) {
        $label = Split-Path $repository -Leaf
        if ($repository -eq $workspace) {
            $label = "workspace"
        }
        Add-CommandStep "diff-check:$label" $repository "git" @("diff", "--check") `
            "Reject whitespace errors in tracked changes."
    }
}

function Add-FrontendFast {
    Add-CommandStep "frontend:test" $frontend "npm.cmd" @("test") `
        "Run deterministic frontend unit and contract tests."
    Add-CommandStep "frontend:typecheck" $frontend "npm.cmd" @("run", "typecheck") `
        "Catch TypeScript and frontend/backend contract drift."
}

function Add-FrontendFull {
    Add-FrontendFast
    Add-CommandStep "frontend:build" $frontend "npm.cmd" @("run", "build") `
        "Produce the optimized application build."
}

function Add-BackendFast {
    Add-CommandStep "backend:test" $backend $mavenWrapper @("test") `
        "Run the normal backend suite without deleting compiled output first."
}

function Add-BackendFull {
    Add-CommandStep "backend:clean-test" $backend $mavenWrapper @("clean", "test") `
        "Run the authoritative clean backend suite and Maven test count."
}

function Get-ChangedPaths {
    param(
        [string]$Repository,
        [string[]]$IgnoredPatterns = @()
    )

    $lines = @(& git -C $Repository status --porcelain=v1 --untracked-files=all)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not inspect changes in $Repository"
    }

    $paths = foreach ($line in $lines) {
        if ($line.Length -lt 4) {
            continue
        }
        $path = $line.Substring(3).Trim('"') -replace '\\', '/'
        if ($path -match ' -> ') {
            $path = ($path -split ' -> ')[-1]
        }

        $ignored = $false
        foreach ($pattern in $IgnoredPatterns) {
            if ($path -like $pattern) {
                $ignored = $true
                break
            }
        }
        if (-not $ignored) {
            $path
        }
    }
    return @($paths)
}

function Add-ChangedScope {
    $rootChanges = Get-ChangedPaths $workspace
    $frontendChanges = Get-ChangedPaths $frontend
    $backendChanges = Get-ChangedPaths $backend @(
        ".mcp.json",
        "docs/architecture/*",
        "hs_err_pid*.log",
        "replay_pid*.log"
    )

    Write-Host "Changed-path mapping:" -ForegroundColor Cyan
    Write-Host "  workspace: $($rootChanges.Count) relevant path(s) -> diff check"
    Write-Host "  frontend:  $($frontendChanges.Count) relevant path(s) -> test + build"
    Write-Host "  tradestack: $($backendChanges.Count) relevant path(s) -> clean test"

    if ($rootChanges.Count -gt 0) {
        Add-DiffChecks @($workspace)
    }
    if ($frontendChanges.Count -gt 0) {
        Add-DiffChecks @($frontend)
        Add-FrontendFull
    }
    if ($backendChanges.Count -gt 0) {
        Add-DiffChecks @($backend)
        Add-BackendFull
    }
    if ($steps.Count -eq 0) {
        Add-SkipStep "changed:none" "No relevant working-tree changes were found."
    }
}

function Add-BrokerScope {
    if ([string]::IsNullOrWhiteSpace($Broker)) {
        throw "-Scope broker requires -Broker <id>, for example -Broker kite."
    }

    $testRoot = Join-Path $backend "src\test\java\com\goldenbook\tradestack\broker"
    $brokerTestRoot = Join-Path $testRoot $Broker
    if (-not (Test-Path $brokerTestRoot -PathType Container)) {
        $available = @(Get-ChildItem $testRoot -Directory | Where-Object {
            @(Get-ChildItem $_.FullName -Recurse -Filter "*Test.java").Count -gt 0
        } | Select-Object -ExpandProperty Name | Sort-Object)
        throw "No broker test directory exists for '$Broker'. Available broker test profiles: $($available -join ', ')."
    }

    $brokerTests = @(Get-ChildItem $brokerTestRoot -Recurse -Filter "*Test.java" |
        Select-Object -ExpandProperty BaseName)
    if ($brokerTests.Count -eq 0) {
        throw "Broker '$Broker' has no *Test.java classes under $brokerTestRoot."
    }

    $sharedTests = @(
        "ApiExceptionHandlerTest",
        "BrokerCatalogTest",
        "BrokerServiceFanOutTest",
        "SessionControllerTest"
    )
    $selector = @(($sharedTests + $brokerTests) | Sort-Object -Unique) -join ","

    Add-DiffChecks @($backend)
    Add-CommandStep "broker:$Broker" $backend $mavenWrapper @("-Dtest=$selector", "test") `
        "Run $Broker adapter tests plus shared catalogue, fan-out, session and error contracts."
}

switch ($Scope) {
    "changed" {
        Add-ChangedScope
    }
    "fast" {
        Add-DiffChecks @($workspace, $frontend, $backend)
        Add-FrontendFast
        Add-BackendFast
    }
    "frontend" {
        Add-DiffChecks @($frontend)
        Add-FrontendFull
    }
    "backend" {
        Add-DiffChecks @($backend)
        Add-BackendFull
    }
    "broker" {
        Add-BrokerScope
    }
    "integration" {
        Add-CommandStep "integration:docker" $workspace "docker" @("info") `
            "Confirm Docker is available before starting Testcontainers."
        Add-CommandStep "integration:backend-db" $backend $mavenWrapper @("clean", "test", "-DexcludedGroups=") `
            "Run the normal backend suite plus db-tagged Testcontainers tests."
    }
    "ui" {
        Add-SkipStep "ui:not-implemented" `
            "No browser smoke pack exists yet. This is an explicit project gap, not a passing UI check."
    }
    "all" {
        Add-DiffChecks @($workspace, $frontend, $backend)
        Add-FrontendFull
        Add-BackendFull
        Add-SkipStep "integration:not-in-all" `
            "Use -Scope integration explicitly; it requires Docker and is not part of the network-free gate."
        Add-SkipStep "ui:not-implemented" `
            "No browser smoke pack exists yet. This is an explicit project gap, not a passing UI check."
    }
}

Write-Host ""
Write-Host "GoldenBook verification" -ForegroundColor Cyan
Write-Host "  scope:     $Scope"
if ($Broker) {
    Write-Host "  broker:    $Broker"
}
Write-Host "  workspace: $workspace"
Write-Host "  dry run:   $([bool]$DryRun)"
Write-Host ""
Write-Host "Plan:" -ForegroundColor Cyan
foreach ($step in $steps) {
    $marker = if ($step.SkipReason) { "SKIP" } else { "RUN " }
    Write-Host "  [$marker] $($step.Name) - $($step.Reason)"
    if (-not $step.SkipReason) {
        Write-Host "         cd $($step.WorkingDirectory)"
        Write-Host "         $($step.Reproduce)"
    }
}

if ($DryRun) {
    Write-Host ""
    Write-Host "Dry run complete; no verification commands were executed." -ForegroundColor Yellow
    exit 0
}

$results = [System.Collections.Generic.List[object]]::new()
foreach ($step in $steps) {
    if ($step.SkipReason) {
        $results.Add([pscustomobject]@{
            Name = $step.Name
            Status = "SKIP"
            Seconds = 0
            Detail = $step.SkipReason
            WorkingDirectory = $step.WorkingDirectory
            Reproduce = $step.Reproduce
        }) | Out-Null
        continue
    }

    Write-Host ""
    Write-Host "==> $($step.Name)" -ForegroundColor Cyan
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $status = "PASS"
    $detail = ""

    Push-Location $step.WorkingDirectory
    try {
        $commandArguments = $step.Arguments
        & $step.Executable @commandArguments
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            $status = "FAIL"
            $detail = "Exit code $exitCode"
        }
    }
    catch {
        $status = "FAIL"
        $detail = $_.Exception.Message
    }
    finally {
        Pop-Location
        $timer.Stop()
    }

    $results.Add([pscustomobject]@{
        Name = $step.Name
        Status = $status
        Seconds = [Math]::Round($timer.Elapsed.TotalSeconds, 1)
        Detail = $detail
        WorkingDirectory = $step.WorkingDirectory
        Reproduce = $step.Reproduce
    }) | Out-Null
}

Write-Host ""
Write-Host "Verification summary" -ForegroundColor Cyan
foreach ($result in $results) {
    $colour = switch ($result.Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        default { "Yellow" }
    }
    Write-Host ("  {0,-4} {1,-30} {2,7}s" -f $result.Status, $result.Name, $result.Seconds) `
        -ForegroundColor $colour
    if ($result.Detail) {
        Write-Host "       $($result.Detail)"
    }
    if ($result.Status -eq "FAIL") {
        Write-Host "       Reproduce: cd $($result.WorkingDirectory)"
        Write-Host "                  $($result.Reproduce)"
    }
}

$failures = @($results | Where-Object Status -eq "FAIL")
if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "$($failures.Count) verification step(s) failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Verification completed with no failures." -ForegroundColor Green
exit 0
