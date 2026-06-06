#!/bin/bash
# AdaptAttend — one-shot publish script
# Run from the project root: bash publish.sh
set -e
cd "$(dirname "$0")"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   AdaptAttend — Publish to GitHub    ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 1. Clean up any stale git lock ────────────────────────────────────────────
if [ -f .git/index.lock ]; then
  echo "🧹  Removing stale .git/index.lock..."
  rm -f .git/index.lock
fi

# ── 2. Rename branch to main ──────────────────────────────────────────────────
git branch -m master main 2>/dev/null || true

# ── 3. Stage everything (respects .gitignore) ─────────────────────────────────
echo "📦  Staging files..."
git add .

# Force-remove any secrets that slipped in before .gitignore was finalized
git rm --cached backend/.env backend/.env.example 2>/dev/null || true

# Confirm no secrets staged
if git diff --cached --name-only | grep -q "backend/.env$"; then
  echo "⛔  backend/.env is still staged — aborting."
  exit 1
fi

echo "✅  $(git diff --cached --name-only | wc -l | tr -d ' ') files staged (backend/.env excluded)"

# ── 4. Commit ─────────────────────────────────────────────────────────────────
echo "💾  Committing..."
git commit -m "feat: initial release — AdaptAttend v1.0

Flutter-only offline attendance system
- 6-digit TOTP, QR scan, GPS geo-fence, manager face scan
- On-device LBP face recognition (Google ML Kit + Dart image pkg)
- Drift SQLite, SharedPreferences, fully offline
- Next.js marketing website (adaptattend.vercel.app)"

# ── 5. Add remote and push ────────────────────────────────────────────────────
echo ""
echo "🚀  Pushing to GitHub..."
REMOTE="https://github.com/itsmittalharshit/adaptattend.git"

if git remote get-url origin &>/dev/null; then
  git remote set-url origin "$REMOTE"
else
  git remote add origin "$REMOTE"
fi

git push -u origin main

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅  GitHub: https://github.com/itsmittalharshit/adaptattend ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── 6. Deploy website to Vercel ───────────────────────────────────────────────
echo "🌐  Deploying website to Vercel..."
cd frontend

# Deploy via npx (no global install needed)
npx vercel@latest --prod --yes --name adaptattend

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅  Website live — check output above for your Vercel URL   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Done! 🎉"
