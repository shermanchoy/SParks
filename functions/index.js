const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { ImageAnnotatorClient } = require("@google-cloud/vision");

const vision = new ImageAnnotatorClient();

/**
 * Callable: moderateChatImage
 * Body: { image: "<base64 string>" }
 * Returns: { allowed: boolean, containsCat?: boolean }
 * Uses Vision Safe Search + label detection (cat) so desktop/web can blur cat photos.
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
      const img = { image: { content: imageBase64 } };
      const [safeResult, labelResult] = await Promise.all([
        vision.safeSearchDetection(img),
        vision.labelDetection(img),
      ]);

      let allowed = false;
      const annotation = safeResult[0]?.safeSearchAnnotation;
      if (annotation) {
        const block = (l) => l === "LIKELY" || l === "VERY_LIKELY";
        const adult = (annotation.adult || "").toUpperCase();
        const racy = (annotation.racy || "").toUpperCase();
        const violence = (annotation.violence || "").toUpperCase();
        allowed = !block(adult) && !block(racy) && !block(violence);
      }

      let containsCat = false;
      const labels = labelResult[0]?.labelAnnotations || [];
      const minScore = 0.3;
      for (const l of labels) {
        const desc = (l.description || "").toLowerCase().trim();
        const score = l.score || 0;
        if (score < minScore) continue;
        if (desc === "cat" || desc.includes(" cat") || desc.includes("cat ") || desc === "tabby" || desc === "kitten" || desc === "domestic cat") {
          containsCat = true;
          break;
        }
      }

      return { allowed, containsCat };
    } catch (e) {
      console.error("Vision API error:", e);
      throw new HttpsError("internal", "Image check failed.");
    }
  }
);

/**
 * Callable: detectCatInImage
 * Body: { image: "<base64 string>" }
 * Returns: { containsCat: boolean }
 * Used for profile photos and when client cannot run ML Kit (e.g. Windows/web).
 */
exports.detectCatInImage = onCall(
  { region: "us-central1", maxInstances: 10 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }
    const imageBase64 = request.data?.image;
    if (typeof imageBase64 !== "string" || !imageBase64) {
      throw new HttpsError("invalid-argument", "Missing image (base64).");
    }
    try {
      const [result] = await vision.labelDetection({ image: { content: imageBase64 } });
      const labels = result.labelAnnotations || [];
      let containsCat = false;
      const minScore = 0.3;
      for (const l of labels) {
        const desc = (l.description || "").toLowerCase().trim();
        const score = l.score || 0;
        if (score < minScore) continue;
        if (desc === "cat" || desc.includes(" cat") || desc.includes("cat ") || desc === "tabby" || desc === "kitten" || desc === "domestic cat") {
          containsCat = true;
          break;
        }
      }
      return { containsCat };
    } catch (e) {
      console.error("Vision API error:", e);
      return { containsCat: false };
    }
  }
);
