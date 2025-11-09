#!/bin/bash
set -e

echo "========================================="
echo " 🚀 Create a Container Artifact Registry and Upload Code by infr4SeC"
echo "========================================="
echo ""

# -------------------------------
# 1️⃣ - VALIDAR AUTENTICAÇÃO
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

echo ""
echo "⚙️ Configurando o projeto e região..."
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION

# -------------------------------
# 3️⃣ - HABILITAR API NECESSÁRIA
# -------------------------------

echo ""
echo "🔌 Habilitando API Artifact Registry..."
gcloud services enable artifactregistry.googleapis.com

# -------------------------------
# 4️⃣ - CRIAR REPOSITÓRIO DOCKER NO ARTIFACT REGISTRY
# -------------------------------

echo ""
echo "🗄️ Criando repositório Docker 'my-docker-repo'..."
gcloud artifacts repositories create my-docker-repo \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository" || echo "ℹ️ Repositório já existe, continuando..."

# -------------------------------
# 5️⃣ - CONFIGURAR AUTENTICAÇÃO DOCKER
# -------------------------------

echo ""
echo "🔑 Configurando autenticação do Docker com Artifact Registry..."
gcloud auth configure-docker $REGION-docker.pkg.dev -q

# -------------------------------
# 6️⃣ - CRIAR APP DE EXEMPLO E DOCKERFILE
# -------------------------------

echo ""
echo "📦 Criando app de exemplo e Dockerfile..."
mkdir -p sample-app
cd sample-app

cat > Dockerfile <<'EOF'
FROM nginx:latest
EOF

echo "✅ Dockerfile criado com sucesso!"

# -------------------------------
# 7️⃣ - BUILDAR IMAGEM DOCKER
# -------------------------------

echo ""
echo "🛠️ Buildando imagem Docker..."
docker build -t nginx-image .

# -------------------------------
# 8️⃣ - TAGUEAR IMAGEM PARA ARTIFACT REGISTRY
# -------------------------------

FULL_IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/my-docker-repo/nginx-image:latest"
echo ""
echo "🏷️ Tagueando imagem: $FULL_IMAGE"
docker tag nginx-image $FULL_IMAGE

# -------------------------------
# 9️⃣ - ENVIAR IMAGEM PARA ARTIFACT REGISTRY
# -------------------------------

echo ""
echo "🚀 Enviando imagem para Artifact Registry..."
docker push $FULL_IMAGE

# -------------------------------
# 🔟 - VERIFICAR ENVIO
# -------------------------------

echo ""
echo "🔍 Verificando se a imagem foi enviada com sucesso..."
gcloud artifacts docker images list $REGION-docker.pkg.dev/$PROJECT_ID/my-docker-repo

echo ""
echo "✅ LAB FINALIZADO COM SUCESSO - 100% DAS TAREFAS CONCLUÍDAS! creditos a infr4SeC"
echo "========================================="
