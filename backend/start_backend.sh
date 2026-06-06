#!/bin/bash
set -e
cd "$(dirname "$0")"

PYTHON="/usr/local/bin/python3.12"
if [ ! -f "$PYTHON" ]; then
  PYTHON="$(brew --prefix python@3.12 2>/dev/null)/bin/python3.12"
fi
if [ ! -f "$PYTHON" ]; then
  echo "Python 3.12 not found. Install with: brew install python@3.12"
  exit 1
fi
echo "Using $PYTHON"

# Create venv if needed
if [ ! -d ".venv" ]; then
  echo "Creating virtual environment..."
  $PYTHON -m venv .venv
fi
source .venv/bin/activate

# Install deps
pip install -q -r requirements.txt

# Generate .env if missing
if [ ! -f ".env" ]; then
  echo "Generating .env secrets..."
  FACE_KEY=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
  JWT_KEY=$(python -c "import secrets; print(secrets.token_hex(32))")
  cat > .env << EOF
FACE_ENCRYPTION_KEY=$FACE_KEY
JWT_SECRET=$JWT_KEY
REDIS_URL=redis://localhost:6379
EOF
  echo ".env created"
fi

# Start Redis if not running (requires brew redis)
if ! redis-cli ping &>/dev/null; then
  echo "Starting Redis..."
  brew services start redis 2>/dev/null || redis-server --daemonize yes
  sleep 1
fi

echo ""
echo "✅ AdaptAttend backend starting on http://localhost:8000"
echo "   Docs: http://localhost:8000/docs"
echo ""
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
