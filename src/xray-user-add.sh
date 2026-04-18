#!/bin/bash
set -e
# ============================================
# xray-user-add.sh - Добавление пользователя
# ============================================

USERS_DIR="/root/users"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
HYSTERIA_CONFIG="/etc/hysteria/config.yaml"
SERVER_IP=$(curl -s ifconfig.me)
PUBLIC_KEY=$(cat /root/reality_params.txt | grep PublicKey | awk '{print $2}')
SHORT_ID=$(cat /root/reality_params.txt | grep ShortID | awk '{print $2}')

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Проверка имени
if [ -z "$1" ]; then
    echo -e "${RED}Использование: $0 <имя_пользователя>${NC}"
    exit 1
fi

USERNAME=$1
UUID=$(cat /proc/sys/kernel/random/uuid)
HY_PASSWORD=$(openssl rand -hex 16)

echo -e "${GREEN}=== Добавление пользователя: $USERNAME ===${NC}"

# 1. Добавление в Xray
echo -e "${YELLOW}Добавление в Xray...${NC}"
jq --arg uuid "$UUID" --arg email "$USERNAME" \
   '.inbounds[0].settings.clients += [{"id": $uuid, "flow": "xtls-rprx-vision", "email": $email}]' \
   $XRAY_CONFIG > /tmp/xray_config.json && mv /tmp/xray_config.json $XRAY_CONFIG

# 2. Добавление в Hysteria2
echo -e "${YELLOW}Добавление в Hysteria2...${NC}"
jq --arg user "$USERNAME" --arg pass "$HY_PASSWORD" \
   '.auth.passwords += {($user): $pass}' \
   $HYSTERIA_CONFIG > /tmp/hysteria_config.yaml && mv /tmp/hysteria_config.yaml $HYSTERIA_CONFIG

# 3. Перезапуск сервисов
systemctl restart xray
systemctl restart hysteria-server

# 4. Генерация ссылок
VLESS_LINK="vless://$UUID@$SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&headerType=none#$USERNAME"
HYSTERIA_LINK="hysteria2://$HY_PASSWORD@$SERVER_IP:8443?insecure=1&sni=$SERVER_IP#$USERNAME"

# 5. Сохранение в файл
mkdir -p $USERS_DIR
cat > $USERS_DIR/${USERNAME}.txt << EOF
===== Пользователь: $USERNAME =====
Создан: $(date)

=== Основной канал (VLESS+Reality) ===
$VLESS_LINK

=== Резервный канал (Hysteria2) ===
$HYSTERIA_LINK

=== UUID для Xray ===
$UUID

=== Пароль для Hysteria2 ===
$HY_PASSWORD
EOF

# 6. Вывод на экран
clear
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}✅ ПОЛЬЗОВАТЕЛЬ $USERNAME ДОБАВЛЕН${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${YELLOW}📱 ОСНОВНОЙ КАНАЛ (VLESS+Reality):${NC}"
echo -e "${GREEN}$VLESS_LINK${NC}"
echo ""
echo -e "${YELLOW}🔄 РЕЗЕРВНЫЙ КАНАЛ (Hysteria2):${NC}"
echo -e "${GREEN}$HYSTERIA_LINK${NC}"
echo ""
echo -e "${YELLOW}📁 Данные сохранены в:${NC} $USERS_DIR/${USERNAME}.txt"
echo -e "${YELLOW}🔧 v2rayNG: добавьте обе ссылки${NC}"
echo -e "${GREEN}==========================================${NC}"