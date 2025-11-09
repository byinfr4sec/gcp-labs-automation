#!/bin/bash
set -e

echo "==============================================="
echo " 🐍 Create a Python Artifact Registry and Upload Code"
echo "==============================================="
echo ""

# -------------------------------
# 1️⃣ - VERIFICAR AUTENTICAÇÃO
# -------------------------------
echo "🔑 Verificando autenticação atual..."
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
# 4️⃣ - CRIAR REPOSITÓRIO PYTHON
# -------------------------------
echo ""
echo "🗄️ Criando repositório Python 'my-python-repo'..."
gcloud artifacts repositories create my-python-repo \
  --repository-format=python \
  --location=$REGION \
  --description="Python package repository" || echo "ℹ️ Repositório já existe, continuando..."

echo ""
echo "🔍 Verificando repositório criado..."
gcloud artifacts repositories describe my-python-repo --location=$REGION

# -------------------------------
# 5️⃣ - CONFIGURAR PIP E AUTENTICAÇÃO
# -------------------------------
echo ""
echo "⚙️ Instalando dependências necessárias..."
pip install --quiet --user keyrings.google-artifactregistry-auth twine setuptools wheel

echo ""
echo "🔑 Configurando pip para usar o Artifact Registry..."
pip config set global.extra-index-url https://"$REGION"-python.pkg.dev/"$PROJECT_ID"/my-python-repo/simple

# -------------------------------
# 6️⃣ - CRIAR PACOTE PYTHON DE EXEMPLO
# -------------------------------
echo ""
echo "📦 Criando pacote Python de exemplo..."
mkdir -p my-package/my_package
cd my-package

cat > setup.py <<EOF
from setuptools import setup, find_packages

setup(
    name='my_package',
    version='0.1.0',
    author='Qwiklabs User',
    author_email='student@qwiklabs.net',
    packages=find_packages(exclude=['tests']),
    install_requires=[],
    description='A sample Python package for Artifact Registry lab',
)
EOF

echo "" > my_package/__init__.py

cat > my_package/my_module.py <<EOF
def hello_world():
    return 'Hello, world!'
EOF

echo "✅ Pacote criado com sucesso!"

# -------------------------------
# 7️⃣ - BUILD E UPLOAD DO PACOTE
# -------------------------------
echo ""
echo "⚙️ Construindo o pacote..."
python3 setup.py sdist bdist_wheel

echo ""
echo "🚀 Enviando pacote para o Artifact Registry..."
python3 -m twine upload --repository-url https://"$REGION"-python.pkg.dev/"$PROJECT_ID"/my-python-repo/ dist/*

# -------------------------------
# 8️⃣ - VERIFICAR ENVIO
# -------------------------------
echo ""
echo "🔍 Verificando pacotes publicados..."
gcloud artifacts packages list --repository=my-python-repo --location=$REGION

echo ""
echo "✅ LAB CONCLUÍDO COM SUCESSO!"
echo "==============================================="
