# multi-cloud-infra

A production-grade, cloud-agnostic Infrastructure as Code (IaC) blueprint. This repository provides the framework to provision minimal Ubuntu `aarch64` (ARM64) virtual instances across multiple cloud providers and automatically bootstrap them into a standardized, secure base environment.

---

## 🛠️ Tech Stack & Concepts
* **Declarative Provisioning:** Multi-provider infrastructure orchestration (modular architecture).
* **Configuration Automation:** Idempotent server state configuration management.
* **Target Operating System:** Ubuntu Minimal `aarch64` (optimized for ARM architectures like Oracle Ampere A1 or AWS Graviton).

---

## 📁 Repository Structure

```text
├── .gitignore                # Global exclusions for sensitive credentials and state files
├── README.md                 # Project documentation
├── terraform/                # Declarative provisioning modules
│   ├── oci/                  # Oracle Cloud Infrastructure setup
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars.example
│   ├── aws/                  # AWS Graviton setup (Future extension)
│   └── gcp/                  # GCP ARM64 setup (Future extension)
└── ansible/                  # Configuration management automation
    ├── playbook.yml          # Base configuration entrypoint
    ├── group_vars/
    │   └── all.yml           # Global setup variables
    └── roles/
        └── ubuntu_minimal/   # Baseline optimization tasks for minimal OS
```

---

## 🚀 Getting Started

### 1. Provision Infrastructure
Navigate to your targeted cloud provider directory, set up your credentials using the provided example template, and initialize the declarative configuration:

```bash
cd terraform/oci

# Create your local untracked secrets file
cp terraform.tfvars.example terraform.tfvars

# Initialize and apply infrastructure
terraform init
terraform apply
```

### 2. Automate Server Configuration
Once your instance is up and running, trigger the automation scripts to securely provision packages, configure firewalls, and optimize the minimal Ubuntu OS:

```bash
cd ../../ansible

# Execute configuration against your instance IP
ansible-playbook -i '<INSTANCE_IP>,' playbook.yml --user ubuntu
```

---

## 🔒 Security Best Practices
* **Zero Credential Leaks:** All active `.tfvars`, local states, and sensitive key pairs are strictly blocked from git tracking via `.gitignore`.
* **Example Templates:** Real configurations are substituted with extension `.example` templates for demonstration purposes.
* **Minimalist Footprint:** Server setups enforce strict UFW firewall policies and only inject baseline essential utilities onto the minimal OS layer.

