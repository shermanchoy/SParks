const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { ImageAnnotatorClient } = require("@google-cloud/vision");

const vision = new ImageAnnotatorClient();

/**
 * Callable: moderateChatImage
 * Body: { image: "<base64 string>" }
 * Returns: { allowed: true } or { allowed: false }
 * Uses Google Cloud Vision Safe Search to block inappropriate chat photos.
 */
exports.moderateChatImage = onCall(
  { region: "us-central1", maxInstances: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in to send photos.");
    }
    const imageBase64 = request.data?.image;
    if (typeof imageBase64 !== "string" || !imageBase64) {
      throw new HttpsError("invalid-argument", "Missing image (base64).");
    }

    try {
      const [result] = await vision.safeSearchDetection({
        image: { content: imageBase64 },
      });
      const annotation = result.safeSearchAnnotation;
      if (!annotation) {
        return { allowed: false };
      }

      // Block if adult or racy is LIKELY or VERY_LIKELY
      const block = (likelihood) =>
        likelihood === "LIKELY" || likelihood === "VERY_LIKELY";
      const adult = (annotation.adult || "").toUpperCase();
      const racy = (annotation.racy || "").toUpperCase();
      const violence = (annotation.violence || "").toUpperCase();

      const allowed = !block(adult) && !block(racy) && !block(violence);
      return { allowed };
    } catch (e) {
      console.error("Vision API error:", e);
      throw new HttpsError("internal", "Image check failed.");
    }
  }
);
