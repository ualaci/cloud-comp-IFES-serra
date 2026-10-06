#!/bin/bash
# Destroys the Kubernetes cluster VMs, Terraform state and generated files so the process can be redone from scratch.
cd "$(dirname "$0")"

echo "============================================="
echo " Destroying Kubernetes Cluster"
echo "============================================="

echo -e "\n[1/4] terraform destroy..."
if command -v terraform >/dev/null && [ -f terraform.tfstate ]; then
  TF_VAR_bridge_adapter="unused-for-destroy" terraform destroy -auto-approve -input=false \
    || echo "Warning: terraform destroy failed, continuing with vagrant/VirtualBox cleanup."
else
  echo "No Terraform state found, skipping."
fi

echo -e "\n[2/4] vagrant destroy..."
command -v vagrant >/dev/null && vagrant destroy -f

echo -e "\n[3/4] Removing any orphan VirtualBox VMs..."
if command -v VBoxManage >/dev/null; then
  for vm in k8s-manager k8s-worker1 k8s-worker2; do
    if VBoxManage list vms | grep -q "\"$vm\""; then
      VBoxManage controlvm "$vm" poweroff >/dev/null 2>&1; sleep 2
      VBoxManage unregistervm "$vm" --delete && echo "Removed orphan VM $vm"
    fi
  done
fi

echo -e "\n[4/4] Cleaning local state and generated files..."
rm -rf .vagrant terraform.tfstate terraform.tfstate.backup shared/join.sh shared/kubeconfig
echo "Kept shared/logs for reference (delete manually if not needed)."

echo -e "\n============================================="
echo " Teardown complete. Run ./deploy.sh to start fresh."
echo "============================================="
