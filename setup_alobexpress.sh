#!/bin/bash
set -e

# ==========================================
#  🚀 ALOBEXPRESS INFRASTRUCTURE SETUP
#  Version: 2.0.1
#  Author: AlobExpress Team
#  Updated: 2025-10-17
# ==========================================

# ===== CORES ANSI =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Ícones
CHECK="${GREEN}✓${RESET}"
CROSS="${RED}✗${RESET}"
ARROW="${CYAN}→${RESET}"
WARN="${YELLOW}⚠${RESET}"
INFO="${BLUE}ℹ${RESET}"
ROCKET="${MAGENTA}🚀${RESET}"

# ===== FUNÇÕES AUXILIARES =====
print_banner() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}  ${BOLD}${MAGENTA}🚀 ALOBEXPRESS INFRASTRUCTURE SETUP v2.0.1${RESET}             ${CYAN}║${RESET}"
    echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}  ${DIM}Configuração automatizada para EC2 + Docker + Traefik${RESET}    ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  ${DIM}Servidor: EC2 t3.small Ubuntu 22.04${RESET}                      ${CYAN}║${RESET}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

print_step() {
    echo -e "\n${BOLD}${BLUE}▶${RESET} ${BOLD}$1${RESET}"
}

print_success() {
    echo -e "  ${CHECK} ${GREEN}$1${RESET}"
}

print_error() {
    echo -e "  ${CROSS} ${RED}$1${RESET}"
}

print_warning() {
    echo -e "  ${WARN} ${YELLOW}$1${RESET}"
}

print_info() {
    echo -e "  ${INFO} ${CYAN}$1${RESET}"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [${CYAN}%c${RESET}] " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# ===== BANNER INICIAL =====
print_banner

# ===== PRÉ-REQUISITOS =====
print_step "VERIFICANDO PRÉ-REQUISITOS"

if [ "$EUID" -ne 0 ]; then 
   print_error "Execute com sudo ou como root"
   exit 1
fi
print_success "Executando como root"

# ===== CONFIRMAÇÃO DO USUÁRIO =====
echo ""
echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${YELLOW}║${RESET}  ${BOLD}${WARN} ATENÇÃO - LEIA ANTES DE CONTINUAR${RESET}                       ${YELLOW}║${RESET}"
echo -e "${YELLOW}╠═══════════════════════════════════════════════════════════════╣${RESET}"
echo -e "${YELLOW}║${RESET}  ${WHITE}Certifique-se de que:${RESET}                                     ${YELLOW}║${RESET}"
echo -e "${YELLOW}║${RESET}  ${ARROW} A instância EC2 está limpa (sem instalações prévias)  ${YELLOW}║${RESET}"
echo -e "${YELLOW}║${RESET}  ${ARROW} Você criou um Bucket S3 na AWS                        ${YELLOW}║${RESET}"
echo -e "${YELLOW}║${RESET}  ${ARROW} Você criou um Usuário IAM com acesso ao S3            ${YELLOW}║${RESET}"
echo -e "${YELLOW}║${RESET}  ${ARROW} Você tem as credenciais AWS (Access Key + Secret)     ${YELLOW}║${RESET}"
echo -e "${YELLOW}║${RESET}  ${ARROW} Os domínios estão apontando para o IP desta EC2       ${YELLOW}║${RESET}"
echo -e "${YELLOW}║${RESET}  ${ARROW} Portas 80 e 443 estão liberadas no Security Group    ${YELLOW}║${RESET}"
echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

read -p "$(echo -e ${BOLD}${GREEN}"Você confirma que todos os requisitos acima estão OK? (sim/não): "${RESET})" CONFIRM
if [[ ! "$CONFIRM" =~ ^(sim|SIM|s|S|yes|YES|y|Y)$ ]]; then
    print_error "Instalação cancelada. Configure os requisitos e execute novamente."
    exit 0
fi

print_success "Confirmação recebida. Iniciando instalação..."
sleep 2

# ===== ATUALIZAÇÃO DO SISTEMA =====
print_step "ATUALIZANDO SISTEMA OPERACIONAL"
{
    apt update -y && apt upgrade -y
} > /tmp/apt_update.log 2>&1 &
spinner $!
print_success "Sistema atualizado"

# ===== INSTALAÇÃO DO AWS CLI =====
print_step "INSTALANDO AWS CLI"
{
    apt install -y awscli
} > /tmp/aws_install.log 2>&1 &
spinner $!
print_success "AWS CLI instalado"

# ===== CONFIGURAÇÃO DE CREDENCIAIS AWS =====
print_step "CONFIGURANDO CREDENCIAIS AWS"
echo ""
read -p "$(echo -e ${CYAN}"🗝️  AWS_ACCESS_KEY_ID: "${RESET})" AWS_ACCESS_KEY_ID
read -sp "$(echo -e ${CYAN}"🔒 AWS_SECRET_ACCESS_KEY: "${RESET})" AWS_SECRET_ACCESS_KEY
echo ""
read -p "$(echo -e ${CYAN}"🌍 Região AWS (ex: us-east-1): "${RESET})" S3_REGION
read -p "$(echo -e ${CYAN}"🪣 Nome do Bucket S3: "${RESET})" S3_BUCKET_NAME
echo ""

# Configurar AWS CLI
mkdir -p /root/.aws
cat > /root/.aws/credentials <<EOF
[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOF

cat > /root/.aws/config <<EOF
[default]
region = $S3_REGION
output = json
EOF

chmod 600 /root/.aws/credentials
chmod 600 /root/.aws/config

# ===== VALIDAÇÃO DE CREDENCIAIS AWS =====
print_step "VALIDANDO CREDENCIAIS AWS"

# Teste 1: Verificar credenciais
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    print_error "Credenciais AWS inválidas!"
    print_error "Erro: Unable to locate credentials ou Access Denied"
    echo ""
    print_info "Verifique:"
    print_info "  • Access Key ID está correto"
    print_info "  • Secret Access Key está correto"
    print_info "  • Usuário IAM tem permissões adequadas"
    exit 1
fi
print_success "Credenciais AWS válidas"

# Teste 2: Verificar acesso ao bucket
if ! aws s3 ls "s3://${S3_BUCKET_NAME}" > /dev/null 2>&1; then
    print_error "Erro ao acessar o bucket S3!"
    print_error "Bucket '${S3_BUCKET_NAME}' não existe ou sem permissão"
    echo ""
    print_info "Verifique:"
    print_info "  • O bucket existe na região ${S3_REGION}"
    print_info "  • O usuário IAM tem permissão s3:ListBucket"
    print_info "  • O nome do bucket está correto (case-sensitive)"
    exit 1
fi
print_success "Acesso ao bucket S3 confirmado"

# ===== CRIAR ESTRUTURA DE PASTAS NO S3 =====
print_step "CRIANDO ESTRUTURA DE PASTAS NO S3"

create_s3_folder() {
    local folder=$1
    if aws s3api put-object --bucket "${S3_BUCKET_NAME}" --key "${folder}" > /dev/null 2>&1; then
        print_success "Pasta criada: ${folder}"
    else
        print_warning "Pasta já existe ou erro: ${folder}"
    fi
}

create_s3_folder "evolution/"
create_s3_folder "backups/"
create_s3_folder "backups/n8n/"
create_s3_folder "backups/postgres/"
create_s3_folder "backups/evolution/"

# ===== INSTALAR DOCKER =====
print_step "INSTALANDO DOCKER"
{
    apt install -y ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update -y
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
} > /tmp/docker_install.log 2>&1 &
spinner $!
print_success "Docker instalado e configurado"

# ===== CRIAR SWAP =====
print_step "CONFIGURANDO SWAP (4GB)"
if [ ! -f /swapfile ]; then
    {
        fallocate -l 4G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab > /dev/null
        sysctl vm.swappiness=10 > /dev/null
        echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf > /dev/null
    } > /tmp/swap_setup.log 2>&1 &
    spinner $!
    print_success "SWAP de 4GB criado"
else
    print_info "SWAP já existe"
fi

# ===== CRIAR ESTRUTURA DE DIRETÓRIOS =====
print_step "CRIANDO ESTRUTURA DE DIRETÓRIOS"
cd /home/ubuntu
mkdir -p alobexpress && cd alobexpress
mkdir -p {traefik/letsencrypt,portainer,n8n,evolution,postgres,redis}
print_success "Diretórios criados em /home/ubuntu/alobexpress"

# ===== CONFIGURAÇÕES INTERATIVAS =====
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}  ${BOLD}CONFIGURAÇÃO DOS SERVIÇOS${RESET}                                ${CYAN}║${RESET}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# SSL Email
read -p "$(echo -e ${CYAN}"📧 E-mail para SSL (Let's Encrypt): "${RESET})" TRAEFIK_EMAIL

# Portainer
echo ""
echo -e "${BOLD}${MAGENTA}=== PORTAINER ===${RESET}"
read -p "$(echo -e ${CYAN}"🌐 Domínio (ex: portainer.seudominio.com): "${RESET})" PORTAINER_DOMAIN
read -p "$(echo -e ${CYAN}"👤 Usuário admin: "${RESET})" PORTAINER_USER
while true; do
    read -sp "$(echo -e ${CYAN}"🔒 Senha admin (mín. 12 caracteres): "${RESET})" PORTAINER_PASS
    echo ""
    if [ ${#PORTAINER_PASS} -ge 12 ]; then
        break
    else
        print_error "Senha deve ter no mínimo 12 caracteres!"
    fi
done

# N8N
echo ""
echo -e "${BOLD}${MAGENTA}=== N8N ===${RESET}"
read -p "$(echo -e ${CYAN}"🌐 Domínio (ex: n8n.seudominio.com): "${RESET})" N8N_DOMAIN
read -p "$(echo -e ${CYAN}"👤 Usuário: "${RESET})" N8N_USER
read -sp "$(echo -e ${CYAN}"🔒 Senha: "${RESET})" N8N_PASS
echo ""
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)

# Evolution API
echo ""
echo -e "${BOLD}${MAGENTA}=== EVOLUTION API ===${RESET}"
read -p "$(echo -e ${CYAN}"🌐 Domínio (ex: evolution.seudominio.com): "${RESET})" EVOLUTION_DOMAIN
read -p "$(echo -e ${CYAN}"🔒 Gerar API Key aleatória? (S/n): "${RESET})" GEN_KEY
if [[ ! "$GEN_KEY" =~ ^(n|N|não|nao|NAO|NÃO)$ ]]; then
    EVOLUTION_API_KEY=$(openssl rand -hex 32)
    print_success "API Key gerada: ${EVOLUTION_API_KEY}"
else
    read -p "$(echo -e ${CYAN}"🔒 Digite a API Key: "${RESET})" EVOLUTION_API_KEY
fi

# Gerar senhas de banco de dados
POSTGRES_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)

print_success "Todas as configurações coletadas"
sleep 1

# ===== GERAR .env =====
print_step "GERANDO ARQUIVO .env"
cat <<EOF > .env
# === TRAEFIK ===
TRAEFIK_EMAIL=$TRAEFIK_EMAIL

# === PORTAINER ===
PORTAINER_DOMAIN=$PORTAINER_DOMAIN
PORTAINER_USER=$PORTAINER_USER
PORTAINER_PASS=$PORTAINER_PASS

# === N8N ===
N8N_DOMAIN=$N8N_DOMAIN
N8N_USER=$N8N_USER
N8N_PASS=$N8N_PASS
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY

# === EVOLUTION API ===
EVOLUTION_DOMAIN=$EVOLUTION_DOMAIN
EVOLUTION_API_KEY=$EVOLUTION_API_KEY

# === DATABASE ===
POSTGRES_USER=alobexpress
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=evolution
REDIS_PASSWORD=$REDIS_PASSWORD

# === AWS S3 ===
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
S3_REGION=$S3_REGION
S3_BUCKET_NAME=$S3_BUCKET_NAME
EOF

chmod 600 .env
print_success "Arquivo .env criado com segurança"

# ===== CRIAR DOCKER-COMPOSE.YML =====
print_step "GERANDO DOCKER-COMPOSE.YML"
cat <<'COMPOSE_EOF' > docker-compose.yml
version: "3.8"

services:
  traefik:
    image: traefik:v2.11
    container_name: traefik
    restart: unless-stopped
    command:
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.email=${TRAEFIK_EMAIL}"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--log.level=INFO"
      - "--accesslog=true"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/letsencrypt:/letsencrypt
    networks:
      - alobexpress-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
      - "traefik.http.routers.redirs.rule=hostregexp(\`{host:.+}\`)"
      - "traefik.http.routers.redirs.entrypoints=web"
      - "traefik.http.routers.redirs.middlewares=redirect-to-https"

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    command: -H unix:///var/run/docker.sock
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer:/data
    networks:
      - alobexpress-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(\`${PORTAINER_DOMAIN}\`)"
      - "traefik.http.routers.portainer.entrypoints=websecure"
      - "traefik.http.routers.portainer.tls.certresolver=letsencrypt"
      - "traefik.http.services.portainer.loadbalancer.server.port=9000"

  postgres:
    image: postgres:15-alpine
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - ./postgres:/var/lib/postgresql/data
    networks:
      - alobexpress-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD} --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - ./redis:/data
    networks:
      - alobexpress-net
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASS}
      - N8N_HOST=${N8N_DOMAIN}
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://${N8N_DOMAIN}/
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - N8N_USER_MANAGEMENT_DISABLED=false
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=168
      - NODE_FUNCTION_ALLOW_BUILTIN=*
      - NODE_FUNCTION_ALLOW_EXTERNAL=*
    volumes:
      - ./n8n:/home/node/.n8n
    networks:
      - alobexpress-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n.rule=Host(\`${N8N_DOMAIN}\`)"
      - "traefik.http.routers.n8n.entrypoints=websecure"
      - "traefik.http.routers.n8n.tls.certresolver=letsencrypt"
      - "traefik.http.services.n8n.loadbalancer.server.port=5678"
    depends_on:
      - postgres
      - redis

  evolution:
    image: atendai/evolution-api:latest
    container_name: evolution
    restart: unless-stopped
    environment:
      - SERVER_URL=https://${EVOLUTION_DOMAIN}
      - SERVER_PORT=8080
      - DATABASE_ENABLED=true
      - DATABASE_PROVIDER=postgresql
      - DATABASE_CONNECTION_URI=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      - DATABASE_SAVE_DATA_INSTANCE=true
      - DATABASE_SAVE_DATA_NEW_MESSAGE=true
      - DATABASE_SAVE_MESSAGE_UPDATE=true
      - DATABASE_SAVE_DATA_CONTACTS=true
      - DATABASE_SAVE_DATA_CHATS=true
      - REDIS_ENABLED=true
      - REDIS_URI=redis://default:${REDIS_PASSWORD}@redis:6379
      - REDIS_PREFIX=evolution
      - AUTHENTICATION_TYPE=apikey
      - AUTHENTICATION_API_KEY=${EVOLUTION_API_KEY}
      - AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=true
      - S3_ENABLED=true
      - S3_ACCESS_KEY=${AWS_ACCESS_KEY_ID}
      - S3_SECRET_KEY=${AWS_SECRET_ACCESS_KEY}
      - S3_BUCKET=${S3_BUCKET_NAME}
      - S3_REGION=${S3_REGION}
      - QRCODE_LIMIT=30
      - CONNECTION_TIMEOUT=300000
      - LOG_LEVEL=ERROR
      - LOG_COLOR=true
    volumes:
      - ./evolution:/evolution/instances
    networks:
      - alobexpress-net
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.evolution.rule=Host(\`${EVOLUTION_DOMAIN}\`)"
      - "traefik.http.routers.evolution.entrypoints=websecure"
      - "traefik.http.routers.evolution.tls.certresolver=letsencrypt"
      - "traefik.http.services.evolution.loadbalancer.server.port=8080"
    depends_on:
      - postgres
      - redis

networks:
  alobexpress-net:
    driver: bridge
COMPOSE_EOF

print_success "docker-compose.yml criado"

# ===== CRIAR SCRIPT DE BACKUP =====
print_step "CRIANDO SCRIPT DE BACKUP AUTOMÁTICO"
cat <<'BACKUP_EOF' > backup.sh
#!/bin/bash
set -e

source /home/ubuntu/alobexpress/.env

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/backup_${BACKUP_DATE}"

mkdir -p "$BACKUP_DIR"

echo "📦 Iniciando backup em $(date)..."

# Backup volumes
docker run --rm -v alobexpress_n8n:/data -v "$BACKUP_DIR":/backup alpine tar czf /backup/n8n_${BACKUP_DATE}.tar.gz -C /data .
docker run --rm -v alobexpress_evolution:/data -v "$BACKUP_DIR":/backup alpine tar czf /backup/evolution_${BACKUP_DATE}.tar.gz -C /data .
docker exec postgres pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB} | gzip > "$BACKUP_DIR/postgres_${BACKUP_DATE}.sql.gz"

# Upload para S3
aws s3 sync "$BACKUP_DIR" "s3://${S3_BUCKET_NAME}/backups/$(date +%Y/%m/%d)/" --region ${S3_REGION}

# Limpar backups locais
rm -rf "$BACKUP_DIR"

echo "✅ Backup concluído em $(date)!"
BACKUP_EOF

chmod +x backup.sh
print_success "Script de backup criado"

# ===== CRIAR SCRIPT DE MONITORAMENTO =====
print_step "CRIANDO SCRIPT DE MONITORAMENTO"
cat <<'MONITOR_EOF' > monitor.sh
#!/bin/bash

MEMORY_THRESHOLD=85
CPU_THRESHOLD=90

MEMORY_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}')

echo "📊 Monitoramento de Recursos - $(date)"
echo "   RAM: ${MEMORY_USAGE}%"
echo "   CPU: ${CPU_USAGE}%"

if [ $MEMORY_USAGE -gt $MEMORY_THRESHOLD ]; then
    echo "⚠️  ALERTA: Memória acima de ${MEMORY_THRESHOLD}%!"
    docker stats --no-stream
fi

if [ $CPU_USAGE -gt $CPU_THRESHOLD ]; then
    echo "⚠️  ALERTA: CPU acima de ${CPU_THRESHOLD}%!"
fi
MONITOR_EOF

chmod +x monitor.sh
print_success "Script de monitoramento criado"

# ===== CONFIGURAR CRON JOBS =====
print_step "CONFIGURANDO TAREFAS AGENDADAS (CRON)"
(crontab -l 2>/dev/null | grep -v "alobexpress"; echo "0 3 * * * /home/ubuntu/alobexpress/backup.sh >> /var/log/alobexpress-backup.log 2>&1") | crontab -
(crontab -l 2>/dev/null | grep -v "alobexpress-monitor"; echo "*/30 * * * * /home/ubuntu/alobexpress/monitor.sh >> /var/log/alobexpress-monitor.log 2>&1") | crontab -
print_success "Backup agendado para 03:00 diariamente"
print_success "Monitoramento a cada 30 minutos"

# ===== INICIAR SERVIÇOS =====
print_step "INICIANDO TODOS OS SERVIÇOS"
{
    docker compose up -d
} > /tmp/docker_up.log 2>&1 &
spinner $!
print_success "Containers iniciados"

# ===== AGUARDAR INICIALIZAÇÃO =====
print_step "AGUARDANDO INICIALIZAÇÃO DOS SERVIÇOS"
for i in {60..1}; do
    printf "\r  ${INFO} Aguardando... ${i}s  "
    sleep 1
done
echo ""

# ===== VERIFICAR STATUS =====
print_step "VERIFICANDO STATUS DOS CONTAINERS"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" | while IFS= read -r line; do
    if echo "$line" | grep -q "Up"; then
        echo -e "  ${CHECK} $line"
    else
        echo -e "  ${WARN} $line"
    fi
done

# ===== ESTRUTURA S3 =====
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║${RESET}  ${BOLD}✅ ESTRUTURA FINAL NO S3${RESET}                                 ${GREEN}║${RESET}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${CYAN}${S3_BUCKET_NAME}/${RESET}"
echo -e "${CYAN}│${RESET}"
echo -e "${CYAN}├──${RESET} ${YELLOW}evolution/${RESET}          ${DIM}← Mídias do WhatsApp (criadas automaticamente)${RESET}"
echo -e "${CYAN}│   └──${RESET} ${DIM}(áudios, imagens, vídeos, documentos)${RESET}"
echo -e "${CYAN}│${RESET}"
echo -e "${CYAN}└──${RESET} ${YELLOW}backups/${RESET}           ${DIM}← Backups automáticos (03:00 diariamente)${RESET}"
echo -e "${CYAN}    ├──${RESET} ${BLUE}n8n/${RESET}           ${DIM}← Workflows e configurações do N8N${RESET}"
echo -e "${CYAN}    │   └──${RESET} ${DIM}n8n_YYYYMMDD_HHMMSS.tar.gz${RESET}"
echo -e "${CYAN}    ├──${RESET} ${BLUE}postgres/${RESET}      ${DIM}← Dumps do banco de dados PostgreSQL${RESET}"
echo -e "${CYAN}    │   └──${RESET} ${DIM}postgres_YYYYMMDD_HHMMSS.sql.gz${RESET}"
echo -e "${CYAN}    └──${RESET} ${BLUE}evolution/${RESET}     ${DIM}← Dados das instâncias WhatsApp${RESET}"
echo -e "${CYAN}        └──${RESET} ${DIM}evolution_YYYYMMDD_HHMMSS.tar.gz${RESET}"
echo ""
echo -e "${DIM}Estrutura organizada por data: backups/YYYY/MM/DD/${RESET}"
echo ""

# ===== RESUMO FINAL =====
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║${RESET}  ${BOLD}🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!${RESET}                     ${GREEN}║${RESET}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${BOLD}${CYAN}🌐 ACESSE SEUS SERVIÇOS:${RESET}"
echo -e "   ${ARROW} Portainer → ${WHITE}https://$PORTAINER_DOMAIN${RESET}"
echo -e "   ${ARROW} N8N       → ${WHITE}https://$N8N_DOMAIN${RESET}"
echo -e "   ${ARROW} Evolution → ${WHITE}https://$EVOLUTION_DOMAIN${RESET}"
echo ""
echo -e "${BOLD}${CYAN}🔒 CREDENCIAIS EVOLUTION API:${RESET}"
echo -e "   ${ARROW} API Key: ${WHITE}$EVOLUTION_API_KEY${RESET}"
echo ""
echo -e "${BOLD}${CYAN}📁 DIRETÓRIO DO PROJETO:${RESET}"
echo -e "   ${ARROW} ${WHITE}/home/ubuntu/alobexpress${RESET}"
echo ""
echo -e "${BOLD}${CYAN}🔧 COMANDOS ÚTEIS:${RESET}"
echo -e "   ${ARROW} Ver logs:       ${WHITE}docker compose logs -f [serviço]${RESET}"
echo -e "   ${ARROW} Reiniciar:      ${WHITE}docker compose restart [serviço]${RESET}"
echo -e "   ${ARROW} Parar tudo:     ${WHITE}docker compose down${RESET}"
echo -e "   ${ARROW} Backup manual:  ${WHITE}./backup.sh${RESET}"
echo -e "   ${ARROW} Monitorar:      ${WHITE}./monitor.sh${RESET}"
echo -e "   ${ARROW} Ver containers: ${WHITE}docker compose ps${RESET}"
echo ""
echo -e "${BOLD}${YELLOW}⚠️  LEMBRE-SE:${RESET}"
echo -e "   ${ARROW} Certificados SSL serão gerados automaticamente"
echo -e "   ${ARROW} Aguarde 2-3 minutos para os certificados serem criados"
echo -e "   ${ARROW} Verifique se os domínios estão apontando corretamente"
echo -e "   ${ARROW} Portas 80 e 443 devem estar abertas no Security Group"
echo ""
echo -e "${BOLD}${GREEN}📊 LOGS IMPORTANTES:${RESET}"
echo -e "   ${ARROW} Backups:       ${WHITE}/var/log/alobexpress-backup.log${RESET}"
echo -e "   ${ARROW} Monitoramento: ${WHITE}/var/log/alobexpress-monitor.log${RESET}"
echo ""
echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${DIM}  AlobExpress Setup v2.0.1 | $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""