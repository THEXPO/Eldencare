# 🩺 EldenCare — Care, Connected. Health, Simplified.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-20+-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL%20%7C%20Auth-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM%20%7C%20Hosting-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Render](https://img.shields.io/badge/Render-Deployed%20Backend-46E3B7?logo=render&logoColor=white)](https://eldencare.onrender.com)

**EldenCare** is an elderly healthcare management and safety platform designed to bridge communication between **seniors**, **family caregivers**, and **attending physicians**. It eliminates medication non-adherence and over-medication through an innovative **Dual Confirmation Safety System**, proactive push notifications, and clinical care plan versioning.

---

## 🌐 Live Deployments

| Component | Status | URL |
| :--- | :--- | :--- |
| **Backend REST API** | 🟢 Live on Render | [https://eldencare.onrender.com](https://eldencare.onrender.com) |
| **Interactive Swagger API Docs** | 🟢 Available | [https://eldencare.onrender.com/api-docs](https://eldencare.onrender.com/api-docs) |
| **Backend Health Check** | 🟢 Healthy | [https://eldencare.onrender.com/health](https://eldencare.onrender.com/health) |
| **Web Frontend (Firebase)** | 🚀 Ready for Hosting | [https://eldencare.web.app](https://eldencare.web.app) |

---

## 💡 The Problem & Our Solution

### The Challenge
1. **Medication Mismanagement:** Elderly patients frequently forget whether they took their morning pills, leading to either missed doses or dangerous accidental double-dosing.
2. **Caregiver Blind Spots:** Family caregivers often have no clear visibility into whether routines were completed without intrusive calls.
3. **Disconnected Medical Oversight:** Doctors prescribe medications without a continuous feedback loop on patient adherence or home vital trends.

### The EldenCare Solution
* **Elder-First Accessibility:** Simplified touch targets, readable typography, and calming color palettes designed for low-vision and non-tech-savvy seniors.
* **Dual Confirmation Engine:** Independent task verification by both senior and caregiver. When logs mismatch (e.g. senior marked taken, but caregiver found full pillbox), an immediate **Discrepancy Alert** is flagged to the care team.
* **Clinical Care Plans:** Doctors review vitals, log consultation notes, and publish immutable versioned care plans with automated duplicate prescription warnings.
* **Time-Aware Push Automation:** Automated 24-hour and 1-hour appointment reminders, routine alerts, and configurable **Quiet Hours** ensuring sleep is uninterrupted except for vital medical emergencies.

---

## 👥 Three Tailored Interfaces (One Unified Platform)

```
                            +--------------------------+
                            |     EldenCare Platform   |
                            +------------+-------------+
                                         |
            +----------------------------+----------------------------+
            |                            |                            |
            v                            v                            v
   👵 Patient Mode              🤝 Caretaker Mode            🩺 Doctor Mode
   - High-contrast UI           - Real-time Vitals (BP/Glu)  - Patient Roster
   - Today's Routine Schedule   - Daily Routine Verification - Versioned Care Plans
   - 1-Tap Completion Buttons   - Dual Confirmation Alerts   - Consultation Notes
   - Medication Reminders       - Clinic Appointments Log    - Adherence & Trends
```

### 1. 👵 Patient Mode
* Accessible typography and high-contrast color scheme (`#1B6B6B` Teal on `#F7F4EE` Sand).
* Simple daily schedule grouping tasks into Morning, Afternoon, Evening, and Night.
* One-tap confirmation cards for Medication, Diet, and Physical Therapy.

### 2. 🤝 Caretaker Mode
* Multi-patient management dashboard with real-time status indicators.
* Health vital recorders for Blood Pressure (Systolic/Diastolic/Pulse) and Blood Glucose (Fasting/Post-meal).
* Confirmation review feed highlighting discrepancies in real time.
* Clinic visit scheduler with 24-hour and 1-hour automated push reminders.

### 3. 🩺 Doctor Mode
* Comprehensive patient health summaries, historical charts, and active prescription overview.
* Care plan manager with draft editing, change summaries, and automatic duplicate medication detection.
* Chronological consultation notes log.
* Adherence analytics with interactive vitals trend graphing powered by `fl_chart`.

---

## 🏗️ Architecture & Technology Stack

### Frontend (Mobile & Web)
* **Framework:** Flutter 3.x (Dart 3.x) targeting Android, iOS, and Web.
* **State Management:** Provider Architecture with workspace-isolated data providers.
* **Data Visualization:** `fl_chart` for systolic/diastolic blood pressure and glucose charts.
* **Web Push Notifications:** Firebase Cloud Messaging (`firebase_messaging` + Service Worker).
* **Cross-Platform Storage:** Native file persistence with automatic `SharedPreferences` / browser `localStorage` fallback.

### Backend & Cloud Database
* **Runtime:** Node.js with Express.js and TypeScript.
* **Database:** Supabase PostgreSQL with strict Row-Level Security (RLS) policies.
* **Authentication:** Supabase Auth (JWT) with email/password and session restoration.
* **Automation & Scheduler:** Background `node-cron` daemon evaluating notification preferences, quiet hours, and appointment reminder windows.
* **Push Notifications:** Firebase Admin SDK server-side multicast messaging.
* **API Documentation:** Interactive OpenAPI 3.0 / Swagger UI at `/api-docs`.

---

## 📁 Repository Structure

```
Eldencare/
├── android/                   # Native Android project (Kotlin DSL, google-services.json)
├── backend/                   # Node.js Express REST API (TypeScript)
│   ├── src/
│   │   ├── config/            # Env, Supabase clients, Firebase Admin
│   │   ├── controllers/       # HTTP request handlers (Auth, Care Plans, Tasks, etc.)
│   │   ├── middleware/        # JWT Authentication, RBAC, Zod Validators
│   │   ├── routes/            # Express REST route definitions
│   │   ├── services/          # Dual confirmation, scheduler, FCM push dispatch
│   │   ├── types/             # Domain TypeScript interfaces
│   │   └── server.ts          # Server entry point & cron scheduler bootstrap
│   ├── tests/                 # Jest automated test suites
│   └── package.json           # Backend dependencies & build scripts
├── lib/                       # Flutter Cross-Platform Application
│   ├── config/                # Supabase, API, and Firebase configuration
│   ├── models/                # Immutable domain data models
│   ├── providers/             # State providers (Auth, Care, Role, Notifications)
│   ├── repositories/          # Platform-safe data persistence layer
│   ├── screens/
│   │   ├── auth/              # Login, Registration, Recovery, Onboarding
│   │   ├── caretaker/         # Daily Care, Vitals forms, Appointments
│   │   ├── doctor/            # Doctor Dashboard, Care Plans, Consultations
│   │   ├── notifications/     # Notification History & Preferences UI
│   │   └── patient/           # Accessible Patient Home, Schedule, Health
│   ├── services/              # Notification service, Seed data, Schedule service
│   ├── theme/                 # Accessibility-focused Material 3 theme
│   └── main.dart              # Flutter application entry point
├── supabase/
│   └── migrations/            # SQL migration scripts (Tables, Triggers, RLS)
├── web/                       # Web build template, service worker & icons
└── firebase.json              # Firebase Hosting & FlutterFire configuration
```

---

## 🚀 Quick Start Guide

### 1. Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.24+ recommended)
* [Node.js](https://nodejs.org/) (v18+ or v20+)
* npm or pnpm

### 2. Run the Backend Locally
```bash
cd backend
npm install
npm run dev
```
* API Server: `http://localhost:3000/api/v1`
* Interactive Swagger Docs: `http://localhost:3000/api-docs`
* Health Check: `http://localhost:3000/health`

### 3. Run the Flutter Application Locally
```bash
# In the repository root:
flutter pub get

# Run on Chrome Web:
flutter run -d chrome

# Run on Android Emulator / Device:
flutter run -d android
```

### 4. Build Flutter for Public Web Hosting
```bash
flutter build web --release \
  --dart-define=BACKEND_URL=https://eldencare.onrender.com \
  --dart-define=SUPABASE_URL=https://pkprjgpoolrtzkalnfxy.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_QOam9LD8droQp8WcnMvF3g_mmMxnVvU \
  --base-href="/"
```
Deploy the output in `build/web` to Firebase Hosting:
```bash
firebase deploy --only hosting
```

---

## 🔑 Hackathon Quick Evaluation & Demo Sandbox

EldenCare includes a **Sandbox Mode** accessible directly from the top AppBar chip. Evaluators can instantly switch roles without registering separate accounts:

| Demo Profile | Role | Context |
| :--- | :--- | :--- |
| **Eleanor Vance** | 👵 Patient | 78-year-old senior managing hypertension and mild type 2 diabetes. |
| **Priya Hart** | 🤝 Caretaker | Primary family caregiver (daughter) managing daily care and logging vitals. |
| **Dr. Sarah Nguyen, MD** | 🩺 Doctor | Lead Geriatrician reviewing blood pressure trends and prescribing care plans. |

### Demo Invitation Codes (For Testing Real Registration Flow)
* Caretaker joining patient: `ELDEN-CARE-789` or `CARE-789`
* Doctor clinic verification: `DOCTOR-CLINIC-456` or `DOC-456`

---

## 🔒 Security & Privacy

* **Zero Secret Leakage:** Firebase Admin SDK service account credentials reside exclusively on the trusted Node.js backend. The Flutter app never receives or stores administrative keys.
* **Row-Level Security (RLS):** Database policies ensure that patients, caregivers, and doctors can only access data belonging to authorized care relationships.
* **Session Sanitization:** Logging out instantly deletes the device FCM token from the server, clears cached health data from memory, and purges local session stores.

---

## 📄 License
This project is licensed under the MIT License.
