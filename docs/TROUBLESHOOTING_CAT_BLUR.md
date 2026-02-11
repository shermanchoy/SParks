# Troubleshooting: Cat Images Not Blurring

Use this guide when cat (sensitive) images are **not** being blurred in profile, discover cards, matches, or chat.

---

## Quick checklist (do in order)

| # | Check | Pass? |
|---|--------|-------|
| 1 | User is **signed in** (callables require auth) | |
| 2 | **Cloud Functions deployed**: `firebase deploy --only functions` | |
| 3 | **Cloud Vision API** enabled for your Firebase project (GCP Console) | |
| 4 | You're testing with a **new** upload (old data may not have the flag) | |
| 5 | **Debug logs** show what’s happening (see below) | |

---

## Step 1: Confirm the function is deployed and callable

1. In project root run:
   ```bash
   firebase deploy --only functions
   ```
2. In the output, confirm **`detectCatInImage`** and **`moderateChatImage`** are listed.
3. In [Firebase Console](https://console.firebase.google.com) → your project → **Functions**, you should see both functions in region **us-central1**.

If the app was using an old backend, redeploy and try again.

---

## Step 2: Enable Cloud Vision API

The backend uses **Google Cloud Vision API** for label detection. If it’s not enabled, the function will log an error and return `containsCat: false`.

1. Open [Google Cloud Console](https://console.cloud.google.com).
2. Select the **same project** as your Firebase app (top project dropdown).
3. Go to **APIs & Services** → **Library**.
4. Search for **Cloud Vision API** and open it.
5. Click **Enable** if it’s not already enabled.

---

## Step 3: Use app debug logs (Flutter)

The app now logs cat-detection results in **debug mode only** (when you run from IDE, not in release).

1. Run the app in **debug** (e.g. `flutter run` or Run/Debug in your IDE).
2. Upload a **clear cat photo** (profile photo or send in chat).
3. In the **debug console** look for:
   - **`[CatDetection] Cloud returned containsCat: true`** or **`false`**  
     → If you see `true` but the image still doesn’t blur, the issue is **after** detection (Firestore or UI).
   - **`[CatDetection] Cloud failed: ...`**  
     → Cloud Function didn’t run or threw (auth, network, or backend error). Check Step 4 (backend logs).
   - **`[CatDetection] Mobile fallback returned: ...`**  
     → Cloud failed and the app used on-device ML Kit (mobile only).
   - **`[ProfileScreen] containsCat=...`** (profile only)  
     → Confirms the value passed from detection to the profile screen.

**How to interpret:**

- **Cloud returned false** → Backend ran but Vision didn’t match a “cat” label. Go to Step 4 and check what labels Vision returned.
- **Cloud failed** → Backend not deployed, not authenticated, or Vision API error. Check Step 4 (backend logs) and Step 1–2.
- **Cloud returned true but no blur** → Detection is fine; problem is saving the flag or the UI. Check Step 5 (Firestore) and Step 6 (UI).

---

## Step 4: Check backend logs (what Vision actually returns)

The Cloud Function **`detectCatInImage`** now logs the labels Vision returns. That shows why a cat image might not be flagged.

1. Open [Google Cloud Console](https://console.cloud.google.com) → same project.
2. Go to **Logging** → **Logs Explorer** (or search “Logs”).
3. In the query box use:
   ```text
   resource.type="cloud_run_revision"
   textPayload=~"detectCatInImage"
   ```
   Or simply search: **detectCatInImage**
4. Set time range to **Last 1 hour** (or when you last tested).
5. Upload a **cat photo** in the app (profile or chat), then refresh the logs.

**What to look for:**

- **`detectCatInImage labels (score>=0.15): ...`**  
  Lists the labels Vision returned (e.g. `cat:0.92, mammal:0.88`). If you see something like **`cat:0.9`** but the next line says **`returning containsCat: false`**, the backend matching logic might be wrong (report that).
- **`detectCatInImage match: cat score: 0.xx`**  
  A cat term matched; the next line should be **`returning containsCat: true`**.
- **`Vision API error: ...`**  
  Vision call failed (e.g. API not enabled, quota, or bad image). Fix the error (often enable Vision API or check quota).

If Vision returns labels that **don’t** include “cat” (e.g. only “mammal”, “pet”, “animal”), you can add those terms to the backend **catTerms** list in `functions/index.js` (in both `moderateChatImage` and `detectCatInImage`) and redeploy.

---

## Step 5: Confirm the flag is stored (Firestore)

Detection might be correct but the flag not saved or not read.

**Profile photo:**

1. Firebase Console → **Firestore** → **users** → your user document.
2. After uploading a cat profile photo, check:
   - **`photoFlaggedSensitive`** should be **true** (boolean).

**Chat photo:**

1. Firestore → **chats** → [some chatId] → **messages**.
2. Open a **new** message that has a cat image.
3. Check:
   - **`imageFlaggedSensitive`** should be **true** (boolean).

If the field is **false** or **missing**:

- For **profile**: detection is returning false (use Step 3 and 4) or the write in `profile_screen.dart` isn’t running (check for errors in the console).
- For **chat**: same for detection, or the message write in `chat_room_screen.dart` isn’t including `imageFlaggedSensitive` or an exception is being caught.

---

## Step 6: Confirm the UI gets the flag

- **Profile**: `BlurredImageWithUnblur(flaggedAsSensitive: _photoFlaggedSensitive, ...)` in `profile_screen.dart`. If Firestore has `photoFlaggedSensitive: true` but the profile was loaded before the update, **leave Profile and re-enter** (or restart the app) so the user doc is re-read.
- **Discover / Matches**: User cards use `user.photoFlaggedSensitive` from the user or match document. Ensure those docs have the flag and the app isn’t using cached data.
- **Chat**: `MessageBubble(..., imageFlaggedSensitive: imageFlaggedSensitive, ...)` and inside it `BlurredImageWithUnblur(flaggedAsSensitive: imageFlaggedSensitive, ...)`. If the message document has `imageFlaggedSensitive: true` but the bubble doesn’t blur, check that the stream/document data is parsed correctly (e.g. `rawFlag == true || rawFlag == 'true' || rawFlag == 1`).

---

## Step 7: Force-blur for testing (optional)

To verify that **blur works at all** (independent of detection), you can temporarily force the flag to true:

- **Profile**: In `profile_screen.dart` after `final containsCat = await _catDetection...`, add:
  `final containsCat = true; // force for testing`
- **Chat**: In `chat_room_screen.dart` in `_sendPhoto`, set `imageFlaggedSensitive = true` before the Firestore `add(...)`.

If the image blurs with this change, the problem is **only** detection or saving the flag (Steps 1–5). If it still doesn’t blur, the problem is in the UI or how the flag is passed (Step 6). Remove the force after testing.

---

## Summary

| Symptom | What to do |
|--------|-------------|
| No `[CatDetection]` logs | Run in debug; upload cat photo again. |
| `Cloud failed: unauthenticated` | User must be signed in. |
| `Cloud failed: ...` other | Check deploy (Step 1), Vision API (Step 2), and backend logs (Step 4). |
| `Cloud returned containsCat: false` | Check backend logs (Step 4) for Vision labels; add missing terms to `catTerms` and redeploy. |
| `Cloud returned containsCat: true` but no blur | Check Firestore (Step 5) and UI (Step 6). |
| Firestore has `true` but no blur | Check Step 6 (widget receives flag; re-open screen or reload data). |

After changing **backend** (`functions/index.js`), always run:

```bash
firebase deploy --only functions
```

Then test with a **new** cat photo (profile or chat).
