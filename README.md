## 🧾 README.md

```markdown
# ☁️ Google Cloud Arcade — Automação dos Labs (Level 3: Scalable Deployments & Delivery)

### por [Rapha “infr4SeC” Pereira](https://github.com/byinfr4sec)

---

## 🧭 Sobre o Projeto

Este repositório reúne **scripts automatizados e otimizados** para os laboratórios do **Google Cloud Arcade - Level 3: Scalable Deployments and Delivery**.  
O objetivo é **acelerar a execução**, **minimizar erros** e **tornar o aprendizado mais fluido e prático**, ajudando quem está iniciando no mundo **Cloud, DevOps e Infra as Code**.

Todos os labs foram realizados, validados e otimizados dentro do **Cloud Shell**, com **100% de compatibilidade** com os ambientes do **Qwiklabs** e **Google Cloud Skills Boost**.

---

## 🧱 Labs Automatizados

| 🧩 Lab | ⏱️ Tempo Médio (Manual) | ⚡ Tempo com Script | 🚀 Status |
|--------|-------------------------|--------------------|-----------|
| Deploy a Static Site with Nginx on Cloud Run using Artifact Registry | 30 min | ~6 min | ✅ Concluído |
| Deploy a Static Site Using Traefik and Cloud Run | 30 min | ~5 min | ✅ Concluído |
| Create a Container Artifact Registry and Upload Code | 30 min | ~4 min | ✅ Concluído |
| Create a Go Artifact Registry and Upload Code | 30 min | ~6 min | ✅ Concluído |
| Create an NPM Artifact Registry and Upload Code | 30 min | ~3 min | ✅ Concluído |
| Create a Python Artifact Registry and Upload Code | 30 min | ~2 min | ✅ Concluído |
| Docker Essentials: Container Networking | 30 min | ~8 min | ✅ Concluído |
| Terraform Essentials: Cloud Firestore Database | 30 min | ~3 min | ✅ Concluído |

Total de labs otimizados: **8/8** 🎯  
Tempo total reduzido de **4 horas para menos de 40 minutos**, com **execuções reproduzíveis e à prova de erros**.

---

## 🧠 Habilidades e Tecnologias Aplicadas

| Categoria | Tecnologias / Conceitos |
|------------|-------------------------|
| ☁️ Cloud Platform | Google Cloud Platform (GCP), Cloud Shell, Cloud Run, Artifact Registry, Firestore |
| 🧱 Infra as Code | Terraform, Remote Backend (GCS), State Management |
| 🐳 Containers | Docker, Traefik, Nginx, Container Networking |
| 🔄 CI/CD | Cloud Build, Continuous Deployment com Cloud Run |
| 🧰 Automação | Shell Script, controle de erros (`set -e`), validação de entradas, variáveis dinâmicas |
| 🔐 DevOps | IaC, versionamento, automação de deploys, pipelines reprodutíveis |
| 💡 Didática | Scripts comentados, feedback interativo no terminal, uso educativo voltado a iniciantes |

---

## ⚙️ Estrutura do Repositório

```

gcp-labs-automation/
├── nginx_cloudrun_lab.sh
├── traefik_cloudrun_lab.sh
├── container_registry_lab.sh
├── go_registry_lab.sh
├── npm_registry_lab.sh
├── python_registry_lab.sh
├── docker_networking_lab.sh
├── terraform_firestore_lab.sh
└── README.md

```

Cada script é independente e projetado para rodar diretamente no **Cloud Shell**.  
Basta informar o **PROJECT_ID** e a **REGION**, o restante é totalmente automatizado.

---

## 🧩 Funcionamento dos Scripts

Cada script segue o mesmo fluxo base:

1. **Configuração do ambiente**
   - Define o projeto ativo (`gcloud config set project`)
   - Configura região padrão
   - Ativa as APIs necessárias

2. **Provisionamento**
   - Cria registries, containers, bancos de dados ou serviços conforme o lab
   - Gera recursos com nomes dinâmicos e evita conflitos

3. **Validação**
   - Realiza testes automáticos (curl, docker inspect, etc.)
   - Exibe resultados coloridos e mensagens explicativas

4. **Limpeza**
   - Remove containers, redes, buckets ou instâncias temporárias
   - Mantém o ambiente pronto para o próximo lab

---

## 💬 Considerações Pessoais

> “Meu objetivo com esse projeto é **ajudar quem está entrando na área de Cloud e DevOps** a vencer a parte mais chata dos labs — a repetição e os erros de digitação — e focar no que realmente importa: **entender o conceito por trás das ferramentas**.”  
>
> “Esses scripts não substituem o aprendizado, mas **potencializam ele**, tornando o processo mais direto e didático.”  
>
> — **Rapha "infr4SeC" Pereira**

---

## 🤝 Contribuições

Quer colaborar?  
Sinta-se à vontade para enviar melhorias, novos labs ou ajustes!

1. Faça um **fork** do repositório  
2. Crie uma branch (`feature/novo-lab`)  
3. Envie um **Pull Request**

---

## 🧩 Próximos Passos

- 🔹 Automatização dos labs de **Cloud SQL, GKE e Cloud Functions**
- 🔹 Pipeline de deploy Terraform + Cloud Build
- 🔹 Interface web para execução de scripts no Cloud Shell (em andamento)

---

## 👨🏻‍💻 Autor

**Rapha “infr4SeC” Pereira**  
Cloud | DevOps | Infra as Code | Segurança  
📍 Brasil  
[GitHub](https://github.com/byinfr4sec) • [LinkedIn](https://www.linkedin.com/in/byrafanet/)

> “Automatizar é bom. Compartilhar conhecimento é melhor.” 💡