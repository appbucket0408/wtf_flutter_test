# WTF Guru ↔ Trainer Chat + Video Call System — Design

**Date:** 2026-07-07
**Timebox:** 6 hours hard stop
**Deliverables:** GitHub repo + 3-min demo video + AI_LEDGER.md

## Context

WTF Flutter Engineer assessment: build two Flutter apps (Guru/Member app for "DK", Trainer app for "Aarav") that work together locally with real-time chat, 100ms video call scheduling + calling, session logs, and basic CRM lists. AI-native workflow is mandatory and must be evidenced in `AI_LEDGER.md` (≥10 entries) and commit messages (≥6 referencing AI). Hard-fail conditions: no 100ms integration, no AI ledger, or app doesn't run.

## Decisions (ADRs)

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | State management | **Bloc** (flutter_bloc) | User choice; one bloc/cubit per feature to bound ceremony within timebox; reads well on rubric's architecture score |
| 2 | Storage/sync | **Cloud Firestore** (live sync) + **Hive** (local cache/auth persistence) | Firebase chosen by user for cross-app communication; Firestore snapshot streams give real-time feel free; spec requires local caching even with Firebase |
| 3 | RTC strategy | **100ms SDK** (`hmssdk_flutter`) + **Node.js token server** with per-call dynamic rooms | Spec mandates 100ms + token server. Room creation via `POST /v2/rooms` is idempotent by name (`call-{callRequestId}`), so dynamic rooms are cheap. Static dashboard room kept as documented fallback |

## Repository Structure

```
wtf_flutter_test/
├─ README.md                  # one-command build for both apps
├─ AI_LEDGER.md               # ≥10 entries: prompt, tool, intent, output, commit
├─ ARCHITECTURE.md            # layers, data flow, 100ms approach
├─ DECISIONS.md               # ADRs above
├─ .env.example               # 100ms + Firebase placeholders
├─ token_server/              # Node.js + express
│  ├─ index.js                # GET /token, POST /room
│  ├─ .env.example
│  └─ README.md
├─ shared/                    # Flutter package, path dependency for both apps
│  ├─ lib/
│  │  ├─ models/              # user, message, call_request, session_log, room_meta
│  │  ├─ services/            # auth_service, chat_service, call_service, log_service
│  │  │                       # (abstract interfaces + Firebase/100ms impls)
│  │  ├─ widgets/             # chat bubbles, chips, empty states, skeletons, dev_panel
│  │  └─ utils/               # theme factory, validators, extensions, tagged logger
│  └─ test/                   # message round-trip, scheduler validation, duration calc
├─ guru_app/                  # Member app — primary #1769E0, id com.wtf.guru
└─ trainer_app/               # Trainer app — primary #E50914, id com.wtf.trainer
```

Both Android apps registered in **one Firebase project** (two `google-services.json`).

## Data Model (Firestore collections)

- `users` — `User { id, role: trainer|member, name, email, avatarUrl?, assignedTrainerId? }`
- `chats/{chatId}/messages` — `Message { id, chatId, senderId, receiverId, text, createdAt, status: sending|sent|read }`; chat doc holds `lastMessage`, `unreadCount`, `typingUserId?`
- `callRequests` — `CallRequest { id, memberId, trainerId, requestedAt, scheduledFor, note ≤140, status: pending|approved|declined|cancelled, declineReason? }`
- `sessionLogs` — `SessionLog { id, memberId, trainerId, startedAt, endedAt, durationSec, rating?, trainerNotes?, memberNotes? }`
- `rooms` — `RoomMeta { id, callRequestId, hmsRoomId, hmsRoleMember, hmsRoleTrainer }`

`chatId` is deterministic: `{memberId}_{trainerId}`. Seeds: Trainer "Aarav (Lead Trainer)" written on trainer app first login; DK profile created via guru onboarding.

## State Management (Bloc map)

| Bloc/Cubit | App | Responsibility |
|---|---|---|
| `AuthCubit` | both | onboarding/login state, Hive persistence, seeding |
| `ChatListBloc` | both | conversations stream, unread badges |
| `ConversationBloc` | both | messages stream, send, read-marking, typing simulation (400–800ms) |
| `ScheduleBloc` | guru | slot selection, validation (no past), request creation |
| `RequestsBloc` | trainer | pending list, approve (→ room create + system message), decline (reason) |
| `CallBloc` | both | wraps HMSSDK: preview → join → in-call events → leave → SessionLog write |
| `SessionsCubit` | both | logs stream, filter chips (All / 7 days / This Month) |

UI never touches Firebase/100ms directly — blocs consume the abstract services from `shared/`.

## 100ms Integration

**Token server (Node/express, port 3000):**
- `GET /token?userId=&role=&roomId=` → HS256 JWT: `{ access_key, room_id, user_id, role, type: "app", version: 2, iat, nbf, exp (24h), jti }` signed with `APP_SECRET` from `.env`
- `POST /room { name }` → self-signs management token (`type: "management"`), calls `POST https://api.100ms.live/v2/rooms { name, template_id }`; idempotent — same name returns same room

**Flutter flow (spec scenario D):**
1. Approve → trainer app calls `POST /room` with `call-{callRequestId}` → saves `RoomMeta` → system message "Call approved for {date} {time}."
2. Join button visible from 10 min before `scheduledFor` (Upcoming Calls list + chat toolbar camera icon)
3. Pre-join modal: `HMSPreviewListener` + `hmsSDK.preview(config)` → `HMSVideoView(setMirror: true)` camera preview, mic/cam toggles; role auto-mapped (member/trainer)
4. Join: swap to `HMSUpdateListener`, `hmsSDK.join(config)`; in-call grid of two tiles, name labels; Mute/Video/Flip/End buttons; `onTrackUpdate` reflects peer toggles; `onReconnecting/onReconnected` shows loader
5. Leave/end → compute duration (join→leave timestamps) → write `SessionLog` → post-call sheet: member rates 1–5 + note; trainer quick notes + "Mark as complete"

**Android config:** `minSdkVersion 21`, permissions `CAMERA`, `RECORD_AUDIO`, `READ_PHONE_STATE`, foreground-service perms (Android 14+).

**Edge cases:** token expiry → re-fetch from server on join error; app background/foreground → SDK handles, verify; network loss → reconnect loader. Fallback if per-call room creation fails: static dashboard room documented in ARCHITECTURE.md.

## UX / UI

Per spec section 3 (scenarios A–E) and 4 (pixel-level): 8pt spacing, H1 24sp / H2 20sp / body 14–16sp, role colors (Guru blue `#1769E0`, Trainer red `#E50914`), status colors (`#12B76A`/`#F79009`/`#D92D20`), loading skeletons + empty states + error retry, UI copy strings from spec section 11 verbatim, 150–250ms transitions. Shared theme factory takes primary color so both apps stay consistent.

## Observability

- `DevPanel` (shared widget): floating "⋮" → env (masked), build info, last 20 logs
- Tagged logger: `[CHAT] [RTC] [SCHEDULE] [AUTH]`, in-memory ring buffer feeds DevPanel
- Errors: snackbars with human copy + "Copy error" action

## Security

`.env.example` at root and in `token_server/`; no hardcoded keys; secrets masked in DevPanel/logs; token server reads 100ms creds from `.env`.

## Testing (spec minimum)

Unit tests in `shared/test/`:
1. `Message` JSON serialization round-trip
2. Scheduler validation — rejects past times; conflict when slot already approved
3. SessionLog duration calculation

Manual: the spec's 9-step reviewer script is the definition of done and the demo-video outline.

## Execution Timeline (6h)

| Hour | Work |
|---|---|
| 0–1 | Scaffold repo + shared package; **user creates Firebase project + 100ms account in browser** (guided); theme, models, logger |
| 1–2 | Auth/onboarding both apps; seed Aarav; DK onboarding → auto-assign |
| 2–3 | Chat end-to-end: list, conversation, ticks, typing, quick replies, empty states |
| 3–4 | Scheduler: calendar + slots + validation + conflict; approve/decline; system messages |
| 4–5 | 100ms: token server, room-on-approve, pre-join, in-call UI, SessionLog write |
| 5–6 | Rating/notes sheets, sessions list + filters, DevPanel, docs, lint zero-warnings, demo script |

AI_LEDGER.md updated at the end of each hour block; Conventional Commits throughout with AI references in bodies.

## Out of Scope (YAGNI unless time remains)

Push notifications, chat attachments, offline send queue, dark theme, session export — spec section 15 stretch items only.
