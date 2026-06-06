#!/bin/bash
set -e
cd "$(dirname "$0")"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   Adaptive Attendance System - Startup   ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. Start Docker services
echo "▶ Starting PostgreSQL + Redis via Docker..."
docker compose up -d
echo "  Waiting for DB to be healthy..."
sleep 5

# 2. Setup Python env if needed
echo ""
echo "▶ Checking Python environment..."
cd backend
if [ ! -d ".venv" ]; then
  echo "  Creating virtualenv..."
  python3 -m venv .venv
fi

source .venv/bin/activate

echo "  Installing dependencies (first run may take a few minutes)..."
pip install -r requirements.txt -q --break-system-packages 2>/dev/null || pip install -r requirements.txt -q

# 3. Set up .env if missing
if [ ! -f ".env" ]; then
  echo ""
  echo "  Generating .env from template..."
  cp .env.example .env
  # Generate secrets automatically
  JWT_SECRET=$(python3 -c "import secrets; print(secrets.token_hex(32))")
  FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
  # Replace in .env
  sed -i '' "s/change-me-to-a-random-secret-string/$JWT_SECRET/" .env 2>/dev/null || sed -i "s/change-me-to-a-random-secret-string/$JWT_SECRET/" .env
  sed -i '' "s|<your-fernet-key>|$FERNET_KEY|" .env 2>/dev/null || sed -i "s|<your-fernet-key>|$FERNET_KEY|" .env
  echo "  .env created with auto-generated secrets"
fi

# 4. Run migrations
echo ""
echo "▶ Running database migrations..."
alembic upgrade head

# 5. Start API server in background
echo ""
echo "▶ Starting FastAPI server on http://localhost:8000 ..."
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload &
API_PID=$!
echo "  API PID: $API_PID"

sleep 3

# 6. Seed demo data
echo ""
echo "▶ Seeding demo attendance data..."
python seed.py --all 2>/dev/null || echo "  (seed skipped — may need data already)"

# 7. Start Next.js frontend
echo ""
echo "▶ Starting Next.js frontend on http://localhost:3000 ..."
cd ../frontend
npm install --legacy-peer-deps -q
npm run dev &
FRONTEND_PID=$!
echo "  Frontend PID: $FRONTEND_PID"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  ✅ All services started!                ║"
echo "║                                          ║"
echo "║  Website:  http://localhost:3000         ║"
echo "║  API docs: http://localhost:8000/docs    ║"
echo "║                                          ║"
echo "║  Demo key:  AAS-DEMO-DEMO-0001           ║"
echo "║  Mgr key:   MGR-DEMO-DEMO-0001           ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Press Ctrl+C to stop all services."
wait
