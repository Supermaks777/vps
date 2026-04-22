#!/bin/bash
set -e

USERS_DIR="/opt/vps-manage/users"

if [ -z "$1" ]; then
    echo "Использование: $0 <имя_пользователя>"
    exit 1
fi

USERNAME=$1
USER_FILE="$USERS_DIR/${USERNAME}.txt"

if [ ! -f "$USER_FILE" ]; then
    echo "❌ Ошибка: пользователь $USERNAME не найден"
    exit 1
fi

cat "$USER_FILE"