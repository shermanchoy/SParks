# Option B: Fix cat detection (step-by-step)

Goal: Only cat images get blurred. We need to see what labels Google Vision returns for your cat photos, then add those labels to the backend.

---

## Step 1: Turn off “flag all photos” (already done)

- In `lib/screens/chat/chat_room_screen.dart`, `kFlagAllChatPhotosAsSensitive` is set to **false**.
- So from now on, only messages with `imageFlaggedSensitive: true` (from detection) will blur.

---

## Step 2: Open Cloud Logs

1. Go to **https://console.cloud.google.com**
2. Sign in with the same Google account you use for Firebase.
3. At the top, open the **project dropdown** and select the **same project** as your Firebase app (the one that has your Functions).
4. In the left menu (or search bar), open **Logging** → **Logs Explorer**.
   - Or search for “Logs” in the top search bar and choose **Logging**.

---

## Step 3: Filter logs for your function

1. In Logs Explorer you’ll see a **query** box (e.g. “Build query” or a search field).
2. Clear any existing query and paste this (replace if your function name is different):

   ```
   resource.type="cloud_run_revision"
   textPayload=~"moderateChatImage"
   ```

   Or simpler: in the search box type:

   ```
   moderateChatImage
   ```

3. Set the **time range** to “Last 1 hour” or “Last 24 hours”.
4. Click **Run query** (or the logs will auto-refresh).

---

## Step 4: Send a cat photo in your app

1. Run your dating app (same Firebase project).
2. Open a chat and **send a photo of a cat** (clear, obvious cat image).
3. Wait a few seconds so the function runs and the log appears.

---

## Step 5: Find the “Vision labels” line in the logs

1. Back in **Logs Explorer**, look at the log entries.
2. Find an entry that contains text like:
   - **`Vision labels (no cat match):`** followed by a list such as `dog:0.95, pet:0.87, mammal:0.82, ...`
3. That line is what Vision actually returned for your cat image. We need it to add the right labels so the backend flags it as a cat.

**If you don’t see that line:**

- Make sure you’re in the correct project and time range.
- Send another cat photo and wait ~30 seconds, then refresh the logs.
- You can also look for: **`moderateChatImage returning:`** — that shows the function ran. If it says `containsCat: false`, then somewhere above or in the same timeframe there should be a “Vision labels” line (or we’ll add more logging).

---

## Step 6: Copy and paste the labels here

1. **Copy** the full line that looks like:
   ```
   Vision labels (no cat match): mammal:0.92, carnivore:0.88, pet:0.85, ...
   ```
2. **Paste** it in the chat (or in a reply to the person helping you).
3. We’ll add those label names (and any similar ones) to `functions/index.js` so the next time you send a cat photo, the backend will set `containsCat: true` and the image will blur.

---

## Step 7: Redeploy the backend (after we update the code)

Once the backend code is updated with the new labels:

1. In a terminal, from your **project root** (the folder that contains `functions/`):
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```
2. Wait until deploy finishes.
3. Send another **new** cat photo in the app — it should now be blurred.

---

## Quick checklist

- [ ] Step 1: `kFlagAllChatPhotosAsSensitive = false` (already done)
- [ ] Step 2: Open Google Cloud Console → same project → Logging → Logs Explorer
- [ ] Step 3: Filter by `moderateChatImage` (or the query above), time range Last 1–24 h
- [ ] Step 4: Send a cat photo in the app
- [ ] Step 5: Find the log line “Vision labels (no cat match): …”
- [ ] Step 6: Copy that full line and paste it here
- [ ] Step 7: After we add the labels, run `firebase deploy --only functions` and test again
