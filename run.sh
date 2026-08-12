#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT/frappe-docker"

SITE="${SITE:-whatsapp.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-root}"

echo "==> Pulling Frappe Docker image..."
docker pull shridh0r/frappe:develop

echo "==> Starting Frappe stack (MariaDB 10.6 + workers)..."
export DB_IMAGE=mariadb:10.6
./bench-docker up --workers

echo "==> Waiting for services..."
sleep 25

if [ ! -f "./sites/${SITE}/site_config.json" ]; then
  echo "==> Creating site ${SITE}..."
  docker compose exec -T web-app bench new-site "${SITE}" \
    --force \
    --admin-password "${ADMIN_PASSWORD}" \
    --db-root-password "${DB_ROOT_PASSWORD}" \
    --mariadb-user-host-login-scope='%' \
    --install-app frappe
fi

echo "==> Installing frappe_whatsapp on ${SITE}..."
docker compose exec -T web-app bench --site "${SITE}" install-app frappe_whatsapp
docker compose exec -T web-app bench --site "${SITE}" migrate
docker compose exec -T web-app bench --site "${SITE}" set-config developer_mode 1
docker compose exec -T web-app bench --site "${SITE}" set-default "${SITE}"
docker compose exec -T web-app bench build --app frappe_whatsapp
./bench-docker fix-db-permissions "${SITE}" || true
./bench-docker restart --workers

echo ""
echo "Frappe WhatsApp is running."
echo "  Desk/API: http://localhost:8000"
echo "  Nginx:    http://localhost (if nginx container is healthy)"
echo "  Login:    Administrator / ${ADMIN_PASSWORD}"
echo "  Site:     ${SITE}"
echo "  Webhook:  http://localhost:8000/api/method/frappe_whatsapp.utils.webhook.webhook"
echo ""
echo "Commands (from frappe-docker/):"
echo "  ./bench-docker logs"
echo "  ./bench-docker shell"
echo "  ./bench-docker down"
