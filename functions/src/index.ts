import { initializeApp } from "firebase-admin/app";
import { setGlobalOptions } from "firebase-functions/v2";

initializeApp();

// Samakan dengan lokasi Firestore (Jakarta).
setGlobalOptions({ region: "asia-southeast2", maxInstances: 10 });

export { hitungSkor, kumpulkanSubtes, mulaiSubtes, pembahasan } from "./ujian.js";
