param(
  [ValidateSet("dev", "stage", "prod")]
  [string]$Environment = "dev",

  [Parameter(Mandatory = $true)]
  [string]$TerraformVarFile,

  [string]$ImageTag = "0.1.0",

  [switch]$SkipImages,
  [switch]$SkipKubernetes
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$envPath = Join-Path $repoRoot "infra\terraform\environments\$Environment"
$varFilePath = Resolve-Path $TerraformVarFile

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

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
  throw "terraform is required"
}
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI is required"
}

$env:TF_DATA_DIR = Join-Path $env:TEMP "retail-azure-tfdata-$Environment"

Invoke-NativeCommand terraform "-chdir=$envPath" init
Invoke-NativeCommand terraform "-chdir=$envPath" plan "-var-file=$varFilePath" -out=tfplan
Invoke-NativeCommand terraform "-chdir=$envPath" apply tfplan

$outputsJson = (Invoke-NativeOutput terraform "-chdir=$envPath" output -json) -join "`n" | ConvertFrom-Json
$platform = $outputsJson.platform.value
$acrLoginServer = $platform.acr_login_server
$acrName = $acrLoginServer.Split(".")[0]

if (-not $SkipImages) {
  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "docker is required unless -SkipImages is set"
  }

  Invoke-NativeCommand az acr login --name $acrName
  Invoke-NativeCommand docker build -f services/ingestion-api/Dockerfile -t "$acrLoginServer/retail-ingestion-api:$ImageTag" .
  Invoke-NativeCommand docker build -f services/stream-processor/Dockerfile -t "$acrLoginServer/retail-stream-processor:$ImageTag" .
  Invoke-NativeCommand docker push "$acrLoginServer/retail-ingestion-api:$ImageTag"
  Invoke-NativeCommand docker push "$acrLoginServer/retail-stream-processor:$ImageTag"
}

if (-not $SkipKubernetes) {
  if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    throw "kubectl is required unless -SkipKubernetes is set"
  }

  Invoke-NativeCommand az aks get-credentials `
    --resource-group $platform.resource_group_name `
    --name $platform.aks_cluster_name `
    --overwrite-existing

  $overlay = Join-Path $repoRoot "k8s\overlays\$Environment"
  $rendered = Invoke-NativeOutput kubectl kustomize $overlay
  $rendered = $rendered -replace "REPLACE_WITH_DEV_ACR.azurecr.io", $acrLoginServer
  $rendered = $rendered -replace "REPLACE_WITH_STAGE_ACR.azurecr.io", $acrLoginServer
  $rendered = $rendered -replace "REPLACE_WITH_PROD_ACR.azurecr.io", $acrLoginServer
  $rendered = $rendered -replace "REPLACE_WITH_WORKLOAD_IDENTITY_CLIENT_ID", $platform.ingestion_workload_identity_client_id
  $rendered | kubectl apply -f -
  if ($LASTEXITCODE -ne 0) {
    throw "kubectl apply failed with exit code $LASTEXITCODE"
  }
}

Write-Host "Deployment command sequence completed for $Environment."
