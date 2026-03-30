# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Structure

- **`app/`** — macOS SwiftUI dictation app. See `app/CLAUDE.md` for build commands and architecture.
- **`backend/`** — Go gateway + Docker Compose stack that exposes the Whisper transcription API on `http://localhost:8080`.

## Running the backend

```bash
cd backend
docker compose up -d gateway whisper-large
```

The gateway proxies requests to a Faster Whisper container. Available models: `small`, `medium`, `large` (configured via `DEFAULT_MODEL` env var in `docker-compose.yml`).

## API

See `backend/API.md` for full endpoint reference. Key endpoints:

- `GET  /health` — gateway liveness check
- `GET  /v1/models` — list models and availability
- `POST /v1/audio/transcriptions` — file upload transcription
- `WS   /v1/audio/stream` — real-time PCM streaming (used by the app)
