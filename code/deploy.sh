#!/bin/bash
export PATH="$PATH:/usr/local/bin"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="./logs/deploy_$TIMESTAMP.log"
mkdir -p ./logs

{
    echo "==> Inicializando o Terraform..."
    terraform init -input=false

    echo "==> Validando configurações..."
    terraform validate

    echo "==> Aplicando infraestrutura..."
    terraform apply -auto-approve

    echo "==> Processo finalizado com sucesso!"
} 2>&1 | tee "$LOG_FILE"

echo "==> Log salvo em: $LOG_FILE"
