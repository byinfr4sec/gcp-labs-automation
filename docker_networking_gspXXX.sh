#!/bin/bash
set -e

echo "==============================================="
echo "🐳 Docker Essentials: Container Networking"
echo "==============================================="

echo ""
echo "🧹 Limpando containers e redes antigas (se existirem)..."
for c in container1 container2 container3 container4 nginx_public; do
  if [ "$(docker ps -aq -f name=$c)" ]; then
    echo "   ➤ Removendo container existente: $c"
    docker rm -f $c >/dev/null 2>&1 || true
  fi
done
if [ "$(docker network ls -q -f name=my-net)" ]; then
  echo "   ➤ Removendo rede antiga: my-net"
  docker network rm my-net >/dev/null 2>&1 || true
fi
echo "✅ Ambiente limpo e pronto para iniciar!"
echo ""

echo "🔑 Verificando autenticação atual..."
gcloud auth list

read -p "👉 Digite o ID do Projeto (PROJECT_ID): " PROJECT_ID
read -p "👉 Digite a Região (ex: us-central1, us-east1, europe-west1): " REGION

echo ""
echo "⚙️ Configurando o projeto e região..."
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION

echo ""
echo "🔌 Habilitando Artifact Registry API..."
gcloud services enable artifactregistry.googleapis.com --quiet

echo ""
echo "🗄️ Criando repositório Docker 'lab-registry'..."
if ! gcloud artifacts repositories create lab-registry \
  --repository-format=docker \
  --location=$REGION \
  --description="Lab Docker Registry" >/dev/null 2>&1; then
  echo "ℹ️ Repositório já existe, continuando..."
fi

echo ""
echo "🔑 Configurando autenticação do Docker com Artifact Registry..."
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

echo ""
echo "📦 Baixando imagens e enviando para o Artifact Registry..."
docker pull alpine/curl:latest
docker tag alpine/curl:latest $REGION-docker.pkg.dev/$PROJECT_ID/lab-registry/alpine-curl:latest
docker push $REGION-docker.pkg.dev/$PROJECT_ID/lab-registry/alpine-curl:latest >/dev/null

docker pull nginx:latest
docker tag nginx:latest $REGION-docker.pkg.dev/$PROJECT_ID/lab-registry/nginx:latest
docker push $REGION-docker.pkg.dev/$PROJECT_ID/lab-registry/nginx:latest >/dev/null
echo "✅ Imagens enviadas com sucesso!"
echo ""

echo "🌉 Testando rede padrão (bridge)..."
docker run -d --name container1 alpine/curl sleep 300
docker run -d --name container2 alpine/curl sleep 300
echo "🔍 Containers ativos:"
docker ps --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "🚫 Tentando pingar container2 de container1 (DNS não disponível na bridge padrão)..."
docker exec container1 ping -c 2 container2 || echo "❌ Nome não resolvido — comportamento esperado."

echo ""
echo "🧹 Substituindo container2 por servidor nginx..."
docker rm -f container2 >/dev/null 2>&1 || true

# Detecta automaticamente porta livre
PORT=8080
while lsof -i :$PORT >/dev/null 2>&1; do
  PORT=$((PORT+1))
done
echo "🌍 Publicando nginx na porta disponível: $PORT"
docker run -d --name container2 -p $PORT:80 nginx

echo ""
echo "🌐 Criando rede personalizada 'my-net'..."
docker network create my-net

echo ""
echo "🚀 Iniciando containers na rede my-net..."
docker run -d --name container3 --network my-net alpine/curl sleep 300
docker run -d --name container4 --network my-net alpine/curl sleep 300

echo ""
echo "📡 Testando comunicação container3 -> container4..."
docker exec container3 ping -c 2 container4

echo ""
echo "🧩 Reiniciando container4 como servidor nginx (porta 8081)..."
docker rm -f container4 >/dev/null 2>&1 || true
docker run -d --name container4 --network my-net -p 8081:80 nginx

echo ""
echo "🔗 Testando acesso HTTP entre containers na rede personalizada..."
docker exec container3 curl -s container4 | grep '<title>' && echo "✅ Comunicação interna OK"

echo ""
echo "🌍 Publicando nginx externo na porta $PORT..."
docker rm -f nginx_public >/dev/null 2>&1 || true
docker run -d --name nginx_public -p $PORT:80 nginx >/dev/null 2>&1 && \
echo "✅ Nginx publicado externamente na porta $PORT"

echo ""
echo "🎉 Lab concluído com sucesso — sem erros! by inf4SeC"
