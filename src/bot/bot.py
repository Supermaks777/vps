#!/usr/bin/env python3
import asyncio
import asyncssh
import os
import sys
import logging
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

TELEGRAM_TOKEN = os.environ.get("TELEGRAM_TOKEN")
if not TELEGRAM_TOKEN:
    print("❌ Ошибка: TELEGRAM_TOKEN не найден!")
    sys.exit(1)

SSH_HOST = "host.docker.internal"
SSH_USER = os.environ.get("USER", "jocastab")
SSH_KEY_PATH = "/app/ssh_key"
SCRIPTS_DIR = "/opt/vps-manage"

async def run_ssh_command(command: str) -> str:
    try:
        async with asyncssh.connect(
            SSH_HOST,
            username=SSH_USER,
            client_keys=[SSH_KEY_PATH],
            known_hosts=None
        ) as conn:
            result = await conn.run(command, check=False)
            return result.stdout if result.stdout else ""
    except asyncssh.Error as e:
        logger.error(f"Ошибка SSH: {str(e)}")
        return ""

async def user_exists(username: str) -> bool:
    result = await run_ssh_command(f"test -f {SCRIPTS_DIR}/users/{username}.txt && echo 'exists'")
    return "exists" in result

async def cmd_add(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("❌ Укажите имя: /add имя")
        return
    username = context.args[0]
    await update.message.reply_text(f"🔄 Добавляю пользователя {username}...")
    await run_ssh_command(f"sudo {SCRIPTS_DIR}/xray-user-add.sh {username}")
    if await user_exists(username):
        await update.message.reply_text(f"✅ Пользователь {username} успешно добавлен")
    else:
        await update.message.reply_text(f"❌ Ошибка при добавлении {username}")

async def cmd_del(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("❌ Укажите имя: /del имя")
        return
    username = context.args[0]
    await update.message.reply_text(f"🔄 Удаляю пользователя {username}...")
    await run_ssh_command(f"sudo {SCRIPTS_DIR}/xray-user-del.sh {username}")
    if not await user_exists(username):
        await update.message.reply_text(f"✅ Пользователь {username} успешно удалён")
    else:
        await update.message.reply_text(f"❌ Ошибка при удалении {username}")

async def cmd_list(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("🔄 Получаю список пользователей...")
    output = await run_ssh_command(f"sudo {SCRIPTS_DIR}/xray-user-list.sh")
    if output:
        await update.message.reply_text(f"```\n{output[:4000]}\n```", parse_mode="Markdown")
    else:
        await update.message.reply_text("❌ Не удалось получить список пользователей")

async def cmd_show(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("❌ Укажите имя: /show имя")
        return
    username = context.args[0]
    await update.message.reply_text(f"🔄 Получаю данные {username}...")
    output = await run_ssh_command(f"sudo {SCRIPTS_DIR}/xray-user-show.sh {username}")
    if output:
        await update.message.reply_text(f"```\n{output[:4000]}\n```", parse_mode="Markdown")
    else:
        await update.message.reply_text(f"❌ Пользователь {username} не найден")

async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "🤖 VPS Manager Bot\n\n"
        "Доступные команды:\n"
        "/add <имя> - добавить пользователя\n"
        "/del <имя> - удалить пользователя\n"
        "/list - список пользователей\n"
        "/show <имя> - показать данные пользователя"
    )

def main():
    app = Application.builder().token(TELEGRAM_TOKEN).build()
    app.add_handler(CommandHandler("start", cmd_start))
    app.add_handler(CommandHandler("add", cmd_add))
    app.add_handler(CommandHandler("del", cmd_del))
    app.add_handler(CommandHandler("list", cmd_list))
    app.add_handler(CommandHandler("show", cmd_show))
    print("🤖 Бот запущен!")
    app.run_polling()

if __name__ == "__main__":
    main()