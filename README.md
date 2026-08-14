# 🦇 CloudRun — Proxy Reverso dinámico (Google Cloud Run)

Nginx que rutea el tráfico según el header HTTP **`Backend: svN`**.
Diseñado para túneles HTTP Custom / VPN: el cliente conecta a un dominio de
Google (ej: `www.googletagmanager.com`), el tráfico llega al Cloud Run, y
nginx lo reenvía al backend que elijas con el header.

## 🚀 Deploy en Cloud Run

```bash
# 1. Build + push (con Google Cloud SDK)
gcloud builds submit --tag gcr.io/TU-PROYECTO/cloudrun-proxy

# 2. Deploy — APUNTÁ PROXY_TARGETS A TU VPS
gcloud run deploy cloudrun-proxy \
    --image gcr.io/TU-PROYECTO/cloudrun-proxy \
    --platform managed \
    --region us-east1 \
    --allow-unauthenticated \
    --set-env-vars "PROXY_TARGETS=TU-IP-DEL-VPS:80" \
    --port 8080
```

> ⚠️ **Importante:** `--port 8080` o el que uses — Cloud Run inyecta la variable
> `PORT` y el contenedor escucha en `$PORT` (default `8080`).

## 🔀 Cómo rutea

| Header enviado | Backend usado |
|----------------|---------------|
| `Backend: sv1` | `PROXY_TARGETS[0]` (el primero) |
| `Backend: sv2` | `PROXY_TARGETS[1]` |
| (sin header) | `PROXY_TARGETS[0]` (default) |

## 📱 Ejemplo de payload (HTTP Custom)

```
GET / HTTP/1.1
Host: TU-CLOUDRUN.run.app        ← tu dominio .run.app
Backend: sv1                      ← elige el backend
Connection: Upgrade
Upgrade: Websocket

```

**Host del payload:** el dominio `.run.app` de tu Cloud Run.
**Host de conexión:** un dominio de Google (ej: `www.googletagmanager.com:80`) con SNI igual.

## ⚙️ Variables de entorno

| Variable | Obligatorio | Descripción |
|----------|-------------|-------------|
| `PROXY_TARGETS` | ✅ | Backends separados por coma, `IP:puerto`. El primero es el default |
| `PORT` | ❌ | Puerto de escucha (Cloud Run lo inyecta; default `8080`) |
