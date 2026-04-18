# Настройка VPS для VLESS + Reality

## 📁 Структура репозитория


## 🚀 Первичная настройка сервера (выполняется один раз)

### 1. Подключитесь как root

ssh root@IP_ВАШЕГО_СЕРВЕРА

2. Создайте пользователя и добавьте в sudo
bash
# Создаём пользователя (замените jocastab на своё имя)
useradd -m -s /bin/bash jocastab

# Устанавливаем пароль (придумайте надёжный)
passwd jocastab

# Добавляем в группу sudo
usermod -aG sudo jocastab

3. Скопируйте SSH-ключи (если есть)
bash
# Копируем ключи от root новому пользователю
mkdir -p /home/jocastab/.ssh
cp /root/.ssh/authorized_keys /home/jocastab/.ssh/ 2>/dev/null
chown -R jocastab:jocastab /home/jocastab/.ssh
chmod 700 /home/jocastab/.ssh
chmod 600 /home/jocastab/.ssh/authorized_keys 2>/dev/null

4. Проверьте вход под новым пользователем
bash
exit
ssh jocastab@IP_ВАШЕГО_СЕРВЕРА

# 1. Создать директорию
sudo mkdir -p /opt/vps-manage

# 2. Скачать скрипты туда
cd /opt/vps-manage
sudo curl -fsSL https://raw.githubusercontent.com/Supermaks777/vps/main/src/create_server.sh -o create_server.sh
sudo curl -fsSL https://raw.githubusercontent.com/Supermaks777/vps/main/src/xray-user-add.sh -o xray-user-add.sh
sudo curl -fsSL https://raw.githubusercontent.com/Supermaks777/vps/main/src/xray-user-del.sh -o xray-user-del.sh
sudo curl -fsSL https://raw.githubusercontent.com/Supermaks777/vps/main/src/xray-user-list.sh -o xray-user-list.sh

# 3. Сделать исполняемыми
sudo chmod +x /opt/vps-manage/*.sh

echo 'alias vps-setup="sudo bash /opt/vps-manage/create_server.sh"' >> ~/.bashrc
echo 'alias vps-add="sudo bash /opt/vps-manage/xray-user-add.sh"' >> ~/.bashrc
echo 'alias vps-del="sudo bash /opt/vps-manage/xray-user-del.sh"' >> ~/.bashrc
echo 'alias vps-list="sudo bash /opt/vps-manage/xray-user-list.sh"' >> ~/.bashrc
source ~/.bashrc