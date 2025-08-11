cloud-migration-demo/
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── modules/
│       ├── network/
│       │   └── main.tf
│       ├── compute/
│       │   └── main.tf
│       └── storage/
│           └── main.tf
│
├── ansible/
│   ├── inventory.ini
│   ├── playbooks/
│   │   └── configure-app.yml
│   └── templates/
│       └── app.conf.j2
│
└── vault/
    ├── store-secrets.sh
    └── fetch-secret.yml

---

#1. Terraform — Reusable Modules
-----------------------------------------------------------------
#Network

variable "vpc_cidr" {}
variable "env" {}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.env}-vpc"
  }
}

#compute

variable "instance_type" {}
variable "ami_id" {}
variable "subnet_id" {}
variable "env" {}

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  tags = {
    Name = "${var.env}-app-instance"
  }
}

#Storage

variable "bucket_name" {}
variable "env" {}

resource "aws_s3_bucket" "storage" {
  bucket = "${var.bucket_name}-${var.env}"
  acl    = "private"
}

#main.tf

variable "env" {
  default = "dev"
}

module "network" {
  source   = "./modules/network"
  vpc_cidr = "10.0.0.0/16"
  env      = var.env
}

module "compute" {
  source        = "./modules/compute"
  ami_id        = "ami-123456"
  instance_type = "t3.micro"
  subnet_id     = "subnet-abc123"
  env           = var.env
}

module "storage" {
  source      = "./modules/storage"
  bucket_name = "app-storage"
  env         = var.env
}

2. Ansible — Configuration Management
-------------------------------------------------------------------------------

#ansible/inventory.ini

[app_servers]
<EC2_PUBLIC_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

#ansible/playbooks/configure-app.yml

---
- name: Configure application servers
  hosts: app_servers
  become: yes
  tasks:
    - name: Install dependencies
      apt:
        name: "{{ item }}"
        state: present
        update_cache: yes
      loop:
        - nginx
        - python3-pip

    - name: Deploy application config
      template:
        src: templates/app.conf.j2
        dest: /etc/nginx/sites-available/app.conf
      notify:
        - restart nginx
  handlers:
    - name: restart nginx
      service:
        name: nginx
        state: restarted

#ansible/templates/app.conf.j2

server {
    listen 80;
    server_name _;
    location / {
        root /var/www/html;
        index index.html;
    }
}

3. Vault Integration
--------------------------------------------------------------------------------
#vault/store-secrets.sh

#!/bin/bash
vault login $VAULT_TOKEN
vault kv put secret/db password="S3cur3P@ssw0rd"

#vault/fetch-secret.yml

---
- name: Fetch secret from Vault
  hosts: localhost
  tasks:
    - name: Get DB password from Vault
      set_fact:
        db_password: "{{ lookup('community.hashi_vault.hashi_vault', 'secret=db:password token={{ vault_token }} url=http://vault.local:8200') }}"

    - name: Show secret
      debug:
        msg: "DB password is {{ db_password }}"

4. Demo Flow for Interview

1. Provision Infrastructure

cd terraform
terraform init
terraform apply -var env=dev

2. Configure App Servers
cd ../ansible
ansible-playbook -i inventory.ini playbooks/configure-app.yml

3. Store Secrets in Vault

cd ../vault
./store-secrets.sh

4. Fetch Secret in Playbook
ansible-playbook fetch-secret.yml -e vault_token=<token>

