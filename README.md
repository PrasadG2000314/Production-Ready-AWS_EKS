# 🚀 Production-Ready AWS EKS GitOps Infrastructure with Terraform

[![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-623CE4?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS EKS](https://img.shields.io/badge/AWS_EKS-v1.30-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.30-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD_Ready-F26100?style=for-the-badge&logo=argo&logoColor=white)](https://argoproj.github.io/cd/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

An enterprise-grade Infrastructure as Code (IaC) repository for provisioning an **Amazon EKS (Elastic Kubernetes Service)** cluster and dedicated **VPC networking** on AWS, purpose-built and optimized for modern **GitOps engine deployment** (e.g., ArgoCD / FluxCD).

---

## 📋 Table of Contents

- [Overview & Key Features](#-overview--key-features)
- [Architecture Diagram](#-architecture-diagram)
- [Technical Specifications](#-technical-specifications)
- [Prerequisites](#-prerequisites)
- [Quick Start Deployment Guide](#-quick-start-deployment-guide)
- [ArgoCD GitOps Setup Guide](#-argocd-gitops-setup-guide)
- [Repository Structure](#-repository-structure)
- [Subnet Tagging & Controller Integration](#-subnet-tagging--controller-integration)
- [Troubleshooting & Known Pitfalls](#-troubleshooting--known-pitfalls)
- [Security & Production Best Practices](#-security--production-best-practices)
- [Cleanup & Teardown](#-cleanup--teardown)
- [License](#-license)

---

## 📌 Overview & Key Features

This project leverages official AWS Terraform modules to deploy a high-availability, dual-AZ Kubernetes cluster on AWS. It eliminates manual cluster setups and ensures repeatability, security, and GitOps readiness out of the box.

### Key Highlights
- **VPC Infrastructure**: Dedicated 2-AZ network topology (`10.0.0.0/16`) featuring public and private subnets with a NAT Gateway for secure outbound internet routing.
- **EKS Kubernetes v1.30**: Managed Control Plane utilizing AWS EKS v1.30 with cluster creator administrator permissions.
- **Amazon Linux 2023 (`AL2023`) Nodes**: EKS Managed Node Group (`t3.medium` instances) pre-configured with the latest AL2023 standard AMI compatible with EKS 1.30+.
- **Auto-Scaling**: Elastic Node Group scaling configured with 1 min, 2 desired, and 3 max nodes.
- **Cloud-Native Ingress Ready**: Subnet auto-discovery tags for AWS Load Balancer Controller (`kubernetes.io/role/elb` & `kubernetes.io/role/internal-elb`).
- **GitOps Engine Ready**: Sized and memory-tuned to host ArgoCD control planes and microservice workloads cleanly.

---

## 📐 Architecture Diagram

### Flowchart Topology

```mermaid
flowchart TB
    subgraph AWS ["AWS Cloud (us-east-1)"]
        subgraph VPC ["VPC (10.0.0.0/16)"]
            subgraph PublicAZ1 ["Public Subnet us-east-1a (10.0.101.0/24)"]
                IGW ["Internet Gateway"]
                NAT ["NAT Gateway"]
                ALB ["AWS Load Balancer (Public)"]
            end

            subgraph PublicAZ2 ["Public Subnet us-east-1b (10.0.102.0/24)"]
            end

            subgraph PrivateAZ1 ["Private Subnet us-east-1a (10.0.1.0/24)"]
                Node1 ["EKS Managed Node 1 (t3.medium)"]
                ArgoCD ["ArgoCD Controller & UI"]
            end

            subgraph PrivateAZ2 ["Private Subnet us-east-2b (10.0.2.0/24)"]
                Node2 ["EKS Managed Node 2 (t3.medium)"]
                Pods ["Workload Pods"]
            end

            EKS_CP ["EKS Managed Control Plane (v1.30)"]
        end
    end

    DevOps ["DevOps Engineer / CI/CD"] -->|terraform apply| VPC
    DevOps -->|kubectl / aws cli| EKS_CP
    ALB --> ArgoCD
    Node1 <--> EKS_CP
    Node2 <--> EKS_CP
    PrivateAZ1 -->|Outbound traffic| NAT
    NAT --> IGW
    IGW --> Internet (["Internet"])
```

### Detailed Subnet Layout

```text
+-----------------------------------------------------------------------------+
|                                 AWS Region: us-east-1                       |
|                                                                             |
|  +-----------------------------------------------------------------------+  |
|  |                        EKS VPC (10.0.0.0/16)                           |  |
|  |                                                                       |  |
|  |  +---------------------------------+ +-----------------------------+  |  |
|  |  | Public Subnets (AZ1 & AZ2)       | | Private Subnets (AZ1 & AZ2) |  |  |
|  |  | - 10.0.101.0/24 (us-east-1a)      | | - 10.0.1.0/24 (us-east-1a)  |  |  |
|  |  | - 10.0.102.0/24 (us-east-1b)      | | - 10.0.2.0/24 (us-east-1b)  |  |  |
|  |  |                                 | |                             |  |  |
|  |  | [ Internet GW ] [ NAT Gateway ] | | [ EKS Worker Nodes ]        |  |  |
|  |  | Tag: kubernetes.io/role/elb=1   | | [ ArgoCD / App Pods ]       |  |  |
|  |  |                                 | | Tag: internal-elb=1         |  |  |
|  |  +----------------+----------------+ +--------------+--------------+  |  |
|  +-------------------|---------------------------------|-----------------+  |
+----------------------|---------------------------------|--------------------+
                       v                                 v
               Public Load Balancers                   Private Compute
```

---

## 📋 Technical Specifications

| Parameter | Specification | Description |
| :--- | :--- | :--- |
| **IaC Tool** | Terraform `>= 1.5.0` | Declarative infrastructure provisioning |
| **Cloud Provider** | AWS (`hashicorp/aws ~> 5.0`) | Primary cloud host |
| **AWS Region** | `us-east-1` | Target deployment region |
| **VPC CIDR Block** | `10.0.0.0/16` | Isolated Virtual Private Cloud |
| **Kubernetes Version** | `1.30` | EKS Managed Control Plane release |
| **EKS Module Version** | `~> 20.0` | Official `terraform-aws-modules/eks/aws` |
| **VPC Module Version** | `5.0.0` | Official `terraform-aws-modules/vpc/aws` |
| **Node Instance Sizing** | `t3.medium` (2 vCPU, 4GB RAM) | Optimized for system pods + ArgoCD engine |
| **Node AMI Type** | `AL2023_x86_64_STANDARD` | Amazon Linux 2023 standard EKS AMI |
| **Node Group Scaling** | Min: `1` \| Desired: `2` \| Max: `3` | Managed Auto-Scaling Group bounds |

---

## ⚙️ Prerequisites

Ensure the following local tools are installed and configured before running Terraform:

- 🛠️ **[Terraform](https://developer.hashicorp.com/terraform/downloads)** `>= 1.5.0`
- ☁️ **[AWS CLI](https://aws.amazon.com/cli/)** `>= 2.x` (configured with admin IAM rights)
- ☸️ **[kubectl](https://kubernetes.io/docs/tasks/tools/)** `>= 1.30`
- 📦 **[Helm](https://helm.sh/docs/intro/install/)** `>= 3.x` (optional, for deploying add-ons)
- 🐙 **[Git](https://git-scm.com/)**

Verify installed versions:
```bash
terraform version
aws --version
kubectl version --client
```

---

## 🚀 Quick Start Deployment Guide

### Step 1: AWS Credentials Setup
Ensure your AWS credentials are exported or configured via AWS CLI:
```bash
aws configure
```

### Step 2: Clone Repository
```bash
git clone https://github.com/PrasadG2000314/Cloud-Infrastructure-with-Terraform.git
cd Cloud-Infrastructure-with-Terraform
```

### Step 3: Initialize Terraform
Initialize required provider plugins and modules:
```bash
terraform init
```

### Step 4: Validate & Plan Infrastructure
Generate and review the execution plan:
```bash
terraform plan
```

### Step 5: Apply Configuration
Provision the VPC and EKS cluster on AWS:
```bash
terraform apply -auto-approve
```
> ⏱️ *Note: EKS Cluster creation typically takes 10–15 minutes.*

### Step 6: Configure `kubectl` Authentication
Update local kubeconfig to point to the newly provisioned EKS cluster:
```bash
aws eks update-kubeconfig --region us-east-1 --name gitops-eks-cluster
```

### Step 7: Verify Cluster Health
Confirm nodes are active and Ready:
```bash
kubectl get nodes -o wide
kubectl get pods -A
```

---

## 🔄 ArgoCD GitOps Setup Guide

Once your EKS cluster is operational, deploy **ArgoCD** to establish a GitOps continuous delivery pipeline:

### 1. Create ArgoCD Namespace
```bash
kubectl create namespace argocd
```

### 2. Install ArgoCD Core Components
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 3. Verify ArgoCD Deployment
```bash
kubectl get pods -n argocd -w
```

### 4. Access ArgoCD UI (Port-Forwarding)
Forward port 8080 to the ArgoCD Server service:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Now access the web interface at: `https://localhost:8080`

### 5. Retrieve Initial Admin Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode; echo
```
- **Username**: `admin`
- **Password**: *(output from command above)*

---

## 📂 Repository Structure

```text
.
├── main.tf                 # Core Infrastructure (VPC & EKS Cluster Module definitions)
├── provider.tf             # AWS Provider, Region, and Terraform Version declarations
├── .gitignore              # Ignores .terraform/, *.tfstate, and sensitive files
├── README.md               # Project documentation and operational guide
└── .terraform.lock.hcl     # Dependency lockfile for provider versions
```

### Module Breakdown
- **[`main.tf`](file:///c:/Users/nipun/OneDrive/Desktop/DevOps/eks-gitops-project/main.tf)**:
  - `module "vpc"`: Creates multi-AZ network with NAT Gateway & Kubernetes ELB tags.
  - `module "eks"`: Spins up managed Control Plane v1.30 and AL2023 `t3.medium` Node Group.
- **[`provider.tf`](file:///c:/Users/nipun/OneDrive/Desktop/DevOps/eks-gitops-project/provider.tf)**:
  - Declares HashiCorp AWS provider requirements (`~> 5.0`) and target region (`us-east-1`).

---

## 🏷️ Subnet Tagging & Controller Integration

For AWS Load Balancer Controller (ALB/NLB) and Kubernetes `Service` type `LoadBalancer` to automatically discover cluster subnets, specific tags are applied in `main.tf`:

| Subnet Type | Required Tag | Purpose |
| :--- | :--- | :--- |
| **Public Subnets** | `kubernetes.io/role/elb = 1` | Instructs AWS to launch internet-facing Load Balancers (ALB/NLB) |
| **Private Subnets** | `kubernetes.io/role/internal-elb = 1` | Instructs AWS to launch internal Load Balancers for private workloads |
| **VPC Shared Tag** | `kubernetes.io/cluster/gitops-eks-cluster = shared` | Links VPC resources to the EKS cluster instance |

```hcl
public_subnet_tags = {
  "kubernetes.io/role/elb" = 1
}

private_subnet_tags = {
  "kubernetes.io/role/internal-elb" = 1
}
```

---

## 🔧 Troubleshooting & Known Pitfalls

### 1. Pod Scheduling Failure on Small Nodes (`t3.micro`)
- **Symptom**: Pods remain stuck in `Pending` state with `0/2 nodes are available: Insufficient memory/pods`.
- **Root Cause**: `t3.micro` instances provide only 1GB RAM and support a maximum of 4 ENI Pod IPs. EKS system pods (`aws-node`, `coredns`, `kube-proxy`) exhaust these limits immediately.
- **Fix**: Use `t3.medium` instances (`instance_types = ["t3.medium"]`) which provide 4GB RAM, 2 vCPUs, and support up to 17 pod IPs per node.

### 2. Managed Node Group Bootstrap Failure on EKS 1.30
- **Symptom**: `terraform apply` fails while waiting for EKS Node Group creation.
- **Root Cause**: EKS 1.30 with `terraform-aws-modules/eks/aws` v20+ deprecates standard Amazon Linux 2 (`AL2_x86_64`) bootstrap scripts.
- **Fix**: Specify Amazon Linux 2023 standard AMI:
  ```hcl
  ami_type = "AL2023_x86_64_STANDARD"
  ```

### 3. Subnet Auto-Discovery Failure for Ingress
- **Symptom**: Kubernetes Ingress or LoadBalancer Service returns `FailedBuildModel: failed to discover subnets`.
- **Root Cause**: Missing ELB tags on public or private subnets.
- **Fix**: Verify tags `kubernetes.io/role/elb` and `kubernetes.io/role/internal-elb` are present on VPC subnets.

### 4. Git Encoding / Binary Diff Error (`Git: Failed to execute git`)
- **Symptom**: VS Code or Git CLI throws errors when staging `README.md`.
- **Root Cause**: Document saved with UTF-16LE encoding or containing null bytes `0x00`.
- **Fix**: Save file explicitly in **UTF-8 without BOM** encoding and verify `.gitignore` excludes `.terraform/` provider binaries.

---

## 🔒 Security & Production Best Practices

1. **State File Protection**:
   - Store `terraform.tfstate` in an encrypted remote S3 bucket with DynamoDB state locking (never commit state files to Git).
2. **Private Worker Nodes**:
   - All EKS worker nodes run inside **Private Subnets** without public IP addresses, routing outbound traffic through a NAT Gateway.
3. **IAM Least Privilege**:
   - Enable `enable_cluster_creator_admin_permissions = true` for bootstrapping, then transition access control to AWS IAM IRSA (IAM Roles for Service Accounts).
4. **Secrets Management**:
   - Use AWS Secrets Manager or Sealed Secrets / External Secrets Operator inside ArgoCD for handling sensitive configuration credentials.

---

## 🧹 Cleanup & Teardown

To avoid incurring cloud charges on AWS when testing is complete, destroy all provisioned infrastructure:

```bash
# 1. (Optional) Delete any deployed Kubernetes LoadBalancers or Ingresses first
kubectl delete svc --all -n argocd

# 2. Destroy Terraform resources
terraform destroy -auto-approve
```

---

## 📜 License

This project is open-source and released under the **[MIT License](LICENSE)**.

---

<p align="center">
  <b>Built with ❤️ for DevOps & GitOps Engineers</b>
</p>