#!/bin/bash
# ============================================
# xray-user-list.sh - Список всех пользователей
# ============================================

XRAY_CONFIG="/usr/local/etc/xray/config.json"
USERS_DIR="/opt/vps-manage/users"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Список пользователей Xray ===${NC}"
echo ""

if [ -s $XRAY_CONFIG ]; then
    jq -r '.inbounds[0].settings.clients[] | "   📱 \(.email) - UUID: \(.id)"' $XRAY_CONFIG 2>/dev/null || echo "   Нет пользователей"
else
    echo "   Нет пользователей"
fi

echo ""
echo -e "${YELLOW}📁 Файлы пользователей:${NC}"
if [ -d "$USERS_DIR" ] && [ -n "$(ls -A $USERS_DIR 2>/dev/null)" ]; then
    for file in $USERS_DIR/*.txt; do
        basename "$file" .txt
    done
else
    echo "   Нет файлов"
fi