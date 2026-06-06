#!/bin/bash
set -e
cd "$(dirname "$0")/backend"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   AdaptAttend — FastAPI Microservice     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Python 3.12
if ! command -v python3.12 &>/dev/null; then
  echo "▶ Installing Python 3.12..."
  brew install python@3.12 -q
fi
PYTHON=$(command -v python3.12 || echo /opt/homebrew/bin/python3.12)

# Redis
echo "▶ Starting Redis..."
brew services start redis 2>/dev/null || true

# Venv
if [ ! -d ".venv" ] || [ "$(.venv/bin/python --version 2>&1 | grep -o '3\.[0-9]*')" != "3.12" ]; then
  echo "▶ Creating Python 3.12 venv..."
  rm -rf .venv
  $PYTHON -m venv .venv
fi
source .venv/bin/activate

echo "▶ Installing packages (first run takes 3-5 min)..."
pip install -q --upgrade pip
pip install -r requirements.txt

# Generate .env
if [ ! -f ".env" ]; then
  cp .env.example .env
  JWT=$(python -c "import secrets; print(secrets.token_hex(32))")
  FERNET=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
  sed -i '' "s/replace_with_random_hex/$JWT/" .env
  sed -i '' "s/replace_with_fernet_key/$FERNET/" .env
  echo "▶ .env created ✓"
fi

echo ""
echo "▶ Starting API on http://localhost:8000 ..."
echo "  Docs: http://localhost:8000/docs"
echo ""
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
