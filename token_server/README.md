# WTF Agora Token Server

Mints **Agora RTC tokens** for the Flutter apps. Channels are created implicitly when the first peer joins, so `/room` simply validates and echoes the channel name.

## Run locally

```bash
cp .env.example .env   # fill AGORA_APP_ID, AGORA_APP_CERTIFICATE
npm install
npm start              # listens on 0.0.0.0:3000
```

## Endpoints

| Method | Path | Params | Returns |
|--------|------|--------|---------|
| GET | `/token` | `userId`, `role` (`member`\|`trainer`), `roomId` (channel) | `{ "token", "appId", "uid" }` |
| POST | `/room` | body `{ "name": "call-<requestId>" }` | `{ "roomId": "<name>" }` |
| GET | `/health` | — | `{ "ok": true }` |

Fixed uids: `member_dk` → 1, `trainer_aarav` → 2 (both join as PUBLISHER).

## Smoke test

```bash
curl 'http://localhost:3000/health'
curl 'http://localhost:3000/token?userId=member_dk&role=member&roomId=call-test'
curl -X POST http://localhost:3000/room -H 'Content-Type: application/json' -d '{"name":"call-test"}'
```

## Notes

- Android emulator reaches this server at `http://10.0.2.2:3000`; real devices use your Mac's LAN IP (pass `--dart-define=TOKEN_URL=http://<lan-ip>:3000` to `flutter run`).
- Secrets live only in `.env` (gitignored). The App Certificate never leaves the server.
