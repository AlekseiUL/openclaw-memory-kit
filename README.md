# OpenClaw Memory Kit

Complete memory and context persistence system for OpenClaw AI agents.

## Canonical source

This project is maintained by Aleksei Ulianov / Sprut_AI.
Original repository: https://github.com/AlekseiUL/openclaw-memory-kit

If you found this project mirrored, repackaged, or redistributed elsewhere, check this repository as the source of truth.

## Attribution

Where permitted by the applicable license, if you reuse, fork, modify, package, or publish this work, keep the original copyright and license notice and link back to the canonical repository.

An agent without memory is like a person with amnesia. Every session starts from scratch. This kit solves the problem: file templates, auto-save crons, hygiene scripts, compaction configs. Everything your agent needs to remember.

---

## Who is this for?

OpenClaw Memory Kit is for users who want durable agent context without building a memory system from scratch:

- personal OpenClaw operators who lose context after compaction or restarts;
- agent builders who need file memory, handoff notes, daily notes, and cleanup scripts;
- teams who want a safe, inspectable memory structure before enabling vector search;
- anyone who prefers backup-first setup over risky one-shot automation.

It is not a magic database. You still decide what should be remembered, archived, or kept private.

## Quick Start

### Option 1: Let the Bot Do It (Recommended)

**First, backup your config:**
```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup
```

Copy the contents of [SETUP-AGENT.md](SETUP-AGENT.md) and send it to your agent in chat. It will execute all steps automatically - clone the repo, install files, configure settings, and create crons.

If the bot goes silent after setup - roll back:
```bash
cp ~/.openclaw/openclaw.json.backup ~/.openclaw/openclaw.json
openclaw gateway start
```

### Option 2: Manual Installation (5 minutes)

```bash
git clone https://github.com/AlekseiUL/openclaw-memory-kit.git
cd openclaw-memory-kit
bash install.sh
```

The installer:
1. Checks that OpenClaw is installed
2. Asks for workspace path
3. Creates memory/ structure (core, decisions, projects, archive)
4. Copies templates (BOOTSTRAP.md, MEMORY.md, DO_NOT_DELETE.md, handoff.md)
5. Installs scripts to `~/.openclaw/scripts/`
6. Shows next steps (which snippets to add to config)

**install.sh does NOT modify openclaw.json.** It only copies files and shows instructions.

---

## What Works Without vectorDB

You do **NOT** need an OpenAI API key to get started. 80% of the value works out of the box.

**Works immediately (zero dependencies):**
- Templates: BOOTSTRAP.md, MEMORY.md, handoff.md, DO_NOT_DELETE.md
- Memory structure (core, decisions, projects, archive)
- Crons: auto-handoff (3x/day), auto-diary (2x/day), night-cleanup (bash)
- Compaction with memoryFlush (saves context before compression)
- Scripts: health-check, consistency-check, archive-old-notes

**Requires OpenAI API key (for embeddings):**
- memory-search.json - vector search across memory (hybrid: 70% vector + 30% BM25)
- Consolidator works better with vectorDB but functions without it

**Bottom line:** start without vectorDB. Your agent will remember context via handoff, write daily notes, archive old ones. When you need to search 3-month-old memories - add embeddings.

---

## Repository Structure

```
openclaw-memory-kit/
├── README.md                    # This file
├── LICENSE                      # MIT
├── install.sh                   # Auto-installation
│
├── templates/                   # Ready-made templates
│   ├── BOOTSTRAP.md             # Wake-up after compaction
│   ├── MEMORY.md                # Long-term memory (template)
│   ├── MEMORY-example.md        # Example of filled MEMORY.md
│   ├── DO_NOT_DELETE.md         # File protection
│   └── handoff.md               # Context transfer
│
├── memory/                      # Memory folder structure
│   ├── core/                    # Eternal facts
│   ├── decisions/               # Decisions and rules
│   ├── projects/                # Projects
│   └── archive/daily/           # Daily notes archive
│
├── crons/                       # Cron prompts
│   ├── auto-handoff.md          # 3x/day - context save
│   ├── auto-diary.md            # 2x/day - daily note
│   ├── consolidator.md          # 1x/week - consolidation
│   └── night-cleanup.md         # 1x/night - cleanup (0 tokens)
│
├── config/                      # Config snippets for openclaw.json
│   ├── compaction.json          # Compaction (safeguard mode)
│   ├── memory-flush.json        # memoryFlush prompt
│   └── memory-search.json       # Vector search (hybrid)
│
├── scripts/                     # Utilities (bash, 0 tokens)
│   ├── health-check.sh          # System health check
│   ├── consistency-check.sh     # Data integrity
│   └── archive-old-notes.sh     # Archive + rotate + cleanup
│
└── docs/                        # Documentation
    ├── architecture.md          # Architecture (5 memory layers)
    ├── how-it-works.md          # Each component in detail
    ├── troubleshooting.md       # Problem solving
    └── faq.md                   # FAQ
```

---

## Components

### Templates (templates/)

| File | Purpose |
|------|---------|
| **BOOTSTRAP.md** | Instructions for agent after wake-up/compaction. Reads handoff → daily note → sessions_history. Restores context. |
| **MEMORY.md** | Long-term memory (template with hints). Loaded in every session. Keep < 3000 chars. |
| **MEMORY-example.md** | Example of filled MEMORY.md from a real agent. Copy structure, replace data. |
| **DO_NOT_DELETE.md** | List of files agent should NOT delete. Protection from accidental cleanup. |
| **handoff.md** | Context transfer between sessions. Format: Topic, Decisions, TODO, Files, Context, Drafts. |

### Crons (crons/)

| Cron | Schedule | Model | Purpose |
|------|----------|-------|---------|
| **auto-handoff** | 3x/day (12, 18, 23) | Sonnet | Saves current context to handoff.md |
| **auto-diary** | 2x/day (13, 22) | Sonnet | Daily note in memory/YYYY-MM-DD.md |
| **consolidator** | Sun 03:00 | Sonnet | Extracts patterns from daily notes → core/, decisions/ |
| **night-cleanup** | 03:30 | bash (0 tokens) | Archive, log rotation, session cleanup |

Each file contains prompt + ready JSON for `openclaw.json → crons[]`.

### Configs (config/)

| File | Where to insert | Purpose |
|------|----------------|---------|
| **compaction.json** | `agents[].compaction` | Safeguard mode + memoryFlush before compression |
| **memory-flush.json** | `compaction.memoryFlush.prompt` | Full prompt for context save |
| **memory-search.json** | `memorySearch` | Hybrid vector search (70% vector + 30% BM25) |

### Scripts (scripts/)

| Script | Purpose |
|--------|---------|
| **health-check.sh** | Check: files in place, handoff current, SQLite WAL, gateway alive |
| **consistency-check.sh** | Find conflicts between files (MEMORY.md size, duplicates) |
| **archive-old-notes.sh** | Full night cleanup: archive > 14d, delete > 90d, log rotation, session cleanup, SQLite vacuum |

---

## Installation

### Automatic

```bash
bash install.sh
```

### Manual

1. Copy templates to agent workspace:
```bash
WS="$HOME/.openclaw/agents/main/agent"  # your path
cp templates/BOOTSTRAP.md "$WS/"
cp templates/MEMORY.md "$WS/"
cp templates/DO_NOT_DELETE.md "$WS/memory/"
cp templates/handoff.md "$WS/memory/"
```

2. Create structure:
```bash
mkdir -p "$WS/memory/"{core,decisions,projects,archive/daily}
```

3. Copy scripts:
```bash
mkdir -p ~/.openclaw/scripts
cp scripts/*.sh ~/.openclaw/scripts/
chmod +x ~/.openclaw/scripts/*.sh
```

4. Allow crons to read session history:

In `~/.openclaw/openclaw.json` add to `tools` section:
```json
"tools": {
  "sessions": {
    "visibility": "agent"
  }
}
```

> ⚠️ **Without this setting Auto Handoff and Auto Diary crons cannot read main session history!** By default isolated crons only see themselves (`visibility: "tree"`). Value `"agent"` allows reading sessions of the same agent.

---

## Cron Setup

Add to `~/.openclaw/openclaw.json` → `agents` → `[your agent]` → `crons`:

```json
{
  "crons": [
    {
      "id": "auto-handoff",
      "name": "Auto Handoff",
      "schedule": "0 12,18,23 * * *",
      "sessionTarget": "isolated",
      "deleteAfterRun": true,
      "payload": {
        "kind": "agentTurn",
        "message": "Write current context to memory/handoff.md. Format: ## Topic, ## Decisions, ## TODO, ## Files, ## Context, ## Drafts. Facts only, exact paths. If nothing - NO_REPLY.",
        "model": "anthropic/claude-sonnet-4-6",
        "timeoutSeconds": 120
      },
      "delivery": { "mode": "none" }
    },
    {
      "id": "auto-diary",
      "name": "Auto Diary",
      "schedule": "0 13,22 * * *",
      "sessionTarget": "isolated",
      "deleteAfterRun": true,
      "payload": {
        "kind": "agentTurn",
        "message": "Write diary in memory/YYYY-MM-DD.md (current date). If file exists - add. Format: What happened, Decisions, Insights. Max 200 words. If nothing - NO_REPLY.",
        "model": "anthropic/claude-sonnet-4-6",
        "timeoutSeconds": 120
      },
      "delivery": { "mode": "none" }
    },
    {
      "id": "weekly-consolidator",
      "name": "Weekly Consolidator",
      "schedule": "0 3 * * 0",
      "sessionTarget": "isolated",
      "deleteAfterRun": true,
      "payload": {
        "kind": "agentTurn",
        "message": "Consolidation: read daily notes for 7 days, extract patterns, update memory/decisions/ and memory/core/. Check MEMORY.md < 3000 chars. Don't overwrite - add. If nothing - NO_REPLY.",
        "model": "anthropic/claude-sonnet-4-6",
        "timeoutSeconds": 300
      },
      "delivery": { "mode": "none" }
    }
  ]
}
```

Full prompts and details in `crons/*.md`.

---

## Config Snippets

### Compaction

Add to `agents[].compaction`:

```json
{
  "mode": "safeguard",
  "reserveTokensFloor": 25000,
  "maxHistoryShare": 0.7,
  "identifierPolicy": "strict",
  "model": "anthropic/claude-sonnet-4-6",
  "memoryFlush": {
    "enabled": true,
    "softThresholdTokens": 8000,
    "prompt": "BEFORE compaction write to memory/handoff.md: ## Topic, ## Decisions, ## TODO, ## Files, ## Context, ## Drafts. Exact paths, facts, drafts IN FULL."
  }
}
```

### Vector Search

Add to root of `openclaw.json`:

```json
{
  "memorySearch": {
    "enabled": true,
    "sources": ["memory", "sessions"],
    "experimental": { "sessionMemory": true },
    "provider": "openai",
    "model": "text-embedding-3-small",
    "query": {
      "hybrid": {
        "enabled": true,
        "vectorWeight": 0.7,
        "textWeight": 0.3
      }
    }
  }
}
```

---

## FAQ

**Why handoff if there's memory_search?**
handoff - fast restore of "what we were doing 5 minutes ago". memory_search - deep search across entire database. After compaction you need handoff.

**Can I use without vector memory?**
Yes. Base system (handoff + daily notes + MEMORY.md) works without it.

**How much do crons cost?**
~4000-7000 tokens/day on Sonnet. Less than $0.01/day.

**Which model to use in crons?**
Any light one. Examples: `anthropic/claude-sonnet-4-6`, `openai/gpt-4o-mini`, `google/gemini-2.5-flash`. Crons write summaries - powerful model not needed.

**How to migrate?**
Copy files to memory/core/, create MEMORY.md, configure crons. Details in docs/faq.md.

More questions - [docs/faq.md](docs/faq.md).

---

## Documentation

- [Architecture](docs/architecture.md) - 5 memory layers, data flows
- [How it Works](docs/how-it-works.md) - each component in detail
- [Troubleshooting](docs/troubleshooting.md) - 8 typical situations
- [FAQ](docs/faq.md) - frequently asked questions

---

## Author

**Aleksei Ulianov** - AI automation, agents, OpenClaw

- 🎬 YouTube: [@alekseiulianov](https://youtube.com/@alekseiulianov)
- 📱 Telegram: [@Sprut_AI](https://t.me/Sprut_AI)
- 💎 AI OPERATIONS (paid group): [Subscribe](https://t.me/tribute/app?startapp=sJyg)

This kit is part of a battle-tested system running 9 AI agents in production daily.

## License

MIT - do whatever you want.

---

# OpenClaw Memory Kit (Русский)

Полная система памяти и восстановления контекста для AI-агентов на OpenClaw.

Агент без памяти - как человек с амнезией. Каждая новая сессия начинается с чистого листа. Этот кит решает проблему: шаблоны файлов, кроны для автосохранения, скрипты для гигиены, конфиги для компактификации. Всё что нужно чтобы агент помнил.

## Быстрый старт

### Вариант 1: Пусть бот сделает сам (рекомендуется)

**Сначала сделай бэкап конфига:**
```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup
```

Скопируй содержимое файла [SETUP-AGENT.md](SETUP-AGENT.md) и отправь своему агенту в чат. Он выполнит все шаги автоматически - клонирует репо, установит файлы, настроит конфиг и создаст кроны.

Если после настройки бот замолчал - откатывай:
```bash
cp ~/.openclaw/openclaw.json.backup ~/.openclaw/openclaw.json
openclaw gateway start
```

### Вариант 2: Ручная установка (5 минут)

```bash
git clone https://github.com/AlekseiUL/openclaw-memory-kit.git
cd openclaw-memory-kit
bash install.sh
```

Скрипт:
1. Проверит что OpenClaw установлен
2. Спросит путь к workspace
3. Создаст структуру `memory/` (core, decisions, projects, archive)
4. Скопирует шаблоны (BOOTSTRAP.md, MEMORY.md, DO_NOT_DELETE.md, handoff.md)
5. Установит скрипты в `~/.openclaw/scripts/`
6. Покажет что дальше (какие сниппеты добавить в конфиг)

**install.sh НЕ меняет openclaw.json.** Только копирует файлы и показывает инструкции.

---

## Что работает без vectorDB

Для старта **НЕ нужен** OpenAI API ключ. 80% ценности доступно сразу.

**Работает сразу (0 зависимостей):**
- Шаблоны: BOOTSTRAP.md, MEMORY.md, handoff.md, DO_NOT_DELETE.md
- Структура memory/ (core, decisions, projects, archive)
- Кроны: auto-handoff (3x/день), auto-diary (2x/день), night-cleanup (bash)
- Компактификация с memoryFlush (запись контекста перед сжатием)
- Скрипты: health-check, consistency-check, archive-old-notes

**Требует OpenAI API ключ (для эмбеддингов):**
- memory-search.json - векторный поиск по памяти (hybrid: 70% vector + 30% BM25)
- Консолидатор работает лучше с vectorDB, но функционирует и без него

**Вывод:** начни без vectorDB. Агент будет помнить контекст через handoff, писать дневники, архивировать старое. Когда понадобится поиск по памяти трёхмесячной давности - добавь эмбеддинги.

---

## Структура репо

```
openclaw-memory-kit/
├── README.md                    # Этот файл
├── LICENSE                      # MIT
├── install.sh                   # Автоустановка
│
├── templates/                   # Готовые шаблоны
│   ├── BOOTSTRAP.md             # Старт после компактификации
│   ├── MEMORY.md                # Долгосрочная память (шаблон)
│   ├── MEMORY-example.md        # Пример заполненного MEMORY.md
│   ├── DO_NOT_DELETE.md         # Защита файлов
│   └── handoff.md               # Передача контекста
│
├── memory/                      # Структура папок памяти
│   ├── core/                    # Вечные факты
│   ├── decisions/               # Решения и правила
│   ├── projects/                # Проекты
│   └── archive/daily/           # Архив дневников
│
├── crons/                       # Промпты кронов
│   ├── auto-handoff.md          # 3x/день - сохранение контекста
│   ├── auto-diary.md            # 2x/день - дневник
│   ├── consolidator.md          # 1x/неделю - консолидация
│   └── night-cleanup.md         # 1x/ночь - уборка (0 токенов)
│
├── config/                      # Конфиг-сниппеты для openclaw.json
│   ├── compaction.json          # Компактификация (safeguard mode)
│   ├── memory-flush.json        # memoryFlush промпт
│   └── memory-search.json       # Векторный поиск (hybrid)
│
├── scripts/                     # Утилиты (bash, 0 токенов)
│   ├── health-check.sh          # Проверка здоровья системы
│   ├── consistency-check.sh     # Целостность данных
│   └── archive-old-notes.sh     # Архивация + ротация + cleanup
│
└── docs/                        # Документация
    ├── architecture.md          # Архитектура (5 слоёв памяти)
    ├── how-it-works.md          # Каждый компонент подробно
    ├── troubleshooting.md       # Решение проблем
    └── faq.md                   # Частые вопросы
```

---

## Компоненты

### Шаблоны (templates/)

| Файл | Зачем |
|------|-------|
| **BOOTSTRAP.md** | Инструкция для агента после пробуждения/компактификации. Читает handoff → daily note → sessions_history. Восстанавливает контекст. |
| **MEMORY.md** | Долгосрочная память (шаблон с подсказками). Грузится в каждую сессию. Держи < 3000 символов. |
| **MEMORY-example.md** | Пример заполненного MEMORY.md у реального агента. Скопируй структуру, замени данные. |
| **DO_NOT_DELETE.md** | Список файлов которые агент НЕ должен удалять. Защита от случайной чистки. |
| **handoff.md** | Передача контекста между сессиями. Формат: Тема, Решения, TODO, Файлы, Контекст, Черновики. |

### Кроны (crons/)

| Крон | Расписание | Модель | Зачем |
|------|------------|--------|-------|
| **auto-handoff** | 3x/день (12, 18, 23) | Sonnet | Сохраняет текущий контекст в handoff.md |
| **auto-diary** | 2x/день (13, 22) | Sonnet | Дневник дня в memory/YYYY-MM-DD.md |
| **consolidator** | Вс 03:00 | Sonnet | Извлекает паттерны из daily notes → core/, decisions/ |
| **night-cleanup** | 03:30 | bash (0 токенов) | Архивация, ротация логов, чистка сессий |

Каждый файл содержит промпт + готовый JSON для `openclaw.json → crons[]`.

### Конфиги (config/)

| Файл | Куда вставлять | Зачем |
|------|----------------|-------|
| **compaction.json** | `agents[].compaction` | Safeguard mode + memoryFlush перед сжатием |
| **memory-flush.json** | `compaction.memoryFlush.prompt` | Полный промпт для записи контекста |
| **memory-search.json** | `memorySearch` | Hybrid vector search (70% vector + 30% BM25) |

### Скрипты (scripts/)

| Скрипт | Зачем |
|--------|-------|
| **health-check.sh** | Проверка: файлы на месте, handoff актуален, SQLite WAL, gateway жив |
| **consistency-check.sh** | Поиск противоречий между файлами (размер MEMORY.md, дубликаты) |
| **archive-old-notes.sh** | Полная ночная уборка: архивация > 14д, удаление > 90д, ротация логов, чистка сессий, SQLite vacuum |

---

## Установка

### Автоматическая

```bash
bash install.sh
```

### Ручная

1. Скопируй шаблоны в workspace агента:
```bash
WS="$HOME/.openclaw/agents/main/agent"  # ваш путь
cp templates/BOOTSTRAP.md "$WS/"
cp templates/MEMORY.md "$WS/"
cp templates/DO_NOT_DELETE.md "$WS/memory/"
cp templates/handoff.md "$WS/memory/"
```

2. Создай структуру:
```bash
mkdir -p "$WS/memory/"{core,decisions,projects,archive/daily}
```

3. Скопируй скрипты:
```bash
mkdir -p ~/.openclaw/scripts
cp scripts/*.sh ~/.openclaw/scripts/
chmod +x ~/.openclaw/scripts/*.sh
```

4. Разреши кронам читать историю сессии:

В `~/.openclaw/openclaw.json` добавь в секцию `tools`:
```json
"tools": {
  "sessions": {
    "visibility": "agent"
  }
}
```

> ⚠️ **Без этой настройки кроны Auto Handoff и Auto Diary не смогут читать историю основной сессии!** По умолчанию isolated кроны видят только себя (`visibility: "tree"`). Значение `"agent"` разрешает читать сессии того же агента.

---

## Настройка кронов

Добавь в `~/.openclaw/openclaw.json` → `agents` → `[ваш агент]` → `crons`:

```json
{
  "crons": [
    {
      "id": "auto-handoff",
      "name": "Auto Handoff",
      "schedule": "0 12,18,23 * * *",
      "sessionTarget": "isolated",
      "deleteAfterRun": true,
      "payload": {
        "kind": "agentTurn",
        "message": "Запиши текущий контекст в memory/handoff.md. Формат: ## Тема, ## Решения, ## TODO, ## Файлы, ## Контекст, ## Черновики. Только факты, точные пути. Если ничего - NO_REPLY.",
        "model": "anthropic/claude-sonnet-4-6",
        "timeoutSeconds": 120
      },
      "delivery": { "mode": "none" }
    },
    {
      "id": "auto-diary",
      "name": "Auto Diary",
      "schedule": "0 13,22 * * *",
      "sessionTarget": "isolated",
      "deleteAfterRun": true,
      "payload": {
        "kind": "agentTurn",
        "message": "Напиши дневник в memory/YYYY-MM-DD.md (текущая дата). Если файл есть - дополни. Формат: Что было, Решения, Инсайты. Max 200 слов. Если ничего - NO_REPLY.",
        "model": "anthropic/claude-sonnet-4-6",
        "timeoutSeconds": 120
      },
      "delivery": { "mode": "none" }
    },
    {
      "id": "weekly-consolidator",
      "name": "Weekly Consolidator",
      "schedule": "0 3 * * 0",
      "sessionTarget": "isolated",
      "deleteAfterRun": true,
      "payload": {
        "kind": "agentTurn",
        "message": "Консолидация: прочитай daily notes за 7 дней, извлеки паттерны, обнови memory/decisions/ и memory/core/. Проверь MEMORY.md < 3000 символов. Не перезаписывай - дополняй. Если ничего - NO_REPLY.",
        "model": "anthropic/claude-sonnet-4-6",
        "timeoutSeconds": 300
      },
      "delivery": { "mode": "none" }
    }
  ]
}
```

Полные промпты и детали - в `crons/*.md`.

---

## Конфиг-сниппеты

### Компактификация

Добавь в `agents[].compaction`:

```json
{
  "mode": "safeguard",
  "reserveTokensFloor": 25000,
  "maxHistoryShare": 0.7,
  "identifierPolicy": "strict",
  "model": "anthropic/claude-sonnet-4-6",
  "memoryFlush": {
    "enabled": true,
    "softThresholdTokens": 8000,
    "prompt": "ПЕРЕД компактификацией запиши в memory/handoff.md: ## Тема, ## Решения, ## TODO, ## Файлы, ## Контекст, ## Черновики. Точные пути, факты, черновики ЦЕЛИКОМ."
  }
}
```

### Векторный поиск

Добавь в корень `openclaw.json`:

```json
{
  "memorySearch": {
    "enabled": true,
    "sources": ["memory", "sessions"],
    "experimental": { "sessionMemory": true },
    "provider": "openai",
    "model": "text-embedding-3-small",
    "query": {
      "hybrid": {
        "enabled": true,
        "vectorWeight": 0.7,
        "textWeight": 0.3
      }
    }
  }
}
```

---

## FAQ

**Зачем handoff если есть memory_search?**
handoff - быстрый restore "чем занимались 5 минут назад". memory_search - глубокий поиск по всей базе. После компактификации нужен handoff.

**Можно без векторной памяти?**
Да. Базовая система (handoff + daily notes + MEMORY.md) работает без неё.

**Сколько жрут кроны?**
~4000-7000 токенов/день на Sonnet. Меньше $0.01/день.

**Какую модель использовать в кронах?**
Любую лёгкую. Примеры: `anthropic/claude-sonnet-4-6`, `openai/gpt-4o-mini`, `google/gemini-2.5-flash`. Кроны пишут summary - мощная модель не нужна.

**Как мигрировать?**
Скопируй файлы в memory/core/, создай MEMORY.md, настрой кроны. Подробнее - docs/faq.md.

Больше вопросов - [docs/faq.md](docs/faq.md).

---

## Документация

- [Архитектура](docs/architecture.md) - 5 слоёв памяти, потоки данных
- [Как работает](docs/how-it-works.md) - каждый компонент подробно
- [Решение проблем](docs/troubleshooting.md) - 8 типичных ситуаций
- [FAQ](docs/faq.md) - частые вопросы

---

## Автор

**Алексей Ульянов** - AI-автоматизация, агенты, OpenClaw

- 🎬 YouTube: [@alekseiulianov](https://youtube.com/@alekseiulianov)
- 📱 Telegram: [@Sprut_AI](https://t.me/Sprut_AI)
- 💎 AI ОПЕРАЦИОНКА (платная группа): [Подписка](https://t.me/tribute/app?startapp=sJyg)

Этот кит - часть боевой системы из 9 AI-агентов. Работает в продакшне каждый день.

## Лицензия

MIT - делай что хочешь.

---

## Resources | Ресурсы

- 📺 YouTube: [youtube.com/@alekseiulianov](https://youtube.com/@alekseiulianov)
- 📱 Telegram: [t.me/Sprut_AI](https://t.me/Sprut_AI)
- 🔥 AI ОПЕРАЦИОНКА (Premium): [Подписка](https://t.me/tribute/app?startapp=sJyg) — продвинутые материалы, скиллы, агенты, поддержка
- 💻 GitHub: [github.com/AlekseiUL](https://github.com/AlekseiUL)

## License

MIT

---

*Making AI agents remember since 2026 | Делаю AI-агентов с памятью с 2026*
