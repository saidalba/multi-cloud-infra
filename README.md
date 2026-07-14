# multi-cloud-infra

From time to time Oracle Cloud, AWS and/or Azure udpates their free tier resources but generally aarch64(ARM) processors are avaible with higher memory allocations. So this repo here for free riders who wants spin up quick instances for testing, learning Kubernetes or building microservices and doing this in a reproducible way.

You don't need to be a cloud expert to use this. Follow the steps below in order and you'll have a working server in a few minutes.

---

## How it works

Spin up a secure, ready-to-use Ubuntu ARM64 server on **Oracle Cloud, AWS, or Azure** with a single command — no cloud console clicking, no manual server setup.
This repo uses two well-known, free, open-source tools:

- **Terraform** — creates the server and its networking on your chosen cloud provider.
- **Ansible** — connects to that new server and locks it down (firewall, automatic security updates, no password logins, etc).

The `Makefile` runs both for you in the right order, so in practice you only ever type one command.

---

## ☁️ Supported providers

| Provider | Free-tier ARM64 offer | Default server size |
|---|---|---|
| **Oracle Cloud (OCI)** | Best free tier — 4 OCPU / 24GB, always free | `VM.Standard.A1.Flex` |
| **AWS** | 750 hrs/month of `t4g.micro` for 12 months | `t4g.micro` |
| **Azure** | Free credits cover Ampere Altra ARM VMs for 12 months | `Standard_D2ps_v5` |

Pick whichever one you already have an account with. Oracle Cloud has been tested end-to-end; AWS and Azure follow the identical setup process.

---

## ✅ Prerequisites

Install these once on your own computer (macOS example shown):

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform ansible jq
ansible-galaxy collection install -r ansible/requirements.yml
```

You'll also need:
- An account with your chosen cloud provider, with billing/free-tier set up.
- An SSH key pair on your computer. If you don't have one: `ssh-keygen -t ed25519`.

---

## 🚀 Quickstart

1. **Pick a provider folder** and copy the example config:
   ```bash
   cd terraform/live/oci        # or terraform/live/aws, terraform/live/azure
   cp terraform.tfvars.example terraform.tfvars
   ```
2. **Open `terraform.tfvars`** and fill in the few values it asks for (region, path to your SSH key, etc). Every line has a comment explaining it.
3. **Log in to your cloud provider's CLI** so Terraform can authenticate (one-time per provider — see the Credentials table below).
4. **From the repository root, run:**
   ```bash
   make up PROVIDER=oci         # or aws / azure
   ```
   This creates the server and automatically secures it. Takes 2-5 minutes.
5. **When you're done with the server:**
   ```bash
   make down PROVIDER=oci
   ```

That's it — steps 1-2 only happen once per provider; after that it's just `make up` / `make down`.

---

## 🔑 Credentials (one-time setup per provider)

No cloud credentials are ever stored in this repo. Each provider reads them from your machine automatically:

| Provider | How to log in |
|---|---|
| Oracle Cloud | Run `oci setup config` (installs `~/.oci/config`) |
| AWS | Run `aws configure` (installs `~/.aws/credentials`) |
| Azure | Run `az login` |

---

## 📁 Repository structure

```text
├── Makefile                    # make up / make down / make lint — the commands you'll actually use
├── scripts/
│   ├── generate-inventory.sh   # terraform output -> ansible inventory (used by `make up`)
│   └── quick-setup.sh          # optional: manual paste-and-run hardening, see below
├── terraform/
│   ├── modules/                # Reusable building blocks, one per provider
│   │   ├── oci-instance/
│   │   ├── aws-instance/
│   │   └── azure-instance/
│   └── live/                   # Your actual settings live here (terraform.tfvars)
│       ├── oci/
│       ├── aws/
│       └── azure/
└── ansible/
    ├── playbook.yml
    ├── group_vars/all.yml      # Tweak the admin username, SSH port, swap size, timezone here
    └── roles/ubuntu_minimal/   # The security hardening steps
```

---

## Everyday commands

```bash
make up PROVIDER=oci        # create + secure a server
make down PROVIDER=oci      # destroy it
make plan PROVIDER=aws      # preview changes before applying
make lint                   # check everything is valid (useful before committing changes)
```

---

## 🩹 Quick manual setup (optional)

The Terraform + Ansible flow above is the recommended path — it's reproducible and works the same way across all three providers. But sometimes you just want a box hardened *right now*: a server you spun up by hand in a cloud console, a one-off test instance, or a moment where you're on your phone/a borrowed machine SSH'd into a fresh box with no Terraform or Ansible installed locally. That's what `scripts/quick-setup.sh` is for.

It's a single, self-contained bash script covering the same essentials as the `ubuntu_minimal` Ansible role (SSH hardening, fail2ban, unattended security upgrades, log-size limits) but with nothing to install locally — copy-paste it into an SSH session and run it.

```bash
# On the server, as root:
curl -O https://raw.githubusercontent.com/saidalba/multi-cloud-infra/main/scripts/quick-setup.sh
# or just paste the file contents into a new file with nano/vim/micro
chmod +x quick-setup.sh
./quick-setup.sh
```

**Read it before you run it.** It disables SSH password login and restarts sshd. It intentionally uses `PermitRootLogin prohibit-password` rather than `no` — the stricter setting would also block the root SSH key you're using to run the script, and this script doesn't create a fallback sudo user like the Ansible role does. If you want root SSH disabled entirely, create and test a separate sudo user with your key authorized first.

---

## 🔒 What gets secured automatically

Every server this repo creates gets, out of the box:
- Firewall open to SSH only (port 22)
- Password login disabled — SSH key only
- Root login disabled, non-root admin user created
- Automatic security updates
- fail2ban (blocks repeated failed login attempts)
- A swap file, sized for small free-tier instances

---

## Notes
- State is stored locally (already excluded from git) — fine for personal use. See the comment in each `terraform/live/<provider>/backend.tf` if you later want to move it to shared/remote storage.
- Only Oracle Cloud has been tested against a real account so far. AWS and Azure use the identical, validated structure — if a region/size isn't available on your account, the error message will tell you and the `.tfvars.example` comments point you to how to check.
