#!/bin/bash

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="./logs/destroy_$TIMESTAMP.log"
mkdir -p ./logs

{
    # 1. Terraform Destroy
    echo "==> [1/3] Executando terraform destroy..."
    terraform destroy -auto-approve

    # 2. Limpeza de VMs orfas
    echo "==> [2/3] Verificando VMs orfas no VirtualBox..."
    MANAGED_VMS=("linux-node-1" "alpine-node" "ubuntu-node")
    for vm in "${MANAGED_VMS[@]}"; do
        if VBoxManage list vms 2>/dev/null | grep -q "\"$vm\""; then
            echo "    VM orfa encontrada: $vm. Removendo..."
            VBoxManage controlvm "$vm" poweroff 2>/dev/null
            sleep 3
            VBoxManage unregistervm "$vm" --delete 2>/dev/null
        fi
    done

    # 3. Limpeza dos arquivos de state
    echo "==> [3/3] Limpando arquivos de state..."
    rm -f terraform.tfstate terraform.tfstate.backup

    echo "==> Ambiente destruido e limpo com sucesso!"
} 2>&1 | tee "$LOG_FILE"

echo "==> Log salvo em: $LOG_FILE"
