# Sparks App – Team Guide: Pages, Work Split & “Hardest Challenge” Stories

This document is the main reference for the Sparks dating app. It explains every Flutter page, how to split work among 3 people, backend requirements, where to troubleshoot, and three distinct “hardest challenge” stories for reports or interviews.

---

## 1. What each Flutter page does

### Entry & auth flow

| Page | File | What it does |
|------|------|----------------|
| **Splash** | `screens/onboarding/splashscreen.dart` | Shows app logo for ~2 seconds, then sends user to Login or Home based on auth. |
| **Auth gate** | `routes.dart` (class `AuthGate`) | Listens to auth state: if not logged in → Login; if no profile in Firestore → Onboarding; else → Home. |
| **Login** | `screens/auth/login_screen.dart` | Email/password form, animated background. **Always uses dark theme** (wrapped in `Theme(data: buildSParksTheme(isDark: true), ...)`). Calls `AuthService().login()`, then navigates to auth gate. |
| **Register** | `screens/auth/register_screen.dart` | Email/password sign-up, validation, calls `AuthService().register()`, then auth gate. |

### Onboarding

| Page | File | What it does |
|------|------|----------------|
| **Onboarding** | `screens/onboarding/onboarding_screen.dart` | First-time profile setup: name, course, bio, school, intent (Dating/Friends/Networking), interests. Saves to Firestore via `FirestoreService`. |

### Main app (bottom nav)

| Page | File | What it does |
|------|------|----------------|
| **Home shell** | `screens/home/home_shell.dart` | Bottom nav with 3 tabs (Discover, Matches, Profile). App bar: theme toggle, notifications, logout. Shows one of the three tab screens. |
| **Discover** | `screens/home/discover_screen.dart` | Loads other users from Firestore, shows a stack of cards. Like / pass; on mutual like, creates match and chat, shows match dialog, can open chat. Uses `MatchService`, `UserCard`, `MatchDialog`. |
| **Matches** | `screens/home/matches_screen.dart` | Stream of matches from `matches/{uid}/list`. List with optional blur for sensitive photos; tap to open chat (`chatId`, `otherUid`, `otherName`). |
| **Profile** | `screens/home/profile_screen.dart` | View/edit profile: name, course, bio, school, intent, interests. Profile photo: pick → **cat detection** (Cloud Vision / ML Kit) → upload to Storage → save `photoUrl`, `photoPath`, `photoFlaggedSensitive`. Uses `BlurredImageWithUnblur` for sensitive photo. |

### Chat & notifications

| Page | File | What it does |
|------|------|----------------|
| **Chat room** | `screens/chat/chat_room_screen.dart` | Single conversation: route args `chatId`, `otherUid`, `otherName`. Streams `chats/{chatId}/messages`. Send text and photos; photos go through **moderation** (`moderateChatImage`) and **cat detection**; store `imageFlaggedSensitive`. Delete message (+ Storage cleanup). Push notification on send. |
| **Notifications** | `screens/notifications/notifications_screens.dart` | List from `users/{uid}/notifications`, ordered by `createdAt`. |

### Other (in project)

| Page | File | What it does |
|------|------|----------------|
| **Settings** | `screens/settings/settings_screen.dart` | Empty. |
| **Blocked users** | `screens/safety/blocked_users_screen.dart` | Empty. |
| **Report** | `screens/safety/report_screen.dart` | Empty. |
| **Bot** | `screens/chat/bot_screen.dart` | In folder; not in main route map. |

**Main pages to explain and split:** Splash, Auth gate, Login, Register, Onboarding, Home shell, Discover, Matches, Profile, Chat room, Notifications.

---

## 2. Backend & shared setup

These apply to the whole app; any team member may need them for testing.

| Item | Where | Notes |
|------|--------|------|
| **Firebase** | Firebase Console | Auth, Firestore, Storage, Functions – same project as the app. |
| **Cloud Functions** | `functions/index.js` | `moderateChatImage` (chat photo moderation + cat labels), `detectCatInImage` (profile/standalone cat detection). Both use **Cloud Vision API**, region **us-central1**. |
| **Cloud Vision API** | [Google Cloud Console](https://console.cloud.google.com) → APIs & Services | Must be **enabled** for the same project. Otherwise Vision calls return `PERMISSION_DENIED` and cat detection/moderation fail. |
| **Deploy functions** | Terminal | `cd functions` then `firebase deploy --only functions`. Required after changing `functions/index.js`. |
| **Flutter region** | `lib/services/cat_detection_service.dart`, `image_moderation_service.dart` | Both use `FirebaseFunctions.instanceFor(region: 'us-central1')` – must match Functions deploy region. |

**Cat detection flow (current):** App calls **Cloud** (Vision API) first via `detectCatInImage`; if that throws (e.g. network, API disabled), on **mobile** it falls back to on-device ML Kit. Debug builds log `[CatDetection] Cloud returned containsCat: ...` or `Cloud failed: ...` in the debug console.

---

## 3. Dividing work evenly between 3 people

Split by **feature area** so each person owns a clear part and can tell a coherent “hardest challenge” story.

### Person A – Auth, onboarding & profile (entry flow & profile UX)

**Screens:** Splash, Auth gate, Login, Register, Onboarding, Profile (and the Profile tab inside Home).

**Related code:**

- `AuthService`, `FirestoreService` (profile create/read/update, `userProfileExists`).
- **Auth gate:** `routes.dart` – `AuthGate` (StreamBuilder on auth + FutureBuilder on profile exists → Login / Onboarding / Home).
- Profile: `StorageService` (upload, progress, delete old), profile form state; cat detection runs here for blur but is shared with backend.
- `utils/validators.dart`, `utils/school_list.dart`, `utils/theme.dart` (Login always dark: `buildSParksTheme(isDark: true)`).
- Widgets: `BlurredImageWithUnblur`, `NetworkCircleAvatar`, `PrimaryButton`, `SparksTitle`.

**Deliverables:** User can sign up, log in (login always dark), complete onboarding, and edit profile including photo upload (progress, Firestore merge, sensitive blur). Focus: **getting the right screen at the right time** (auth vs profile completion) and **reliable profile photo upload**.

---

### Person B – Discovery & matching

**Screens:** Home shell, Discover, Matches.

**Related code:**

- `MatchService` (like, mutual like → create chat + match docs + notifications).
- `DiscoverScreen`: load users, stack state, like/pass, match dialog.
- `MatchesScreen`: stream `matches/{uid}/list`, open chat with `chatId`/`otherUid`/`otherName`.
- Widgets: `UserCard`, `MatchDialog`, `AnimatedGradientAppBar`, `GradientAppBar`.
- `routes.dart` (e.g. `chatRoute` and navigation to chat).

**Deliverables:** Discover stack, like/pass, match dialog on mutual like, Matches list that opens the correct chat.

---

### Person C – Chat, notifications & image-safety pipeline

**Screens:** Chat room, Notifications.

**Related code:**

- `ChatRoomScreen`: real-time message stream, send text/photo, **full photo pipeline** (moderation → cat detection → upload → Firestore with `imageFlaggedSensitive`), delete message + Storage cleanup, push notifications.
- `ImageModerationService`, `CatDetectionService` (used when sending photos in chat).
- `NotificationService`, Firestore `notifications` subcollection.
- Widgets: `MessageBubble` (text + image, blur for sensitive, delete).
- `app.dart`: `onGenerateRoute` for chat (passing `chatId`, `otherUid`, `otherName`).
- Shared image-safety: `BlurredImageWithUnblur`, backend `moderateChatImage` / `detectCatInImage` (Person C owns the **chat** use of this pipeline).

**Deliverables:** Open conversation, real-time messages, send text and photos through **moderation and cat-flagging**, blur in bubbles, delete messages, view notifications. Focus: **chat UX and the image-safety pipeline** (moderate → detect → store flag → display blur).

---

## 4. “Hardest challenge I faced making this app” (for 3 people)

Each story is tied to real code so you can back it up in a report or interview.

---

### Person A – “Auth gate and profile completion flow”

**Challenge:**  
Getting the **right screen at the right time** after login: we have an **AuthGate** that listens to auth state and then checks Firestore to see if the user has completed their profile. That meant coordinating a `StreamBuilder` (auth) with a `FutureBuilder` (profile exists) so we show Login → Onboarding → Home in the correct order without flashing the wrong screen. On top of that, the **profile screen** had to handle photo upload with progress, Firestore merge (so we don’t overwrite other fields), and cleaning up the old Storage file when the user changes their photo. We also made the **login screen always dark** by wrapping it in a fixed theme. The trickiest part was keeping auth state and profile completion in sync and making the profile photo upload reliable (progress, merge, mounted checks).

**Where to point in the code:**

- `lib/routes.dart` – `AuthGate`: `authStateChanges()` → `userProfileExists(uid)` → Login / Onboarding / Home.
- `lib/services/auth_service.dart`, `lib/services/firestore_service.dart` – auth and profile existence.
- `lib/screens/auth/login_screen.dart` – always-dark theme wrapper, form, navigation to auth gate.
- `lib/screens/home/profile_screen.dart` – `_pickAndUploadPhoto` (upload, progress, Firestore merge, old path delete), form state, `_load`.
- `lib/utils/theme.dart` – `buildSParksTheme(isDark: true)` used for login.

**One-liner:**  
“The hardest part was the auth and profile-completion flow (AuthGate: when to show Login vs Onboarding vs Home) and making profile photo upload reliable with progress, Firestore merge, and cleanup.”

---

### Person B – “Match logic and keeping the Discover stack in sync”

**Challenge:**  
Implementing the **match flow** so that when two users like each other, we create a single chat, write match documents for both users, and notify both—without double-creating chats or showing stale data. The **Discover** screen had to manage a local stack of users, handle like/pass without double-taps, and show the match dialog only when a mutual like actually happened. Coordinating Firestore writes (`likes`, `matches`, `chats`) with the UI state (stack, busy flags, navigation to chat with the right `chatId`) was the tricky part.

**Where to point in the code:**

- `lib/services/match_service.dart` – `likeUser`, checking `otherLikeRef`, creating chat and both `matches/{uid}/list` docs, calling `NotificationService`.
- `lib/screens/home/discover_screen.dart` – `_likeTop`, `_stack`, `_busy`, match dialog and navigation using `Routes.chatRoute(...)`.
- `lib/screens/home/matches_screen.dart` – reading `chatId` from match doc and opening chat.
- `lib/widgets/match_dialog.dart` – “It’s a match” and “Send message” (navigate to chat).

**One-liner:**  
“The hardest part was implementing mutual-like logic in Firestore (likes, matches, and chat creation) and keeping the Discover card stack and match dialog in sync so users always saw the right state and could open the correct chat.”

---

### Person C – “Chat photo pipeline: moderation, cat-flagging, blur, and delete”

**Challenge:**  
In chat we own the **full image-safety pipeline**: users can send photos that must go through **moderation** (block if inappropriate) and **cat detection** (flag as sensitive, show blurred in the bubble). The flow had to run in the right order: moderation first (and block send if not allowed), then cat detection, then upload to Storage, then write the message with `imageFlaggedSensitive` to Firestore, and send a push notification. We also had to support **deleting** messages and cleaning up the Storage file for image messages, and handle Firestore permission errors so the UI showed a clear message. Making sure the blur widget received the flag correctly and that the pipeline never sent inappropriate content was the core challenge.

**Where to point in the code:**

- `lib/screens/chat/chat_room_screen.dart` – `_sendPhoto`: moderation → cat detection → upload → Firestore with `imageFlaggedSensitive`; `_deleteMessage` and Storage delete; message stream and parsing of `imageFlaggedSensitive`.
- `lib/services/image_moderation_service.dart` – `getModerationResult` (allowed + containsCat).
- `lib/services/cat_detection_service.dart` – used when sending chat photos (cloud-first, ML Kit fallback).
- `lib/widgets/message_bubble.dart` – image messages and blur for sensitive.
- `lib/services/notification_service.dart` – “Sent a photo” notification.
- Backend: `functions/index.js` – `moderateChatImage` (Person C’s pipeline depends on it).

**One-liner:**  
“The hardest part was the chat photo pipeline: running moderation and cat detection in the right order, storing the sensitive flag on messages, showing blur in bubbles, and implementing message delete with Storage cleanup and clear error handling for Firestore rules.”

---

## 5. Troubleshooting & docs

| Doc | When to use it |
|-----|-----------------|
| **TROUBLESHOOTING_CAT_BLUR.md** | Cat images not blurring: checklist (auth, deploy, Vision API), Flutter debug logs (`[CatDetection]`), backend logs (Vision labels), Firestore (`photoFlaggedSensitive` / `imageFlaggedSensitive`), UI (blur widget). |
| **TROUBLESHOOTING_SENSITIVE_IMAGE_BLUR.md** | General “images not flagged or not blurred” (send path, Firestore, read path, UI). |
| **OPTION_B_FIX_CAT_DETECTION_STEPS.md** | Step-by-step: use Cloud logs to see Vision labels for a cat photo, then add missing labels to the backend `catTerms` and redeploy. |

**Debug console:** When running the app in debug (e.g. `flutter run` or F5 in the IDE), cat detection logs appear in the **Debug Console** (or terminal): `[CatDetection] Cloud returned containsCat: true/false` or `Cloud failed: ...`.

---

## 6. Quick reference: who owns what

| Item | Person A | Person B | Person C |
|------|----------|----------|----------|
| Splash | ✓ | | |
| Auth gate | ✓ | | |
| Login / Register | ✓ | | |
| Login (always dark) | ✓ | | |
| Onboarding | ✓ | | |
| Profile (form, photo upload, blur) | ✓ | | |
| Home shell | | ✓ | |
| Discover | | ✓ | |
| Matches | | ✓ | |
| Chat room | | | ✓ |
| Notifications | | | ✓ |
| MatchService | | ✓ | |
| **A’s main challenge** | Auth + profile flow, photo upload | | |
| **B’s main challenge** | | Match logic, Discover stack | |
| **C’s main challenge** | | | Chat + image-safety pipeline |
| Cat/Moderation (profile) | ✓ (uses shared service) | | |
| Cat/Moderation (chat) | | | ✓ (owns pipeline) |
| BlurredImageWithUnblur | ✓ (profile) | ✓ (cards) | ✓ (bubbles) |
| Backend (Functions, Vision API) | shared | shared | shared |

**Difference between A and C:** Person A focuses on **auth state, profile completion, and profile photo upload UX** (AuthGate, progress, Firestore merge). Person C focuses on **chat and the image-safety pipeline** (moderation → cat detection → store flag → blur in bubbles, delete). Both may use the same backend/services, but A’s story is routing and profile; C’s story is chat and the moderation pipeline.

Use this doc to explain the app, divide tasks, and prepare “hardest challenge” answers for each team member.
