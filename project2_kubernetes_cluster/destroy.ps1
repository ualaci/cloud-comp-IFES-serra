<#
.SYNOPSIS
    Destroys the Kubernetes cluster VMs, Terraform state and generated files so the process can be redone from scratch.
#>
$ErrorActionPreference = "Continue"
Set-Location -Path $PSScriptRoot

function Resolve-Tool([string]$Name, [string[]]$Candidates) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($pattern in $Candidates) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $env:PATH = "$($found.DirectoryName);$env:PATH"; return $found.FullName }
    }
    return $null
}

$terraform = Resolve-Tool "terraform" @("C:\Program Files\terraform*\terraform.exe", "C:\HashiCorp\Terraform\terraform.exe")
$vagrant   = Resolve-Tool "vagrant"   @("C:\Program Files\Vagrant\bin\vagrant.exe", "C:\HashiCorp\Vagrant\bin\vagrant.exe")
$vbox      = Resolve-Tool "VBoxManage" @("C:\Program Files\Oracle\VirtualBox\VBoxManage.exe")

Write-Host "=============================================" -ForegroundColor Red
Write-Host " Destroying Kubernetes Cluster" -ForegroundColor Red
Write-Host "=============================================" -ForegroundColor Red

Write-Host "`n[1/4] terraform destroy..." -ForegroundColor Yellow
if ($terraform -and (Test-Path "terraform.tfstate")) {
    $env:TF_VAR_bridge_adapter = "unused-for-destroy"
    & $terraform destroy -auto-approve -input=false
    if ($LASTEXITCODE -ne 0) { Write-Warning "terraform destroy failed, continuing with vagrant/VirtualBox cleanup." }
} else { Write-Host "No Terraform state found, skipping." }

Write-Host "`n[2/4] vagrant destroy..." -ForegroundColor Yellow
if ($vagrant) { & $vagrant destroy -f }

Write-Host "`n[3/4] Removing any orphan VirtualBox VMs (k8s-manager, k8s-worker1, k8s-worker2)..." -ForegroundColor Yellow
if ($vbox) {
    foreach ($vm in "k8s-manager", "k8s-worker1", "k8s-worker2") {
        if ((& $vbox list vms) -match "`"$vm`"") {
            & $vbox controlvm $vm poweroff 2>$null | Out-Null
            Start-Sleep -Seconds 2
            & $vbox unregistervm $vm --delete
            Write-Host "Removed orphan VM $vm"
        }
    }
}

Write-Host "`n[4/4] Cleaning local state and generated files..." -ForegroundColor Yellow
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue ".vagrant", "terraform.tfstate", "terraform.tfstate.backup"
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "shared\join.sh", "shared\kubeconfig"
Write-Host "Kept shared\logs for reference (delete manually if not needed)."

Write-Host "`n=============================================" -ForegroundColor Green
Write-Host " Teardown complete. Run .\deploy.ps1 to start fresh." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
