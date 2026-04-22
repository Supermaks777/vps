#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Установка Docker ===${NC}"

# Проверка, установлен ли Docker
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker уже установлен: $(docker --version)${NC}"
    exit 0
fi

echo "Docker не найден. Начинаю установку..."

# Удаление старых версий
sudo apt remove -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc 2>/dev/null || true

# Установка зависимостей
sudo apt update
sudo apt install -y ca-certificates curl

# Добавление ключей и репозитория
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"${UBUNTU_CODENAME:-$VERSION_CODENAME}\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER

echo -e "${GREEN}✅ Docker установлен${NC}"
echo -e "${YELLOW}⚠️  Выйдите и зайдите заново, чтобы применить права Docker${NC}"