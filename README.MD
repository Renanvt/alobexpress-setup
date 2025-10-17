<!--
 alobexpress-setup (c) by Jonatan Renan
 
 alobexpress-setup is licensed under a
 Creative Commons Attribution 4.0 International License.
 
 You should have received a copy of the license along with this
 work. If not, see <https://creativecommons.org/licenses/by/4.0/>.
-->

<p align="center">
  <a href="" rel="noopener">
 <img width=200px height=200px src="https://i.imgur.com/FxL5qM0.jpg" alt="Bot logo"></a>
</p>

<h2 align="center">ALOB EXPRESS SETUP</h2>
<h3 align="center">N8N + Evolution API + Supabase + Portainer + Traefik + S3</h3>

<div align="center">

[![Status](https://img.shields.io/badge/status-active-success.svg)]()
[![Platform](https://img.shields.io/badge/platform-reddit-orange.svg)](https://www.reddit.com/user/Wordbook_Bot)
[![GitHub Issues](https://img.shields.io/github/issues/renanvt/The-Documentation-Compendium.svg)](https://github.com/renanvt/The-Documentation-Compendium/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/renanvt/The-Documentation-Compendium.svg)](https://github.com/renanvt/The-Documentation-Compendium/pulls)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)

</div>

---

<p align="center"> 🤖 Few lines describing what your bot does.
    <br> 
</p>


# Tópicos

[Como Usar o Script](#-como-usar-o-script)

[Porque Free Tier?](#porque-free-tier)

[Projeção de custos reais](#-projeção-de-custos-real)

[Criar Bucket S3 para AlobExpress](#criar-bucket-s3-para-alobexpress)

[Criar a instância EC2](#criar-a-instância-ec2)

[Otimizações para Maximizar o tempo](#-otimizações-para-maximizar-o-tempo)


[Testes](#-teste-completo-de-uploaddownload)

[Atualizar o .env do Projeto](#-atualizar-o-env-do-projeto)

[Verificar se Evolution API Está Usando S3](#-verificar-se-evolution-api-está-usando-s3)

[Configurar CORS (para Evolution API)](#️-configurar-cors-para-evolution-api)

[Problemas Comuns](#-problemas-comuns)

[Viabilidade para N8N em Produção](#-viabilidade-para-n8n-em-produção)



🔍 Principais Diferenças da Versão Anterior

![Diferença Versões](/img/5.PNG)

# 📝 Como Usar o Script 

## 1. Fazer upload do script para a EC2

```bash
scp setup_alobexpress_v2.sh ubuntu@seu-ip-ec2:/home/ubuntu/
```
## 2. Conectar na EC21

```bash
ssh ubuntu@seu-ip-ec2
```

## 3. Dar permissão de execução

```bash
chmod +x setup_alobexpress_v2.sh
```
## 4. Executar como root

```bash
sudo ./setup_alobexpress_v2.sh
```

---

## 🎨 Exemplo de Saída Visual

```bash
╔═══════════════════════════════════════════════════════════════╗
║  🚀 ALOBEXPRESS INFRASTRUCTURE SETUP v2.0.1                   ║
╠═══════════════════════════════════════════════════════════════╣
║  Configuração automatizada para EC2 + Docker + Traefik        ║
║  Servidor: EC2 t3.small Ubuntu 22.04                          ║
╚═══════════════════════════════════════════════════════════════╝

▶ VALIDANDO CREDENCIAIS AWS
  ✓ Credenciais AWS válidas
  ✓ Acesso ao bucket S3 confirmado

▶ CRIANDO ESTRUTURA DE PASTAS NO S3
  ✓ Pasta criada: evolution/
  ✓ Pasta criada: backups/n8n/

Nome: alobexpress-production
```


**Tags recomendadas:**
- `Name`: alobexpress-production
- `Environment`: production
- `Project`: alobexpress
- `ManagedBy`: terraform (opcional)

---


# Porque Free Tier?

## 🎁 Free Tier - Primeiro Ano (12 meses)
Conforme a imagem, você tem direito a:
✅ 750 horas/mês de t3.small (equivale a 1 instância 24/7)
✅ 30GB EBS gp2/gp3
✅ 5GB S3 Standard
✅ 100GB Data Transfer OUT

Custos REAIS no Free Tier (primeiros 12 meses):
![Custos Reais no Free Tier](/img/2.PNG)


## 💰 Análise Detalhada de Custos (N. Virginia - us-east-1)

📊 Breakdown de Custos Mensais
![Breakdown de Custos Mensais](/img/1.PNG)

**Por que t3.small?**
- ✅ 2 GB RAM (mínimo para Evolution + N8N + Postgres + Redis)
- ✅ 2 vCPUs (melhor performance)
- ✅ Créditos de CPU balanceados
- ⚠️ **t2.micro** (Free Tier) **NÃO é recomendado** - RAM insuficiente


## ⏰ Quanto Tempo Durará Seu Crédito? Exemplo: $119.20

Cenário 1: Primeiros 12 Meses (Free Tier Ativo)


Custo mensal: $1.54
Duração: $119.20 ÷ $1.54 = 77 meses (6+ anos!)

```bash
✅ **Seu crédito durará TODO o Free Tier e sobrará ~$100!**
```

## **Cenário 2: Após Free Tier (mês 13+)**
```bash
Custo mensal: $19.23
Crédito restante: ~$100
Duração extra: $100 ÷ $19.23 = 5.2 meses
---

✅ Total: 12 meses (Free) + 5 meses (pago) = ~17 meses!
```

# 📈 Projeção de Custos Real

![Projeção de Custo Real](/img/3.PNG)

### 🛡️ Plano B: Se Estourar o Orçamento

#### Opção 1: Migrar para Spot Instance

```bash
# t3.small spot = $0.0062/h (~$4.50/mês)
# Economia: 70%
```

#### Opção 2: Downgrade para t3.micro

```bash
# 1 vCPU, 1GB RAM = $7.59/mês
# Economia: 50%
# ⚠️ Só para testes, não produção
```

# Criar Bucket S3 para AlobExpress

Para que o script funcione de maneira correta, você precisa criar um Bucket no S3 da sua AWS

## 📋 Passo 1: Criar o Bucket

Pelo Console AWS:

Acesse: https://s3.console.aws.amazon.com/s3/
Clique em "Create bucket"
Preencha conforme abaixo:

### ⚙️ Configurações Recomendadas

![Buckecket](/img/0.PNG)

## 🔹 Passo 2: Object Ownership

```bash
✅ ACLs disabled (recommended)
```
- Você será o único dono dos objetos
- Evolution API gravará com suas credenciais IAM

---

### **🔹 Block Public Access**

```bash
✅ Block all public access
  ✅ Block public access to buckets and objects granted through new ACLs
  ✅ Block public access to buckets and objects granted through any ACLs
  ✅ Block public access to buckets and objects granted through new public bucket or access point policies
  ✅ Block public and cross-account access to buckets and objects through any public bucket or access point policies
```

⚠️ **IMPORTANTE:** Manter tudo bloqueado! Evolution API acessa via credenciais, não precisa ser público.

---

### **🔹 Bucket Versioning**

```bash
⚪ Disable (para economizar)
```

**Por quê?**
- Versioning duplica custos (cada versão conta como arquivo)
- Para backups, usaremos datas nos nomes
- Se quiser recuperação de arquivos deletados: ative só depois

---

### **🔹 Default Encryption**

```bash
✅ Server-side encryption with Amazon S3 managed keys (SSE-S3)
  ⚪ Bucket Key: Enabled
```

**Benefícios:**
- Criptografia automática (grátis)
- Reduz custos de requisições KMS em 99%

---

### **🔹 Advanced Settings**

```bash
⚪ Object Lock: Disabled
```



# Criar a instância EC2

## 🐧 **PASSO 3: Escolher Sistema Operacional**

### ⚠️ **CRÍTICO: Escolha EXATAMENTE esta imagem**

**Application and OS Images (Amazon Machine Image)**
```bash
🔍 Buscar: Ubuntu Server 22.04 LTS
```

Selecione:

```bash
┌─────────────────────────────────────────┐
│ Ubuntu Server 22.04 LTS (HVM)          │
│ SSD Volume Type                         │
│ Architecture: 64-bit (x86)              │
│ ✅ Free tier eligible                   │
└─────────────────────────────────────────┘
```

**Especificações:**
- **Nome**: Ubuntu Server 22.04 LTS
- **Arquitetura**: 64-bit (x86) - **NÃO escolha ARM**
- **Root device type**: EBS
- **Virtualization**: HVM

---

## 💻 **PASSO 4: Tipo de Instância**

### Escolha: **t3.small**

```bash
┌──────────────────────────────────────────────────────┐
│ Instance Type: t3.small                              │
│                                                      │
│ vCPUs: 2                                            │
│ Memory: 2 GiB                                       │
│ Network Performance: Up to 5 Gigabit                │
│                                                      │
│ ⚠️ NÃO é Free Tier                                  │
│ Custo aproximado: ~$15-20/mês                       │
└──────────────────────────────────────────────────────┘
```


## 🔑 **PASSO 5: Key Pair (Par de Chaves)**

### Opção A: Criar Nova Chave

```bash
1. Clique em "Create new key pair"
2. Nome: alobexpress-key
3. Key pair type: RSA
4. Private key format: .pem (para Linux/Mac) ou .ppk (para Windows/PuTTY)
5. Clique em "Create key pair"
6. ⚠️ SALVE O ARQUIVO .pem EM LOCAL SEGURO
```

### Opção B: Usar Chave Existente

```bash
Selecione uma chave SSH que você já possui
```

**⚠️ IMPORTANTE:** Guarde o arquivo `.pem` com segurança! Você precisará dele para conectar via SSH.

---

## 🔒 **PASSO 6: Network Settings (CRÍTICO)**

### 6.1 **Criar Security Group**

```bash
┌─────────────────────────────────────────────────────┐
│ ✅ Create security group                            │
│                                                     │
│ Security group name: alobexpress-sg                │
│ Description: Security group for AlobExpress        │
└─────────────────────────────────────────────────────┘
```

### 6.2 **Configurar Regras de Firewall**

#### **Regra 1: SSH (22)** - Para você acessar

```bash
Type: SSH
Protocol: TCP
Port: 22
Source: My IP (seu IP atual) ✅ RECOMENDADO
   OU
Source: 0.0.0.0/0 (qualquer IP) ⚠️ MENOS SEGURO
```

#### **Regra 2: HTTP (80)** - Redirecionamento HTTPS

```bash
Type: HTTP
Protocol: TCP
Port: 80
Source: 0.0.0.0/0 (Anywhere IPv4) ✅ OBRIGATÓRIO
```

#### **Regra 3: HTTPS (443)** - Acesso aos serviços

```bash
Type: HTTPS
Protocol: TCP
Port: 443
Source: 0.0.0.0/0 (Anywhere IPv4) ✅ OBRIGATÓRIO
```

### 6.3 **Resumo das Regras**

| Tipo | Protocolo | Porta | Origem | Descrição |
|------|-----------|-------|--------|-----------|
| SSH | TCP | 22 | Seu IP | Acesso administrativo |
| HTTP | TCP | 80 | 0.0.0.0/0 | Redirecionamento para HTTPS |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Portainer, N8N, Evolution |

---

## 💾 **PASSO 7: Configurar Armazenamento**

### Configuração Recomendada:

```bash
┌────────────────────────────────────────────────────┐
│ Volume 1 (Root Volume)                            │
│                                                    │
│ Size: 30 GiB (mínimo recomendado)                │
│ Volume Type: gp3 (melhor custo-benefício)        │
│ IOPS: 3000 (padrão)                               │
│ Throughput: 125 MB/s (padrão)                     │
│                                                    │
│ ✅ Delete on Termination: Yes                     │
│ ✅ Encrypted: No (opcional)                       │
└────────────────────────────────────────────────────┘
```

## 🔧 **PASSO 8: Advanced Details (Opcional, mas Recomendado)**

### User Data (Script de Inicialização)

```bash
#!/bin/bash
# Atualizar sistema na primeira inicialização
apt-get update -y
apt-get upgrade -y

# Configurar timezone
timedatectl set-timezone America/Sao_Paulo

# Criar usuário de deploy (opcional)
# useradd -m -s /bin/bash deploy
# usermod -aG sudo deploy
```

---

## 📊 **PASSO 9: Resumo e Lançamento**

### Revise as Configurações:

```bash
✅ Instância: Ubuntu Server 22.04 LTS
✅ Tipo: t3.small (2 vCPU, 2 GB RAM)
✅ Armazenamento: 30 GB gp3
✅ Security Group: Portas 22, 80, 443 abertas
✅ Key Pair: Criado e salvo
```

### Clique em **"Launch Instance"**

---

## 🎯 **PASSO 10: Após Lançamento**

### 10.1 **Aguardar Inicialização**

```bash
Status: Pending → Running (aguarde 2-3 minutos)
Status Checks: 2/2 checks passed
```

### 10.2 **Alocar IP Elástico (OBRIGATÓRIO)**

**Por quê?** O IP público muda a cada reinicialização. IP elástico é fixo e **GRATUITO** enquanto estiver associado.

```bash
1. No menu lateral: Network & Security → Elastic IPs
2. Clique em "Allocate Elastic IP address"
3. Clique em "Allocate"
4. Selecione o IP criado → Actions → Associate Elastic IP address
5. Instance: Selecione sua instância alobexpress-production
6. Clique em "Associate"
```

### 10.3 **Copiar IP Público/Elástico**

```bash
Exemplo: 54.123.45.67
```

---

## 🌐 **PASSO 11: Configurar DNS (ANTES de rodar o script)**

Aponte seus domínios para o **IP Elástico** da EC2:

### No seu provedor de DNS (ex: Registro.br, Cloudflare, Route53):
```bash
Tipo A:
portainer.seudominio.com.br  →  54.123.45.67
n8n.seudominio.com.br        →  54.123.45.67
evolution.seudominio.com.br  →  54.123.45.67
```

## 🌐 **PASSO 12: Adicionar Permissões IAM  (ANTES de rodar o script)**

Vá ao Console AWS e configure:
IAM → Usuários → Seu usuário → Permissões

Adicione esta política (inline policy):

```bash
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::SEU_BUCKET_NAME",
                "arn:aws:s3:::SEU_BUCKET_NAME/*"
            ]
        }
    ]
}
```
> ⚠️ SUBSTITUA SEU_BUCKET_NAME pelo nome real do seu bucket!

# 🔧 Otimizações para Maximizar o Tempo



## 1. Reduzir Custos de S3 ($1.04/mês → $0.30/mês)

Configurar Lifecycle Policy (ECONOMIA!)

1. Acesse o bucket criado
2. Aba Management → Create lifecycle rule

![Lifecycle Policy](/img/4.PNG)

```bash
# Adicionar lifecycle policy no S3
aws s3api put-bucket-lifecycle-configuration \
  --bucket seu-bucket \
  --lifecycle-configuration '{
    "Rules": [{
      "Id": "DeleteOldMedia",
      "Status": "Enabled",
      "Filter": {"Prefix": "evolution/"},
      "Transitions": [{
        "Days": 30,
        "StorageClass": "GLACIER_IR"
      }],
      "Expiration": {"Days": 90}
    }]
  }'
```
> Economia: Arquivos antigos vão para Glacier ($0.004/GB) ou são deletados após 90 dias.

***Transitions:**

After 30 days → Move to Glacier Instant Retrieval ($0.004/GB)
After 90 days → Permanently delete

Economia estimada: $1.04/mês → $0.35/mês (~66% de redução!)


## 2. Otimizar N8N para Poupar RAM

Adicione ao docker-compose.yml:

```bash
n8n:
  environment:
    # Limitar workers
    - EXECUTIONS_PROCESS=main
    - N8N_PAYLOAD_SIZE_MAX=16
    
    # Limpar execuções antigas
    - EXECUTIONS_DATA_PRUNE=true
    - EXECUTIONS_DATA_MAX_AGE=72  # 3 dias (era 7)
    - EXECUTIONS_DATA_SAVE_ON_ERROR=always
    - EXECUTIONS_DATA_SAVE_ON_SUCCESS=none  # Não salvar sucessos
    
  deploy:
    resources:
      limits:
        memory: 800M  # Limite de RAM
```
> Ganho: N8N usará max 800MB, deixando RAM para outros serviços.

## 3. Ativar Compactação no Traefik

```bash
traefik:
  command:
    - "--entrypoints.websecure.http.middlewares=compress@docker"
    - "--experimental.plugins.compress.modulename=github.com/klauspost/compress"
```
> Ganho: Reduz Data Transfer em ~50%.

## 4. Limitar Evolution API

```bash
evolution:
  environment:
    # Desabilitar logs verbosos
    - LOG_LEVEL=ERROR
    - LOG_BAILEYS=false
    
    # Limitar cache Redis
    - CACHE_TTL=3600  # 1 hora
    
    # Não salvar mensagens antigas
    - DATABASE_SAVE_MESSAGE_UPDATE=false
    - DATABASE_SAVE_OLD_MESSAGE=false
```
> Ganho: Menos I/O no banco, menos RAM consumida.

- Use as otimizações acima para evitar surpresas
- Monitore custos semanalmente com AWS Cost Explorer
- Evite processar vídeos no N8N (use Lambda para isso)
- Delete mídias antigas do S3 mensalmente

## 5. Configurar Alertas de Custo

```bash
# Criar alerta no AWS Budgets
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget '{
    "BudgetName": "AlobExpressAlert",
    "BudgetLimit": {"Amount": "10", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[{
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80
    },
    "Subscribers": [{
      "SubscriptionType": "EMAIL",
      "Address": "seu@email.com"
    }]
  }]'
```

# 🧪 Teste Completo de Upload/Download

## 1. Criar arquivo de teste:
   
```bash
echo "AlobExpress funcionando!" > teste.txt
```

## 2. Upload para S3:

```bash
aws s3 cp teste.txt s3://alobexpress-storage-2025/teste.txt
# upload: ./teste.txt to s3://alobexpress-storage-2025/teste.txt
```

## 3. Listar arquivos:

```bash
aws s3 ls s3://alobexpress-storage-2025/
# 2025-01-15 14:23:10         25 teste.txt
```

## 4. Download do S3:
   
```bash
aws s3 cp s3://alobexpress-storage-2025/teste.txt baixado.txt
# download: s3://alobexpress-storage-2025/teste.txt to ./baixado.txt
```

## 1. Verificar conteúdo:

```bash
cat baixado.txt
# AlobExpress funcionando!
```

## 6. Deletar arquivo de teste:
   
```bash
aws s3 rm s3://alobexpress-storage-2025/teste.txt
# delete: s3://alobexpress-storage-2025/teste.txt
```

# 🔄 Atualizar o .env do Projeto

Se JÁ rodou o script:

```bash
cd /home/ubuntu/alobexpress
nano .env
```

Procure as linhas do S3 e atualize:

```bash
# === AWS S3 (Backups) ===
AWS_ACCESS_KEY_ID=AKIA...                    # Sua Access Key
AWS_SECRET_ACCESS_KEY=wJalr...               # Seu Secret
S3_REGION=us-east-1
S3_BUCKET_NAME=alobexpress-storage-2025      # Nome do SEU bucket
```

## Reiniciar os serviços:

```bash
docker compose down
docker compose up -d
```


# 🎯 Verificar se Evolution API Está Usando S3

```bash
docker compose logs -f evolution
```

Deve aparecer algo como:

```bash
[S3] Connected successfully to bucket: alobexpress-storage-2025
[S3] Region: us-east-1
```

## 2. Criar instância WhatsApp de teste:

Acesse: https://evolution.seudominio.com.br/manager
Crie uma instância e envie uma imagem via WhatsApp.

## 3. Verificar se foi para o S3:

```bash
aws s3 ls s3://alobexpress-storage-2025/evolution/ --recursive

# Deve aparecer algo como:
# 2025-01-15 15:10:23   145678 evolution/instance-teste/media/IMG-20250115-WA0001.jpg
```

> Se aparecer arquivos = S3 funcionando perfeitamente!

# 🛡️ Configurar CORS (para Evolution API)

Via Console:

1. Aba **Permissions → CORS**
2. Clique **Edit**
3. Cole a configuração:

```bash
[
  {
    "AllowedHeaders": [
      "*"
    ],
    "AllowedMethods": [
      "GET",
      "PUT",
      "POST",
      "DELETE",
      "HEAD"
    ],
    "AllowedOrigins": [
      "https://evolution.seudominio.com.br",
      "https://n8n.seudominio.com.br"
    ],
    "ExposeHeaders": [
      "ETag",
      "x-amz-request-id"
    ],
    "MaxAgeSeconds": 3600
  }
]
```
>  Substitua evolution.seudominio.com.br pelos seus domínios reais!

# 🚀 Viabilidade para N8N em Produção

## você consegue operar em produção! Mas com ressalvas:


### Cenário Otimista (uso moderado):

50-100 workflows ativos
5.000-10.000 execuções/dia
Webhooks leves (WhatsApp, HTTP)
Automações de resposta rápida

Duração: ✅ Facilmente 17+ meses

### Cenário Realista (uso intenso):

200+ workflows
20.000+ execuções/dia
Processamento de imagens/vídeos
Integrações pesadas (Google Sheets, Airtable)
Múltiplas instâncias WhatsApp no Evolution

### Problemas esperados:

RAM insuficiente (2GB é apertado)
CPU Credits esgotados (t3.small fica lento)
S3 crescendo (mídias WhatsApp)
Swap constante (degrada performance)

Duração: ⚠️ 12-15 meses (com otimizações)


### **Opção 3: Usar Oracle Cloud Free Tier**

```bash
4 vCPUs ARM, 24GB RAM, 200GB storage = GRÁTIS SEMPRE
```



# 🚨 Problemas Comuns

## Erro: "Unable to locate credentials"

```bash
# Reconfigurar
aws configure
```

```bash
# Verificar se salvou
cat ~/.aws/credentials
```

## Erro: "Access Denied"

```bash
# Verificar permissões do usuário IAM
aws iam get-user-policy --user-name alobexpress-s3-user --policy-name AlobExpressS3Policy
```

Se não aparecer nada, volte no console AWS e vincule a policy novamente.

## Erro: "Bucket does not exist"


```bash
# Listar buckets disponíveis
aws s3 ls

# Se não aparecer, verifique se criou na região correta:
aws s3api get-bucket-location --bucket alobexpress-storage-2025
```

---

## 📝 **Resumo do Fluxo**
```
1. ✅ Conectar na EC2 (SSH)
2. ✅ Instalar AWS CLI (apt install awscli)
3. ✅ Configurar credenciais (aws configure)
4. ✅ Criar estrutura de pastas (aws s3api put-object)
5. ✅ Testar upload/download
6. ✅ Atualizar .env com credenciais S3
7. ✅ Rodar/reiniciar docker compose
8. ✅ Verificar logs da Evolution API


