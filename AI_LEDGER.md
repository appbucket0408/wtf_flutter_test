# AI Ledger — WTF Flutter Assessment

> Evidence of AI-native workflow. Tool used throughout: **Claude Code (Opus 4.8)** in terminal — design → plan → TDD implementation → infra automation. Prompts condensed; full session transcript available on request.

| # | Tool | Intent | Prompt (condensed) | Output / where used | Commit |
|---|------|--------|--------------------|---------------------|--------|
| 1 | Claude Code | Requirements analysis | "Review the requirement clearly for this project" (assessment PDF attached) | Structured breakdown of all 15 spec sections; identified hard-fail gates and scoring weights; strategic build order | docs commit |
| 2 | Claude Code | RTC vendor research | "Go through https://www.100ms.live/docs" | Verified SDK APIs, JWT claim schema, room REST API — shaped the provider-agnostic api layer that later made the Agora pivot cheap | docs commit |
| 3 | Claude Code | Architecture brainstorm | Guided Q&A: Firebase for cross-app sync, Bloc vs Riverpod, token server language | Validated design spec (docs/superpowers/specs/) with 3 ADRs, Firestore schema, 6-h timeline | docs commit |
| 4 | Claude Code | Implementation planning | "Write implementation plan from approved spec" + style directives (MVVM api/ folder, global const files, dio, fluttertoast, no one-off sub-widgets) | 13-task TDD plan (docs/superpowers/plans/) | docs commit |
| 5 | Claude Code | Scaffolding | "Execute plan Task 1: monorepo, path deps, Android RTC permissions" | 3 Flutter projects wired; minSdk 24; manifests with camera/mic permissions | scaffold commit |
| 6 | Claude Code | TDD models | "Write failing round-trip tests for the 5 models from spec §2, then implement" | `models_test.dart` (6 tests) red→green; manual toMap/fromMap, enum byName | models commit |
| 7 | Claude Code | TDD validators | "Failing tests for schedule validation, conflict, duration, note length" | `validators_test.dart` (9 tests) red→green; pure functions consumed by ScheduleCubit | validators commit |
| 8 | Claude Code | Design system | "Global const files: app_colors, app_text_styles, app_strings (spec §11 verbatim), theme factory, tagged logger with masking" | Both apps consume one theme factory; zero literals in screens | consts commit |
| 9 | Claude Code | Service layer | "Firebase impls behind abstract services; api/ folder with dio + interceptor per my MVVM structure" | 4 services + ApiService singleton; typed AppException chain to toasts | services commit |
| 10 | Claude Code | **Debugging with AI** | Analyzer: deprecated `RadioListTile.groupValue/onChanged` (Flutter 3.32+) | Migrated onboarding trainer picker to `RadioGroup` ancestor pattern — zero warnings restored | auth commit |
| 11 | Claude Code | **Refactor with AI** (RTC pivot) | "Instead of 100ms we will use Agora" mid-build | Before: hms token server (HS256 JWT), RoomMeta.hmsRoomId. After: agora-token AccessToken2 server, channelId, `/token` returns {token, appId, uid}. ~30 min swap thanks to ApiServiceInterface abstraction | token-server commit |
| 12 | Claude Code | Infra automation | "Do the Firebase setup using firebase cli" / "use browser tool to add project on agora" | Firebase project + 2 app registrations + Firestore + rules deployed via CLI; Agora project created via browser automation; credentials piped to .env without terminal exposure | config commit |
| 13 | Claude Code | Chat feature | "Conversation bloc + shared screen: receipts, simulated typing 400–800ms, quick replies, unread badges" | `ConversationBloc` + `ConversationScreen` shared by both apps | chat commit |
| 14 | Claude Code | Scheduler | "Guru 3-day/30-min scheduler + trainer approve/decline with reason modal, conflict check" | ScheduleCubit/RequestsCubit; system messages on approve/decline | scheduler commit |
| 15 | Claude Code | Video calls | "AgoraCallService + CallCubit: preview → join → controls → reconnect → SessionLog" | Full §3D flow incl. token-expiry retry, peer-left state, post-call sheets | calls commit |

**Debugging-with-AI entries:** #10 (deprecation), #11 (cross-provider migration), plus analyzer-driven fixes (unused imports, unnecessary casts) each round — `flutter analyze` kept at zero warnings after every task.
