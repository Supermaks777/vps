#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

USERS_DIR="/opt/vps-manage/users"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
HYSTERIA_CONFIG="/etc/hysteria/config.yaml"
SERVER_IP=$(curl -s ifconfig.me)
PUBLIC_KEY=$(cat /opt/vps-manage/reality_params.txt | grep PublicKey | awk '{print $2}')
SHORT_ID=$(cat /opt/vps-manage/reality_params.txt | grep ShortID | awk '{print $2}')

if [ -z "$1" ]; then
    echo -e "${RED}Использование: $0 <имя_пользователя>${NC}"
    exit 1
fi

USERNAME=$1
USER_FILE="$USERS_DIR/${USERNAME}.txt"

# Проверка существования пользователя
echo -e "${YELLOW}🔍 Проверка: пользователь $USERNAME...${NC}"

if jq -e ".inbounds[0].settings.clients[] | select(.email == \"$USERNAME\")" $XRAY_CONFIG > /dev/null 2>&1; then
    echo -e "${RED}❌ Ошибка: пользователь $USERNAME уже существует в Xray${NC}"
    exit 1
fi

if grep -q "^    $USERNAME: " $HYSTERIA_CONFIG 2>/dev/null; then
    echo -e "${RED}❌ Ошибка: пользователь $USERNAME уже существует в Hysteria2${NC}"
    exit 1
fi

if [ -f "$USER_FILE" ]; then
    echo -e "${RED}❌ Ошибка: файл пользователя $USERNAME уже существует${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Пользователь $USERNAME не найден. Добавляем...${NC}"

# Генерация UUID и пароля
UUID=$(cat /proc/sys/kernel/random/uuid)
HY_PASSWORD=$(openssl rand -hex 16)

# Добавление в Xray
jq --arg uuid "$UUID" --arg email "$USERNAME" \
   '.inbounds[0].settings.clients += [{"id": $uuid, "flow": "xtls-rprx-vision", "email": $email}]' \
   $XRAY_CONFIG > /tmp/xray_config.json && mv /tmp/xray_config.json $XRAY_CONFIG

# Добавление в Hysteria2 (userpass)
if ! grep -q "userpass:" $HYSTERIA_CONFIG; then
    sudo sed -i "/auth:/a \  userpass:" $HYSTERIA_CONFIG
fi
sudo sed -i "/userpass:/a \    $USERNAME: $HY_PASSWORD" $HYSTERIA_CONFIG

# Перезапуск сервисов
systemctl restart xray hysteria-server

# Создание файла пользователя
mkdir -p $USERS_DIR
cat > $USER_FILE << EOF
===== Пользователь: $USERNAME =====
Создан: $(date)

=== Основной канал (VLESS+Reality) ===
vless://$UUID@$SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&headerType=none#$USERNAME

=== Резервный канал (Hysteria2) ===
hysteria2://$USERNAME:$HY_PASSWORD@$SERVER_IP:8443?insecure=1&sni=www.bing.com#$USERNAME

=== UUID для Xray ===
$UUID

=== Пароль для Hysteria2 ===
$HY_PASSWORD
EOF

clear
echo -e "${GREEN}=========================================="
echo "✅ ПОЛЬЗОВАТЕЛЬ $USERNAME ДОБАВЛЕН"
echo -e "==========================================${NC}"
echo ""
echo -e "${YELLOW}📱 ОСНОВНОЙ КАНАЛ (VLESS+Reality):${NC}"
echo -e "${GREEN}vless://$UUID@$SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&headerType=none#$USERNAME${NC}"
echo ""
echo -e "${YELLOW}🔄 РЕЗЕРВНЫЙ КАНАЛ (Hysteria2):${NC}"
echo -e "${GREEN}hysteria2://$USERNAME:$HY_PASSWORD@$SERVER_IP:8443?insecure=1&sni=www.bing.com#$USERNAME${NC}"
echo ""
echo -e "${YELLOW}📁 Данные сохранены:${NC} $USER_FILE"