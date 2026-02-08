# Troubleshooting: Images Not Flagged or Not Blurred

Use this checklist when cat (sensitive) images are not being flagged, or are flagged but not blurred in chat.

---

## 1. Backend (Cloud Functions)

| Step | Check | How to verify |
|------|--------|----------------|
| 1.1 | **Functions are deployed** | Run `firebase deploy --only functions` from project root. Confirm `moderateChatImage` and `detectCatInImage` are in the deploy output. |
| 1.2 | **Region is us-central1** | In `functions/index.js`, both callables use `region: "us-central1"`. The Flutter app uses `FirebaseFunctions.instanceFor(region: 'us-central1')` — they must match. |
| 1.3 | **Vision API is enabled** | In Google Cloud Console: APIs & Services → enable **Cloud Vision API** for the project linked to Firebase. |
| 1.4 | **Callable returns `containsCat`** | Backend runs Vision label detection and sets `containsCat: true` when a label matches cat terms (e.g. "cat", "tabby", "kitten", "feline") with score ≥ 0.25. Check Firebase Functions logs after sending a cat photo: look for errors or confirm the function runs. |

**Quick test:** From Firebase Console → Functions → `moderateChatImage` → Logs, send a cat photo in the app and see if the function is invoked and completes without error.

---

## 2. Send path (when user sends a photo in chat)

| Step | Check | How to verify |
|------|--------|----------------|
| 2.1 | **Moderation is called** | In `lib/screens/chat/chat_room_screen.dart`, `_sendPhoto()` must call `_moderation.getModerationResult(bytes)` before uploading. If the photo is blocked by `!result.allowed`, the image is never sent (expected). |
| 2.2 | **`result.containsCat` is used** | Right after moderation, `imageFlaggedSensitive = result.containsCat`. If the cloud returns `containsCat: true`, the flag should be true. |
| 2.3 | **Local cat detection (Android only)** | If `!imageFlaggedSensitive`, the app calls `_catDetection.containsCatFromBytes(bytes)`. On Android this uses ML Kit; on web/Windows it uses the `detectCatInImage` callable. Ensure ML Kit / callable is working if you rely on this fallback. |
| 2.4 | **Message is written with the flag** | The Firestore `add()` must include `'imageFlaggedSensitive': imageFlaggedSensitive` (see ~line 235 in `chat_room_screen.dart`). If this line is missing or the value is always `false`, messages will never be flagged. |
| 2.5 | **No exception swallowed** | If `getModerationResult` throws (e.g. network, auth), the catch block may set nothing or leave the flag false. Check for snackbar "Could not send photo: ..." and fix the underlying error. |

**Quick test:** Add a temporary `print('imageFlaggedSensitive = $imageFlaggedSensitive');` right before the Firestore `add()` and send a clear cat photo. Confirm it prints `true` when you expect blur.

---

## 3. Firestore data (stored message)

| Step | Check | How to verify |
|------|--------|----------------|
| 3.1 | **Document has `imageFlaggedSensitive`** | In Firebase Console → Firestore → `chats` → [chatId] → `messages` → open a photo message. The field `imageFlaggedSensitive` should exist and be `true` for cat images. |
| 3.2 | **Old messages** | Messages sent **before** the app wrote `imageFlaggedSensitive` will not have the field. They will never blur. Only **new** photo messages (sent after the flag was added) can show blur. To test, send a **new** cat photo. |
| 3.3 | **Type of value** | The app accepts `true`, `'true'`, or `1`. If your backend or another client writes a different type, the read logic in step 4 must match. |

---

## 4. Read path (when the chat list is built)

| Step | Check | How to verify |
|------|--------|----------------|
| 4.1 | **Snapshot includes the field** | In `chat_room_screen.dart`, the stream is `collection('chats').doc(chatId).collection('messages')`. Each `doc.data()` should contain `imageFlaggedSensitive` for photo messages. |
| 4.2 | **Flag is parsed correctly** | Code: `final rawFlag = data['imageFlaggedSensitive'];` then `imageFlaggedSensitive = rawFlag == true \|\| rawFlag == 'true' \|\| rawFlag == 1;`. If the document has the field but with a different value (e.g. string `"false"`), it will be false. |
| 4.3 | **Flag is passed to MessageBubble** | `MessageBubble( ..., imageFlaggedSensitive: imageFlaggedSensitive, ... )` must be present. Default is `false` if not passed. |

**Quick test:** Add `print('doc ${doc.id} imageFlaggedSensitive = $imageFlaggedSensitive');` in the itemBuilder and confirm the photo message doc shows `true`.

---

## 5. UI (MessageBubble and BlurredImageWithUnblur)

| Step | Check | How to verify |
|------|--------|----------------|
| 5.1 | **MessageBubble receives the flag** | In `lib/widgets/message_bubble.dart`, `BlurredImageWithUnblur(flaggedAsSensitive: imageFlaggedSensitive, ...)` is used for the image. If `imageFlaggedSensitive` is always false here, blur never shows. |
| 5.2 | **BlurredImageWithUnblur shows blur when true** | In `lib/widgets/blurred_image_with_unblur.dart`, `_showBlur` is `widget.flaggedAsSensitive && !_revealed`. So blur is shown only when the prop is true and the user has not tapped "Unblur". |
| 5.3 | **Web / BackdropFilter** | On web, `BackdropFilter` can fail to render. The widget uses a strong dark overlay (opacity 0.92 on web) so the image should still be covered even if the blur effect does not show. If the image is fully visible on web, the flag is likely false (re-check steps 1–4). |

---

## 6. Summary checklist (minimal order)

1. Deploy functions and confirm Vision API is enabled.
2. Send a **new** cat photo (old messages don’t have the flag).
3. In Firestore, confirm that the new message document has `imageFlaggedSensitive: true`.
4. If the document has `true` but the UI does not blur, check that the read path passes `imageFlaggedSensitive` into `MessageBubble` and that `BlurredImageWithUnblur` receives `flaggedAsSensitive: true`.
5. If the document has `false` or the field is missing, the problem is in the send path or the backend (steps 1–2).

---

## Files reference

| Role | File |
|------|------|
| Backend (cat detection + moderation) | `functions/index.js` — `moderateChatImage`, `detectCatInImage` |
| Moderation client | `lib/services/image_moderation_service.dart` — `getModerationResult` |
| Cat detection client | `lib/services/cat_detection_service.dart` — `containsCatFromBytes` |
| Send photo + write flag | `lib/screens/chat/chat_room_screen.dart` — `_sendPhoto()`, Firestore `add()` |
| Read messages + pass flag | `lib/screens/chat/chat_room_screen.dart` — stream `itemBuilder`, `MessageBubble(...)` |
| Display blur | `lib/widgets/message_bubble.dart` → `lib/widgets/blurred_image_with_unblur.dart` |
