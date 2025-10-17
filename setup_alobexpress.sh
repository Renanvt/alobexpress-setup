# alobexpress-setup (c) by Jonatan Renan
# 
# alobexpress-setup is licensed under a
# Creative Commons Attribution 4.0 International License.
# 
# You should have received a copy of the license along with this
# work. If not, see <https://creativecommons.org/licenses/by/4.0/>.

#!/bin/bash
set -e

echo "🚀 Iniciando configuração da infraestrutura AlobExpress..."
sleep 2

# Atualizar sistema
sudo apt update -y && sudo apt upgrade -y

# Instalar Docker e Compose
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker

# Criar SWAP de 2GB
echo "⚙️  Criando SWAP de 2GB..."
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Criar diretório do projeto
cd /home/ubuntu
mkdir -p alobexpress && cd alobexpress

# Criar docker-compose.yml
cat <<EOF > docker-compose.yml
version: "3.9"

services:
  traefik:
    image: traefik:v2.11
    container_name: traefik
    command:
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.httpchallenge=true"
      - "--certificatesresolvers.myresolver.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.myresolver.acme.email=empresaalob@gmail.com"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./letsencrypt:/letsencrypt
    restart: always

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    command: -H unix:///var/run/docker.sock
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.rule=Host(\`portainer.alobexpress.com.br\`)"
      - "traefik.http.routers.portainer.entrypoints=websecure"
      - "traefik.http.routers.portainer.tls.certresolver=myresolver"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    restart: always

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    env_file:
      - .env
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n.rule=Host(\`n8n.alobexpress.com.br\`)"
      - "traefik.http.routers.n8n.entrypoints=websecure"
      - "traefik.http.routers.n8n.tls.certresolver=myresolver"
    volumes:
      - n8n_data:/home/node/.n8n
    restart: always

  evolution:
    image: atendai/evolution-api:latest
    container_name: evolution
    env_file:
      - .env
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.evolution.rule=Host(\`evolution.alobexpress.com.br\`)"
      - "traefik.http.routers.evolution.entrypoints=websecure"
      - "traefik.http.routers.evolution.tls.certresolver=myresolver"
    restart: always

volumes:
  portainer_data:
  n8n_data:
EOF

# Criar arquivo .env
cat <<EOF > .env
# === CONFIGURAÇÕES DO N8N ===
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=suasenha
WEBHOOK_TUNNEL_URL=https://n8n.alobexpress.com.br/
GENERIC_TIMEZONE=America/Sao_Paulo

# === SUPABASE ===
SUPABASE_URL=
SUPABASE_ANON_KEY=

# === AWS S3 ===
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
S3_BUCKET_NAME=alobexpress-storage
S3_REGION=us-east-1

# === EVOLUTION API ===
PORT=8080
SERVER_URL=https://evolution.alobexpress.com.br
EOF

# Subir containers
sudo docker-compose up -d

echo "✅ Infraestrutura AlobExpress instalada com sucesso!"
echo "Acesse:"
echo " - Portainer: https://portainer.alobexpress.com.br"
echo " - n8n: https://n8n.alobexpress.com.br"
echo " - EvolutionAPI: https://evolution.alobexpress.com.br"
