#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

USERS_DIR="/opt/vps-manage/users"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
HYSTERIA_CONFIG="/etc/hysteria/config.yaml"

if [ -z "$1" ]; then
    echo -e "${RED}Использование: $0 <имя_пользователя>${NC}"
    exit 1
fi

USERNAME=$1

echo -e "${YELLOW}=== Удаление пользователя: $USERNAME ===${NC}"

# Удаление из Xray
if jq -e ".inbounds[0].settings.clients[] | select(.email == \"$USERNAME\")" $XRAY_CONFIG > /dev/null 2>&1; then
    jq --arg email "$USERNAME" 'del(.inbounds[0].settings.clients[] | select(.email == $email))' \
       $XRAY_CONFIG > /tmp/xray_config.json && mv /tmp/xray_config.json $XRAY_CONFIG
    echo -e "${GREEN}✅ Удалён из Xray${NC}"
else
    echo -e "${YELLOW}⚠️ Пользователь не найден в Xray${NC}"
fi

# Удаление из Hysteria2 (удаляем строку с паролем)
if grep -q "^    $USERNAME: " $HYSTERIA_CONFIG 2>/dev/null; then
    sudo sed -i "/^    $USERNAME: /d" $HYSTERIA_CONFIG
    echo -e "${GREEN}✅ Удалён из Hysteria2${NC}"
else
    echo -e "${YELLOW}⚠️ Пользователь не найден в Hysteria2${NC}"
fi

# Перезапуск сервисов
systemctl restart xray hysteria-server

# Удаление файла пользователя
if [ -f "$USERS_DIR/${USERNAME}.txt" ]; then
    rm "$USERS_DIR/${USERNAME}.txt"
    echo -e "${GREEN}✅ Удалён файл: $USERS_DIR/${USERNAME}.txt${NC}"
fi

echo -e "${GREEN}✅ Пользователь $USERNAME удалён${NC}"