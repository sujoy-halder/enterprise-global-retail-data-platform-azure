param(
  [ValidateSet("dev", "stage", "prod")]
  [string]$Environment = "dev",

  [string]$AcrLoginServer = "retailacr.azurecr.io",
  [string]$WorkloadIdentityClientId = "00000000-0000-0000-0000-000000000000"
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$overlay = Join-Path $repoRoot "k8s\overlays\$Environment"

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

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
  throw "kubectl is required"
}

$rendered = Invoke-NativeOutput kubectl kustomize $overlay
$rendered = $rendered -replace "REPLACE_WITH_DEV_ACR.azurecr.io", $AcrLoginServer
$rendered = $rendered -replace "REPLACE_WITH_STAGE_ACR.azurecr.io", $AcrLoginServer
$rendered = $rendered -replace "REPLACE_WITH_PROD_ACR.azurecr.io", $AcrLoginServer
$rendered = $rendered -replace "REPLACE_WITH_WORKLOAD_IDENTITY_CLIENT_ID", $WorkloadIdentityClientId
$rendered
