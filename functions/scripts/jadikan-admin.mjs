#!/usr/bin/env node
/**
 * Jadikan pengguna sebagai admin portal. Pengguna harus sudah masuk ke portal
 * dan melengkapi profil.
 *
 *   node functions/scripts/jadikan-admin.mjs email@contoh.id
 *
 * Kredensial: secrets/firebase-adminsdk.json (tidak masuk git).
 */
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { cert, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

const email = process.argv[2];
if (!email) {
  console.error("Pakai: jadikan-admin.mjs email@contoh.id");
  process.exit(1);
}

const akar = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const sa = JSON.parse(readFileSync(join(akar, "secrets/firebase-adminsdk.json"), "utf8"));
initializeApp({ credential: cert(sa) });

const pengguna = await getAuth().getUserByEmail(email).catch(() => null);
if (!pengguna) {
  console.error(`${email} belum pernah masuk ke portal.`);
  process.exit(1);
}
const ref = getFirestore().doc(`pengguna/${pengguna.uid}`);
if (!(await ref.get()).exists) {
  console.error(`${email} belum melengkapi profil di portal.`);
  process.exit(1);
}
await ref.update({ peran: "admin", diperbarui: FieldValue.serverTimestamp() });
console.log(`${email} sekarang admin.`);
