#!/bin/bash
# archive-old-notes.sh - Архивация и очистка daily notes
# Часть ночной уборки. Можно запускать отдельно.
#
# БЕЗОПАСНОСТЬ:
# - По умолчанию работает в dry-run режиме (показывает что будет сделано)
# - Для реального выполнения: ./archive-old-notes.sh --execute
# - Для интерактивного режима: ./archive-old-notes.sh --confirm
#
# НАСТРОЙКА:
# - ARCHIVE_AFTER_DAYS (default: 14) - через сколько дней архивировать
# - PURGE_AFTER_DAYS (default: 90) - через сколько дней удалять
# - LOG_MAX_MB (default: 10) - максимальный размер лога для ротации
# - OPENCLAW_WORKSPACE - путь к workspace агента

set -euo pipefail

# === ПАРАМЕТРЫ ===
DRY_RUN=true
CONFIRM_MODE=false

for arg in "$@"; do
  case "$arg" in
    --execute|-x) DRY_RUN=false ;;
    --confirm|-c) CONFIRM_MODE=true; DRY_RUN=false ;;
    --help|-h)
      echo "Usage: $0 [--execute|-x] [--confirm|-c] [--help|-h]"
      echo ""
      echo "  --execute, -x   Выполнить реальные действия (по умолчанию dry-run)"
      echo "  --confirm, -c   Запрашивать подтверждение перед каждым действием"
      echo "  --help, -h      Показать эту справку"
      echo ""
      echo "Environment variables:"
      echo "  ARCHIVE_AFTER_DAYS  Days before archiving (default: 14)"
      echo "  PURGE_AFTER_DAYS    Days before deletion (default: 90)"
      echo "  LOG_MAX_MB          Max log size for rotation (default: 10)"
      echo "  OPENCLAW_WORKSPACE  Agent workspace path"
      exit 0
      ;;
  esac
done

# === ПУТИ (configurable через env) ===
WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/agents/main/agent}"
MEMORY_DIR="$WORKSPACE/memory"
ARCHIVE_DIR="$MEMORY_DIR/archive/daily"
LOG_DIR="${OPENCLAW_LOG_DIR:-$HOME/.openclaw/logs}"
TMP_LOG_DIR="/tmp/openclaw"
SQLITE_DB="${OPENCLAW_SQLITE_DB:-$HOME/.openclaw/memory/main.sqlite}"

ARCHIVE_AFTER_DAYS="${ARCHIVE_AFTER_DAYS:-14}"
PURGE_AFTER_DAYS="${PURGE_AFTER_DAYS:-90}"
LOG_MAX_MB="${LOG_MAX_MB:-10}"

log() { echo "$(date '+%H:%M:%S') $1"; }

confirm() {
  if [ "$CONFIRM_MODE" = true ]; then
    read -p "  Выполнить? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
  else
    return 0
  fi
}

execute() {
  local cmd="$1"
  local desc="${2:-}"
  
  if [ "$DRY_RUN" = true ]; then
    log "  [DRY-RUN] $desc: $cmd"
    return 0
  fi
  
  if [ "$CONFIRM_MODE" = true ]; then
    log "  $desc"
    if confirm; then
      eval "$cmd"
    else
      log "  ⏭️ Пропущено"
      return 1
    fi
  else
    eval "$cmd"
  fi
}

# === HEADER ===
log "📚 archive-old-notes.sh"
if [ "$DRY_RUN" = true ]; then
  log "⚠️  DRY-RUN MODE: реальных изменений не будет"
  log "   Для выполнения запустите: $0 --execute"
fi
echo ""
log "Настройки:"
log "  WORKSPACE: $WORKSPACE"
log "  ARCHIVE_AFTER_DAYS: $ARCHIVE_AFTER_DAYS"
log "  PURGE_AFTER_DAYS: $PURGE_AFTER_DAYS"
log "  LOG_MAX_MB: $LOG_MAX_MB"
echo ""

# Проверка существования директорий
if [ ! -d "$MEMORY_DIR" ]; then
  log "⚠️  Memory directory not found: $MEMORY_DIR"
  log "   Укажите OPENCLAW_WORKSPACE или создайте директорию"
  exit 1
fi

# === 1. АРХИВАЦИЯ DAILY NOTES ===
log "📚 Архивация daily notes..."
[ "$DRY_RUN" = false ] && mkdir -p "$ARCHIVE_DIR"

ARCHIVED=0
DELETED=0
WOULD_ARCHIVE=0
WOULD_DELETE=0

for f in "$MEMORY_DIR"/20??-*.md; do
  [ -f "$f" ] || continue
  fname=$(basename "$f")
  [[ "$fname" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]] || continue

  file_date="${fname%.md}"
  # Совместимость macOS/Linux
  if date -v-1d '+%Y' >/dev/null 2>&1; then
    cutoff_archive=$(date -v-${ARCHIVE_AFTER_DAYS}d '+%Y-%m-%d')
    cutoff_purge=$(date -v-${PURGE_AFTER_DAYS}d '+%Y-%m-%d')
  else
    cutoff_archive=$(date -d "${ARCHIVE_AFTER_DAYS} days ago" '+%Y-%m-%d')
    cutoff_purge=$(date -d "${PURGE_AFTER_DAYS} days ago" '+%Y-%m-%d')
  fi

  if [[ "$file_date" < "$cutoff_purge" ]]; then
    if execute "rm -f \"$f\"" "🗑️ Удаление (>$PURGE_AFTER_DAYS д): $fname"; then
      [ "$DRY_RUN" = false ] && DELETED=$((DELETED+1))
    fi
    WOULD_DELETE=$((WOULD_DELETE+1))
  elif [[ "$file_date" < "$cutoff_archive" ]]; then
    if execute "mv \"$f\" \"$ARCHIVE_DIR/$fname\"" "📦 Архивация (>$ARCHIVE_AFTER_DAYS д): $fname"; then
      [ "$DRY_RUN" = false ] && ARCHIVED=$((ARCHIVED+1))
    fi
    WOULD_ARCHIVE=$((WOULD_ARCHIVE+1))
  fi
done

# Удаляем из архива старше PURGE_AFTER_DAYS
if [ -d "$ARCHIVE_DIR" ]; then
  old_nullglob=$(shopt -p nullglob || true)
  shopt -s nullglob
  for f in "$ARCHIVE_DIR"/*.md; do
    [ -f "$f" ] || continue
    fname=$(basename "$f")
    [[ "$fname" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]] || continue
    file_date="${fname%.md}"
    if [[ "$file_date" < "$cutoff_purge" ]]; then
      if execute "rm -f \"$f\"" "🗑️ Удаление из архива: $fname"; then
        [ "$DRY_RUN" = false ] && DELETED=$((DELETED+1))
      fi
      WOULD_DELETE=$((WOULD_DELETE+1))
    fi
  done
  eval "$old_nullglob"
fi

if [ "$DRY_RUN" = true ]; then
  log "  📊 Будет: archived=$WOULD_ARCHIVE deleted=$WOULD_DELETE"
else
  log "  ✅ Memory: archived=$ARCHIVED deleted=$DELETED"
fi

# === 2. РОТАЦИЯ ЛОГОВ ===
log "🔄 Ротация логов..."
ROTATED=0
WOULD_ROTATE=0

if [ -d "$LOG_DIR" ]; then
  for f in "$LOG_DIR"/*.log "$LOG_DIR"/*.jsonl; do
    [ -f "$f" ] || continue
    size_mb=$(du -m "$f" 2>/dev/null | cut -f1)
    if [ "${size_mb:-0}" -ge "$LOG_MAX_MB" ]; then
      if execute "tail -1000 \"$f\" > \"$f.tmp\" && mv \"$f.tmp\" \"$f\"" "✂️ $(basename "$f"): ${size_mb}MB → 1000 строк"; then
        [ "$DRY_RUN" = false ] && ROTATED=$((ROTATED+1))
      fi
      WOULD_ROTATE=$((WOULD_ROTATE+1))
    fi
  done
fi

if [ -d "$TMP_LOG_DIR" ]; then
  tmp_count=$(find "$TMP_LOG_DIR" -name "*.log" -mtime +7 2>/dev/null | wc -l | tr -d ' ')
  if [ "$tmp_count" -gt 0 ]; then
    execute "find \"$TMP_LOG_DIR\" -name \"*.log\" -mtime +7 -delete" "🧹 tmp логи старше 7д ($tmp_count файлов)"
  fi
fi

if [ "$DRY_RUN" = true ]; then
  log "  📊 Будет ротировано: $WOULD_ROTATE"
else
  log "  ✅ Logs: rotated=$ROTATED"
fi

# === 3. ОЧИСТКА СТАРЫХ СЕССИЙ ===
log "🤖 Очистка старых сессий..."
SESSION_CLEANED=0
WOULD_CLEAN_SESSIONS=0

old_nullglob=$(shopt -p nullglob || true)
shopt -s nullglob
for agent_dir in "$HOME/.openclaw/agents"/*/sessions; do
  [ -d "$agent_dir" ] || continue
  for f in "$agent_dir"/*.jsonl; do
    [ -f "$f" ] || continue
    if stat -f %m "$f" >/dev/null 2>&1; then
      file_age=$(( ( $(date +%s) - $(stat -f %m "$f") ) / 86400 ))
    else
      file_age=$(( ( $(date +%s) - $(stat -c %Y "$f") ) / 86400 ))
    fi
    if [ "$file_age" -ge 30 ]; then
      if execute "rm -f \"$f\"" "🗑️ Сессия >30д: $(basename "$f")"; then
        [ "$DRY_RUN" = false ] && SESSION_CLEANED=$((SESSION_CLEANED+1))
      fi
      WOULD_CLEAN_SESSIONS=$((WOULD_CLEAN_SESSIONS+1))
    fi
  done
done
eval "$old_nullglob"

if [ "$DRY_RUN" = true ]; then
  log "  📊 Будет очищено сессий: $WOULD_CLEAN_SESSIONS"
else
  log "  ✅ Sessions: cleaned=$SESSION_CLEANED"
fi

# === 4. SQLITE CLEANUP (опционально, с подтверждением) ===
if [ -f "$SQLITE_DB" ]; then
  log "🧹 SQLite cleanup..."
  BEFORE=$(du -m "$SQLITE_DB" 2>/dev/null | cut -f1)
  
  if [ "$DRY_RUN" = true ]; then
    log "  [DRY-RUN] Очистка embedding_cache и VACUUM (текущий размер: ${BEFORE}MB)"
  else
    if [ "$CONFIRM_MODE" = true ]; then
      log "  ⚠️  Очистка embedding_cache удалит кеш эмбеддингов"
      log "     Текущий размер БД: ${BEFORE}MB"
      if confirm; then
        sqlite3 "$SQLITE_DB" "DELETE FROM embedding_cache;" 2>/dev/null || true
        sqlite3 "$SQLITE_DB" "VACUUM;" 2>/dev/null || true
        AFTER=$(du -m "$SQLITE_DB" 2>/dev/null | cut -f1)
        log "  ✅ SQLite: ${BEFORE}MB → ${AFTER}MB"
      else
        log "  ⏭️ SQLite cleanup пропущен"
      fi
    else
      sqlite3 "$SQLITE_DB" "DELETE FROM embedding_cache;" 2>/dev/null || true
      sqlite3 "$SQLITE_DB" "VACUUM;" 2>/dev/null || true
      AFTER=$(du -m "$SQLITE_DB" 2>/dev/null | cut -f1)
      log "  ✅ SQLite: ${BEFORE}MB → ${AFTER}MB"
    fi
  fi
fi

# === ИТОГ ===
echo ""
if [ "$DRY_RUN" = true ]; then
  TOTAL=$((WOULD_ARCHIVE + WOULD_DELETE + WOULD_ROTATE + WOULD_CLEAN_SESSIONS))
  log "📊 DRY-RUN SUMMARY:"
  log "   Будет архивировано: $WOULD_ARCHIVE"
  log "   Будет удалено: $WOULD_DELETE"
  log "   Будет ротировано логов: $WOULD_ROTATE"
  log "   Будет очищено сессий: $WOULD_CLEAN_SESSIONS"
  log "   TOTAL: $TOTAL"
  echo ""
  log "💡 Для выполнения запустите: $0 --execute"
  log "   Для интерактивного режима: $0 --confirm"
else
  TOTAL=$((ARCHIVED + DELETED + ROTATED + SESSION_CLEANED))
  log "✅ Готово: archived=$ARCHIVED deleted=$DELETED rotated=$ROTATED sessions=$SESSION_CLEANED total=$TOTAL"
fi
