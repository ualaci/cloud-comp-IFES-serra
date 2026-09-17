$env:PATH += ";C:\Program Files\Oracle\VirtualBox"

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = ".\logs\cleanup_$timestamp.log"
New-Item -ItemType Directory -Path .\logs -Force | Out-Null

& {
    Write-Host "==> [1/4] Removendo VMs orfas do VirtualBox..." -ForegroundColor Yellow
    $managedVMs = @("linux-node-1", "alpine-node", "ubuntu-node")
    foreach ($vm in $managedVMs) {
        $exists = VBoxManage list vms 2>$null | Select-String -Pattern "`"$vm`""
        if ($exists) {
            Write-Host "    Removendo VM: $vm" -ForegroundColor Yellow
            VBoxManage controlvm $vm poweroff 2>$null
            Start-Sleep -Seconds 3
            VBoxManage unregistervm $vm --delete 2>$null
        }
    }

    Write-Host "==> [2/4] Removendo arquivos de state do Terraform..." -ForegroundColor Yellow
    Remove-Item -Path terraform.tfstate, terraform.tfstate.backup -ErrorAction SilentlyContinue

    Write-Host "==> [3/4] Removendo lock file..." -ForegroundColor Yellow
    Remove-Item -Path .terraform.lock.hcl -ErrorAction SilentlyContinue

    Write-Host "==> [4/4] Removendo cache do provider (.terraform/)..." -ForegroundColor Yellow
    Remove-Item -Path .terraform -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "==> Limpeza total concluida. Execute .\deploy.ps1 para recomecar do zero." -ForegroundColor Green
} 2>&1 | Tee-Object -FilePath $logFile

Write-Host "==> Log salvo em: $logFile" -ForegroundColor DarkGray
