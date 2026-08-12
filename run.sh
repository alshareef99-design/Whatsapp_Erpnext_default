#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT/official-frappe-docker"

SITE="${SITE:-frontend}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
APP_URL="https://github.com/shridarpatil/frappe_whatsapp"
SERVICES=(backend queue-long queue-short scheduler websocket)

echo "==> Pulling official Frappe/ERPNext image..."
docker compose -f pwd.yml pull

echo "==> Starting ERPNext stack..."
docker compose -f pwd.yml up -d

echo "==> Waiting for site ${SITE}..."
for i in $(seq 1 40); do
  if docker compose -f pwd.yml exec -T backend test -f "sites/${SITE}/site_config.json" 2>/dev/null; then
    echo "Site ready."
    break
  fi
  sleep 10
done

if ! docker compose -f pwd.yml exec -T backend test -f "sites/${SITE}/site_config.json" 2>/dev/null; then
  echo "Site creation failed. Logs:"
  docker compose -f pwd.yml logs create-site | tail -30
  exit 1
fi

echo "==> Installing frappe_whatsapp in all containers..."
for svc in "${SERVICES[@]}"; do
  echo "  -> ${svc}"
  docker compose -f pwd.yml exec -T "$svc" bench get-app --skip-assets "$APP_URL"
done

echo "==> Activating frappe_whatsapp on site ${SITE}..."
docker compose -f pwd.yml exec -T backend bench --site "${SITE}" install-app frappe_whatsapp
docker compose -f pwd.yml exec -T backend bench --site "${SITE}" migrate
docker compose -f pwd.yml exec -T backend bench --site "${SITE}" set-config developer_mode 1
docker compose -f pwd.yml exec -T backend bench build --app frappe_whatsapp
docker compose -f pwd.yml restart backend queue-long queue-short scheduler websocket frontend

echo ""
echo "Frappe WhatsApp is running."
echo "  Desk:    http://localhost:8080"
echo "  Login:   Administrator / ${ADMIN_PASSWORD}"
echo "  Site:    ${SITE}"
echo "  Webhook: http://localhost:8080/api/method/frappe_whatsapp.utils.webhook.webhook"
