#!/bin/bash
set -e

echo "==============================================="
echo "🐳 Docker Essentials: Container Networking"
echo "==============================================="
echo ""

# 🧹 LIMPEZA PREVENTIVA
echo "🧹 Limpando possíveis containers e redes antigas..."
docker rm -f container1 container2 container3 container4 >/dev/null 2>&1 || true
docker network rm my-net >/dev/null 2>&1 || true
echo "✅ Ambiente limpo e pronto para iniciar!"
echo ""

# -------------------------------
# 1️⃣ - CONFIGURAÇÃO INICIAL
# -------------------------------
echo "🔑 Verificando autenticação atual..."
gcloud auth list
echo ""

read -p "👉 Digite o ID do Projeto (PROJECT_ID): " PROJECT_ID
read -p "👉 Digite a Região (ex: us-central1, us-east1, europe-west1): " REGION

echo ""
echo "⚙️ Configurando o projeto e região..."
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION

# -------------------------------
# 2️⃣ - HABILITAR API E CRIAR REPOSITÓRIO
# -------------------------------
echo ""
echo "🔌 Habilitando Artifact Registry API..."
gcloud services enable artifactregistry.googleapis.com

echo ""
echo "🗄️ Criando repositório Docker 'lab-registry'..."
gcloud artifacts repositories create lab-registry \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository" || echo "ℹ️ Repositório já existe, continuando..."

# -------------------------------
# 3️⃣ - CONFIGURAR DOCKER AUTENTICAÇÃO
# -------------------------------
echo ""
echo "🔑 Configurando autenticação do Docker com Artifact Registry..."
gcloud auth configure-docker "$REGION"-docker.pkg.dev -q

# -------------------------------
# 4️⃣ - PUXAR, TAGUEAR E ENVIAR IMAGENS
# -------------------------------
echo ""
echo "📦 Baixando imagens do Docker Hub e enviando para o Artifact Registry..."

# Alpine Curl
docker pull alpine/curl
docker tag alpine/curl "$REGION"-docker.pkg.dev/"$PROJECT_ID"/lab-registry/alpine-curl:latest
docker push "$REGION"-docker.pkg.dev/"$PROJECT_ID"/lab-registry/alpine-curl:latest

# Nginx
docker pull nginx:latest
docker tag nginx:latest "$REGION"-docker.pkg.dev/"$PROJECT_ID"/lab-registry/nginx:latest
docker push "$REGION"-docker.pkg.dev/"$PROJECT_ID"/lab-registry/nginx:latest

echo ""
echo "✅ Imagens enviadas com sucesso para o Artifact Registry!"

# -------------------------------
# 5️⃣ - EXPLORANDO REDE BRIDGE PADRÃO
# -------------------------------
echo ""
echo "🌉 Testando rede padrão (bridge)..."

docker run -d --name container1 "$REGION"-docker.pkg.dev/"$PROJECT_ID"/lab-registry/alpine-curl:latest sleep infinity
docker run -d --name container2 "$REGION"-docker.pkg.dev/"$PROJECT_ID"/lab-registry/alpine-curl:latest sleep infinity

echo ""
echo "🔍 Inspecionando rede bridge..."
docker network inspect bridge | grep Name || true

echo ""
echo "🚫 Tentando pingar container2 de container1 (DNS não disponível na bridge padrão)..."
docker exec -it container1 ping -c 2 container2 || echo "❌ Nome não resolvido — comportamento esperado."

echo ""
echo "🧹 Substituindo container2 por servidor nginx na porta 8080..."
docker stop container2 && docker rm container2
docker run -d --name container2 -p 8080:80 "$REGION"-docker.pkg.dev/"$PROJECT_ID"/lab-registry/nginx:latest

echo ""
echo "🌐 Tentando acessar container2 (nginx) a partir do container1..."
docker exec -it container1 curl -s container2:8080 || echo "⚠️ Nome não resolvido — esperado na rede padrão."

# -------------------------------
# 6️⃣ - CRIAR E USAR REDE PERSONALIZADA
# -------------------------------
echo ""
echo "🌐 Criando rede personalizada 'my-net'..."
docker network create my-net

echo ""
echo "🚀 Iniciando containers na rede my-net..."
docker run -d --name container3 --network my-net "$REGION"-docker.pkg.dev/"$PROJECT_ID"/lab-registry/alpine-curl:latest sleep infinity
docker run -d --name container4 --network my-net "$REGION"-docker.pkg.dev/"$PROJECT_ID"/lab-registry/alpine-curl:latest sleep infinity

echo ""
echo "🔍 Inspecionando rede my-net..."
docker network inspect my-net | grep Name

echo ""
echo "📡 Testando comunicação container3 -> container4..."
docker exec -it container3 ping -c 2 container4

echo ""
echo "🧩 Reiniciando container4 como servidor nginx (porta 8081)..."
docker stop container4 && docker rm container4
docker run -d --name container4 --network my-net -p 8081:80 "$REGION"-docker.pkg.dev/"$PROJECT_ID"/lab-registry/nginx:latest

echo ""
echo "🔗 Testando acesso HTTP entre containers na rede personalizada..."
docker exec -it container3 curl -s container4:80 | grep "Welcome" && echo "✅ Comunicação interna OK"

# -------------------------------
# 7️⃣ - PUBLICAR PORTAS E ACESSAR DO HOST
# -------------------------------
echo ""
echo "🌍 Publicando nginx na porta 8080..."
docker stop container4 && docker rm container4
docker run -d --name container4 -p 8080:80 "$REGION"-docker.pkg.dev/"$PROJECT_ID"/lab-registry/nginx:latest

echo ""
echo "🌐 Acessando nginx via host (localhost:8080)..."
curl -s localhost:8080 | grep "Welcome" && echo "✅ Nginx acessível externamente!"

echo ""
echo "🔍 Verificando mapeamento de portas..."
docker port container4 80

# -------------------------------
# 8️⃣ - LIMPEZA FINAL
# -------------------------------
echo ""
echo "🧹 Limpando containers e rede..."
docker stop container1 container2 container3 container4 || true
docker rm container1 container2 container3 container4 || true
docker network rm my-net || true

echo ""
echo "✅ LAB CONCLUÍDO COM SUCESSO! by infr4Sec"
echo "==============================================="
