# WTF — Guru ↔ Trainer Chat + Video Call System

Two Flutter apps that work together locally: **Guru App** (Member "DK", blue) and **Trainer App** ("Aarav", red). Real-time chat and scheduling sync via Cloud Firestore; video calls via **Agora** (pivot from 100ms — see `DECISIONS.md` ADR #3) with a local Node token server.

| | |
|---|---|
| 📄 Architecture | [ARCHITECTURE.md](ARCHITECTURE.md) |
| 📄 ADRs (state mgmt, storage, RTC) | [DECISIONS.md](DECISIONS.md) |
| 🤖 AI-native evidence | [AI_LEDGER.md](AI_LEDGER.md) |

## Prerequisites

- Flutter ≥ 3.35 (built on 3.41.1), Node ≥ 18 (built on 26)
- Android emulator or device (two of them to demo both sides)
- Firebase project + Agora project credentials (see below)

## 1. Token server (required for calls)

```bash
cd token_server
cp .env.example .env    # fill AGORA_APP_ID + AGORA_APP_CERTIFICATE from console.agora.io
npm install && npm start
```

Smoke test: `curl 'localhost:3000/token?userId=member_dk&role=member&roomId=x'` → `{token, appId, uid}`.

## 2. Firebase

The repo ships `firebase.json`, `.firebaserc`, `firestore.rules`, `firestore.indexes.json` for project `wtf-guru-trainer`. To use your own project:

```bash
firebase projects:create <your-id>
firebase apps:create ANDROID guru --package-name=com.wtf.guru --project <your-id>
firebase apps:create ANDROID trainer --package-name=com.wtf.trainer --project <your-id>
# put each google-services.json into <app>/android/app/
firebase firestore:databases:create "(default)" --location=asia-south1 --project <your-id>
firebase deploy --only firestore --project <your-id>
```

`google-services.json` files are **gitignored** — drop them into `guru_app/android/app/` and `trainer_app/android/app/`.

## 3. Run both apps

```bash
# terminal 1 — member app
cd guru_app && flutter run

# terminal 2 — trainer app (second emulator/device: flutter run -d <deviceId>)
cd trainer_app && flutter run
```

- Both apps install side-by-side (`com.wtf.guru` / `com.wtf.trainer`).
- Android emulator reaches the token server at `http://10.0.2.2:3000` (default). Real device: `flutter run --dart-define=TOKEN_URL=http://<mac-lan-ip>:3000`.

## 4. Manual test walkthrough (reviewer script)

1. Trainer app → login (any password) as Aarav.
2. Guru app → onboarding → DK → pick Aarav → home.
3. DK: Chat with Trainer → "Hi Coach 👋" → trainer sees unread badge → opens → replies (DK sees ✓✓ + typing dots).
4. DK: Schedule Call → today, pick a near slot → note "Macros review" → Request Call.
5. Trainer: Requests → Approve → DK sees system message + Upcoming Call banner.
6. Within the 10-min join window both tap **Join Call** → device check (camera preview, mic/cam toggles) → join.
7. Toggle mute/video/flip on one side; other side sees the change. End call.
8. Rate 5★ + note (DK); quick notes + mark complete (trainer).
9. Sessions list on both apps → latest on top with duration + rating; tap → both notes.

## Quality gates

```bash
cd shared && flutter test          # 16 tests: models, validators, duration
for d in shared guru_app trainer_app; do (cd $d && flutter analyze); done   # zero warnings
```

## Repo layout

```
shared/        models, services, api (dio), blocs, widgets, utils (global consts)
guru_app/      member app (blue #1769E0)
trainer_app/   trainer app (red #E50914)
token_server/  Node/express Agora token server
docs/          design spec + implementation plan
```
