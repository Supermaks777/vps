# Настройка VPS для VLESS + Reality

## 📁 Структура репозитория
git@github.com:Supermaks777/vps.git
├── src/
│ ├── create_xray.sh # Первичная установка Xray
│ └── regenerate_keys.sh # Генерация новых ключей
└── README.md # Эта инструкция

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

📦 Установка Xray (выполняется под jocastab)
Способ А: Клонировать репозиторий и запустить локально
bash
git clone https://github.com/Supermaks777/vps.git
cd vps/src
chmod +x create_xray.sh regenerate_keys.sh
./create_xray.sh
Способ Б: Запустить напрямую из GitHub (публичный репозиторий)
bash
bash <(curl -fsSL https://raw.githubusercontent.com/Supermaks777/vps/main/src/create_xray.sh)
После установки скрипт покажет VLESS-ссылку — сохраните её.

🔄 Генерация новых ключей (если старые скомпрометированы)
bash
bash <(curl -fsSL https://raw.githubusercontent.com/Supermaks777/vps/main/src/regenerate_keys.sh)
После выполнения старые клиенты перестанут работать — обновите ссылку во всех устройствах.

⚡ Быстрые команды (добавить в ~/.bashrc)
Чтобы не запоминать длинные команды, добавьте в файл ~/.bashrc:

bash
nano ~/.bashrc
В конец файла добавьте:

bash
# Быстрая установка/настройка VPS
alias vps-setup='bash <(curl -fsSL https://raw.githubusercontent.com/Supermaks777/vps/main/src/create_xray.sh)'
alias vps-renew='bash <(curl -fsSL https://raw.githubusercontent.com/Supermaks777/vps/main/src/regenerate_keys.sh)'
Примените изменения:

bash
source ~/.bashrc
Теперь достаточно ввести:

Команда	Что делает
vps-setup	Первичная установка Xray
vps-renew	Генерация новых ключей
🔒 Дополнительные рекомендации
Отключить вход по паролю для SSH (если используете ключи)
bash
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
Настроить Fail2ban (защита от брутфорса)
bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban --now
Проверить статус Xray
bash
sudo systemctl status xray
Посмотреть логи Xray
bash
sudo journalctl -u xray -f
📱 Настройка клиентов
Платформа	Клиент	Как добавить
Android	v2rayNG	Скопировать VLESS-ссылку → импорт из буфера
Windows	v2rayN	Скопировать VLESS-ссылку → Ctrl+V
iOS	Shadowrocket / Streisand	Добавить по ссылке
macOS	V2RayX	По ссылке
⚠️ Важные замечания
Не запускайте скрипты от root — используйте пользователя с sudo

Сохраняйте VLESS-ссылку в надёжном месте (менеджер паролей)

После regenerate_keys все старые клиенты потеряют доступ

Публичный репозиторий означает, что ссылки видны всем — но сами ключи генерируются на сервере