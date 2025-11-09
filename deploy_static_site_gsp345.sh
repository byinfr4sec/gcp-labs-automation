#!/bin/bash
set -e

echo "========================================="
echo " 🚀 Deploy a Static Site with Nginx on Cloud Run (GSP345)"
echo "========================================="
echo ""

# -------------------------------
# 1️⃣ - INPUTS DO USUÁRIO
# -------------------------------

read -p "👉 Digite o ID do Projeto (PROJECT_ID): " PROJECT_ID
read -p "👉 Digite a Região (ex: us-central1, us-east1, europe-west1): " REGION

echo ""
echo "🔧 Configurando ambiente..."
gcloud config set project $PROJECT_ID
gcloud config set run/region $REGION

# -------------------------------
# 2️⃣ - HABILITAR APIs NECESSÁRIAS
# -------------------------------

echo ""
echo "🔌 Habilitando APIs (Cloud Run + Artifact Registry)..."
gcloud services enable run.googleapis.com artifactregistry.googleapis.com

# -------------------------------
# 3️⃣ - CRIAR SITE ESTÁTICO (HTML)
# -------------------------------

echo ""
echo "🌐 Criando arquivo index.html..."
cat > index.html <<EOL
<!DOCTYPE html>
<html>
<head>
    <title>My Static Website</title>
</head>
<body>
    <div>Welcome to My Static Website!</div>
    <p>This website is served from Google Cloud Run using Nginx and Artifact Registry.</p>
</body>
</html>
EOL

echo "✅ index.html criado com sucesso!"

# -------------------------------
# 4️⃣ - CRIAR CONFIGURAÇÃO DO NGINX
# -------------------------------

echo ""
echo "⚙️ Criando arquivo nginx.conf..."
cat > nginx.conf <<EOL
events {}
http {
    server {
        listen 8080;
        root /usr/share/nginx/html;
        index index.html index.htm;

        location / {
            try_files \$uri \$uri/ =404;
        }
    }
}
EOL

echo "✅ nginx.conf criado com sucesso!"

# -------------------------------
# 5️⃣ - CRIAR DOCKERFILE
# -------------------------------

echo ""
echo "📦 Criando Dockerfile..."
cat > Dockerfile <<EOL
FROM nginx:latest

COPY index.html /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
EOL

echo "✅ Dockerfile criado com sucesso!"

# -------------------------------
# 6️⃣ - CRIAR REPOSITÓRIO NO ARTIFACT REGISTRY
# -------------------------------

echo ""
echo "🗄️ Criando repositório Artifact Registry (nginx-static-site)..."
gcloud artifacts repositories create nginx-static-site \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository for static website" || echo "ℹ️ Repositório já existe, continuando..."

# -------------------------------
# 7️⃣ - AUTENTICAÇÃO DOCKER + GCP
# -------------------------------

echo ""
echo "🔑 Configurando autenticação do Docker..."
gcloud auth configure-docker $REGION-docker.pkg.dev -q

# -------------------------------
# 8️⃣ - BUILDAR IMAGEM DOCKER
# -------------------------------

echo ""
echo "🛠️ Buildando imagem Docker (nginx-static-site)..."
docker build -t nginx-static-site .

# -------------------------------
# 9️⃣ - TAGUEAR IMAGEM
# -------------------------------

FULL_IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/nginx-static-site/nginx-static-site"

echo ""
echo "🏷️ Tagueando imagem: $FULL_IMAGE"
docker tag nginx-static-site $FULL_IMAGE

# -------------------------------
# 🔟 - ENVIAR IMAGEM PARA ARTIFACT REGISTRY
# -------------------------------

echo ""
echo "🚀 Enviando imagem para Artifact Registry..."
docker push $FULL_IMAGE

# -------------------------------
# 1️⃣1️⃣ - DEPLOY NO CLOUD RUN
# -------------------------------

echo ""
echo "☁️ Fazendo deploy no Cloud Run..."
gcloud run deploy nginx-static-site \
  --image $FULL_IMAGE \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated

# -------------------------------
# 1️⃣2️⃣ - MOSTRAR URL FINAL
# -------------------------------

echo ""
echo "🌍 Site publicado com sucesso!"
SERVICE_URL=$(gcloud run services describe nginx-static-site --platform managed --region $REGION --format='value(status.url)')
echo "🔗 Acesse sua aplicação em: $SERVICE_URL"
echo ""
echo "✅ LAB FINALIZADO COM SUCESSO - 100% DAS TAREFAS CONCLUÍDAS!"
echo "========================================="
