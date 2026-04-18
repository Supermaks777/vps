#!/bin/bash

set -e

echo "=== Генерация новых ключей и обновление конфига Xray ==="

# 1. Останавливаем Xray
sudo systemctl stop xray

# 2. Генерируем новые ключи
UUID=$(cat /proc/sys/kernel/random/uuid)
PRIVATE_KEY=$(sudo xray x25519 | awk '/PrivateKey/ {print $2}')
PUBLIC_KEY=$(sudo xray x25519 -i "$PRIVATE_KEY" | grep 'Password (PublicKey):' | sed 's/Password (PublicKey): //')
SHORT_ID=$(openssl rand -hex 8)
SERVER_IP=$(curl -s ifconfig.me)

# 3. Выводим ключи
echo ""
echo "===== НОВЫЕ КЛЮЧИ ====="
echo "UUID: $UUID"
echo "PrivateKey: $PRIVATE_KEY"
echo "PublicKey: $PUBLIC_KEY"
echo "Short ID: $SHORT_ID"
echo ""

# 4. Создаём новый конфиг
sudo tee /usr/local/etc/xray/config.json > /dev/null << EOF
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision", "level": 0}],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "www.microsoft.com:443",
          "serverNames": ["www.microsoft.com", "cloudflare.com"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": ["$SHORT_ID"]
        }
      }
    }
  ],
  "outbounds": [{"protocol": "freedom", "tag": "direct"}]
}
EOF

# 5. Запускаем Xray
sudo systemctl start xray

# 6. Формируем ссылку
VLESS_LINK="vless://$UUID@$SERVER_IP:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&headerType=none#VLESS_Reality"

# 7. Вывод
echo "===== ГОТОВАЯ ССЫЛКА ====="
echo "$VLESS_LINK"
echo ""
echo "✅ Конфиг обновлён, Xray перезапущен."