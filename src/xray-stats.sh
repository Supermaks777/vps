#!/bin/bash
# Скрипт для получения статистики трафика пользователей Xray

API_ADDR="127.0.0.1:10085"
USERS=$(sudo xray api statsquery --server=$API_ADDR | jq -r '.stat[] | .name' | grep 'user>>>' | cut -d '>' -f 3 | sort -u)

echo "📊 СТАТИСТИКА ТРАФИКА ПОЛЬЗОВАТЕЛЕЙ"
echo "==================================="
echo ""

for USER in $USERS; do
    DOWN=$(sudo xray api statsquery --server=$API_ADDR --name="user>>>$USER>>>traffic>>>downlink" | jq -r '.stat[].value' 2>/dev/null)
    UP=$(sudo xray api statsquery --server=$API_ADDR --name="user>>>$USER>>>traffic>>>uplink" | jq -r '.stat[].value' 2>/dev/null)
    
    # Конвертируем байты в человекочитаемый вид
    DOWN_HR=$(numfmt --to=iec-i --suffix=B $DOWN 2>/dev/null || echo "0 B")
    UP_HR=$(numfmt --to=iec-i --suffix=B $UP 2>/dev/null || echo "0 B")
    
    echo "👤 $USER"
    echo "   📥 Скачано: $DOWN_HR"
    echo "   📤 Отправлено: $UP_HR"
    echo ""
done
