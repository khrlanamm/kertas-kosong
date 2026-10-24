# Kertas Kosong

Tryout and student portal for Bimbel Ayo Kuliah 2026, the university entrance study program run by Komunitas Kertas Kosong.

Live at [kertas-kosong.web.app](https://kertas-kosong.web.app).

## Pages

- `/`: landing page with the tryout schedule and important links.
- `/portal-bimbel`: student portal with class recordings by week and subtest, and attendance links.
- `/tryout`: tryout questions by subtest, opened during the scheduled window.

Content comes from Firestore (`jadwal_tryout`, `rekaman`, `kehadiran`, `tryout`, `tautan_penting`) and is read-only for visitors.

## Stack

React 18, Vite, Tailwind CSS, React Router, Firebase (Firestore and Hosting).

## Running locally

Create `.env` with the Firebase web config (not committed):

```sh
VITE_FIREBASE_API_KEY=...
VITE_FIREBASE_AUTH_DOMAIN=...
VITE_FIREBASE_PROJECT_ID=...
VITE_FIREBASE_STORAGE_BUCKET=...
VITE_FIREBASE_MESSAGING_SENDER_ID=...
VITE_FIREBASE_APP_ID=...
VITE_FIREBASE_MEASUREMENT_ID=...
```

Then:

```sh
npm install
npm run dev
```

## Deploy

```sh
npm run build
firebase deploy --only hosting
```
