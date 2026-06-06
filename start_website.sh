#!/bin/bash
set -e
cd "$(dirname "$0")/frontend"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   AdaptAttend — Marketing Website    ║"
echo "╚══════════════════════════════════════╝"
echo ""

echo "▶ Installing packages..."
npm install --legacy-peer-deps 2>&1 | tail -5

echo ""
echo "▶ Starting Next.js on http://localhost:3000 ..."
echo "  ℹ  EmailJS: fill in your IDs in app/page.tsx → ContactSection"
echo ""
npm run dev
