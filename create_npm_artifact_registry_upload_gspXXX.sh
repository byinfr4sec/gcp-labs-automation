#!/bin/bash
set -e

echo "========================================="
echo " 📦 Create an NPM Artifact Registry and Upload Code"
echo "========================================="
echo ""

# -------------------------------
# 1️⃣ - VERIFICAR AUTENTICAÇÃO
# -------------------------------
echo "🔑 Verificando autenticação..."
gcloud auth list
echo ""
echo "🔍 Verificando projeto ativo..."
gcloud config list project
echo ""

# -------------------------------
# 2️⃣ - INPUTS DO USUÁRIO
# -------------------------------
read -p "👉 Digite o ID do Projeto (PROJECT_ID): " PROJECT_ID
read -p "👉 Digite a Região (ex: us-central1, us-east1, europe-west1): " REGION

echo ""
echo "⚙️ Configurando o projeto e a região..."
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION

# -------------------------------
# 3️⃣ - HABILITAR API NECESSÁRIA
# -------------------------------
echo ""
echo "🔌 Habilitando Artifact Registry API..."
gcloud services enable artifactregistry.googleapis.com

# -------------------------------
# 4️⃣ - CRIAR REPOSITÓRIO NPM
# -------------------------------
echo ""
echo "🗄️ Criando repositório NPM 'my-npm-repo'..."
gcloud artifacts repositories create my-npm-repo \
  --repository-format=npm \
  --location=$REGION \
  --description="NPM repository" || echo "ℹ️ Repositório já existe, continuando..."

echo ""
echo "🔍 Verificando repositório criado..."
gcloud artifacts repositories describe my-npm-repo --location=$REGION

# -------------------------------
# 5️⃣ - CRIAR PACOTE NPM DE EXEMPLO
# -------------------------------
echo ""
echo "📦 Criando pacote NPM de exemplo..."
mkdir -p my-npm-package
cd my-npm-package

npm init --scope=@$PROJECT_ID -y

echo 'console.log(`Hello from my-npm-package!`);' > index.js
echo "✅ index.js criado com sucesso!"

# -------------------------------
# 6️⃣ - CONFIGURAR AUTENTICAÇÃO DO NPM
# -------------------------------
echo ""
echo "⚙️ Configurando autenticação NPM com Artifact Registry..."
gcloud artifacts print-settings npm \
  --project="$PROJECT_ID" \
  --repository=my-npm-repo \
  --location="$REGION" \
  --scope=@$PROJECT_ID > .npmrc

echo ""
echo "🔑 Configurando autenticação Docker (para NPM)..."
gcloud auth configure-docker "$REGION"-npm.pkg.dev

# -------------------------------
# 7️⃣ - ATUALIZAR package.json
# -------------------------------
echo ""
echo "🧩 Atualizando package.json..."
cat > package.json <<EOF
{
  "name": "@$PROJECT_ID/my-npm-package",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "artifactregistry-login": "npx google-artifactregistry-auth --repo-config=./.npmrc --credential-config=./.npmrc",
    "test": "echo \\"Error: no test specified\\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "type": "commonjs"
}
EOF

# -------------------------------
# 8️⃣ - AUTENTICAR E PUBLICAR PACOTE
# -------------------------------
echo ""
echo "🔑 Executando login no Artifact Registry..."
npm run artifactregistry-login

echo ""
echo "🔍 Verificando token no .npmrc..."
cat .npmrc

echo ""
echo "🚀 Publicando pacote para Artifact Registry..."
npm publish --registry=https://"$REGION"-npm.pkg.dev/"$PROJECT_ID"/my-npm-repo/

# -------------------------------
# 9️⃣ - VERIFICAR ENVIO
# -------------------------------
echo ""
echo "🔍 Verificando pacotes no repositório..."
gcloud artifacts packages list --repository=my-npm-repo --location="$REGION"

echo ""
echo "✅ LAB CONCLUÍDO COM SUCESSO! by infr4Sec"
echo "========================================="
