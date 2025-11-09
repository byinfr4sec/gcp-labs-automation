#!/bin/bash
set -e

echo "==============================================="
echo "🐳 Docker Essentials: Container Networking"
echo "==============================================="

echo ""
echo "🧹 Limpando containers e redes antigas (se existirem)..."
for c in container1 container2 container3 container4; do
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
echo "📦 Baixando imagens do Docker Hub e enviando para o Artifact Registry..."
docker pull alpine/curl:latest
docker tag alpine/curl:latest $REGION-docker.pkg.dev/$PROJECT_ID/lab-registry/alpine-curl:latest
docker push $REGION-docker.pkg.dev/$PROJECT_ID/lab-registry/alpine-curl:latest

docker pull nginx:latest
docker tag nginx:latest $REGION-docker.pkg.dev/$PROJECT_ID/lab-registry/nginx:latest
docker push $REGION-docker.pkg.dev/$PROJECT_ID/lab-registry/nginx:latest
echo ""
echo "✅ Imagens enviadas com sucesso para o Artifact Registry!"
echo ""

echo "🌉 Testando rede padrão (bridge)..."
docker run -d --name container1 alpine/curl sleep 300
docker run -d --name container2 alpine/curl sleep 300
docker inspect bridge | grep '"Name"'
echo ""
echo "🚫 Tentando pingar container2 de container1 (DNS não disponível na bridge padrão)..."
docker exec container1 ping -c 2 container2 || echo "❌ Nome não resolvido — comportamento esperado."
echo ""

echo "🧹 Substituindo container2 por servidor nginx na porta 8080..."
docker rm -f container2 >/dev/null 2>&1 || true
docker run -d --name container2 -p 8080:80 nginx || echo "⚠️ Porta 8080 em uso, tentando 8082..."
if ! docker ps | grep -q "0.0.0.0:8080"; then
  docker run -d --name container2 -p 8082:80 nginx
fi

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
docker exec container3 curl -s container4 | grep '<title>'

echo ""
echo "🌍 Publicando nginx..."
if ! docker run -d --name nginx_public -p 8080:80 nginx; then
  echo "⚠️ Porta 8080 em uso, tentando 8082..."
  docker run -d --name nginx_public -p 8082:80 nginx
fi

echo ""
echo "✅ Lab concluído com sucesso!"
echo "🎉 Todos os testes foram executados corretamente! by infr4SeC"
