param(
  [switch]$SkipTerraformInit,
  [switch]$SkipDocker
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$failures = New-Object System.Collections.Generic.List[string]

function Invoke-Check {
  param(
    [string]$Name,
    [scriptblock]$Command
  )

  Write-Host "==> $Name"
  try {
    & $Command
    Write-Host "PASS $Name"
  }
  catch {
    $failures.Add("$Name :: $($_.Exception.Message)")
    Write-Warning "FAIL $Name :: $($_.Exception.Message)"
  }
}

function Test-CommandAvailable {
  param([string]$CommandName)
  return $null -ne (Get-Command $CommandName -ErrorAction SilentlyContinue)
}

function Invoke-NativeCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$FilePath $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
  }
}

function Invoke-NativeOutput {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  $output = & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$FilePath $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
  }
  return $output
}

Set-Location $repoRoot

Invoke-Check "Python compile" {
  Invoke-NativeCommand python -m compileall src tests
}

Invoke-Check "Python unit tests" {
  Invoke-NativeCommand python -m pytest
}

if (Test-CommandAvailable "ruff") {
  Invoke-Check "Ruff lint" {
    Invoke-NativeCommand ruff check .
  }
}
else {
  Write-Warning "SKIP Ruff lint :: ruff is not installed"
}

if (Test-CommandAvailable "terraform") {
  Invoke-Check "Terraform format" {
    Invoke-NativeCommand terraform fmt -check -recursive infra/terraform
  }

  foreach ($envName in @("dev", "stage", "prod")) {
    $envPath = Join-Path $repoRoot "infra\terraform\environments\$envName"
    $env:TF_DATA_DIR = Join-Path $env:TEMP "retail-azure-tfdata-$envName"

    if (-not $SkipTerraformInit) {
      Invoke-Check "Terraform init $envName" {
        Invoke-NativeCommand terraform "-chdir=$envPath" init -backend=false
      }
    }

    Invoke-Check "Terraform validate $envName" {
      Invoke-NativeCommand terraform "-chdir=$envPath" validate
    }
  }
}
else {
  Write-Warning "SKIP Terraform checks :: terraform is not installed"
}

if (Test-CommandAvailable "kubectl") {
  foreach ($overlay in @("dev", "stage", "prod")) {
    Invoke-Check "Kubernetes render $overlay" {
      Invoke-NativeOutput kubectl kustomize "k8s/overlays/$overlay" | Out-Null
    }
  }
}
else {
  Write-Warning "SKIP Kubernetes render :: kubectl is not installed"
}

if (Test-CommandAvailable "dbt") {
  Invoke-Check "dbt static parse" {
    Push-Location (Join-Path $repoRoot "dbt")
    try {
      $env:SNOWFLAKE_ACCOUNT = "placeholder"
      $env:SNOWFLAKE_USER = "placeholder"
      $env:SNOWFLAKE_PASSWORD = "placeholder"
      $env:SNOWFLAKE_ROLE = "RETAIL_DBT_ROLE"
      $env:SNOWFLAKE_WAREHOUSE = "RETAIL_TRANSFORM_WH"
      $env:SNOWFLAKE_DATABASE = "RETAIL_DW"
      $env:SNOWFLAKE_SCHEMA = "GOLD"
      Invoke-NativeCommand dbt --no-version-check --log-path "$env:TEMP\retail-dbt-logs" parse --profiles-dir . --target-path "$env:TEMP\retail-dbt-target" --no-partial-parse
    }
    finally {
      Pop-Location
    }
  }
}
else {
  Write-Warning "SKIP dbt static parse :: dbt is not installed"
}

if (-not $SkipDocker -and (Test-CommandAvailable "docker")) {
  Invoke-Check "Docker build ingestion-api" {
    Invoke-NativeCommand docker build -f services/ingestion-api/Dockerfile -t retail-ingestion-api:local .
  }

  Invoke-Check "Docker build stream-processor" {
    Invoke-NativeCommand docker build -f services/stream-processor/Dockerfile -t retail-stream-processor:local .
  }
}
elseif ($SkipDocker) {
  Write-Warning "SKIP Docker checks :: requested by -SkipDocker"
}
else {
  Write-Warning "SKIP Docker checks :: docker is not installed or not running"
}

if ($failures.Count -gt 0) {
  Write-Host ""
  Write-Host "Validation failures:"
  $failures | ForEach-Object { Write-Host " - $_" }
  exit 1
}

Write-Host ""
Write-Host "All locally available validation checks passed."
