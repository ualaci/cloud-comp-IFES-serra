$env:PATH += ";C:\Program Files\Oracle\VirtualBox"

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = ".\logs\deploy_$timestamp.log"
New-Item -ItemType Directory -Path .\logs -Force | Out-Null

# Redireciona toda a saida para o terminal E para o arquivo de log
& {
    Write-Host "==> Inicializando o Terraform..." -ForegroundColor Cyan
    .\terraform init -input=false

    Write-Host "==> Validando configurações..." -ForegroundColor Cyan
    .\terraform validate

    Write-Host "==> Aplicando infraestrutura..." -ForegroundColor Cyan
    .\terraform apply -auto-approve

    Write-Host "==> Processo finalizado com sucesso!" -ForegroundColor Green
} 2>&1 | Tee-Object -FilePath $logFile

Write-Host "==> Log salvo em: $logFile" -ForegroundColor DarkGray