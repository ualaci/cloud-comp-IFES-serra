$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Running Kubernetes Cluster Verification Test" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Write-Host "`n[1/4] Checking Cluster Nodes..." -ForegroundColor Yellow
vagrant ssh manager -c "kubectl get nodes -o wide"

Write-Host "`n[2/4] Deploying a test Nginx web server..." -ForegroundColor Yellow
vagrant ssh manager -c "kubectl create deployment test-nginx --image=nginx"

Write-Host "`n[3/4] Waiting for the Nginx pod to be scheduled on a worker node..." -ForegroundColor Yellow
# We wait up to 60 seconds for the pod to pull the image and become 'Available'
vagrant ssh manager -c "kubectl wait --for=condition=Available deployment/test-nginx --timeout=60s"

Write-Host "`n[4/4] Verifying Pod Status and Node Assignment..." -ForegroundColor Yellow
vagrant ssh manager -c "kubectl get pods -o wide"

Write-Host "`n[Cleaning Up] Removing the test deployment..." -ForegroundColor DarkGray
vagrant ssh manager -c "kubectl delete deployment test-nginx"

Write-Host "`n=============================================" -ForegroundColor Green
Write-Host " Test Complete! The cluster is fully functional." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
