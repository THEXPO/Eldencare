# EldenCare — Cloud Synchronization & Backend REST API

This backend provides cloud synchronization, role-based access control (RBAC), and domain business logic for **EldenCare**.

---

## 1. Quick Start

### Prerequisites
- Node.js $\ge$ 18 (installed: `v24.12.0`)
- npm $\ge$ 9

### Install Dependencies
```bash
cd backend
npm install
```

### Configure Environment Variables
Copy `.env.example` to `.env` or reference the root `.env`:
```ini
PORT=3000
NODE_ENV=development
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

### Authentication and Local Demos

Real accounts require a configured Supabase project; access tokens are verified
with Supabase Auth. Missing configuration never enables unverified JWT access.

For a local demo without Supabase, set `ENABLE_DEMO_AUTH=true` and
`NODE_ENV=development`, and leave the Supabase URL and keys unset (including in
the root `.env`). Only `demo-patient-token`, `demo-caretaker-token`,
`demo-doctor-token`, and the legacy `test-token` alias are accepted.
Demo authentication is disabled by default and is always disabled in production,
in other environments, or when Supabase is configured. Do not expose a local
demo server to the internet.

### Start Local Development Server
```bash
npm run dev
```
* **API Base URL**: `http://localhost:3000/api/v1`
* **Swagger API Docs**: `http://localhost:3000/api-docs`
* **Health Check**: `http://localhost:3000/health`

### Run Backend Automated Tests
```bash
npm test
```

---

## 2. API Groups

- **Auth & Profiles**: `/api/v1/me`, `/api/v1/me/profile`
- **Patient Management**: `/api/v1/patients`, `/api/v1/patients/:patientId/overview`
- **Medications**: `/api/v1/patients/:patientId/medications` (with duplicate detection)
- **Daily Tasks**: `/api/v1/patients/:patientId/tasks`
- **Confirmations & Dual Review**: `/api/v1/task-instances/:instanceId/confirmations`, `/api/v1/patients/:patientId/discrepancies`
- **Health Readings**: `/api/v1/patients/:patientId/blood-pressure`, `/api/v1/patients/:patientId/glucose`
- **Appointments**: `/api/v1/patients/:patientId/appointments`
- **Doctor Care Plans**: `/api/v1/patients/:patientId/care-plans`, `/api/v1/care-plans/:planId/activate`
- **Consultation Notes**: `/api/v1/patients/:patientId/consultations`
