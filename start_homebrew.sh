#!/bin/bash
set -e
cd "$(dirname "$0")"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Adaptive Attendance System - Startup   ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Install Python 3.12 if needed ─────────────────────────────────────────
echo "▶ Checking Python 3.12..."
if ! command -v python3.12 &>/dev/null; then
  echo "  Installing Python 3.12 via Homebrew..."
  brew install python@3.12 -q
fi
PYTHON=$(command -v python3.12 || echo /opt/homebrew/bin/python3.12)
echo "  Using: $PYTHON ($($PYTHON --version))"

# ── 2. PostgreSQL ─────────────────────────────────────────────────────────────
echo ""
echo "▶ Setting up PostgreSQL..."
if ! brew list postgresql@16 &>/dev/null; then
  brew install postgresql@16 -q
fi
brew services start postgresql@16 2>/dev/null || true
sleep 3

PG=/opt/homebrew/opt/postgresql@16/bin
$PG/createdb attendance_db 2>/dev/null || true
$PG/psql -d attendance_db -c "CREATE USER attendance WITH PASSWORD 'attendance_secret';" 2>/dev/null || true
$PG/psql -d attendance_db -c "GRANT ALL PRIVILEGES ON DATABASE attendance_db TO attendance;" 2>/dev/null || true
$PG/psql -d attendance_db -c "ALTER DATABASE attendance_db OWNER TO attendance;" 2>/dev/null || true
$PG/psql -d attendance_db -c "GRANT ALL ON SCHEMA public TO attendance;" 2>/dev/null || true
echo "  PostgreSQL ready ✓"

# ── 3. Redis ──────────────────────────────────────────────────────────────────
echo ""
echo "▶ Setting up Redis..."
if ! brew list redis &>/dev/null; then brew install redis -q; fi
brew services start redis 2>/dev/null || true
echo "  Redis ready ✓"

# ── 4. Python venv with Python 3.12 ──────────────────────────────────────────
echo ""
echo "▶ Setting up Python 3.12 virtual environment..."
cd backend

# Remove old venv if it was created with Python 3.13
if [ -d ".venv" ]; then
  VENV_PY=$(.venv/bin/python --version 2>&1 | grep -o "3\.[0-9]*")
  if [ "$VENV_PY" != "3.12" ]; then
    echo "  Removing old venv (was $VENV_PY, need 3.12)..."
    rm -rf .venv
  fi
fi

if [ ! -d ".venv" ]; then
  $PYTHON -m venv .venv
  echo "  Virtual environment created with Python 3.12 ✓"
fi

source .venv/bin/activate
echo "  Active Python: $(python --version)"

echo ""
echo "▶ Installing Python packages (takes 3-5 min on first run)..."
pip install -q --upgrade pip setuptools wheel
pip install -r requirements.txt
echo "  Python packages installed ✓"

# ── 5. Generate .env ──────────────────────────────────────────────────────────
if [ ! -f ".env" ]; then
  echo ""
  echo "▶ Generating .env..."
  cp .env.example .env
  JWT_SECRET=$(python -c "import secrets; print(secrets.token_hex(32))")
  FERNET_KEY=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
  sed -i '' "s/replace_with_a_random_64_char_hex_string/$JWT_SECRET/" .env
  sed -i '' "s|replace_with_fernet_key|$FERNET_KEY|" .env
  echo "  .env created ✓"
fi

# ── 6. Migrations ─────────────────────────────────────────────────────────────
echo ""
echo "▶ Running database migrations..."
alembic upgrade head
echo "  Migrations done ✓"

# ── 7. Start FastAPI ──────────────────────────────────────────────────────────
echo ""
echo "▶ Starting API server on http://localhost:8000 ..."
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload &
API_PID=$!
sleep 5

# ── 8. Seed demo data ─────────────────────────────────────────────────────────
echo ""
echo "▶ Seeding 30 days of demo attendance data..."
python seed.py --all 2>/dev/null && echo "  Demo data seeded ✓" || echo "  (seed skipped)"

# ── 9. Next.js ────────────────────────────────────────────────────────────────
echo ""
cd ../frontend
echo "▶ Installing frontend packages..."
npm install --legacy-peer-deps 2>/dev/null | tail -3

echo ""
echo "▶ Starting Next.js on http://localhost:3000 ..."
npm run dev &
FRONTEND_PID=$!

sleep 6
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  ✅ All services started!                ║"
echo "║                                          ║"
echo "║  🌐 Website:   http://localhost:3000     ║"
echo "║  📖 API docs:  http://localhost:8000/docs║"
echo "║                                          ║"
echo "║  Demo key:  AAS-DEMO-DEMO-0001           ║"
echo "║  Mgr login: admin / Admin@1234           ║"
echo "║  Mgr key:   MGR-DEMO-DEMO-0001           ║"
echo "║  Emp login: employee1 / Demo@1234        ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Open http://localhost:3000 in your browser."
echo "Press Ctrl+C to stop all services."

trap "echo ''; echo 'Stopping...'; kill $API_PID $FRONTEND_PID 2>/dev/null; brew services stop redis; exit 0" INT TERM
wait
