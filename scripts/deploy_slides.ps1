# Script de sincronização e deploy dos slides no Firebase Hosting
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$publicDir = Join-Path $projectRoot "slides_public"
$assetsSource = Join-Path $projectRoot "apresentacao_assets"
$assetsDest = Join-Path $publicDir "apresentacao_assets"
$sourceHtml = Join-Path $projectRoot "apresentacao_conecta_saude.html"
$destHtml = Join-Path $publicDir "index.html"

Write-Host "Preparando arquivos para deploy em $publicDir..." -ForegroundColor Cyan

if (-not (Test-Path $publicDir)) {
    New-Item -ItemType Directory -Path $publicDir -Force | Out-Null
}

Copy-Item -Path $sourceHtml -Destination $destHtml -Force
Write-Host "Copiado $sourceHtml -> $destHtml" -ForegroundColor Green

if (Test-Path $assetsSource) {
    if (-not (Test-Path $assetsDest)) {
        New-Item -ItemType Directory -Path $assetsDest -Force | Out-Null
    }
    Copy-Item -Path "$assetsSource\*" -Destination $assetsDest -Recurse -Force
    Write-Host "Ativos copiados para $assetsDest" -ForegroundColor Green
}

Write-Host "Disparando deploy para o site 'slide-conecta-hospital'..." -ForegroundColor Cyan
Set-Location $projectRoot
firebase deploy --only hosting:slide-conecta-hospital

Write-Host "Deploy dos slides concluído com sucesso!" -ForegroundColor Green
