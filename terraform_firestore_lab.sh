#!/bin/bash
set -e

echo "==============================================="
echo "🔥 Terraform Essentials: Cloud Firestore Database"
echo "==============================================="

# Etapa 1️⃣: Configuração inicial
echo ""
echo "🔑 Verificando autenticação atual..."
gcloud auth list

read -p "👉 Digite o ID do Projeto (PROJECT_ID): " PROJECT_ID
read -p "👉 Digite a Região (ex: us-central1, us-east1): " REGION

echo ""
echo "⚙️ Configurando projeto e região..."
gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"

# Etapa 2️⃣: Ativar APIs necessárias
echo ""
echo "🚀 Habilitando APIs necessárias..."
gcloud services enable firestore.googleapis.com --quiet
gcloud services enable cloudbuild.googleapis.com --quiet
echo "✅ APIs ativadas com sucesso!"

# Etapa 3️⃣: Criar bucket remoto para o Terraform State
BUCKET_NAME="${PROJECT_ID}-tf-state"
echo ""
echo "🗄️ Criando bucket remoto para o Terraform state..."
if ! gsutil ls -b gs://$BUCKET_NAME >/dev/null 2>&1; then
  gcloud storage buckets create gs://$BUCKET_NAME --location=us
  echo "✅ Bucket criado: gs://$BUCKET_NAME"
else
  echo "ℹ️ Bucket já existe: gs://$BUCKET_NAME"
fi

# Etapa 4️⃣: Criar diretório Terraform e arquivos .tf
WORKDIR="firestore-terraform"
mkdir -p $WORKDIR && cd $WORKDIR

echo ""
echo "📄 Gerando arquivos Terraform..."

# main.tf
cat <<EOF > main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    bucket = "${BUCKET_NAME}"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "${PROJECT_ID}"
  region  = "${REGION}"
}

resource "google_firestore_database" "default" {
  name         = "default"
  project      = "${PROJECT_ID}"
  location_id  = "nam5"
  type         = "FIRESTORE_NATIVE"
}

output "firestore_database_name" {
  value       = google_firestore_database.default.name
  description = "The name of the Cloud Firestore database."
}
EOF

# variables.tf
cat <<EOF > variables.tf
variable "project_id" {
  type        = string
  description = "The ID of the Google Cloud project."
  default     = "${PROJECT_ID}"
}

variable "bucket_name" {
  type        = string
  description = "Bucket name for terraform state"
  default     = "${BUCKET_NAME}"
}
EOF

# outputs.tf
cat <<EOF > outputs.tf
output "project_id" {
  value       = var.project_id
  description = "The ID of the Google Cloud project."
}

output "bucket_name" {
  value       = var.bucket_name
  description = "The name of the bucket to store terraform state."
}
EOF

echo "✅ Arquivos Terraform criados com sucesso!"
ls -1 *.tf

# Etapa 5️⃣: Inicializar e aplicar Terraform
echo ""
echo "🧱 Inicializando Terraform..."
terraform init -input=false

echo ""
echo "🪄 Gerando plano Terraform..."
terraform plan -out=tfplan -input=false

echo ""
echo "🚀 Aplicando configuração Terraform..."
terraform apply -input=false -auto-approve tfplan

echo ""
echo "✅ Firestore criado com sucesso!"
terraform output

# Etapa 6️⃣: Limpeza opcional
echo ""
read -p "🧹 Deseja destruir os recursos criados ao final (y/N)? " RESP
if [[ "$RESP" =~ ^[Yy]$ ]]; then
  echo "⚠️ Destruindo recursos Terraform..."
  terraform destroy -auto-approve
  echo "✅ Recursos removidos com sucesso!"
else
  echo "ℹ️ Recursos mantidos. Firestore ativo no projeto $PROJECT_ID."
fi

echo ""
echo "🎯 Lab concluído com sucesso! by inf4SeC"
