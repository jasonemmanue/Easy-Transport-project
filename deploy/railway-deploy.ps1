# Carlinq - (re)deploiement sur Railway depuis le code local.
#
#   powershell -ExecutionPolicy Bypass -File deploy\railway-deploy.ps1                 # api + backoffice
#   powershell -ExecutionPolicy Bypass -File deploy\railway-deploy.ps1 -Service api
#
# Chaque sous-dossier est envoye comme racine du build (--path-as-root) :
# Railway y lit railway.json et le Dockerfile.

param(
    [ValidateSet("all", "api", "backoffice")]
    [string]$Service = "all",
    [string]$Environment = "production"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$targets = [ordered]@{ "api" = "API"; "backoffice" = "Backoffice" }

foreach ($name in $targets.Keys) {
    if ($Service -ne "all" -and $Service -ne $name) { continue }
    Write-Host "`n== Deploiement $name ($($targets[$name])/) ==" -ForegroundColor Cyan
    & railway up (Join-Path $Root $targets[$name]) --path-as-root `
        --service $name --environment $Environment --detach `
        --message "deploy $name (local)"
    if ($LASTEXITCODE -ne 0) { throw "railway up $name a echoue (code $LASTEXITCODE)" }
}

Write-Host "`nSuivi : railway logs --service api   |   railway logs --service backoffice   |   railway open"
