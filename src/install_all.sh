#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Установка VPS Manager ===${NC}"

USER=$(whoami)
SCRIPTS_DIR="/opt/vps-manage"
REPO_URL="https://raw.githubusercontent.com/Supermaks777/vps/main/src/scripts"

# Создание директории
echo -e "${YELLOW}1. Создание директории $SCRIPTS_DIR...${NC}"
sudo mkdir -p $SCRIPTS_DIR
sudo chown $USER:$USER $SCRIPTS_DIR
cd $SCRIPTS_DIR

# Скачивание скриптов
echo -e "${YELLOW}2. Скачивание скриптов...${NC}"
curl -fsSL $REPO_URL/create_server.sh -o create_server.sh
curl -fsSL $REPO_URL/user-add.sh -o user-add.sh
curl -fsSL $REPO_URL/user-del.sh -o user-del.sh
curl -fsSL $REPO_URL/user-list.sh -o user-list.sh
curl -fsSL $REPO_URL/user-show.sh -o user-show.sh

# Делаем исполняемыми
chmod +x $SCRIPTS_DIR/*.sh

# Создание алиасов
echo -e "${YELLOW}3. Создание алиасов...${NC}"
if ! grep -q "alias vps-setup=" ~/.bashrc; then
    echo 'alias vps-setup="sudo bash /opt/vps-manage/create_server.sh"' >> ~/.bashrc
    echo 'alias vps-add="sudo bash /opt/vps-manage/user-add.sh"' >> ~/.bashrc
    echo 'alias vps-del="sudo bash /opt/vps-manage/user-del.sh"' >> ~/.bashrc
    echo 'alias vps-list="sudo bash /opt/vps-manage/user-list.sh"' >> ~/.bashrc
    echo 'alias vps-show="sudo bash /opt/vps-manage/user-show.sh"' >> ~/.bashrc
    echo -e "${GREEN}✅ Алиасы добавлены${NC}"
else
    echo -e "${YELLOW}⚠️ Алиасы уже существуют, пропускаем${NC}"
fi

# Создание алиаса для установки бота
echo -e "${YELLOW}4. Создание алиаса для установки бота...${NC}"
if ! grep -q "alias vps-create-bot=" ~/.bashrc; then
    echo 'alias vps-create-bot="bash <(curl -fsSL https://raw.githubusercontent.com/Supermaks777/vps/main/src/bot/install-bot.sh)"' >> ~/.bashrc
    echo -e "${GREEN}✅ Алиас vps-create-bot добавлен${NC}"
else
    echo -e "${YELLOW}⚠️ Алиас уже существует, пропускаем${NC}"
fi

# Применение алиасов
source ~/.bashrc

echo -e "${GREEN}=========================================="
echo "✅ УСТАНОВКА ЗАВЕРШЕНА"
echo -e "==========================================${NC}"
echo ""
echo "Доступные команды:"
echo "  vps-setup   - установка сервера (Xray + Hysteria2)"
echo "  vps-add     - добавить пользователя"
echo "  vps-del     - удалить пользователя"
echo "  vps-list    - список пользователей"
echo "  vps-show    - показать данные пользователя"
echo "  vps-create-bot - установка Telegram-бота"
echo ""
echo -e "${YELLOW}⚠️  Для применения алиасов выполните: source ~/.bashrc${NC}"

echo ""
echo -e "${YELLOW}📝 Дальнейшие шаги:${NC}"
echo "  1. Запустите установку сервера: vps-setup"
echo "  2. Затем установите бота: vps-create-bot <TOKEN>"