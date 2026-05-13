#!/bin/bash
# install.sh - Установка openclaw-memory-kit
# Копирует шаблоны, создаёт структуру, НЕ меняет конфиг автоматически.
set -euo pipefail

echo "╔══════════════════════════════════════╗"
echo "║   OpenClaw Memory Kit - Установка    ║"
echo "╚══════════════════════════════════════╝"
echo ""

# 1. Проверяем OpenClaw
if ! command -v openclaw &> /dev/null; then
  echo "❌ OpenClaw не найден. Установите: https://docs.openclaw.ai"
  exit 1
fi
echo "✅ OpenClaw найден: $(which openclaw)"

# 1.5 Бэкап конфига
CONF="$HOME/.openclaw/openclaw.json"
if [ -f "$CONF" ]; then
  BACKUP="$CONF.backup-$(date +%Y%m%d-%H%M%S)"
  cp "$CONF" "$BACKUP"
  echo "✅ Бэкап конфига: $BACKUP"
else
  echo "⚠️  Конфиг не найден: $CONF"
fi

# 2. Определяем workspace
DEFAULT_WS="$HOME/.openclaw/agents/main/agent"
echo ""
echo "Укажите путь к workspace агента."
echo "По умолчанию: $DEFAULT_WS"
echo ""
echo "Подсказка: путь можно найти в ~/.openclaw/openclaw.json"
echo "  → agents → entries → [ваш агент] → workspace"
echo "  Типичные варианты:"
echo "    ~/.openclaw/agents/main/agent"
echo "    ~/Projects/my-openclaw-agent"
echo "    ~/.openclaw/workspace"
echo ""
read -p "Workspace [Enter = default]: " WORKSPACE
WORKSPACE="${WORKSPACE:-$DEFAULT_WS}"

if [ ! -d "$WORKSPACE" ]; then
  echo "❌ Папка не найдена: $WORKSPACE"
  exit 1
fi
echo "✅ Workspace: $WORKSPACE"

# 3. Определяем откуда копировать (рядом с install.sh)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 4. Создаём структуру памяти
echo ""
echo "📁 Создаю структуру памяти..."
mkdir -p "$WORKSPACE/memory/core"
mkdir -p "$WORKSPACE/memory/decisions"
mkdir -p "$WORKSPACE/memory/projects"
mkdir -p "$WORKSPACE/memory/archive/daily"
echo "  ✅ memory/core/"
echo "  ✅ memory/decisions/"
echo "  ✅ memory/projects/"
echo "  ✅ memory/archive/daily/"

# 5. Копируем шаблоны (если файлов ещё нет)
echo ""
echo "📄 Копирую шаблоны..."

copy_if_missing() {
  local src="$1"
  local dst="$2"
  local name="$3"
  if [ -f "$dst" ]; then
    echo "  ⏭️  $name уже существует - пропускаю"
  else
    cp "$src" "$dst"
    echo "  ✅ $name"
  fi
}

copy_if_missing "$SCRIPT_DIR/templates/BOOTSTRAP.md" "$WORKSPACE/BOOTSTRAP.md" "BOOTSTRAP.md"
copy_if_missing "$SCRIPT_DIR/templates/MEMORY.md" "$WORKSPACE/MEMORY.md" "MEMORY.md"
copy_if_missing "$SCRIPT_DIR/templates/DO_NOT_DELETE.md" "$WORKSPACE/memory/DO_NOT_DELETE.md" "memory/DO_NOT_DELETE.md"
copy_if_missing "$SCRIPT_DIR/templates/handoff.md" "$WORKSPACE/memory/handoff.md" "memory/handoff.md"

# 6. Копируем скрипты
echo ""
echo "🔧 Копирую скрипты..."
SCRIPTS_DIR="$HOME/.openclaw/scripts"
mkdir -p "$SCRIPTS_DIR"

for script in health-check.sh consistency-check.sh archive-old-notes.sh; do
  if [ -f "$SCRIPT_DIR/scripts/$script" ]; then
    cp "$SCRIPT_DIR/scripts/$script" "$SCRIPTS_DIR/$script"
    chmod +x "$SCRIPTS_DIR/$script"
    echo "  ✅ $script → $SCRIPTS_DIR/"
  fi
done

# 7. Итог
echo ""
echo "╔══════════════════════════════════════╗"
echo "║          Установка завершена         ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "📋 Что дальше:"
echo ""
echo "1. Отредактируй MEMORY.md - заполни свои данные"
echo "   nano $WORKSPACE/MEMORY.md"
echo ""
echo "2. Добавь компактификацию в openclaw.json:"
echo "   Скопируй содержимое config/compaction.json"
echo "   в секцию agents → [ваш агент] → compaction"
echo ""
echo "3. Добавь векторный поиск (опционально):"
echo "   Скопируй содержимое config/memory-search.json"
echo "   в секцию memorySearch"
echo ""
echo "4. Настрой кроны (см. crons/*.md):"
echo "   Каждый файл содержит промпт + конфиг для openclaw.json"
echo ""
echo "5. Настрой ночную уборку:"
echo "   См. crons/night-cleanup.md (LaunchAgent / crontab)"
echo ""
echo "6. Проверь здоровье:"
echo "   bash $SCRIPTS_DIR/health-check.sh"
echo ""
echo "📚 Документация: docs/"
