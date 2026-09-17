# Provisionamento de Máquinas Virtuais no VirtualBox com Terraform

Este tutorial documenta o processo passo-a-passo para criar e configurar Máquinas Virtuais (VMs) no Oracle VirtualBox utilizando o Terraform.

## 1. Pré-requisitos

Antes de iniciar, certifique-se de ter os seguintes softwares instalados em seu ambiente local:
- **Oracle VirtualBox**: [Download oficial](https://www.virtualbox.org/wiki/Downloads)
- **Terraform**: [Download oficial](https://developer.hashicorp.com/terraform/downloads)

> **Nota sobre o PATH no Windows**: Caso você não tenha instalado o Terraform e o VirtualBox de forma global (via instalador), é necessário que os executáveis `terraform.exe` e `VBoxManage.exe` estejam acessíveis. Se você apenas copiou o `terraform.exe` para a pasta do projeto, use `.\terraform` nos comandos. Para o VirtualBox, adicione o caminho ao PATH temporariamente no início do seu script:
> ```powershell
> $env:PATH += ";C:\Program Files\Oracle\VirtualBox"
> ```

## 2. Opções de Sistemas Operacionais (Imagens)

O provedor Terraform para VirtualBox (`terra-farm/virtualbox`) consome imagens empacotadas nativamente no formato de "Vagrant boxes". Você pode buscar imagens prontas de diversos Sistemas Operacionais (Linux, Windows, etc.) no repositório oficial da HashiCorp, o [Vagrant Cloud](https://app.vagrantup.com/boxes/search).

### Como buscar e acessar imagens:
1. Acesse o [Vagrant Cloud](https://app.vagrantup.com/boxes/search).
2. **Para Linux**: Pesquise por distribuições oficiais como `ubuntu`, `debian` ou `centos`. Exemplo: `ubuntu/bionic64`.
3. **Para Windows**: Pesquise pela tag `windows`. Note que imagens Windows tendem a ser maiores e geralmente são disponibilizadas pela comunidade (ex: `gusztavvargadr/windows-server`).
4. **Obtendo a URL da imagem (A API do Vagrant)**: O Terraform exige a URL direta para download do arquivo `.box`. 

Você vai montar o link seguindo a estrutura fixa da API do Vagrant. Olhando para uma página que você encontrou (ex: `generic/alpine318`), você tem:
- **Usuário:** `generic`
- **Nome da box:** `alpine318`

Agora você só precisa olhar no site qual é o número da versão que você quer (na aba "Versions" da página da box. Vamos supor que seja a versão `4.3.12`). A URL que você vai colocar no `main.tf` fica montada exatamente assim:

`https://app.vagrantup.com/generic/boxes/alpine318/versions/4.3.12/providers/virtualbox.box`

Sempre substitua apenas as palavras da estrutura principal:
`https://app.vagrantup.com/<USUARIO>/boxes/<NOME_DA_BOX>/versions/<VERSAO>/providers/virtualbox.box`

> **Aviso sobre o Vagrant Cloud**: A HashiCorp está em processo de limitar recursos da sua plataforma em nuvem. Se no futuro as URLs públicas acima não funcionarem (ou expirarem como links S3 temporários), o provedor Terraform para VirtualBox também aceita caminhos locais. Basta baixar o arquivo `.box` manualmente e apontar o caminho local no código (ex: `image = "./alpine318.box"`).

## 3. Personalização Avançada da VM

O provedor Terraform para VirtualBox gerencia nativamente as configurações básicas (CPU, Memória e Placa de Rede). Para configurações mais profundas de hardware (como USB, Área de Transferência e Pastas Compartilhadas), o Terraform não possui suporte nativo, sendo necessário usar comandos do próprio VirtualBox (`VBoxManage`) logo após a criação da máquina.

### Configurações de Rede (NAT vs Bridged)
Dentro do recurso `virtualbox_vm`, o bloco `network_adapter` define a placa de rede. Os tipos suportados incluem:
- **NAT (`type = "nat"`)**: É o padrão. A VM compartilha a conexão de internet do seu computador. Ela consegue acessar a internet, mas outros dispositivos na sua rede local não conseguem acessá-la diretamente.
- **Bridged (`type = "bridged"`)**: A VM recebe um IP próprio do seu roteador (como se fosse outro celular ou PC na mesma rede Wi-Fi/Cabo). Para usá-la, você deve especificar o nome exato da sua placa de rede física no Windows/Linux em `host_interface` (ex: `Wi-Fi` ou `Ethernet`).

Exemplo para modo Bridged:
```hcl
  network_adapter {
    type           = "bridged"
    host_interface = "Wi-Fi" # Coloque o nome correto do seu adaptador hospedeiro
  }
```

### USB, Área de Transferência e Pastas Compartilhadas
Para essas configurações, injetamos um bloco `provisioner "local-exec"` no Terraform, que executa comandos no seu computador hospedeiro para alterar a VM recém-criada.

> **Atenção (Windows)**: O provedor Terraform cria a VM e a inicia automaticamente. Como o `VBoxManage modifyvm` exige que a máquina esteja **desligada** para modificar suas propriedades, o provisioner precisa seguir esta sequência obrigatória:
> 1. Desligar a VM (`controlvm ... poweroff`)
> 2. Aguardar alguns segundos para liberar o lock (`Start-Sleep`)
> 3. Aplicar as modificações (`modifyvm`)
> 4. Religar a VM (`startvm ... --type headless`)
>
> Além disso, no Windows, use `interpreter = ["PowerShell", "-Command"]` no bloco `provisioner`, pois o interpretador padrão (`cmd /C`) não lida bem com comandos longos e caracteres especiais.

```hcl
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "VBoxManage controlvm minha-vm poweroff; Start-Sleep -Seconds 5; VBoxManage modifyvm minha-vm --clipboard-mode bidirectional --usb off; VBoxManage sharedfolder add minha-vm --name pasta_compartilhada --hostpath 'C:\\MinhaPasta' --automount; VBoxManage startvm minha-vm --type headless"
  }
```

## 4. Criando uma Única Máquina Virtual

Crie um diretório para o seu projeto e, dentro dele, um arquivo chamado `main.tf`.

### main.tf

```hcl
terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      # A única versão disponível é a alpha; use a versão exata (sem ~>)
      version = "0.2.2-alpha.1"
    }
  }
}

resource "virtualbox_vm" "node" {
  name   = "linux-node-1"
  # URL do Vagrant Cloud OU caminho local para o arquivo .box
  image  = "https://app.vagrantup.com/generic/boxes/alpine318/versions/4.3.12/providers/virtualbox.box"
  cpus   = 1
  memory = "1024 mib"

  network_adapter {
    type           = "bridged"
    host_interface = "Wi-Fi" # Substitua pelo nome do seu adaptador de rede
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "VBoxManage controlvm linux-node-1 poweroff; Start-Sleep -Seconds 5; VBoxManage modifyvm linux-node-1 --usb off; VBoxManage sharedfolder add linux-node-1 --name minha_pasta --hostpath 'C:\\MinhaPastaCompartilhada' --automount; VBoxManage startvm linux-node-1 --type headless"
  }
}

output "vm_ip" {
  value = virtualbox_vm.node.network_adapter[0].ipv4_address
}
```

### Execução
Execute os comandos abaixo no terminal, dentro do diretório do projeto, para provisionar a VM:

1. **Inicializar o Terraform**: Baixa o provedor do VirtualBox.
   ```bash
   terraform init
   ```
2. **Visualizar o plano de execução**: Exibe os recursos que serão criados.
   ```bash
   terraform plan
   ```
3. **Aplicar a infraestrutura**: Cria a Máquina Virtual.
   ```bash
   terraform apply -auto-approve
   ```

## 5. Criando Múltiplas Máquinas Virtuais

Para provisionar múltiplas VMs, permitindo configurações e sistemas operacionais distintos para cada uma de forma organizada, a melhor prática é utilizar a função `for_each` do Terraform iterando sobre um bloco de variáveis (mapa). Isso evita problemas de realocação de índices que ocorrem ao usar `count`.

Altere o arquivo `main.tf` para o seguinte formato:

### main.tf (Múltiplas VMs)

```hcl
terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

# Definição das configurações individuais das VMs
locals {
  vms = {
    "linux-web" = {
      cpus   = 1
      memory = "1024 mib"
      image  = "https://app.vagrantup.com/generic/boxes/alpine318/versions/4.3.12/providers/virtualbox.box"
    },
    "linux-db" = {
      cpus   = 2
      memory = "2048 mib"
      image  = "https://app.vagrantup.com/ubuntu/boxes/bionic64/versions/20180903.0.0/providers/virtualbox.box"
    }
  }
}

resource "virtualbox_vm" "cluster" {
  for_each = local.vms

  name   = each.key
  image  = each.value.image
  cpus   = each.value.cpus
  memory = each.value.memory

  network_adapter {
    type           = "bridged"
    host_interface = "Wi-Fi" # Substitua pelo nome do seu adaptador de rede
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "VBoxManage controlvm ${each.key} poweroff; Start-Sleep -Seconds 5; VBoxManage modifyvm ${each.key} --usb off; VBoxManage startvm ${each.key} --type headless"
  }
}

output "vms_ips" {
  value = {
    for k, vm in virtualbox_vm.cluster : k => vm.network_adapter[0].ipv4_address
  }
}
```

### Comandos para atualização
1. Execute `terraform plan` para conferir a alteração. O Terraform perceberá que deve criar as novas VMs.
2. Execute `terraform apply -auto-approve` para efetivar as mudanças.

## 6. Destruição da Infraestrutura

Para remover todas as Máquinas Virtuais criadas e liberar o espaço em disco e os recursos, execute:
```bash
terraform destroy -auto-approve
```

> **Atenção**: O comando `terraform destroy` funciona corretamente apenas quando o **state do Terraform está íntegro**. Se o `terraform apply` tiver falhado no meio da execução (crash, erro de provisioner, etc.), a VM pode ter sido criada no VirtualBox mas não registrada no state — nesse caso, o `terraform destroy` dirá "nada para destruir" mas a VM continuará existindo. Para resolver isso, use o script `destroy` aprimorado (Seção 7) ou o script `cleanup` (Seção 8).

## 7. Automatizando a Execução com Scripts

Para acelerar o fluxo de trabalho diário, você pode criar scripts que executam os comandos do Terraform automaticamente. Abaixo estão opções para **Bash** (Linux/Mac/WSL) e **PowerShell** (Windows).

> **Importante (Windows)**: Caso o `terraform.exe` esteja apenas na pasta do projeto (e não instalado globalmente), use `./terraform` nos scripts Bash e `.\terraform` nos scripts PowerShell. Além disso, adicione o VirtualBox ao PATH no início do script para que o `VBoxManage` funcione corretamente dentro do `provisioner "local-exec"`.

### Deploy (PowerShell)
```powershell
# Adiciona o VirtualBox ao PATH da sessão (necessário para o provisioner local-exec)
$env:PATH += ";C:\Program Files\Oracle\VirtualBox"

Write-Host "==> Inicializando o Terraform..." -ForegroundColor Cyan
.\terraform init -input=false

Write-Host "==> Validando configurações..." -ForegroundColor Cyan
.\terraform validate

Write-Host "==> Aplicando infraestrutura..." -ForegroundColor Cyan
.\terraform apply -auto-approve

Write-Host "==> Processo finalizado com sucesso!" -ForegroundColor Green
```

### Deploy (Bash)
```bash
#!/bin/bash
export PATH="$PATH:/usr/local/bin"

echo "==> Inicializando o Terraform..."
terraform init -input=false

echo "==> Validando configurações..."
terraform validate

echo "==> Aplicando infraestrutura..."
terraform apply -auto-approve

echo "==> Processo finalizado com sucesso!"
```
*(Não esqueça de conceder permissão de execução: `chmod +x deploy.sh`)*

### Destroy (PowerShell)
O script abaixo executa o `terraform destroy` e, em seguida, verifica se restaram VMs órfãs no VirtualBox (de execuções anteriores que falharam). Por fim, limpa os arquivos de state.
```powershell
$env:PATH += ";C:\Program Files\Oracle\VirtualBox"

# 1. Terraform Destroy (caminho normal)
Write-Host "==> [1/3] Executando terraform destroy..." -ForegroundColor Red
.\terraform destroy -auto-approve

# 2. Limpeza de VMs orfas no VirtualBox
# Atualize esta lista caso altere os nomes das VMs no main.tf.
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
```

### Destroy (Bash)
```bash
#!/bin/bash

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
```

## 8. Limpeza Total do Ambiente (Cleanup)

Use este script apenas quando o ambiente estiver em estado completamente inconsistente (ex: crash do Terraform, troca de versão do provedor, provider corrompido). Ele remove **tudo**: VMs órfãs, state, lock file e cache do provedor, permitindo recomeçar do zero.

### Cleanup (PowerShell)
```powershell
$env:PATH += ";C:\Program Files\Oracle\VirtualBox"

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
```

### Cleanup (Bash)
```bash
#!/bin/bash

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
```

