#!/bin/bash
set -e

echo "========================================="
echo " 🚀 Deploy a Static Site Using Traefik and Cloud Run"
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
echo "⚙️ Configurando projeto e região..."
gcloud config set project $PROJECT_ID
gcloud config set run/region $REGION

# -------------------------------
# 3️⃣ - HABILITAR SERVIÇOS NECESSÁRIOS
# -------------------------------

echo ""
echo "🔌 Habilitando APIs (Cloud Run + Artifact Registry + Cloud Build)..."
gcloud services enable run.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com

# -------------------------------
# 4️⃣ - CRIAR REPOSITÓRIO NO ARTIFACT REGISTRY
# -------------------------------

echo ""
echo "🗄️ Criando repositório Docker 'traefik-repo'..."
gcloud artifacts repositories create traefik-repo \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository for Traefik static site" || echo "ℹ️ Repositório já existe, continuando..."

# -------------------------------
# 5️⃣ - CRIAR ESTRUTURA DO SITE ESTÁTICO
# -------------------------------

echo ""
echo "🌐 Criando estrutura de diretórios..."
mkdir -p traefik-site/public
cd traefik-site

echo ""
echo "📝 Criando arquivo public/index.html..."
cat > public/index.html <<'EOF'
<html>
<head>
  <title>My Static Website</title>
</head>
<body>
  <p>Hello from my static website on Cloud Run using Traefik!</p>
</body>
</html>
EOF

echo "✅ HTML criado com sucesso!"

# -------------------------------
# 6️⃣ - CONFIGURAÇÃO TRAEFIK
# -------------------------------

echo ""
echo "⚙️ Criando arquivo traefik.yml..."
cat > traefik.yml <<'EOF'
entryPoints:
  web:
    address: ":8080"

providers:
  file:
    filename: /etc/traefik/dynamic.yml
    watch: true

log:
  level: INFO
EOF

echo "✅ traefik.yml criado!"

echo ""
echo "⚙️ Criando arquivo dynamic.yml..."
cat > dynamic.yml <<'EOF'
http:
  routers:
    static-files:
      rule: "PathPrefix(`/`)"
      entryPoints:
        - web
      service: static-service

  services:
    static-service:
      loadBalancer:
        servers:
          - url: "http://localhost:8000"
EOF

echo "✅ dynamic.yml criado!"

# -------------------------------
# 7️⃣ - DOCKERFILE
# -------------------------------

echo ""
echo "📦 Criando Dockerfile..."
cat > Dockerfile <<'EOF'
FROM alpine:3.20

# Instala Traefik e Caddy
RUN apk add --no-cache traefik caddy

# Copia configurações e arquivos estáticos
COPY traefik.yml /etc/traefik/traefik.yml
COPY dynamic.yml /etc/traefik/dynamic.yml
COPY public/ /public/

# Cloud Run usa porta 8080
EXPOSE 8080

# Executa Caddy (porta 8000) + Traefik (porta 8080)
ENTRYPOINT ["/bin/sh", "-c", "caddy file-server --listen :8000 --root /public & traefik"]
EOF

echo "✅ Dockerfile criado com sucesso!"

# -------------------------------
# 8️⃣ - AUTENTICAÇÃO DOCKER
# -------------------------------

echo ""
echo "🔑 Configurando autenticação Docker com Artifact Registry..."
gcloud auth configure-docker $REGION-docker.pkg.dev -q

# -------------------------------
# 9️⃣ - BUILDAR E ENVIAR IMAGEM
# -------------------------------

echo ""
echo "🛠️ Buildando imagem Docker..."
docker build -t $REGION-docker.pkg.dev/$PROJECT_ID/traefik-repo/traefik-static-site:latest .

echo ""
echo "🚀 Enviando imagem para Artifact Registry..."
docker push $REGION-docker.pkg.dev/$PROJECT_ID/traefik-repo/traefik-static-site:latest

# -------------------------------
# 🔟 - DEPLOY NO CLOUD RUN
# -------------------------------

echo ""
echo "☁️ Fazendo deploy no Cloud Run..."
gcloud run deploy traefik-static-site \
  --image $REGION-docker.pkg.dev/$PROJECT_ID/traefik-repo/traefik-static-site:latest \
  --platform managed \
  --allow-unauthenticated \
  --port 8000 \
  --region $REGION

# -------------------------------
# 1️⃣1️⃣ - MOSTRAR URL FINAL
# -------------------------------

echo ""
echo "🌍 Aplicação implantada com sucesso!"
SERVICE_URL=$(gcloud run services describe traefik-static-site --platform managed --region $REGION --format='value(status.url)')
echo "🔗 Acesse sua aplicação em: $SERVICE_URL"
echo ""
echo "✅ LAB FINALIZADO COM SUCESSO - 100% DAS TAREFAS CONCLUÍDAS!"
echo "========================================="
