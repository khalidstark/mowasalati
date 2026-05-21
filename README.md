# Mowasalati (مواصلاتي)

**An AI-Powered Public Transportation App for Egypt**

Mowasalati solves one of the most frustrating parts of getting around in Egypt — figuring out which combination of bus, microbus, metro, or taxi to take, how long it'll actually take, and how much it'll cost. It uses Google Gemini AI and geospatial data to generate accurate, multi-modal travel routes across Egyptian cities and governorates.

A scientific poster for this project is included in the repo: [`Postermowasalati.pdf`](./Postermowasalati.pdf)

---

## The Problem

Egypt's intercity transportation network is complex — multiple transport modes, no unified timetable, inconsistent info, and existing apps that don't cover the full picture (especially outside Cairo). Locals rely on asking around or guessing. Mowasalati replaces that with AI-generated, geospatially-verified routes.

---

## How It Works

The app takes a starting point and destination, then runs them through a multi-stage AI pipeline:

1. **Prompt Engineering** — Builds a structured natural language prompt for Gemini, requesting a JSON-formatted route plan covering transport types, cost, duration, and number of transfers
2. **Gemini API Call** — Sends the prompt to Gemini 2.5 Flash, which generates plausible routes based on its training data
3. **Data Parsing & Sanitization** — Cleans the raw response, extracts valid JSON, and casts all fields to typed Dart objects
4. **Geocoding** — Converts location names to precise coordinates using Google Maps API
5. **Multi-Criteria Ranking** — Scores each route: Cost (40%), Duration (50%), Transfers (10%)
6. **Map Visualization** — Renders the best route on an interactive Flutter map with polylines and key stops

---

## Features

- Multi-modal routes: bus, microbus, metro, taxi — combined intelligently
- Real-time travel tips (traffic congestion warnings, best travel times)
- Cost and duration estimates per route
- Interactive map with route visualization
- Tested across Cairo, Alexandria, Mansoura, Qalyubia, Giza, and border regions

**Accuracy results from field testing:**

| Location | Accuracy |
|---|---|
| Cairo | 91% |
| Alexandria | 90% |
| Giza | 90% |
| Mansoura | 87% |
| Qalyubia | 85% |
| Border Areas | 75% |

---

## Tech Stack

| Layer | Tech |
|---|---|
| Mobile & Web App | Flutter (Dart) |
| AI / NLP | Google Gemini 2.5 Flash API |
| Maps & Geocoding | Google Maps Flutter + Maps API |
| Backend | Python (`main.py`) |
| Database | Firebase Firestore |
| State | Shared Preferences |

---

## Setup

1. Install dependencies:
```bash
flutter pub get
```

2. Create your local environment file from the template:
```bash
cp .env.example .env
```
Then open `.env` and replace `YOUR_GEMINI_API_KEY_HERE` with a real key from [Google AI Studio](https://aistudio.google.com/app/apikey). The `.env` file is gitignored — never commit it.

3. Set up your Google Maps API key in `android/app/src/main/AndroidManifest.xml` and `web/index.html`

4. Configure Firebase with your own project via `lib/firebase_options.dart`

5. Run:
```bash
# Mobile
flutter run

# Web
flutter run -d chrome
```

---

## Research

This project was presented as a scientific research poster at GIU (German International University). The poster covers the methodology, hypothesis, results, and comparisons with existing Egyptian transport apps (Mwasalat Misr, Swvl, Moovit, Uber Egypt, Careem).

See [`Postermowasalati.pdf`](./Postermowasalati.pdf) for the full paper.
