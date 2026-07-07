# WTF Guru ↔ Trainer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Two Flutter apps (Guru/Member "DK" + Trainer "Aarav") sharing one repo, communicating via Firebase, with real-time chat, call scheduling, Agora video calls, and session logs — in a 6-hour timebox.

> **RTC PIVOT (user decision, 2026-07-07):** Agora replaces 100ms as the RTC provider. The spec names 100ms as mandatory — this deviation is documented in DECISIONS.md/ARCHITECTURE.md per the spec's "if exact API calls differ" clause. All references to 100ms/hmssdk below map to: `agora_rtc_engine` SDK, token server mints Agora RTC tokens (AccessToken2 via `agora-token` npm pkg), channels created implicitly on join (POST /room echoes the name), `/token` returns `{token, appId, uid}` (uids: member_dk=1, trainer_aarav=2, both PUBLISHER). Task 0: Agora console project (App ID + App Certificate) instead of 100ms account. Task 10: RtcEngine.initialize → enableVideo → startPreview (pre-join) → joinChannel; listeners onUserJoined/onUserOffline/onConnectionStateChanged for peer tiles + reconnect UX.

**Architecture:** Monorepo with a `shared/` Flutter package (models, services, widgets, utils) consumed by both apps via path dependency. Blocs consume abstract services; Firebase impls behind interfaces. Node token server mints 100ms auth tokens and creates per-call rooms.

**Tech Stack:** Flutter 3.41.1, flutter_bloc, cloud_firestore + firebase_core, hive_flutter, hmssdk_flutter, permission_handler, intl, dio; Node 26 + express + jsonwebtoken for token server.

**Networking (MVVM API layer — user's standard structure):** All HTTP calls (token server: `GET /token`, `POST /room`) go through `shared/lib/api/`:

```
shared/lib/api/
├─ api_endpoints.dart          # abstract final class ApiEndpoints { static const token='/token'; room='/room'; health='/health'; }
├─ api_params.dart             # abstract final class ApiParams { static const userId='userId'; role='role'; roomId='roomId'; name='name'; }
├─ api_connectivity.dart       # hasConnection() pre-flight check (dio HEAD /health with 3s timeout) → throws AppException(AppStrings.noConnection) when unreachable
├─ api_service_interface.dart  # abstract class ApiServiceInterface { Future<String> getAuthToken({userId, role, roomId}); Future<String> createRoom(String name); }
├─ api_service.dart            # ApiService implements ApiServiceInterface — singleton Dio (baseUrl from TOKEN_URL dart-define, 10s timeouts), all DioException → AppException
└─ interceptor/
   └─ logging_interceptor.dart # Interceptor logging req/resp via WtfLog.d('RTC', ...) with token/secret values masked
```

Domain services (`ScheduleService.approve`, `CallService.fetchToken`) depend on `ApiServiceInterface`, never on Dio directly — keeping the view→bloc(viewmodel)→service→api layering clean and the API layer mockable.

## Global Constraints

- Timebox: 6 hours hard stop; commit at every task boundary (Conventional Commits; ≥6 commit bodies reference AI use).
- `AI_LEDGER.md` gets an entry per task (prompt, tool=Claude Code, intent, output summary, commit ref). ≥10 entries by the end. **Hard fail without it.**
- 100ms SDK mandatory. **Hard fail without it.**
- Colors: Guru primary `#1769E0`, Trainer primary `#E50914`, Success `#12B76A`, Warning `#F79009`, Error `#D92D20`.
- Typography: H1 24sp, H2 20sp, Body 14–16sp; semi-bold titles. 8pt spacing.
- UI copy verbatim (spec §11): Empty chat: "No messages yet. Start the conversation." / Request sent: "Call requested. Waiting for trainer approval." / Approved: "Call approved for {date} {time}." / Declined: "Call request declined. Reason: {text}." / Join: "Ready to join? Check mic and camera." / Ended: "Session saved to your logs."
- `flutter_lints` enabled, zero warnings in final build.
- No hardcoded keys; `.env.example` placeholders; secrets masked in logs.
- Android `minSdkVersion 21`; permissions `CAMERA`, `RECORD_AUDIO`, `READ_PHONE_STATE`.
- Application IDs: `com.wtf.guru`, `com.wtf.trainer` (both installable on one device).
- Token server URL: `http://10.0.2.2:3000` from Android emulator, LAN IP from real device — read from `String.fromEnvironment('TOKEN_URL', defaultValue: 'http://10.0.2.2:3000')`.
- Seed IDs are fixed strings: trainer `trainer_aarav`, member `member_dk`, chatId = `{memberId}_{trainerId}` = `member_dk_trainer_aarav`.

**Widget & code style (user directive — applies to every task):**
- Do NOT extract sub-widgets unless they are (a) reused in 2+ places or (b) the parent build method has grown too large (> ~80 lines). Prefer inline builders/local variables inside one screen file over one-off widget classes.
- Everything reusable lives in `shared/` as a global template: theme, text styles, spacing constants, copy strings, buttons, chips, empty/error/loading states, logger. Apps must never redefine what `shared/` already provides.
- Screen files own their layout; `shared/widgets/` owns only genuinely cross-app components (chat bubble, typing dots, empty state, DevPanel, quick-reply chips, upcoming-call banner).
- **Global const files (mandatory, no exceptions):** `shared/lib/utils/app_colors.dart` (all colors — primaries, status, greys), `shared/lib/utils/app_text_styles.dart` (H1/H2/body/caption styles), `shared/lib/utils/app_strings.dart` (EVERY user-facing string in the project — spec §11 copy, titles, CTAs, errors, empty states). No string/color/TextStyle literal inside any screen or widget file.
- **Toasts:** use `fluttertoast` package for all toast messages (`AppToast.show(msg)` / `AppToast.error(msg)` wrappers in `shared/lib/utils/app_toast.dart`); snackbars only for the "Copy error" action case.
- **Error handling (every async call):** service methods wrap Firebase/HTTP/HMS calls in try/catch → log via `WtfLog` with the right tag → rethrow a typed `AppException(userMessage, raw)`; blocs catch `AppException` → emit failure state → UI shows `AppToast.error(userMessage)` (or error-state widget with retry CTA for full-screen loads). No silent catches, no raw exception text shown to users.

---

### Task 0: External accounts (USER does this in browser, ~20 min, parallel with Task 1)

**Files:** none (produces credentials for `.env`)

**Interfaces:**
- Produces: Firebase project with two Android apps registered; two `google-services.json` files; 100ms `APP_ACCESS_KEY`, `APP_SECRET`, `TEMPLATE_ID`.

- [ ] **Step 1: Firebase.** console.firebase.google.com → Add project `wtf-guru-trainer` (disable Analytics for speed). Add Android app #1: package `com.wtf.guru` → download `google-services.json` (keep for Task 5). Add Android app #2: package `com.wtf.trainer` → download its `google-services.json`.
- [ ] **Step 2: Firestore.** Build → Firestore Database → Create database → **Start in test mode** → region `asia-south1` (or nearest).
- [ ] **Step 3: 100ms.** dashboard.100ms.live → sign up → create app/workspace. Choose any template (e.g. "Video Conferencing"); in Templates, ensure roles `member` and `trainer` exist (rename/add roles if template has host/guest — both need audio+video publish permissions). Copy from Developer section: **App Access Key**, **App Secret**; copy the **Template ID** from the template page.
- [ ] **Step 4:** Paste the three 100ms values + confirm both json files downloaded. Store nothing in git.

### Task 1: Repo scaffolding

**Files:**
- Create: `.gitignore`, `README.md` (stub), `AI_LEDGER.md` (header + entry 1), `.env.example`
- Create: `guru_app/`, `trainer_app/` (flutter create), `shared/` (flutter create --template=package)

**Interfaces:**
- Produces: `wtf_shared` package importable as `package:wtf_shared/wtf_shared.dart` from both apps.

- [ ] **Step 1: Scaffold projects**

```bash
cd "/Users/admin1/Desktop/WTF Gyms/wtf_flutter_test"
flutter create --org com.wtf --project-name guru_app --platforms android,ios guru_app
flutter create --org com.wtf --project-name trainer_app --platforms android,ios trainer_app
flutter create --template=package --project-name wtf_shared shared
```

- [ ] **Step 2: Root `.gitignore`** — standard Flutter ignores plus `**/google-services.json`, `**/.env`, `token_server/node_modules/`.

- [ ] **Step 3: Wire dependencies.** In `shared/pubspec.yaml`:

```yaml
environment:
  sdk: ^3.9.0
  flutter: ">=3.35.0"
dependencies:
  flutter: { sdk: flutter }
  flutter_bloc: ^9.1.0
  cloud_firestore: ^6.0.0
  firebase_core: ^4.0.0
  hive_flutter: ^1.1.0
  hmssdk_flutter: ^1.10.0
  permission_handler: ^12.0.0
  dio: ^5.7.0
  intl: ^0.20.0
  fluttertoast: ^8.2.0
dev_dependencies:
  flutter_test: { sdk: flutter }
  flutter_lints: ^6.0.0
```

In both `guru_app/pubspec.yaml` and `trainer_app/pubspec.yaml` add under dependencies: `wtf_shared: { path: ../shared }` plus `flutter_bloc`, `firebase_core`, `hive_flutter` (same versions). Run `flutter pub get` in all three; fix any version resolution errors by relaxing to what `flutter pub get` suggests.

- [ ] **Step 4: Android config (both apps).** `android/app/build.gradle.kts`: `minSdk = 24` (hmssdk needs ≥21; 24 avoids multidex). `AndroidManifest.xml` add:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.INTERNET"/>
<application android:usesCleartextTraffic="true" ...>
```

(cleartext needed for local http token server.)

- [ ] **Step 5: Verify** `flutter analyze` clean in all three; **Commit** `chore: scaffold monorepo (guru_app, trainer_app, shared) [AI: Claude Code generated scaffold config]`.

### Task 2: Models + serialization tests (TDD)

**Files:**
- Create: `shared/lib/models/app_user.dart`, `message.dart`, `call_request.dart`, `session_log.dart`, `room_meta.dart`, `shared/lib/wtf_shared.dart` (barrel)
- Test: `shared/test/models_test.dart`

**Interfaces:**
- Produces: `AppUser{id, role(UserRole.trainer|member), name, email, avatarUrl?, assignedTrainerId?}`; `Message{id, chatId, senderId, receiverId, text, createdAt(DateTime), status(MessageStatus.sending|sent|read)}`; `CallRequest{id, memberId, trainerId, requestedAt, scheduledFor, note, status(CallStatus.pending|approved|declined|cancelled), declineReason?}`; `SessionLog{id, memberId, trainerId, startedAt, endedAt, durationSec, rating?, trainerNotes?, memberNotes?}`; `RoomMeta{id, callRequestId, hmsRoomId, hmsRoleMember, hmsRoleTrainer}`. All have `toMap()`/`fromMap()` (manual — no codegen), `copyWith`. DateTimes stored as ISO-8601 strings in maps.

- [ ] **Step 1: Failing test** `shared/test/models_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wtf_shared/wtf_shared.dart';

void main() {
  test('Message JSON round-trip preserves all fields', () {
    final m = Message(
      id: 'm1', chatId: 'c1', senderId: 'member_dk', receiverId: 'trainer_aarav',
      text: 'Hi Coach 👋', createdAt: DateTime(2026, 7, 7, 18), status: MessageStatus.sent);
    final restored = Message.fromMap(m.toMap());
    expect(restored.id, 'm1');
    expect(restored.text, 'Hi Coach 👋');
    expect(restored.createdAt, DateTime(2026, 7, 7, 18));
    expect(restored.status, MessageStatus.sent);
  });
  test('CallRequest round-trip with status enum', () {
    final r = CallRequest(
      id: 'r1', memberId: 'member_dk', trainerId: 'trainer_aarav',
      requestedAt: DateTime(2026, 7, 7, 12), scheduledFor: DateTime(2026, 7, 7, 18),
      note: 'Macros review', status: CallStatus.pending);
    expect(CallRequest.fromMap(r.toMap()).status, CallStatus.pending);
  });
}
```

- [ ] **Step 2:** `cd shared && flutter test` → FAIL (Message undefined).
- [ ] **Step 3:** Implement the five model files (plain Dart, enum + `toMap`/`fromMap` via `DateTime.toIso8601String()` / `DateTime.parse`, enums serialized by `.name` + `values.byName`). Export all from `shared/lib/wtf_shared.dart`.
- [ ] **Step 4:** `flutter test` → PASS.
- [ ] **Step 5: Commit** `feat(shared): data models with serialization [AI: models generated by Claude Code from spec section 2]`.

### Task 3: Validators + duration calc (TDD)

**Files:**
- Create: `shared/lib/utils/validators.dart`
- Test: `shared/test/validators_test.dart`

**Interfaces:**
- Produces: `String? validateScheduleTime(DateTime slot, DateTime now)` → `'Cannot schedule a call in the past'` or null; `String? checkSlotConflict(DateTime slot, List<CallRequest> existing)` → `'This slot is already booked'` when any `existing` has `status == CallStatus.approved && scheduledFor == slot`, else null; `int durationSec(DateTime start, DateTime end)`; `String? validateNote(String note)` → error if >140 chars.

- [ ] **Step 1: Failing tests**

```dart
void main() {
  final now = DateTime(2026, 7, 7, 12);
  test('rejects past slot', () =>
    expect(validateScheduleTime(DateTime(2026, 7, 7, 11), now), isNotNull));
  test('accepts future slot', () =>
    expect(validateScheduleTime(DateTime(2026, 7, 7, 18), now), isNull));
  test('conflict when slot already approved', () {
    final existing = [CallRequest(id: 'r1', memberId: 'm', trainerId: 't',
      requestedAt: now, scheduledFor: DateTime(2026, 7, 7, 18), note: '',
      status: CallStatus.approved)];
    expect(checkSlotConflict(DateTime(2026, 7, 7, 18), existing), isNotNull);
    expect(checkSlotConflict(DateTime(2026, 7, 7, 18, 30), existing), isNull);
  });
  test('pending request is not a conflict', () {
    final existing = [CallRequest(id: 'r1', memberId: 'm', trainerId: 't',
      requestedAt: now, scheduledFor: DateTime(2026, 7, 7, 18), note: '',
      status: CallStatus.pending)];
    expect(checkSlotConflict(DateTime(2026, 7, 7, 18), existing), isNull);
  });
  test('duration', () =>
    expect(durationSec(DateTime(2026,7,7,18), DateTime(2026,7,7,18,25,30)), 1530));
  test('note over 140 chars rejected', () =>
    expect(validateNote('x' * 141), isNotNull));
}
```

- [ ] **Step 2:** run → FAIL. **Step 3:** implement (pure functions). **Step 4:** run → PASS. **Step 5: Commit** `feat(shared): schedule validators and duration calc [AI: TDD cycle driven by Claude Code]`.

### Task 4: Theme factory, tagged logger, core widgets

**Files:**
- Create: `shared/lib/utils/app_colors.dart`, `shared/lib/utils/app_text_styles.dart`, `shared/lib/utils/app_strings.dart`, `shared/lib/utils/app_toast.dart`, `shared/lib/utils/app_exception.dart`, `shared/lib/utils/wtf_theme.dart`, `shared/lib/utils/wtf_logger.dart`, `shared/lib/widgets/empty_state.dart`, `shared/lib/widgets/wtf_snackbar.dart`, `shared/lib/widgets/dev_panel.dart`

**Interfaces:**
- Produces:
  - `AppColors` — `guruPrimary #1769E0`, `trainerPrimary #E50914`, `success #12B76A`, `warning #F79009`, `error #D92D20`, grey scale (`grey50..grey900`)
  - `AppTextStyles` — `h1` (24 w600), `h2` (20 w600), `body` (16 w400), `bodySmall` (14 w400), `caption` (12)
  - `AppStrings` — abstract final class with EVERY user-facing string (spec §11 verbatim + screen titles, CTAs, error copy, empty states)
  - `AppToast.show(String)` / `AppToast.error(String)` — `fluttertoast` wrappers (error = `AppColors.error` bg)
  - `AppException(String userMessage, Object? raw)` — thrown by services, consumed by blocs
  - `ThemeData wtfTheme(Color primary)` (Material 3, built FROM `AppColors`/`AppTextStyles`, 8pt spacing via `class Gap { static const s8=8.0; s16=16.0; s24=24.0; }`); `WtfLog.d(String tag, String msg)` with tags `CHAT|RTC|SCHEDULE|AUTH`, ring buffer `List<LogEntry> WtfLog.recent` (last 20, mask values of keys containing `key|secret|token`); `EmptyState(icon, title, ctaLabel, onCta)`; `showWtfError(context, String human, String raw)` → snackbar with "Copy error" action (`Clipboard.setData`); `DevPanel.attach(BuildContext)` → floating "⋮" `OverlayEntry` opening bottom sheet with masked env, build info, `WtfLog.recent`.

- [ ] **Step 1:** Implement all five files (no tests — visual widgets; logger is trivially exercised by later tasks and shown in DevPanel).
- [ ] **Step 2:** `flutter analyze` clean. **Commit** `feat(shared): theme, tagged logger, DevPanel, empty/error widgets [AI: Claude Code]`.

### Task 5: Firebase wiring + services layer

**Files:**
- Create: `shared/lib/api/` — `api_endpoints.dart`, `api_params.dart`, `api_connectivity.dart`, `api_service_interface.dart`, `api_service.dart`, `interceptor/logging_interceptor.dart` (per the Networking section above)
- Create: `shared/lib/services/auth_service.dart`, `chat_service.dart`, `schedule_service.dart`, `log_service.dart` (each: abstract class + `Firebase*` impl in same file)
- Modify: `guru_app/android/app/` + `trainer_app/android/app/` ← drop in `google-services.json`; both `main.dart` → `Firebase.initializeApp()`; both android `settings.gradle.kts`/`build.gradle.kts` ← google-services plugin `4.4.2`

**Interfaces:**
- Produces:

```dart
abstract class AuthService {
  Future<AppUser?> restoreSession();                       // Hive box 'auth'
  Future<AppUser> onboardMember({required String name, required String trainerId});
  Future<AppUser> loginTrainer();                          // seeds Aarav doc if absent
  Future<List<AppUser>> seededTrainers();                  // for onboarding picker
  Future<void> logout();
}
abstract class ChatService {
  Stream<ChatSummary?> watchChat(String chatId);           // lastMessage, unreadFor, typingUserId
  Stream<List<Message>> watchMessages(String chatId);      // orderBy createdAt desc, limit 50
  Future<void> send(Message m);                            // set status sent on server write
  Future<void> markRead(String chatId, String readerId);   // batch update peer msgs → read, zero unread
  Future<void> setTyping(String chatId, String? userId);
  Future<void> sendSystem(String chatId, String text);     // senderId 'system'
}
abstract class ScheduleService {
  Stream<List<CallRequest>> watchForMember(String memberId);
  Stream<List<CallRequest>> watchPendingForTrainer(String trainerId);
  Stream<List<CallRequest>> watchApproved(String userIdField, String userId); // upcoming calls
  Future<List<CallRequest>> approvedOn(DateTime day);      // for conflict check
  Future<void> create(CallRequest r);
  Future<void> approve(CallRequest r);   // POST /room → RoomMeta doc → status approved → sendSystem("Call approved for {date} {time}.")
  Future<void> decline(CallRequest r, String reason);
  Future<RoomMeta?> roomFor(String callRequestId);
}
abstract class LogService {
  Stream<List<SessionLog>> watch(String roleField, String userId); // orderBy startedAt desc
  Future<void> create(SessionLog log);
  Future<void> update(SessionLog log);
}
class ChatSummary { final Message? lastMessage; final int unreadCount; final String? typingUserId; }
```

- Consumes: models (Task 2), `WtfLog` (Task 4), validators (Task 3).
- `approve()` calls `ApiServiceInterface.createRoom('call-<requestId>')`; `DioException` → `AppException` → UI shows `AppToast.error`.

- [ ] **Step 1:** Add google-services plugin + json files to both apps; `Firebase.initializeApp()` in both `main()`; run `flutter run` once on emulator per app to verify Firebase boots (log line, no crash).
- [ ] **Step 2:** Implement the four services against Firestore paths: `users/{id}`, `chats/{chatId}` (fields `lastMessage`, `unread_{userId}`, `typingUserId`) + subcollection `messages`, `callRequests/{id}`, `rooms/{id}`, `sessionLogs/{id}`.
- [ ] **Step 3:** `flutter analyze` clean. **Commit** `feat(shared): Firebase service layer + app wiring [AI: service impls generated by Claude Code, reviewed manually]`.

### Task 6: Token server (Node)

**Files:**
- Create: `token_server/index.js`, `token_server/package.json`, `token_server/.env.example`, `token_server/README.md`

**Interfaces:**
- Produces: `GET /token?userId=&role=&roomId=` → `{"token": "<jwt>"}`; `POST /room {"name"}` → `{"roomId": "<id>"}`; `GET /health` → `{"ok":true}`. Env: `APP_ACCESS_KEY`, `APP_SECRET`, `TEMPLATE_ID`, `PORT=3000`.

- [ ] **Step 1:** `package.json` deps: `express@^4`, `jsonwebtoken@^9`, `uuid@^9`, `dotenv@^16`. Implement `index.js`:

```js
require('dotenv').config();
const express = require('express');
const jwt = require('jsonwebtoken');
const { v4: uuid } = require('uuid');
const app = express();
app.use(express.json());
const { APP_ACCESS_KEY, APP_SECRET, TEMPLATE_ID, PORT = 3000 } = process.env;

const sign = (payload, expiresIn) => {
  const now = Math.floor(Date.now() / 1000);
  return jwt.sign({ ...payload, access_key: APP_ACCESS_KEY, version: 2, iat: now, nbf: now },
    APP_SECRET, { algorithm: 'HS256', expiresIn, jwtid: uuid() });
};

app.get('/token', (req, res) => {
  const { userId, role, roomId } = req.query;
  if (!userId || !role || !roomId) return res.status(400).json({ error: 'userId, role, roomId required' });
  res.json({ token: sign({ room_id: roomId, user_id: userId, role, type: 'app' }, '24h') });
});

app.post('/room', async (req, res) => {
  try {
    const resp = await fetch('https://api.100ms.live/v2/rooms', {
      method: 'POST',
      headers: { Authorization: `Bearer ${sign({ type: 'management' }, '1h')}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: req.body.name, template_id: TEMPLATE_ID }),
    });
    const data = await resp.json();
    if (!resp.ok) return res.status(resp.status).json(data);
    res.json({ roomId: data.id });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.get('/health', (_q, res) => res.json({ ok: true }));
app.listen(PORT, '0.0.0.0', () => console.log(`[token_server] :${PORT}`));
```

- [ ] **Step 2:** `.env` from Task 0 creds; `npm i && npm start`; verify: `curl 'localhost:3000/health'`, `curl 'localhost:3000/token?userId=u&role=member&roomId=r'` (decode at jwt.io — claims match 100ms schema), `curl -X POST localhost:3000/room -H 'Content-Type: application/json' -d '{"name":"smoke-test"}'` → returns real room id. Re-run same name → same id (idempotency).
- [ ] **Step 3:** README: `cp .env.example .env`, fill creds, `npm i && npm start`. **Commit** `feat(token-server): 100ms auth token + idempotent room creation [AI: JWT claims structure verified against 100ms docs via Claude Code]`.

### Task 7: Auth & onboarding (both apps)

**Files:**
- Create: `guru_app/lib/screens/onboarding_screen.dart` (2 slides PageView + profile form), `guru_app/lib/screens/home_screen.dart` (3 cards), `guru_app/lib/blocs/auth_cubit.dart`, `guru_app/lib/main.dart` (rewrite)
- Create: `trainer_app/lib/screens/login_screen.dart` (mock), `trainer_app/lib/screens/home_screen.dart` (4 tiles), `trainer_app/lib/blocs/auth_cubit.dart`, `trainer_app/lib/main.dart` (rewrite)

**Interfaces:**
- Consumes: `AuthService` (Task 5), `wtfTheme` (Task 4).
- Produces: `AuthCubit extends Cubit<AuthState>` where `AuthState = AuthLoading | AuthOnboarding | AuthReady(AppUser user)`. Guru home cards: "Chat with Trainer", "Schedule Call", "My Sessions". Trainer home tiles: "Members", "Chats", "Requests", "Sessions". AppBar role badge: "Member • DK" / "Trainer • Aarav". Dummy avatars = `CircleAvatar` with initials.

- [ ] **Step 1:** Guru: `main()` → Hive init + Firebase init → `AuthCubit.restore()`; no session → onboarding (slide 1 "Train with the best", slide 2 "Chat & video call your coach"), profile form (name prefilled "DK"), trainer picker from `seededTrainers()` (shows Aarav), auto-assign → `users/member_dk` doc + Hive session → Home.
- [ ] **Step 2:** Trainer: mock login screen (email prefilled, any password) → `loginTrainer()` seeds `users/trainer_aarav` ("Aarav (Lead Trainer)") → Home. Members tile → list members where `assignedTrainerId == trainer_aarav` (basic CRM list).
- [ ] **Step 3:** Run both apps on emulator: reinstall shows onboarding again (Hive wiped with app data); relaunch without reinstall skips it. **Commit** `feat: onboarding + mock auth + seeded profiles in both apps [AI: Claude Code]`.

### Task 8: Chat end-to-end

**Files:**
- Create: `shared/lib/widgets/chat_bubble.dart`, `shared/lib/widgets/typing_dots.dart`, `shared/lib/widgets/quick_reply_chips.dart`, `shared/lib/screens/conversation_screen.dart` (shared — parameterized by current user), `shared/lib/blocs/conversation_bloc.dart`
- Create: `guru_app/lib/screens/chat_entry.dart` (opens the single DK↔Aarav conversation), `trainer_app/lib/screens/chat_list_screen.dart` (chats with unread badge, last msg preview, "5m ago" via `timeago`-style helper in utils, FAB "+")

**Interfaces:**
- Consumes: `ChatService`, models, `EmptyState`, theme.
- Produces: `ConversationBloc` events `LoadChat(chatId)`, `SendText(String)`, `MarkRead`, states expose `List<Message>`, `bool peerTyping`. Bubble: right-aligned own messages (role color: member blue / trainer red), left peer; ticks: ✓ sent, ✓✓ read (double icon, `Icons.done` / `Icons.done_all`). System messages centered grey pill.

- [ ] **Step 1:** `ConversationBloc.SendText`: write message `status: sent`; then after `Duration(milliseconds: 400 + Random().nextInt(400))` set `typingUserId` = receiver on chat doc for 1.2s (simulated typing on the *other* app via the stream). `MarkRead` on screen open + on new incoming while open.
- [ ] **Step 2:** Conversation UI: reversed `ListView` (auto-bottom), pull-to-refresh loads older (`limit+=50`), sticky multiline input + send icon, quick-reply chips "Got it 👍" / "Can we talk at 6?" / "Share plan?", typing dots animation (3 dots, `AnimationController` 900ms loop), slide-in bubble animation 200ms, empty state "No messages yet. Start the conversation." + "Say hi" CTA.
- [ ] **Step 3:** Manual test with both apps running (two emulators or emulator+device): DK sends "Hi Coach 👋" → trainer badge increments; open → ticks flip to ✓✓ on DK's screen; reply flows back. `WtfLog.d('CHAT', ...)` on send/receive/read. **Commit** `feat: real-time chat with receipts, typing, quick replies [AI: bubble/typing widgets generated by Claude Code]`.

### Task 9: Scheduler + requests workflow

**Files:**
- Create: `guru_app/lib/screens/schedule_screen.dart` (3-day calendar strip + 30-min time chips + note field + CTA), `guru_app/lib/screens/my_requests_screen.dart` (part of schedule screen as list below, or tab), `guru_app/lib/blocs/schedule_bloc.dart`
- Create: `trainer_app/lib/screens/requests_screen.dart`, `trainer_app/lib/blocs/requests_bloc.dart`

**Interfaces:**
- Consumes: `ScheduleService`, `validateScheduleTime`, `checkSlotConflict`, `validateNote`, UI copy constants.
- Produces: approved `CallRequest` + `RoomMeta` in Firestore (created inside `ScheduleService.approve` from Task 5) + system chat message.

- [ ] **Step 1:** Guru: day chips (today/+1/+2), slot chips 06:00–21:30 every 30 min (past slots disabled for today via `validateScheduleTime`), note ≤140 with counter, CTA "Request Call" → `checkSlotConflict` against `approvedOn(day)` → `AppToast.error(AppStrings.slotConflict)` or create → `AppToast.show(AppStrings.requestSent)` ("Call requested. Waiting for trainer approval.") → My Requests list shows "Pending approval by Aarav" with status chip (pending=warning, approved=success, declined=error + reason).
- [ ] **Step 2:** Trainer Requests tab: pending list with DK's note, inline Approve/Decline. Approve → `approve()` (room create + system message "Call approved for {date} {time}."). Decline → reason modal (TextField + confirm) → `decline()`.
- [ ] **Step 3:** Manual: request → approve on trainer → DK sees status flip + system message in chat. Decline path shows reason. Conflict: second request for same approved slot rejected. `[SCHEDULE]` logs. **Commit** `feat: call scheduling with approve/decline + conflict check [AI: Claude Code]`.

### Task 10: 100ms video call

**Files:**
- Create: `shared/lib/services/call_service.dart` (`HmsCallService`: token fetch + HMSSDK lifecycle), `shared/lib/blocs/call_bloc.dart`, `shared/lib/screens/prejoin_modal.dart`, `shared/lib/screens/call_screen.dart`, `shared/lib/widgets/upcoming_call_banner.dart`

**Interfaces:**
- Consumes: `RoomMeta` (via `ScheduleService.roomFor`), `ApiServiceInterface.getAuthToken` (dio API layer), `LogService.create`, `durationSec` (Task 3), `permission_handler`.
- Produces:

```dart
class HmsCallService implements HMSUpdateListener, HMSActionResultListener {
  Future<String> fetchToken({required String userId, required String role, required String roomId});
  Future<void> preview(HMSConfig config, HMSPreviewListener l);
  Future<void> join(HMSConfig config);
  Future<void> toggleMic(); Future<void> toggleCam(); Future<void> flipCamera();
  Future<void> leave();
}
// CallBloc states: CallIdle → CallPreviewing(localVideoTrack, micOn, camOn)
// → CallJoining → CallInRoom(peers: List<PeerTile>, reconnecting: bool)
// → CallEnded(durationSec)
```

- Join button: `UpcomingCallBanner` shown in home + chat toolbar (camera icon + badge) when `scheduledFor.difference(now) <= 10min` (and not ended); text "Ready to join? Check mic and camera."

- [ ] **Step 1:** Permissions: `[Permission.camera, Permission.microphone].request()` before preview.
- [ ] **Step 2:** Pre-join modal: `hmsSDK.preview(config)` → `onPreview` local tracks → `HMSVideoView(setMirror: true)` + mic/cam toggle buttons → "Join" swaps listener and calls `join` with same config (role from current user: member/trainer, auto-mapped).
- [ ] **Step 3:** Call screen: 2-tile grid (`onTrackUpdate` adds/removes peer video), name labels, controls row Mute/Video/Flip/End. `onReconnecting` → overlay loader; `onReconnected` → dismiss. `onPeerUpdate(peerLeft)` → show "Peer left" chip. Record `joinedAt` on `onJoin`.
- [ ] **Step 4:** End/leave → `durationSec(joinedAt, now)` → `LogService.create(SessionLog(...))` → snackbar "Session saved to your logs." → post-call sheet (Task 11). `[RTC]` logs on every transition. Token-expiry edge: on join error `TokenError` re-fetch token once and retry.
- [ ] **Step 5:** Manual on two devices: both join approved call, toggles reflect on peer, one leaves → other sees state change. **Commit** `feat: 100ms video calls with prejoin check + resilience [AI: HMS listener wiring generated by Claude Code from 100ms Flutter docs]`.

### Task 11: Post-call sheets + session logs

**Files:**
- Create: `guru_app/lib/screens/rate_session_sheet.dart` (1–5 stars + note), `trainer_app/lib/screens/trainer_notes_sheet.dart` (notes + "Mark as complete"), `shared/lib/screens/sessions_screen.dart` (chips All / Last 7 days / This Month; rows date, duration, rating; tap → detail modal with both notes), `shared/lib/blocs/sessions_cubit.dart`

**Interfaces:**
- Consumes: `LogService.watch/update`, `SessionLog`, `EmptyState`.
- Produces: sessions list sorted latest-first; empty state "Schedule your first call".

- [ ] **Step 1:** Sheets update the `SessionLog` doc (`rating`/`memberNotes` from guru; `trainerNotes` from trainer).
- [ ] **Step 2:** Sessions screen filter chips client-side on the stream; duration formatted `mm:ss`; detail modal shows both notes.
- [ ] **Step 3:** Manual: after a call, log appears on both apps, latest on top. **Commit** `feat: post-call rating/notes + session logs with filters [AI: Claude Code]`.

### Task 12: DevPanel, polish, docs, quality gates

**Files:**
- Modify: both apps' root widget → `DevPanel.attach`, loading skeletons on lists (shimmer-less: grey rounded boxes with `AnimatedOpacity`)
- Create: `README.md` (full), `ARCHITECTURE.md`, `DECISIONS.md` (3 ADRs from spec doc), root `.env.example`
- Modify: `AI_LEDGER.md` — verify ≥10 entries, add commit hashes

**Interfaces:** none new.

- [ ] **Step 1:** DevPanel in both apps (env masked, build info via `PackageInfo`-free constants, last 20 logs). Verify every list screen has loading/empty/error states.
- [ ] **Step 2:** `flutter analyze` in all three Dart projects → **zero warnings** (fix all).
- [ ] **Step 3:** `cd shared && flutter test` → all pass.
- [ ] **Step 4:** README: prerequisites, Firebase setup pointer, token server run, one command per app (`flutter run` in each dir + combined script `./run_all.sh` optional), manual-test walkthrough. ARCHITECTURE: layer diagram, Firestore schema, 100ms flow, edge cases. DECISIONS: ADR1 Bloc, ADR2 Firestore+Hive, ADR3 dynamic rooms via token server (+ static-room fallback).
- [ ] **Step 5:** Run the spec's 9-step manual test script end-to-end. Fix anything broken. **Commit** `docs: architecture, decisions, ledger finalization [AI: docs drafted by Claude Code, verified by candidate]`.
- [ ] **Step 6:** Record 3-min demo (QuickTime screen record of both emulators): onboarding → chat → schedule → approve → call → rate → logs. Push repo to GitHub (user account sachinbansal091@gmail.com).

---

## Verification (definition of done)

1. Spec's 9-step manual test passes with both apps running.
2. `flutter analyze` zero warnings ×3 projects; `flutter test` green in `shared/`.
3. `curl` smoke tests on token server pass; 100ms join works on both apps.
4. `AI_LEDGER.md` ≥10 entries; `git log` shows ≥6 AI-referencing conventional commits.
5. Fresh clone + README instructions reproduce the build.

## Risk register

- **100ms template roles ≠ member/trainer** → rename roles in dashboard during Task 0 (5 min fix).
- **Two-emulator RAM pressure** → use one emulator + one physical Android device (token URL = Mac's LAN IP via `--dart-define=TOKEN_URL=http://192.168.x.x:3000`).
- **Firestore test-mode rules expire in 30 days** → fine for assessment window.
- **Camera on emulator is virtual** → acceptable; real device recommended for demo video half.
- **Time overrun** → drop order: attachments (already out), Task 11 detail modal, DevPanel build info; never drop 100ms or ledger (hard fails).
