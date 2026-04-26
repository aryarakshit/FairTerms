# FairTerms

**AI-powered bias detection in payment terms for Indian SMEs.**

FairTerms helps small and medium enterprises detect hidden discrimination in the payment terms offered by large corporate buyers. Using counterfactual AI analysis and statistical fairness metrics, it answers: *"Would I get worse payment terms just because of where I am, or who I am?"*

Built for the **GDG Solution Challenge 2026** — Open Innovation Track, *Unbiased AI Decision* theme.

---

## What it does

1. **Submit** your buyer's payment terms (days-to-pay, order value, buyer type).
2. **Analyse** — the system runs counterfactual analysis via Groq LLM + a Python statistical fairness engine.
3. **Report** — receive a plain-language fairness score, bias factor breakdown, peer benchmark comparison, and an interest-owed calculation under the MSMED Act 2006.
4. **Act** — download a pre-drafted MSME Samadhaan grievance letter or RTI application as a PDF.

---

## Architecture

```
fairterms-app/          Flutter web app (frontend)
fairterms-api/          Node.js + Express REST API (backend)
fairness-engine/        Python FastAPI microservice (statistical fairness)
```

| Layer | Stack | Deployed on |
|---|---|---|
| Frontend | Flutter 3, Riverpod, GoRouter | Firebase Hosting |
| Backend API | Node.js, Express 5, Firebase Admin | Google Cloud Run |
| Fairness Engine | Python 3.12, FastAPI, pandas, scipy | Google Cloud Run |
| Auth | Firebase Authentication (Google sign-in) | Firebase |
| Database | Firestore | Firebase |
| AI | Groq API (Llama 3.3 70B) | External |

---

## Getting started

### Prerequisites

- Flutter SDK >= 3.5
- Node.js >= 20
- Python >= 3.12
- A Firebase project with Firestore and Authentication enabled
- A [Groq API key](https://console.groq.com/) (free tier available)

---

### 1. Fairness Engine (Python)

```bash
cd fairness-engine
python -m venv .venv
source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env            # edit if needed
uvicorn src.main:app --port 8081 --reload
```

The engine runs at `http://localhost:8081`. Verify with:

```bash
curl http://localhost:8081/health
```

---

### 2. Backend API (Node.js)

```bash
cd fairterms-api
npm install
cp .env.example .env
```

Edit `.env` and fill in:

| Variable | Where to get it |
|---|---|
| `GROQ_API_KEY` | [console.groq.com](https://console.groq.com) |
| `GOOGLE_APPLICATION_CREDENTIALS` | Firebase Console > Project Settings > Service Accounts > Generate new private key. Save as `firebase-adminsdk.json` (see `firebase-adminsdk.json.example` for the expected shape). |

Start the server:

```bash
npm run dev        # development (nodemon)
npm start          # production
```

API runs at `http://localhost:8080`.

> **Mock mode** — set `ALLOW_MOCK_AUTH=true` and `ALLOW_MOCK_GEMINI=true` in `.env` to run without real Firebase credentials or a Groq key.

---

### 3. Flutter App

```bash
cd fairterms-app
flutter pub get
```

Fill in `lib/firebase_options.dart` with your Firebase web config (run `flutterfire configure` or copy values from the Firebase Console).

```bash
# Development (web)
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080/api/v1

# Production build
flutter build web \
  --dart-define=API_BASE_URL=https://YOUR_CLOUD_RUN_URL/api/v1
```

---

## Environment variables

### `fairterms-api/.env`

See [`.env.example`](fairterms-api/.env.example) for the full list. Key variables:

| Variable | Required | Description |
|---|---|---|
| `GROQ_API_KEY` | Yes (prod) | Groq LLM inference key |
| `GOOGLE_APPLICATION_CREDENTIALS` | Yes (prod) | Path to Firebase service-account JSON |
| `FAIRNESS_ENGINE_URL` | Yes | URL of the Python fairness engine `/compute` endpoint |
| `ALLOW_MOCK_AUTH` | Dev only | Skip Firebase token verification |
| `ALLOW_MOCK_GEMINI` | Dev only | Return canned AI responses |

### `fairness-engine/.env`

| Variable | Default | Description |
|---|---|---|
| `PORT` | `8081` | Listen port |
| `SEED_RECORD_COUNT` | `1000` | Synthetic peer records to generate on startup |
| `BIGQUERY_ENABLED` | `false` | Enable BigQuery aggregation backend |

---

## Project structure

```
fairterms-api/
  src/
    controllers/        Route handlers
    middleware/         Auth, validation
    routes/             Express routers
    services/
      gemini.service.js   Multi-agent Groq pipeline (orchestrator > bias detector > report + grievance)
      fairness.service.js Calls Python fairness engine
      firestore.service.js Firestore CRUD
      pdf.service.js      PDF generation

fairness-engine/
  src/
    main.py             FastAPI entry point
    bias_detector.py    Counterfactual bias scoring
    benchmarking.py     Peer benchmarking (pincode / state / industry)
    metrics.py          Statistical parity, disparate impact, equal opportunity
    aggregation.py      Heatmap / leaderboard aggregation
    models.py           Pydantic request/response models

fairterms-app/
  lib/
    screens/            All app screens (dashboard, report, history, ...)
    providers/          Riverpod state (auth, analysis, profile)
    services/           API client, auth service
    models/             Dart data classes
    widgets/            Reusable UI components
    utils/
      theme.dart        Design system (Fraunces + Inter, paper palette)
      constants.dart    App-wide constants
```

---

## AI pipeline

The backend runs a **multi-agent pipeline** using the Groq API:

```
Orchestrator  ->  validates input, plans execution
     |
     v
Bias Detector  ->  counterfactual analysis across 5 dimensions
     |               (location, industry, scale, region, firm age)
     |-------------------------------------|
     v                                     v
Report Generator                    Grievance Writer
(plain-language explanation)        (MSMED Samadhaan letter + RTI template)
```

All agents are prompted to return **JSON only** and run with retry logic (up to 3 attempts with exponential back-off).

---

## Security notes

- `.env` files and `firebase-adminsdk.json` are excluded from git via `.gitignore`.
- **Never commit real API keys or service-account credentials.**
- Use `firebase-adminsdk.json.example` as a template; fill in real values locally.
- Firebase web config (`firebase_options.dart`) contains a web API key that is intentionally public — restrict it in the Firebase Console under *API restrictions*.
- All API routes require a valid Firebase ID token (except health-check endpoints).
- Input validated with allow-list patterns; no raw user data reaches the database.

---

## Running tests

```bash
# API integration tests (Playwright)
cd fairterms-api
npm test

# Python unit tests
cd fairness-engine
python -m pytest tests/
```

---

## Deploying to Google Cloud

Both backend services include `Dockerfile`s ready for Cloud Run.

```bash
# Fairness engine
gcloud run deploy fairness-engine \
  --source fairness-engine/ \
  --region asia-south1 \
  --allow-unauthenticated

# API
gcloud run deploy fairterms-api \
  --source fairterms-api/ \
  --region asia-south1 \
  --allow-unauthenticated
```

Deploy the Flutter web app to Firebase Hosting:

```bash
cd fairterms-app
flutter build web --dart-define=API_BASE_URL=https://YOUR_API_URL/api/v1
firebase deploy --only hosting
```

---

## License

MIT — see [LICENSE](LICENSE).

---

## Team

Built at GDG Solution Challenge 2026 by a 3-member team.
