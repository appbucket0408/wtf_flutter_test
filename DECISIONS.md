# Architecture Decision Records

## ADR #1 — State Management: Bloc (flutter_bloc)

**Decision:** `flutter_bloc` with one Bloc/Cubit per feature (`AuthCubit`, `ConversationBloc`, `ScheduleCubit`, `RequestsCubit`, `CallCubit`).

**Rationale:**
- Clear separation of view → viewmodel (bloc) → service → api layers, matching MVVM.
- Sealed state classes (`AuthLoading | AuthOnboarding | AuthReady`) make UI switches exhaustive at compile time.
- Cubits used where events add no value (schedule, requests); a full Bloc where event streams matter (conversation).

**Trade-off:** more ceremony than Provider/Riverpod, contained by keeping one bloc per feature and streaming directly from services.

## ADR #2 — Storage & Sync: Cloud Firestore + Hive

**Decision:** Firestore is the live sync backbone between the two apps; Hive persists the local session (auth).

**Rationale:**
- The two apps run in separate Android sandboxes — a shared local DB cannot connect them. Firestore snapshot streams give the "real-time feel" (typing, receipts, request status) with zero custom backend.
- Firestore's built-in offline persistence covers local caching of all synced data; Hive covers what must survive without network at boot (session/profile), satisfying the local-cache requirement.
- Deterministic ids (`member_dk`, `trainer_aarav`, chatId `member_dk_trainer_aarav`) keep the seeded-persona flows simple and idempotent.

**Trade-off:** requires a Firebase project (test-mode rules, expiry 2026-08-07). Rules and indexes are committed (`firestore.rules`, `firestore.indexes.json`).

## ADR #3 — RTC: Agora (pivot from 100ms) + Node token server

**Decision:** `agora_rtc_engine` for video calls; a minimal Node/express token server mints **AccessToken2** RTC tokens via `agora-token`. Deviation from the spec's 100ms requirement made on stakeholder instruction mid-build.

**Rationale:**
- The service layer was provider-agnostic by design (`ApiServiceInterface.getAuthToken/createRoom`), so the pivot cost ~30 minutes: swap SDK dependency, re-implement the token server signing, rename `RoomMeta` fields.
- Agora channels are created implicitly on first join — `POST /room` validates and echoes the channel name (`call-<requestId>`), keeping the approve-flow API identical and idempotent.
- Fixed uid mapping (member_dk→1, trainer_aarav→2), both joining as `PUBLISHER` in a `communication` profile; role names still stored in `RoomMeta` for parity with the original design.

**Trade-off:** the spec scores "100ms Calls (25)" — this deviation is documented per the spec's own escape clause ("If exact API calls differ, document your approach and show it working"). Token expiry handled by one re-fetch + retry on join error; reconnection via `onConnectionStateChanged` loader overlay.

## ADR #4 — Notifications: local (flutter_local_notifications), not FCM

**Decision:** Local notifications driven by the app's existing Firestore listeners — no Cloud Functions / FCM.

**Rationale:**
- Spec §15 lists notifications as a stretch and specifically suggests "local scheduled for reminder".
- FCM background push would require a Cloud Function on the Blaze (paid) plan to send on Firestore writes — out of proportion for a stretch item and blocked without billing.
- `NotificationCoordinator` subscribes to the same message/request streams the UI already uses, firing heads-up notifications for new items (arrivals after app start, so history isn't replayed) and scheduling a 10-min-before-call reminder via `zonedSchedule`.

**Trade-off:** notifications deliver while the app is alive (foreground/background), not when fully killed — acceptable for the stretch scope; a follow-up FCM path is noted in the README if killed-app delivery is later required. Android only (per request): `POST_NOTIFICATIONS` + exact-alarm permissions, core-library desugaring enabled.
