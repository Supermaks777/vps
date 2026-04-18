#!/bin/bash
set -e
# ============================================
# xray-user-del.sh - Удаление пользователя
# ============================================

USERS_DIR="/root/users"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
HYSTERIA_CONFIG="/etc/hysteria/config.yaml"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}Использование: $0 <имя_пользователя>${NC}"
    exit 1
fi

USERNAME=$1

echo -e "${YELLOW}=== Удаление пользователя: $USERNAME ===${NC}"

# 1. Удаление из Xray
echo -e "${YELLOW}Удаление из Xray...${NC}"
jq --arg email "$USERNAME" 'del(.inbounds[0].settings.clients[] | select(.email == $email))' \
   $XRAY_CONFIG > /tmp/xray_config.json && mv /tmp/xray_config.json $XRAY_CONFIG

# 2. Удаление из Hysteria2
echo -e "${YELLOW}Удаление из Hysteria2...${NC}"
jq --arg user "$USERNAME" 'del(.auth.passwords[$user])' \
   $HYSTERIA_CONFIG > /tmp/hysteria_config.yaml && mv /tmp/hysteria_config.yaml $HYSTERIA_CONFIG

# 3. Перезапуск сервисов
systemctl restart xray
systemctl restart hysteria-server

# 4. Удаление файла пользователя
if [ -f "$USERS_DIR/${USERNAME}.txt" ]; then
    rm "$USERS_DIR/${USERNAME}.txt"
    echo -e "${YELLOW}Удалён файл: $USERS_DIR/${USERNAME}.txt${NC}"
fi

echo -e "${GREEN}✅ Пользователь $USERNAME удалён${NC}"