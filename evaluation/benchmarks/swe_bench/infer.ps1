param(
    [string]$OutputDir = "./evaluation/evaluation_outputs/mui",
    [string]$ConfigFile = "config.toml",
    [string]$TestCasesFile = "./evaluation/benchmarks/swe_bench/data/test_cases/mui.jsonl",
    [ValidateSet("docker", "eventstream", "local", "remote", "e2b", "modal", "runloop")]
    [string]$Runtime = "local",
    [string]$LocalRepoBaseDir = "./evaluation/benchmarks/swe_bench/data/mui/material-ui",
    [string]$Dataset = "./evaluation/benchmarks/swe_bench/data/mui_converted.jsonl",
    [string]$Language = "typescript",
    [string[]]$Models = @("gpt54"),
    [string]$AgentName = "CodeActAgent",
    [int]$EvalLimit = 500,
    [int]$MaxIter = 50,
    [int]$NumWorkers = 1,
    [string]$Split = "train",
    [switch]$NoSkipExistingOutput,
    [switch]$CleanupRuntimeImage,
    [string]$EvalNote = "",
    [int]$NRuns = 1,
    [string]$SkipRuns = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../../..")).Path
Set-Location $repoRoot

function Resolve-RepoPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $Path
    }
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }
    return (Join-Path $repoRoot $Path)
}

function Invoke-PythonModule {
    param([string[]]$Arguments)

    $poetry = Get-Command poetry -ErrorAction SilentlyContinue
    if ($poetry) {
        & poetry run python @Arguments
    } else {
        if (-not $env:PYTHONPATH) {
            $env:PYTHONPATH = $repoRoot
        } elseif (($env:PYTHONPATH -split [System.IO.Path]::PathSeparator) -notcontains $repoRoot) {
            $env:PYTHONPATH = "$repoRoot$([System.IO.Path]::PathSeparator)$env:PYTHONPATH"
        }
        & python @Arguments
    }
}

$env:EVAL_DOCKER_IMAGE_PREFIX = if ($Language -eq "python") {
    "docker.io/xingyaoww/"
} elseif ($Language -eq "java") {
    ""
} else {
    "mswebench/"
}
$env:USE_INSTANCE_IMAGE = if ($Runtime -eq "local") { "false" } else { "true" }
$env:RUN_WITH_BROWSING = "false"
$env:LANGUAGE = $Language
$env:CLEANUP_RUNTIME_IMAGE = if ($CleanupRuntimeImage) { "true" } else { "false" }
$env:RUNTIME = $Runtime
$env:LOCAL_REPO_BASE_DIR = Resolve-RepoPath $LocalRepoBaseDir
$env:SKIP_LOCAL_RUNTIME_BROWSER_CHECK = "true"
if ($Runtime -eq "local") {
    $env:LOCAL_RUNTIME_MODE = "1"
}
if (-not $env:USE_HINT_TEXT) {
    $env:USE_HINT_TEXT = "false"
}

$openhandsVersion = "unknown"
try {
    $openhandsVersion = (& git rev-parse --short HEAD).Trim()
} catch {
    Write-Warning "Could not read git version; using '$openhandsVersion'."
}

$baseEvalNote = $openhandsVersion
if ($env:USE_HINT_TEXT -eq "false") {
    $baseEvalNote = "$baseEvalNote-no-hint"
}
if ($env:RUN_WITH_BROWSING -eq "true") {
    $baseEvalNote = "$baseEvalNote-with-browsing"
}
if ($EvalNote) {
    $baseEvalNote = "$baseEvalNote-$EvalNote"
}

$skipRunSet = @{}
if ($SkipRuns) {
    foreach ($item in $SkipRuns.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries)) {
        $skipRunSet[[int]$item.Trim()] = $true
    }
}

$datasetPath = Resolve-RepoPath $Dataset
$outputPath = Resolve-RepoPath $OutputDir
$configPath = Resolve-RepoPath $ConfigFile
$testCasesPath = Resolve-RepoPath $TestCasesFile

foreach ($model in $Models) {
    Write-Host "=============================="
    Write-Host "Running benchmark for MODEL: $model"
    Write-Host "=============================="
    Write-Host "AGENT: $AgentName"
    Write-Host "OPENHANDS_VERSION: $openhandsVersion"
    Write-Host "DATASET: $datasetPath"
    Write-Host "SPLIT: $Split"
    Write-Host "OUTPUT_DIR: $outputPath"
    Write-Host "RUNTIME: $Runtime"
    Write-Host "LOCAL_REPO_BASE_DIR: $env:LOCAL_REPO_BASE_DIR"

    for ($run = 1; $run -le $NRuns; $run++) {
        if ($skipRunSet.ContainsKey($run)) {
            Write-Host "Skipping run $run"
            continue
        }

        $currentEvalNote = "$baseEvalNote-run_$run"
        Write-Host "EVAL_NOTE: $currentEvalNote"

        $commandArgs = @(
            "evaluation/benchmarks/swe_bench/run_infer.py",
            "--agent-cls", $AgentName,
            "--llm-config", $model,
            "--max-iterations", "$MaxIter",
            "--eval-num-workers", "$NumWorkers",
            "--eval-note", $currentEvalNote,
            "--config-file", $configPath,
            "--dataset", $datasetPath,
            "--split", $Split,
            "--eval-output-dir", $outputPath,
            "--runtime", $Runtime
        )

        if ($EvalLimit -gt 0) {
            $commandArgs += @("--eval-n-limit", "$EvalLimit")
        }
        if (-not $NoSkipExistingOutput) {
            $commandArgs += "--skip-existing-output"
        } else {
            $commandArgs += "--no-skip-existing-output"
        }
        if ($TestCasesFile) {
            $commandArgs += @("--test-cases-file", $testCasesPath)
        }
        if ($CleanupRuntimeImage) {
            $commandArgs += "--cleanup-runtime-image"
        } else {
            $commandArgs += "--no-cleanup-runtime-image"
        }
        if ($LocalRepoBaseDir) {
            $commandArgs += @("--local-repo-base-dir", $env:LOCAL_REPO_BASE_DIR)
        }

        Invoke-PythonModule -Arguments $commandArgs
    }

    Write-Host "Completed $model"
    Write-Host ""
}
