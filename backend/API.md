# API Reference

Base URL: `http://localhost:8080`

---

## Endpoints

### `GET /health`

Returns gateway status.

**Response**
```json
{ "status": "ok" }
```

---

### `GET /v1/models`

Returns available models and their availability status.

**Response**
```json
{
  "providers": [
    {
      "id": "whisper",
      "name": "Faster Whisper",
      "models": [
        {
          "id": "small",
          "name": "Small",
          "description": "fast, good for everyday dictation",
          "available": true
        },
        {
          "id": "medium",
          "name": "Medium",
          "description": "slower, handles accents and background noise better",
          "available": false
        }
      ]
    }
  ]
}
```

---

### `POST /v1/audio/transcriptions`

Transcribe an audio file.

**Request**

`Content-Type: multipart/form-data`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | Binary | Yes | Audio file (M4A, MP3, WAV, etc.) |
| `model` | String | No | Model ID (e.g. `small`, `medium`). Uses `DEFAULT_MODEL` if omitted. |
| `language` | String | No | Language code (e.g. `en`, `fr`). Auto-detected if omitted. |

**Query Parameters**

| Param | Description |
|-------|-------------|
| `enhance` | Set to `true` to enable LLM post-processing (requires LLM backend) |

**Response**
```json
{ "text": "transcribed text here" }
```

**Response Headers**

| Header | Description |
|--------|-------------|
| `X-Diction-Whisper-Ms` | Time taken by Whisper in milliseconds |
| `X-Diction-LLM-Ms` | Time taken by LLM enhancement in milliseconds (if enabled) |

**Errors**

| Status | Description |
|--------|-------------|
| `400` | Malformed request or no backend available |
| `413` | Audio exceeds max body size (default 200MB) |
| `500` | Transcription failed |

---

### `WS /v1/audio/stream`

Stream raw PCM audio and receive a transcription when done.

**URL**
```
ws://localhost:8080/v1/audio/stream?language=en
```

**Query Parameters**

| Param | Description |
|-------|-------------|
| `language` | Optional language code |
| `enhance` | Set to `true` for LLM post-processing |

**Audio Format**

PCM, 16-bit little-endian, mono, 16 kHz.

**Protocol**

1. Send binary frames of PCM audio data
2. Send a text frame to signal completion:
```json
{ "action": "done" }
```
3. Receive transcription:
```json
{ "text": "transcribed text here" }
```

**Close Codes**

| Code | Description |
|------|-------------|
| `1000` | Success |
| `4001` | Backend unavailable |
| `4002` | Transcription failed |
| `4003` | Audio too large |
| `4004` | No audio received before done |
