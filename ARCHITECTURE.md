# Architecture

## System overview

```
┌─────────────┐         Cloud Firestore          ┌───────────────┐
│  Guru App    │◄──── users / chats / requests ───►│  Trainer App  │
│ (DK, blue)   │       rooms / sessionLogs         │ (Aarav, red)  │
└──────┬───────┘                                   └──────┬────────┘
       │            ┌──────────────────┐                  │
       └── /token ──►  token_server    ◄──── /token ──────┘
           /room    │  (Node, Agora    │      /room
                    │   AccessToken2)  │
                    └────────┬─────────┘
                             │ RTC join (channel call-<requestId>)
                             ▼
                        Agora SD-RTN
```

## Layering (MVVM)

```
View (screens/) → Bloc/Cubit (blocs/) → Services (services/) → API (api/) / Firestore
```

- **UI never touches Firebase, Dio or the Agora SDK directly.** Screens consume blocs; blocs consume abstract services (`AuthService`, `ChatService`, `ScheduleService`, `LogService`, `CallService`); the only HTTP surface is `ApiServiceInterface` implemented by a Dio singleton with a masking `[RTC]` log interceptor.
- **`shared/` package** owns everything reusable: models, services, api layer, blocs shared by both apps (`ConversationBloc`, `CallCubit`), cross-app widgets (chat bubble, typing dots, empty state, DevPanel, upcoming-call banner) and the global const files (`app_colors`, `app_text_styles`, `app_strings`) — no color/string/TextStyle literals in screens.

## Firestore schema

| Collection | Doc id | Notes |
|---|---|---|
| `users` | `member_dk`, `trainer_aarav` | seeded personas |
| `chats/{chatId}` | `member_dk_trainer_aarav` | `lastMessage`, `unread_{uid}`, `typingUserId` |
| `chats/{chatId}/messages` | client-generated | status: sending→sent→read |
| `callRequests` | epoch-ms | status: pending→approved/declined |
| `rooms` | = callRequestId | `channelId` (`call-<id>`), role names |
| `sessionLogs` | = callRequestId | duration, rating, both notes |

## Call flow (spec §3C–D)

1. DK requests slot → `CallRequest(pending)` (validated: future time, ≤140 note, no conflict with approved slots).
2. Aarav approves → `POST /room {name: call-<id>}` → `RoomMeta` doc → status `approved` → system message "Call approved for {date} {time}." in chat.
3. Join window opens T−10 min (home banner + chat toolbar camera badge; re-checked every 30 s).
4. Join → runtime camera/mic permissions → `GET /token` (returns `{token, appId, uid}`) → engine init + `startPreview()` (device-check modal) → `joinChannel`.
5. In-call: 2-tile grid, mute/video/flip/end; `onConnectionStateChanged` → reconnect overlay; `onUserOffline` → "Peer left" state.
6. End → `SessionLog` written with measured duration → post-call sheet (member: 1–5 rating + note; trainer: quick notes + mark complete) merges into the same log doc.

## Edge cases

- **Token expiry:** one automatic re-fetch + join retry on a token-related engine error.
- **Token server down:** `ApiConnectivity` pre-flight + `DioException → AppException` → `AppToast.error` with human copy; approve/join fail loudly, nothing corrupts.
- **Reinstall:** Hive session wiped with app data → onboarding shows again (spec §3A acceptance).
- **Simulated behaviours (allowed by spec):** typing indicator (400–800 ms delayed `typingUserId` flag), read receipts batch-flip on screen open.

## Observability

`WtfLog.d(tag, msg)` with tags `[CHAT] [RTC] [SCHEDULE] [AUTH]`, 20-entry ring buffer surfaced in the DevPanel (floating "⋮"), secrets masked by regex before storage. Errors surface as toasts (fluttertoast) or snackbars with a "Copy error" action.
