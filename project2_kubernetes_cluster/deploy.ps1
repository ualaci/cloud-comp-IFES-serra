$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Starting Minimal Kubernetes Cluster Deployment" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Let Terraform and Vagrant find each other using your normal system PATH
Write-Host "`n[1/2] terraform init..." -ForegroundColor Yellow
terraform init

Write-Host "`n[2/2] terraform apply (takes ~10 min)..." -ForegroundColor Yellow
terraform apply -auto-approve

Write-Host "=============================================" -ForegroundColor Green
Write-Host " Deployment Complete!" -ForegroundColor Green
Write-Host " To access the manager node, run: vagrant ssh manager" -ForegroundColor Green
Write-Host " To access worker1, run: vagrant ssh worker1" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
