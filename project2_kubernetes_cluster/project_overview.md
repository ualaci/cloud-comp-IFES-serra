# Kubernetes Cluster Deployment Overview

This document provides a comprehensive overview of the architecture, tools, and scripts used to deploy the local Kubernetes cluster. It serves as both a study guide and a technical reference for the project.

---

## 1. Core Concepts

### What is Kubernetes (K8s)?
Kubernetes is an open-source container orchestration platform. It automates the deployment, scaling, and management of containerized applications (like Docker containers). Instead of manually starting and stopping containers on different machines, you give Kubernetes your desired state, and it ensures the system matches that state.

### Cluster Architecture
A Kubernetes cluster consists of at least one **Manager (Control Plane)** and one or more **Workers (Nodes)**.
* **Manager Node:** The "brain" of the cluster. It runs the API server, schedules workloads (Pods), and stores the state of the cluster.
* **Worker Nodes:** The "muscle" of the cluster. They run the actual container workloads. They receive instructions from the Manager node and report their health back to it.

---

## 2. Tools Used

### VirtualBox
* **Purpose:** The hypervisor.
* **Why it's necessary:** VirtualBox is the underlying engine that provides the isolated hardware resources (CPU, RAM, Disk) to create the three Virtual Machines (VMs) running Ubuntu 22.04.

### Vagrant
* **Purpose:** The VM lifecycle manager.
* **Why it's necessary:** Interacting directly with VirtualBox via its UI or command line is tedious and not reproducible. Vagrant uses a simple text file (`Vagrantfile`) to define the VMs' hardware, networking, and setup scripts, allowing us to build and configure the entire infrastructure with a single command. 

### Terraform
* **Purpose:** Infrastructure as Code (IaC) tool.
* **Why it's necessary:** While Vagrant handles local VMs, Terraform is the industry standard for cloud infrastructure. For this project, Terraform acts as the orchestrator. By using the `bmatcuk/vagrant` provider, Terraform treats the Vagrant environment as a resource, allowing us to apply IaC principles to our local deployment.

### Containerd
* **Purpose:** The Container Runtime.
* **Why it's necessary:** Kubernetes orchestrates containers, but it doesn't run them. `containerd` is the software that actually pulls the images (like Nginx) and runs the containers on the worker nodes.

### Flannel
* **Purpose:** The Container Network Interface (CNI).
* **Why it's necessary:** By default, pods on different worker nodes cannot communicate with each other. Flannel creates an overlay network (a virtual network on top of the physical one) that assigns IP addresses to Pods and routes traffic between them, regardless of which worker node they live on.

---

## 3. How the Code Works

### `deploy.ps1`
This is the entry point for the project. Its primary job is to simplify the user experience.
1. **Validation:** It checks if the required tools (Terraform, Vagrant, VirtualBox) are installed on the host machine.
2. **Execution:** It runs `terraform init` to download the necessary plugins, and `terraform apply -auto-approve` to start the cluster creation process without requiring manual confirmation.

### `main.tf`
This is the Terraform configuration file. 
* It declares the `bmatcuk/vagrant` provider, telling Terraform that we want it to manage a Vagrant environment. 
* It creates a `vagrant_vm` resource, which seamlessly triggers Vagrant in the background to read the `Vagrantfile` and build the cluster.

### `Vagrantfile`
This is where the heavy lifting happens. It defines three distinct Virtual Machines: `manager`, `worker1`, and `worker2`. 

**Key Implementations inside the Vagrantfile:**
1. **Private Networking:** We assign static IP addresses (`192.168.56.10`, `11`, `12`) to the VMs on a VirtualBox "Private Network". This isolates the cluster from the physical Wi-Fi adapter, preventing dropped connections and making node-to-node communication extremely stable.
2. **Common Provisioning:** Every VM runs an inline shell script to install `containerd`, `kubeadm`, `kubelet`, and `kubectl`. It also turns off swap memory (a strict requirement for Kubernetes) and enables IP forwarding.
3. **Manager Initialization:** On the `manager` VM, the script runs `kubeadm init` to bootstrap the control plane. It then generates a "join token" and saves it to `/vagrant/shared/join.sh`. 
4. **Synced Folders:** Vagrant automatically shares the `./shared` folder from the Windows host to `/vagrant/shared` inside all the VMs. This acts as a bridge, allowing the Manager to pass the `join.sh` token to the Workers.
5. **Worker Joining:** On the `worker1` and `worker2` VMs, the script automatically executes the `join.sh` file left behind by the manager, securely attaching them to the cluster.
