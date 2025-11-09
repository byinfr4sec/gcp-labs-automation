#!/bin/bash
set -e

echo "========================================="
echo " 🐹 Create a Go Artifact Registry and Upload Code"
echo "========================================="
echo ""

# -------------------------------
# 1️⃣ - VERIFICAR AUTENTICAÇÃO
# -------------------------------

echo "🔑 Verificando autenticação atual..."
gcloud auth list
echo ""
echo "🔍 Verificando o projeto atual..."
gcloud config list project
echo ""

# -------------------------------
# 2️⃣ - INPUTS DO USUÁRIO
# -------------------------------

read -p "👉 Digite o ID do Projeto (PROJECT_ID): " PROJECT_ID
read -p "👉 Digite a Região (ex: us-central1, us-east1, europe-west1): " REGION
read -p "👉 Digite seu e-mail para configurar o Git: " USER_EMAIL

echo ""
echo "⚙️ Configurando o projeto e região..."
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION

# -------------------------------
# 3️⃣ - HABILITAR API NECESSÁRIA
# -------------------------------

echo ""
echo "🔌 Habilitando Artifact Registry API..."
gcloud services enable artifactregistry.googleapis.com

# -------------------------------
# 4️⃣ - CRIAR REPOSITÓRIO GO
# -------------------------------

echo ""
echo "🗄️ Criando repositório Go 'my-go-repo'..."
gcloud artifacts repositories create my-go-repo \
  --repository-format=go \
  --location=$REGION \
  --description="Go repository" || echo "ℹ️ Repositório já existe, continuando..."

echo ""
echo "🔍 Verificando repositório criado..."
gcloud artifacts repositories describe my-go-repo --location=$REGION

# -------------------------------
# 5️⃣ - CONFIGURAR GO PARA USAR ARTIFACT REGISTRY
# -------------------------------

echo ""
echo "⚙️ Configurando Go para usar Artifact Registry..."
go env -w GOPRIVATE=cloud.google.com/$PROJECT_ID

echo ""
echo "🔑 Configurando autenticação Go com Artifact Registry..."
export GONOPROXY=github.com/GoogleCloudPlatform/artifact-registry-go-tools
GOPROXY=proxy.golang.org go run github.com/GoogleCloudPlatform/artifact-registry-go-tools/cmd/auth@latest add-locations --locations=$REGION

# -------------------------------
# 6️⃣ - CRIAR MÓDULO GO DE EXEMPLO
# -------------------------------

echo ""
echo "📦 Criando módulo Go de exemplo..."
mkdir -p hello
cd hello

go mod init labdemo.app/hello

cat > hello.go <<'EOF'
package main

import "fmt"

func main() {
	fmt.Println("Hello, Go module from Artifact Registry!")
}
EOF

echo "✅ Arquivo hello.go criado com sucesso!"
echo ""
echo "🔧 Verificando build..."
go build

# -------------------------------
# 7️⃣ - CONFIGURAR GIT
# -------------------------------

echo ""
echo "⚙️ Configurando Git..."
git config --global user.email "$USER_EMAIL"
git config --global user.name "cls"
git config --global init.defaultBranch main

git init
git add .
git commit -m "Initial commit"
git tag v1.0.0

# -------------------------------
# 8️⃣ - ENVIAR MÓDULO PARA ARTIFACT REGISTRY
# -------------------------------

echo ""
echo "🚀 Enviando módulo para Artifact Registry..."
gcloud artifacts go upload \
  --repository=my-go-repo \
  --location=$REGION \
  --module-path=labdemo.app/hello \
  --version=v1.0.0 \
  --source=.

# -------------------------------
# 9️⃣ - VERIFICAR ENVIO
# -------------------------------

echo ""
echo "🔍 Verificando módulo no Artifact Registry..."
gcloud artifacts packages list --repository=my-go-repo --location=$REGION

echo ""
echo "✅ LAB CONCLUÍDO COM SUCESSO! by infr4SeC"
echo "========================================="
