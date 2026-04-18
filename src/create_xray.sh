#!/bin/bash

set -e

echo "=== Автоматическая настройка сервера VLESS+Reality ==="

# 1. Обновление и фаервол
sudo apt update && sudo apt upgrade -y
sudo apt install ufw -y
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 443/tcp comment 'VLESS'
sudo ufw --force enable

# 2. Установка Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install