# Настройка VPS сервера
**Основной канал:** VLESS + Reality (TCP, порт 443)  
**Резервный канал:** Hysteria2 (UDP, порт 8443)

**Данные пользователей хранятся:** `/opt/vps-manage/users/`

## 📁 Структура репозитория
```
git@github.com:Supermaks777/vps.git
├── src/
│ ├── create_server.sh # Первичная установка сервера
│ ├── xray-user-add.sh # Добавление пользователя
│ ├── xray-user-del.sh # Удаление пользователя
│ └── xray-user-list.sh # Список пользователей
└── README.md # Эта инструкция
```

## 🚀 Первичная настройка сервера (выполняется один раз)
### 1. Подключаемся как root

* ssh root@адрес_сервера

### 2. создаем пользователя и добавьте в sudo
* useradd -m -s /bin/bash my_user

### 3. Устанавливаем пароль
* passwd my_user

### 4. Добавляем в группу sudo
* usermod -aG sudo my_user

### 5. Копируем SSH-ключи (если добавляли при создании сервера)
* mkdir -p /home/my_user/.ssh
* cp /root/.ssh/authorized_keys /home/my_user/.ssh/ 2>/dev/null
* chown -R my_user:my_user /home/my_user/.ssh
* chmod 700 /home/my_user/.ssh
* chmod 600 /home/my_user/.ssh/authorized_keys 2>/dev/null

### 4. Заходим под новым пользователем
* exit
* ssh my_user@адрес_сервера

### 5. Создаем рабочую директорию (для скприптов и данных пользователей)
* sudo mkdir -p /opt/vps-manage

### 6. Скачать скрипты по работе с пользователями и делаем их исполняемыми
* cd /opt/vps-manage
* sudo curl -fsSL https://raw.githubusercontent.com/Supermaks777/vps/main/src/create_server.sh -o create_server.sh
* sudo curl -fsSL https://raw.githubusercontent.com/Supermaks777/vps/main/src/xray-user-add.sh -o xray-user-add.sh
* sudo curl -fsSL https://raw.githubusercontent.com/Supermaks777/vps/main/src/xray-user-del.sh -o xray-user-del.sh
* sudo curl -fsSL https://raw.githubusercontent.com/Supermaks777/vps/main/src/xray-user-list.sh -o xray-user-list.sh
* sudo chmod +x /opt/vps-manage/*.sh

### 7. Создаем алиасы для запуска скриптов
* echo 'alias vps-setup="sudo bash /opt/vps-manage/create_server.sh"' >> ~/.bashrc
* echo 'alias vps-add="sudo bash /opt/vps-manage/xray-user-add.sh"' >> ~/.bashrc
* echo 'alias vps-del="sudo bash /opt/vps-manage/xray-user-del.sh"' >> ~/.bashrc
* echo 'alias vps-list="sudo bash /opt/vps-manage/xray-user-list.sh"' >> ~/.bashrc
* source ~/.bashrc

### 8. Запускаем создание сервера
* vps-setup

# 👥 Управление пользователями

| Действие | Команда | Пример | Что произойдёт |
|----------|---------|--------|----------------|
| **Добавить пользователя** | `vps-add <имя_пользователя>` | `vps-add papa` | • Проверка, что пользователь не существует в Xray и Hysteria2<br>• Генерация UUID для VLESS<br>• Генерация случайного пароля для Hysteria2<br>• Добавление в конфиг Xray<br>• Добавление в конфиг Hysteria2<br>• Создание файла `/opt/vps-manage/users/имя.txt`<br>• Вывод готовых ссылок для клиента |
| **Список пользователей** | `vps-list` | `vps-list` | • Показывает всех пользователей из конфига Xray<br>• Показывает файлы пользователей в директории |
| **Удалить пользователя** | `vps-del <имя_пользователя>` | `vps-del papa` | • Удаление из конфига Xray<br>• Сброс пароля в Hysteria2<br>• Удаление файла пользователя<br>• Перезапуск сервисов |

# 📱 Настройка клиентов

## Основной канал (VLESS+Reality)

| Платформа | Клиент | Как добавить |
|-----------|--------|--------------|
| **Android** | v2rayNG | Импорт ссылки из буфера |
| **Windows** | v2rayN | Импорт ссылки (Ctrl+V) |
| **iOS** | Streisand / Hiddify | По ссылке или QR |

## Резервный канал (Hysteria2)

| Платформа | Клиент | Как добавить |
|-----------|--------|--------------|
| **Android** | v2rayNG | Импорт ссылки (поддерживает Hysteria2) |
| **Windows** | v2rayN / Hiddify | Проверить поддержку Hysteria2 |
| **iOS** | Streisand / Hiddify | По ссылке |

---

# 🔧 Полезные команды

| Команда | Описание |
|---------|----------|
| `vps-setup` | Первичная установка сервера |
| `vps-add <имя>` | Добавить пользователя |
| `vps-list` | Список пользователей |
| `vps-del <имя>` | Удалить пользователя |

## Проверка статуса сервисов
* sudo systemctl status xray
* sudo systemctl status hysteria-server

## Просмотр логов
* sudo journalctl -u xray -f
* sudo journalctl -u hysteria-server -f
# ⚠️ Важные замечания
* **Не запускайте скрипты от root** — используйте пользователя с sudo
* Сохраняйте ссылки в надёжном месте (менеджер паролей)
* После vps-del все клиенты пользователя потеряют доступ
* Публичный репозиторий — ссылки видны всем, но ключи генерируются на сервере
* **Hysteria2 использует самоподписанный сертификат** — клиент может выдавать предупреждение

# 🆘 Возможные проблемы

| Проблема | Решение |
|----------|---------|
| `User already exists` | Пользователь с таким именем уже есть — выберите другое имя |
| `Connection refused` | Проверьте статус сервисов: `sudo systemctl status xray hysteria-server` |
| `Permission denied` | Запускайте скрипты с `sudo` или через алиасы (`vps-add`, `vps-list` и т.д.) |
| `vps-add: command not found` | Алиасы не добавлены — выполните `source ~/.bashrc` или перезайдите в сессию |
| `SSL certificate error` (Hysteria2) | Самоподписанный сертификат — в клиенте включите `allow insecure` или `skip verify` |

