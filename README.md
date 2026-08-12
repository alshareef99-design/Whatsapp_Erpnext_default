# Frappe WhatsApp (Docker)

Run [frappe_whatsapp](https://github.com/shridarpatil/frappe_whatsapp) locally with Docker.

## Prerequisites

- [Docker Desktop](https://docs.docker.com/get-docker/) running
- ~4 GB free disk for images

## Quick start

```bash
chmod +x run.sh frappe-docker/bench-docker
./run.sh
```

This will:

1. Pull `shridh0r/frappe:develop` (maintainer image from [frappe-docker](https://github.com/shridarpatil/frappe-docker))
2. Start MariaDB 10.6, Redis, workers, and the Frappe web app
3. Clone/install `frappe_whatsapp` from `./frappe-docker/apps/frappe_whatsapp`
4. Create site `whatsapp.local` and install the app

## Access

| Service | URL |
|---------|-----|
| Frappe Desk / API | http://localhost:8000 |
| Login | `Administrator` / `admin` |
| WhatsApp webhook | http://localhost:8000/api/method/frappe_whatsapp.utils.webhook.webhook |

Configure your Meta WhatsApp webhook to point at the webhook URL (use ngrok or similar for HTTPS in production).

## Useful commands

From `frappe-docker/`:

```bash
./bench-docker logs          # follow web-app logs
./bench-docker shell         # bash inside web-app container
./bench-docker down          # stop stack
./bench-docker bench --site whatsapp.local migrate
```

Environment overrides for `run.sh`:

```bash
SITE=my.site.local ADMIN_PASSWORD=secret ./run.sh
```

## Project layout

```
.
├── run.sh                 # one-command setup
├── frappe-docker/         # shridarpatil/frappe-docker stack
│   ├── apps/frappe_whatsapp/
│   └── sites/apps.txt
└── official-frappe-docker/  # official frappe_docker (optional production path)
    └── apps.json          # custom image recipe with ERPNext + frappe_whatsapp
```

## Production / custom image (optional)

For multi-container production, bake the app into the image using [official frappe_docker custom apps](https://github.com/frappe/frappe_docker/blob/main/docs/custom-apps.md):

```bash
cd official-frappe-docker
export APPS_JSON_BASE64=$(base64 -i apps.json | tr -d '\n')
docker build \
  --build-arg=FRAPPE_BRANCH=version-16 \
  --build-arg=APPS_JSON_BASE64="$APPS_JSON_BASE64" \
  --tag=frappe-whatsapp:16 \
  --file=images/layered/Containerfile .
```

Or use the maintainer's pre-built image that includes the app:

```bash
docker build -t frappe-whatsapp \
  https://github.com/shridarpatil/frappe_whatsapp.git
```

## Troubleshooting

**Docker I/O error** (`input/output error` on container restart): restart Docker Desktop, then run `./run.sh` again. If it persists, Docker Desktop → Troubleshoot → Clean / Purge data (removes all local containers).

**Site creation fails on Apple Silicon**: the `shridh0r/frappe:develop` image is `linux/amd64` and runs under emulation. MariaDB 12 is incompatible — this setup pins `mariadb:10.6` via `.env`.

**Port 8000 in use**: stop other Frappe containers (`docker ps`) or change the port in `frappe-docker/docker-compose.yml`.

**Reset and retry** (destructive):

```bash
cd frappe-docker
./bench-docker down
rm -rf data/mysql sites/whatsapp.local sites/site1.local
./bench-docker up --workers
# then re-run site creation from run.sh or manually
```

## Next steps (WhatsApp setup)

1. Create a [Meta WhatsApp Business API](https://developers.facebook.com/docs/whatsapp/cloud-api/get-started) app
2. In Frappe Desk → **WhatsApp Account**, enter token, phone ID, business ID, app ID, webhook verify token
3. Subscribe webhook fields: `messages`, `message_template_status_update`

See [frappe_whatsapp docs](https://shridarpatil.github.io/frappe_whatsapp/).
