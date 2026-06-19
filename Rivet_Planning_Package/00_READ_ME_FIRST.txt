RIVET PLANNING PACKAGE
======================

Project name: Rivet
Tagline for internal use only: Daily accountability with teeth.

Logo asset:
- Rivet_Planning_Package/assets/rivet-logo.svg
- The logo is a restrained black, bone, and signal-green mark: a vertical rail, a pressure point, and an angled cut suggesting forward motion. It must be converted into iOS app icon PNG sizes during implementation.

This package is a build specification, not an implementation. The next coding agent must treat these files as the source of truth and must not start coding from the original loose idea alone.

Files in this package:
- 00_READ_ME_FIRST.txt: identity, scope, and hard constraints.
- 01_PRODUCT_UI_SPEC.txt: app behavior, screens, visual design, copy rules, and interaction details.
- 02_IOS_APP_SPEC.txt: native iOS implementation details, notification model, local storage, and scheduling.
- 03_BACKEND_SPEC.txt: autopersonal VM backend, pub/sub model, database, jobs, and API contracts.
- 04_AI_CONTEXT_PROMPTING_SPEC.txt: Mistral Large 3 orchestration, prompts, memory, retrieval, tone controls, and structured outputs.
- 05_SYNC_SECURITY_EDGE_CASES.txt: encryption, auth, conflict handling, offline behavior, rate limits, DST, and multi-device sync.
- 06_TESTING_LINTING_ACCEPTANCE.txt: required linting, formatting, tests, manual QA, and acceptance criteria.
- 07_SIDELOADLY_FOLLOWUP_PLAN.txt: the follow-up packaging and sideloading plan the coding agent must complete after the app is built.
- 08_UBUNTU_OCI_DEPLOYMENT_SECURITY.txt: Ubuntu on Oracle Cloud Infrastructure deployment paths, firewall rules, service layout, TLS, request signing, and backup commands.

Hard requirements:
1. Build a custom iOS app intended to be installed onto the user's phone with Sideloadly after completion.
2. Do not use APNs, Firebase Cloud Messaging, or any backend-driven push notification service. A free Apple account cannot support the needed remote push infrastructure. The backend may publish messages, but each device must create its own local notifications.
3. Use a pull/subscription sync model: the app requests new published records from the autopersonal backend and schedules local notifications from data it has already synced.
4. Store all messages and history on the backend device and sync them to every installed app instance. Never delete message records.
5. Encrypt communication between apps and backend.
6. Keep the app dark by default, with a light mode toggle.
7. Provide a day-based calendar strip across the top of the main screen, a monthly calendar option, and greyed-out future days.
8. Only unlock the progress input after the evening check-in message is published for that day.
9. Lock progress input one hour before the next morning briefing time.
10. Begin formulating the next morning briefing one hour after the final user progress update, and run a final formulation attempt one hour before the morning briefing if no final draft is ready.
11. Use Mistral Large 3 for AI generation. The implementation agent must verify the exact current Mistral API model identifier in official Mistral documentation before coding, then keep the model id configurable.
12. The AI must use the user's three settings inputs: ego-crushing style example, pessimistic motivational style example, and situation summary/memory.
13. The AI must maintain continuity during each formulation session by persisting the full multi-call session state and tool/retrieval results.

Important iOS reality check:
Without APNs, a backend server cannot wake the app at an exact time. iOS background refresh is opportunistic. Therefore, exact local notification timing is achieved by scheduling local notifications ahead of time on-device. If the generated message body has not been synced before the notification time, the app must show a generic local notification such as "Your briefing is ready" and fetch the canonical text when opened. If background refresh succeeds after the backend publishes, the device may update or schedule the local notification with the actual message excerpt. This constraint must be documented in-app only where necessary and must be handled in code; do not build any backend push path.

Required implementation stack:
- iOS app: Swift 6, SwiftUI, GRDB over SQLite for local cache, URLSession, UserNotifications, BackgroundTasks.
- Backend on autopersonal: Ubuntu VM on Oracle Cloud Infrastructure, Python 3.12, FastAPI, SQLite in WAL mode, SQLAlchemy 2.x, Alembic migrations, APScheduler for jobs, httpx for Mistral API calls, Caddy for TLS termination.
- API style: HTTPS JSON over REST, idempotent writes, cursor-based sync.
- Deployment target: iOS 17.0. If the user's physical device cannot run iOS 17, the coding agent must stop before implementation and produce a compatibility adjustment note.

Non-goals:
- No social features.
- No public accounts or multi-user SaaS.
- No APNs, no remote push, no cloud database requirement.
- No deletion feature for messages.
- No literal MCP server is required for history retrieval. The AI orchestration must expose controlled history-retrieval functions internally.

Definition of done for the planning package:
- These files must be sufficient for a coding agent to implement Rivet without asking what stack, screens, backend jobs, API endpoints, data model, AI prompts, notification strategy, sync behavior, or install path to use.
