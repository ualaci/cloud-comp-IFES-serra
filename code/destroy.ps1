$env:PATH += ";C:\Program Files\Oracle\VirtualBox"

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = ".\logs\destroy_$timestamp.log"
New-Item -ItemType Directory -Path .\logs -Force | Out-Null

& {
    # 1. Terraform Destroy (caminho normal)
    Write-Host "==> [1/3] Executando terraform destroy..." -ForegroundColor Red
    .\terraform destroy -auto-approve

    # 2. Limpeza de VMs orfas no VirtualBox
    Write-Host "==> [2/3] Verificando VMs orfas no VirtualBox..." -ForegroundColor Yellow
    $managedVMs = @("linux-node-1", "alpine-node", "ubuntu-node")
    foreach ($vm in $managedVMs) {
        $exists = VBoxManage list vms 2>$null | Select-String -Pattern "`"$vm`""
        if ($exists) {
            Write-Host "    VM orfa encontrada: $vm. Removendo..." -ForegroundColor Yellow
            VBoxManage controlvm $vm poweroff 2>$null
            Start-Sleep -Seconds 3
            VBoxManage unregistervm $vm --delete 2>$null
            Write-Host "    VM $vm removida." -ForegroundColor Green
        }
    }

    # 3. Limpeza dos arquivos de state
    Write-Host "==> [3/3] Limpando arquivos de state..." -ForegroundColor Yellow
    Remove-Item -Path terraform.tfstate, terraform.tfstate.backup -ErrorAction SilentlyContinue

    Write-Host "==> Ambiente destruido e limpo com sucesso!" -ForegroundColor Green
} 2>&1 | Tee-Object -FilePath $logFile

Write-Host "==> Log salvo em: $logFile" -ForegroundColor DarkGray