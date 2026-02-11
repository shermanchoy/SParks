const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { ImageAnnotatorClient } = require("@google-cloud/vision");

const vision = new ImageAnnotatorClient();

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
      const minScore = 0.1;
      const catTerms = [
        "cat", "tabby", "kitten", "domestic cat", "feline", "felidae",
        "cat face", "persian cat", "siamese", "maine coon", "cat breed",
        "whiskers", "small to medium-sized cats",
        "domestic short-haired cat", "domestic long-haired cat", "felis catus",
        "big cat", "cat animal", "house cat",
        "bengal", "ragdoll", "british shorthair", "cat-like", "catlike",
      ];
      for (const l of labels) {
        const desc = (l.description || "").toLowerCase().trim();
        const score = l.score || 0;
        if (score < minScore) continue;
        const match = catTerms.some((term) => desc === term || desc.includes(term)) ||
          /(^|\s)cat(\s|$)/.test(desc) ||
          /\bcat\b/.test(desc);
        if (match) {
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
      const labels = result?.labelAnnotations || [];
      let containsCat = false;
      const minScore = 0.1;
      const catTerms = [
        "cat", "tabby", "kitten", "domestic cat", "feline", "felidae",
        "cat face", "persian cat", "siamese", "maine coon", "cat breed",
        "whiskers", "small to medium-sized cats",
        "domestic short-haired cat", "domestic long-haired cat", "felis catus",
        "big cat", "cat animal", "house cat",
        "bengal", "ragdoll", "british shorthair", "cat-like", "catlike",
      ];
      const labelStr = labels
        .filter((l) => (l.score || 0) >= minScore)
        .map((l) => `${(l.description || "").toLowerCase()}:${(l.score || 0).toFixed(2)}`)
        .join(", ");
      console.log("detectCatInImage labels (score>=" + minScore + "):", labelStr || "(none)");
      for (const l of labels) {
        const desc = (l.description || "").toLowerCase().trim();
        const score = l.score || 0;
        if (score < minScore) continue;
        const match = catTerms.some((term) => desc === term || desc.includes(term)) ||
          /(^|\s)cat(\s|$)/.test(desc) ||
          /\bcat\b/.test(desc);
        if (match) {
          containsCat = true;
          console.log("detectCatInImage match:", desc, "score:", score);
          break;
        }
      }
      if (!containsCat && labelStr) {
        console.log("detectCatInImage NO cat match. Add one of these to catTerms if it is a cat image:", labelStr);
      }
      console.log("detectCatInImage returning containsCat:", containsCat);
      return { containsCat };
    } catch (e) {
      console.error("Vision API error:", e);
      return { containsCat: false };
    }
  }
);
