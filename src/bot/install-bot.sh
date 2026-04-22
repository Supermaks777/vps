#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Проверка параметров
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${RED}❌ Использование: $0 <TOKEN> <USER_ID>${NC}"
    echo "Пример: $0 1234567890:ABCdefGHIJKLMNopQRStUVWXYZ-abcde 123456789"
    exit 1
fi

TOKEN=$1
USER_ID=$2
USER=$(whoami)
BOT_DIR="/opt/vps-bot"
SCRIPTS_DIR="/opt/vps-manage"
REPO_URL="https://raw.githubusercontent.com/Supermaks777/vps/main/src/bot"

echo -e "${GREEN}=== Установка Telegram-бота для VPS Manager ===${NC}"

# Проверка Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker не установлен. Запуск install-docker.sh...${NC}"
    curl -fsSL $REPO_URL/install-docker.sh -o /tmp/install-docker.sh
    chmod +x /tmp/install-docker.sh
    /tmp/install-docker.sh
    rm -f /tmp/install-docker.sh
    echo -e "${YELLOW}⚠️  Выйдите и зайдите заново, затем повторите запуск install-bot.sh${NC}"
    exit 0
fi

# Создание директории
sudo mkdir -p $BOT_DIR
sudo chown $USER:$USER $BOT_DIR
cd $BOT_DIR

# Скачивание файлов
curl -fsSL $REPO_URL/bot.py -o bot.py
curl -fsSL $REPO_URL/Dockerfile -o Dockerfile
curl -fsSL $REPO_URL/requirements.txt -o requirements.txt

# docker-compose.yml с токеном и USER_ID
cat > docker-compose.yml << EOF
version: '3.8'
services:
  vps-bot:
    build: .
    container_name: vps-bot
    restart: unless-stopped
    environment:
      - TELEGRAM_TOKEN=$TOKEN
      - ALLOWED_USER_IDS=$USER_ID
    volumes:
      - /home/$USER/.ssh/id_ed25519_bot:/app/ssh_key:ro
      - $SCRIPTS_DIR:/opt/vps-manage:ro
    extra_hosts:
      - "host.docker.internal:host-gateway"
EOF

# SSH-ключ
if [ ! -f /home/$USER/.ssh/id_ed25519_bot ]; then
    ssh-keygen -t ed25519 -f /home/$USER/.ssh/id_ed25519_bot -N ""
fi
cat /home/$USER/.ssh/id_ed25519_bot.pub >> /home/$USER/.ssh/authorized_keys

# Sudo без пароля
echo "$USER ALL=(ALL) NOPASSWD: $SCRIPTS_DIR/user-add.sh, $SCRIPTS_DIR/user-del.sh, $SCRIPTS_DIR/user-list.sh, $SCRIPTS_DIR/user-show.sh, /usr/bin/systemctl restart xray, /usr/bin/systemctl restart hysteria-server" | sudo tee /etc/sudoers.d/vps-bot

# Запуск
sudo docker compose build
sudo docker compose up -d

sleep 3
if sudo docker ps | grep -q vps-bot; then
    echo -e "${GREEN}✅ Бот успешно запущен${NC}"
else
    echo -e "${RED}❌ Ошибка при запуске бота. Проверьте логи: sudo docker logs vps-bot${NC}"
    exit 1
fi

echo -e "${GREEN}✅ УСТАНОВКА БОТА ЗАВЕРШЕНА${NC}"
echo ""
echo "🤖 Бот запущен. Команды будут отвечать только пользователю с ID: $USER_ID"
echo "Проверьте в Telegram: /start"