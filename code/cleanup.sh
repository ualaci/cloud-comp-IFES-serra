#!/bin/bash

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="./logs/cleanup_$TIMESTAMP.log"
mkdir -p ./logs

{
    echo "==> [1/4] Removendo VMs orfas do VirtualBox..."
    MANAGED_VMS=("linux-node-1" "alpine-node" "ubuntu-node")
    for vm in "${MANAGED_VMS[@]}"; do
        if VBoxManage list vms 2>/dev/null | grep -q "\"$vm\""; then
            echo "    Removendo VM: $vm"
            VBoxManage controlvm "$vm" poweroff 2>/dev/null
            sleep 3
            VBoxManage unregistervm "$vm" --delete 2>/dev/null
        fi
    done

    echo "==> [2/4] Removendo arquivos de state do Terraform..."
    rm -f terraform.tfstate terraform.tfstate.backup

    echo "==> [3/4] Removendo lock file..."
    rm -f .terraform.lock.hcl

    echo "==> [4/4] Removendo cache do provider (.terraform/)..."
    rm -rf .terraform/

    echo "==> Limpeza total concluida. Execute ./deploy.sh para recomecar do zero."
} 2>&1 | tee "$LOG_FILE"

echo "==> Log salvo em: $LOG_FILE"
