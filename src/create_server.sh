#!/bin/bash
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Настройка сервера: Xray + Hysteria2 ===${NC}"

# 1. Обновление системы
echo -e "${YELLOW}1. Обновление системы...${NC}"
apt update && apt upgrade -y
apt install -y curl wget ufw fail2ban jq openssl

# 2. Настройка UFW
echo -e "${YELLOW}2. Настройка UFW...${NC}"
ufw allow 22/tcp comment 'SSH'
ufw allow 443/tcp comment 'VLESS'
ufw allow 8443/tcp comment 'Hysteria2 TCP'
ufw allow 8443/udp comment 'Hysteria2 UDP'
ufw --force enable

# 3. Оптимизация сети (BBR)
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
fi

# 4. Установка Xray
echo -e "${YELLOW}3. Установка Xray...${NC}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 5. Генерация параметров Reality
echo -e "${YELLOW}4. Генерация ключей Reality...${NC}"
UUID=$(cat /proc/sys/kernel/random/uuid)
PRIVATE_KEY=$(xray x25519 | awk '/PrivateKey/ {print $2}')
PUBLIC_KEY=$(xray x25519 -i "$PRIVATE_KEY" | grep 'Password (PublicKey):' | sed 's/Password (PublicKey): //')
SHORT_ID=$(openssl rand -hex 8)
SERVER_IP=$(curl -s ifconfig.me)

mkdir -p /root
cat > /root/reality_params.txt << EOF
# Reality параметры сервера (НЕ ДЕЛИТЬСЯ!)
PrivateKey: $PRIVATE_KEY
PublicKey: $PUBLIC_KEY
ShortID: $SHORT_ID
ServerIP: $SERVER_IP
EOF

# 6. Конфиг Xray (без клиентов)
echo -e "${YELLOW}5. Создание конфигурации Xray...${NC}"
tee /usr/local/etc/xray/config.json > /dev/null << EOF
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
  "outbounds": [{"protocol": "freedom", "tag": "direct"}]
}
EOF

# 7. Установка Hysteria2
echo -e "${YELLOW}6. Установка Hysteria2...${NC}"
bash <(curl -fsSL https://get.hy2.sh/)

# 8. Создание самоподписанного сертификата
echo -e "${YELLOW}7. Создание сертификата...${NC}"
mkdir -p /etc/hysteria/certs
openssl req -x509 -nodes -days 365 -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
  -keyout /etc/hysteria/certs/key.pem -out /etc/hysteria/certs/cert.pem \
  -subj "/CN=$SERVER_IP" -addext "subjectAltName=IP:$SERVER_IP"
chown -R hysteria:hysteria /etc/hysteria/certs

# 9. Конфиг Hysteria2 (без клиентов)
echo -e "${YELLOW}8. Создание конфигурации Hysteria2...${NC}"
tee /etc/hysteria/config.yaml > /dev/null << EOF
listen: :8443

tls:
  cert: /etc/hysteria/certs/cert.pem
  key: /etc/hysteria/certs/key.pem

masquerade:
  type: proxy
  proxy:
    url: https://www.bing.com
    rewriteHost: true
EOF

# 10. Запуск сервисов
systemctl enable xray hysteria-server
systemctl restart xray hysteria-server

# 11. Создание директории для пользователей
mkdir -p /opt/vps-manage/users

clear
echo -e "${GREEN}=========================================="
echo "✅ НАСТРОЙКА СЕРВЕРА ЗАВЕРШЕНА"
echo -e "==========================================${NC}"
echo ""
echo "📁 Директория пользователей: /opt/vps-manage/users/"
echo "🔑 Параметры сервера: /root/reality_params.txt"
echo ""
echo -e "${YELLOW}📝 Следующие шаги:${NC}"
echo "  ./xray-user-add.sh <имя>   - добавить пользователя"
echo "  ./xray-user-list.sh        - список пользователей"
echo "  ./xray-user-del.sh <имя>   - удалить пользователя"