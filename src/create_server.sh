#!/bin/bash
set -e
# ============================================
# create_server.sh - Развёртывание сервера с Xray (VLESS+Reality) и Hysteria2
# ============================================

# Переменные
USERS_DIR="/opt/vps-manage/users"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
HYSTERIA_CONFIG="/etc/hysteria/config.yaml"
SERVER_IP=$(curl -s ifconfig.me)

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Настройка сервера: Xray + Hysteria2 ===${NC}"

# 1. Обновление системы и установка базовых пакетов
echo -e "${YELLOW}1. Обновление системы...${NC}"
apt update && apt upgrade -y
apt install -y curl wget ufw fail2ban jq certbot openssl

# 2. Настройка UFW
echo -e "${YELLOW}2. Настройка UFW...${NC}"
ufw allow 22/tcp comment 'SSH'
ufw allow 443/tcp comment 'VLESS'
ufw allow 8443/tcp comment 'Hysteria2'
ufw allow 8443/udp comment 'Hysteria2 UDP'
ufw --force enable

# 3. Оптимизация сетевого стека (BBR)
echo -e "${YELLOW}3. Оптимизация сетевого стека...${NC}"
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
fi

# 4. Настройка fail2ban
echo -e "${YELLOW}4. Настройка fail2ban...${NC}"
systemctl enable fail2ban --now

# 5. Установка Xray
echo -e "${YELLOW}5. Установка Xray...${NC}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 6. Генерация параметров для Reality
echo -e "${YELLOW}6. Генерация ключей Reality...${NC}"
UUID=$(cat /proc/sys/kernel/random/uuid)
PRIVATE_KEY=$(xray x25519 | awk '/PrivateKey/ {print $2}')
PUBLIC_KEY=$(xray x25519 -i "$PRIVATE_KEY" | grep 'Password (PublicKey):' | sed 's/Password (PublicKey): //')
SHORT_ID=$(openssl rand -hex 8)

# Сохраняем параметры
mkdir -p /root/certs
cat > /root/reality_params.txt << EOF
# Reality параметры сервера (НЕ ДЕЛИТЬСЯ!)
PrivateKey: $PRIVATE_KEY
PublicKey: $PUBLIC_KEY
ShortID: $SHORT_ID
ServerIP: $SERVER_IP
EOF

# 7. Создание конфига Xray (без клиентов)
echo -e "${YELLOW}7. Создание конфигурации Xray...${NC}"
tee $XRAY_CONFIG > /dev/null << EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "www.microsoft.com:443",
          "serverNames": ["www.microsoft.com", "cloudflare.com"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": ["$SHORT_ID"]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    }
  ]
}
EOF

# 8. Установка Hysteria2
echo -e "${YELLOW}8. Установка Hysteria2...${NC}"
bash <(curl -fsSL https://get.hy2.sh/)

# 9. Получение SSL-сертификата (Let's Encrypt)
echo -e "${YELLOW}9. Получение SSL-сертификата...${NC}"
systemctl stop nginx 2>/dev/null || true
certbot certonly --standalone -d $SERVER_IP --non-interactive --agree-tos --register-unsafely-without-email 2>/dev/null || true

# 10. Создание конфига Hysteria2 (без клиентов)
echo -e "${YELLOW}10. Создание конфигурации Hysteria2...${NC}"
mkdir -p /etc/hysteria
tee $HYSTERIA_CONFIG > /dev/null << EOF
tls:
  cert: /etc/letsencrypt/live/$SERVER_IP/fullchain.pem
  key: /etc/letsencrypt/live/$SERVER_IP/privkey.pem

auth:
  type: password
  password: ""  # Будут добавлены пользователи

masquerade:
  type: proxy
  proxy:
    url: https://www.bing.com
    rewriteHost: true

quic:
  initStreamReceiveWindow: 16777216
  maxStreamReceiveWindow: 33554432
  initConnReceiveWindow: 33554432
  maxConnReceiveWindow: 67108864
  maxIdleTimeout: 30s
  maxIncomingStreams: 1024
  disablePathMTUDiscovery: false

bandwidth:
  up: 100 mbps
  down: 100 mbps

ignoreClientBandwidth: false

disableUDP: false

udpIdleTimeout: 60s

resolver:
  type: https
  https:
    addr: 1.1.1.1:443
    timeout: 10s
    sni: cloudflare-dns.com

auth:
  type: passwords
  passwords: {}  # Будут добавлены пользователи
EOF

# 11. Создание директории для пользователей
mkdir -p $USERS_DIR

# 12. Запуск сервисов
echo -e "${YELLOW}11. Запуск сервисов...${NC}"
systemctl enable xray
systemctl restart xray
systemctl enable hysteria-server
systemctl restart hysteria-server

# 13. Итоговая информация
clear
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}✅ НАСТРОЙКА СЕРВЕРА ЗАВЕРШЕНА${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${YELLOW}📁 Параметры сервера сохранены в:${NC} /root/reality_params.txt"
echo -e "${YELLOW}👥 Пользователи будут храниться в:${NC} $USERS_DIR/"
echo ""
echo -e "${YELLOW}🔧 Администраторские данные:${NC}"
echo -e "   PublicKey: ${GREEN}$PUBLIC_KEY${NC}"
echo -e "   ShortID:   ${GREEN}$SHORT_ID${NC}"
echo ""
echo -e "${YELLOW}📝 Следующие шаги:${NC}"
echo -e "   ./xray-user-add.sh <имя>   - добавить пользователя"
echo -e "   ./xray-user-del.sh <имя>   - удалить пользователя"
echo -e "   ./xray-user-list.sh        - список всех пользователей"
echo ""