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
