#!/bin/bash

USERS_DIR="/opt/vps-manage/users"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
HYSTERIA_CONFIG="/etc/hysteria/config.yaml"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== Список пользователей ===${NC}"
echo ""

echo -e "${YELLOW}📋 Из конфига Xray:${NC}"
if [ -f "$XRAY_CONFIG" ]; then
    jq -r '.inbounds[0].settings.clients[] | "  👤 \(.email) (UUID: \(.id))"' $XRAY_CONFIG 2>/dev/null || echo "  (нет пользователей)"
else
    echo "  (конфиг не найден)"
fi

echo ""
echo -e "${YELLOW}🔐 Из конфига Hysteria2:${NC}"
if [ -f "$HYSTERIA_CONFIG" ]; then
    grep "^    .*: " $HYSTERIA_CONFIG 2>/dev/null | sed 's/^    /  👤/' || echo "  (нет пользователей)"
else
    echo "  (конфиг не найден)"
fi

echo ""
echo -e "${YELLOW}📁 Файлы пользователей:${NC}"
if [ -d "$USERS_DIR" ] && [ -n "$(ls -A $USERS_DIR 2>/dev/null)" ]; then
    for file in $USERS_DIR/*.txt; do
        basename "$file" .txt
    done | sed 's/^/  📄 /'
else
    echo "  (нет файлов)"
fi