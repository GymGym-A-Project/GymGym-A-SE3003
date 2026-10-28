# Planning Poker Estimation Session & Effort Baseline

- **Session Date:** 27 October 2026
- **Facilitator:** Mehmet Egemen Karagöz (`230717063` — Project Manager / Facilitator)
- **Participants:**
  - Doğukan Direksiz (`230717015` — Product Owner Representative)
  - Çağatay Oruk (`230717041` — Technical Lead)
  - Berat Kaan Akcan (`230717052` — Quality and Test Lead)
- **Estimation Scale:** Modified Fibonacci Story Points (`1, 2, 3, 5, 8, 13` SP), validated via bottom-up ideal-hour breakdown (`1 SP ≈ 2.4 ideal person-hours`).
- **Total Agreed Baseline:** `80 Story Points` (`~192 ideal person-hours` across 8 active development weeks, Weeks 5–12).

---

## 1. Capacity Calibration

| Parameter | Baseline Value | Notes |
| :--- | :--- | :--- |
| Team Size | `4` members | PM, PO, Tech Lead, QA Lead |
| Active Development Window | `8` weeks (Weeks 5–12) | Four 2-week sprints (`Sprint 1` – `Sprint 4`) |
| Weekly Individual Commitment | `~6` ideal hours/week (`6–8 h` range) | `24` team hours/week (`48` hours/sprint) |
| Total Project Capacity | `192` ideal person-hours (`80 SP`) | `1 SP ≈ 2.4 ideal hours` (`~20 SP` average velocity/sprint) |
| Midterm Exam Buffer (Weeks 7–9) | `20%` expected dip (`A-04`) | Mitigated by front-loading `WP-01`–`WP-04` (`30 SP`) into Sprint 1 |

---

## 2. Work Package & User Story Consensus Table

During the 27.10.2026 session, each Epic (`WP-01`–`WP-08`) was decomposed into two concrete User Stories (`US-01`–`US-16`) so that no single story exceeded `8 SP`. Team members revealed Fibonacci cards simultaneously and discussed discrepancies before locking consensus values:

| Epic ID | User Story | Priority | Round 1 Cards (PO / Tech / QA / PM) | Consensus SP | Ideal Hours | Assigned Owner | Target Sprint |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :---: |
| **WP-01** | `US-01`: Initialize Flutter project skeleton & bundle 152-exercise JSON asset | Must | `3 / 3 / 3 / 3` | **3 SP** | `~7 h` | Çağatay Oruk | Sprint 1 |
| **WP-01** | `US-02`: Configure Firebase connection, Firestore offline cache & GitHub Actions CI | Must | `3 / 3 / 5 / 3` | **3 SP** | `~7 h` | Çağatay Oruk | Sprint 1 |
| **WP-02** | `US-03`: Implement email/password sign-up, sign-in & persistent session state | Must | `3 / 3 / 3 / 3` | **3 SP** | `~7 h` | Çağatay Oruk | Sprint 1 |
| **WP-02** | `US-04`: Add password reset flow, auth error messages & UID Firestore rules | Must | `2 / 3 / 3 / 3` | **3 SP** | `~7 h` | Çağatay Oruk | Sprint 1 |
| **WP-03** | `US-05`: Build exercise library list with muscle-group filter & keyword search (`< 150 ms`) | Must | `5 / 5 / 5 / 5` | **5 SP** | `~12 h` | Doğukan Direksiz | Sprint 1 |
| **WP-03** | `US-06`: Build exercise detail view with `180x180` GIF & mandatory `"© Gym visual"` attribution | Must | `3 / 3 / 3 / 3` | **3 SP** | `~7 h` | Doğukan Direksiz | Sprint 1 |
| **WP-04** | `US-07`: Create and view custom workout routines (1–15 exercises with target sets) | Must | `5 / 5 / 5 / 5` | **5 SP** | `~12 h` | Doğukan Direksiz | Sprint 1 |
| **WP-04** | `US-08`: Edit, reorder and delete routines with Firestore & offline cache persistence | Must | `5 / 5 / 5 / 5` | **5 SP** | `~12 h` | Doğukan Direksiz | Sprint 1 |
| **WP-05** | `US-09`: Build active workout session logger (sets, weight in kg, reps & dynamic exercises) | Must | `8 / 8 / 8 / 8` | **8 SP** | `~19 h` | Çağatay Oruk | Sprint 2 |
| **WP-05** | `US-10`: Implement previous-session ghost value pre-fill (`< 200 ms`) & workout summary | Must | `5 / 8 / 8 / 8` | **8 SP** | `~19 h` | Çağatay Oruk | Sprint 2 |
| **WP-06** | `US-11`: Build chronological workout history list with set breakdown | Must | `5 / 5 / 5 / 5` | **5 SP** | `~12 h` | Berat Kaan Akcan | Sprint 2 |
| **WP-06** | `US-12`: Build per-exercise max weight & volume progression history view | Must | `5 / 5 / 5 / 5` | **5 SP** | `~12 h` | Berat Kaan Akcan | Sprint 2 |
| **WP-07** | `US-13`: Implement deterministic 30-day plateau detection engine & 10 synthetic unit tests | Should | `5 / 8 / 8 / 8` | **8 SP** | `~19 h` | Berat Kaan Akcan | Sprint 3 |
| **WP-07** | `US-14`: Build Gemini Flash Cloud Function proxy, 152-ID whitelist filter & 4s fallback | Should | `8 / 5 / 5 / 8` | **6 SP** | `~15 h` | Çağatay Oruk | Sprint 3 |
| **WP-08** | `US-15`: Add monthly workout calendar highlight view & 3 static starter programs | Should | `3 / 3 / 3 / 3` | **3 SP** | `~7 h` | Doğukan Direksiz | Sprint 4 |
| **WP-08** | `US-16`: Add one-tap Google Sign-In integration | Should | `3 / 3 / 3 / 3` | **3 SP** | `~7 h` | Doğukan Direksiz | Sprint 4 |
| **PM-QA** | `#27`: Project management, weekly status tracking, QA verification & M2–M5 reports | Must | `1 SP / sprint` | **4 SP** | `~10 h` | Mehmet Egemen Karagöz & Berat Kaan Akcan | Sprints 1–4 |
| **Total** | **8 Epics (`16` User Stories + `PM-QA`)** | **6 Must / 2 Should** | **Unanimous** | **80 SP** | **192 h** | **Whole Team** | **Weeks 5–12** |

---

## 3. Key Estimation Discussions & Adjustments

1. **`US-02` (Firebase & Security Rules):** QA Lead initially played `5 SP` citing emulator rules testing complexity (`test/firebase/firestore.rules.test.js`); Tech Lead demonstrated that the Week 3 spike configuration could be reused directly, bringing consensus to `3 SP`.
2. **`US-10` (Ghost Values Engine):** PO initially played `5 SP`; Tech Lead and QA Lead explained that maintaining deterministic `< 200 ms` local cache pre-fill alongside end-of-workout volume aggregation and `lastPerformance` synchronization warranted `8 SP`.
3. **`US-14` (Gemini Proxy & Whitelist Filter):** Because the Node.js Cloud Function proxy (`functions/index.js`) and 152-ID whitelist unit tests were already prototyped in the Week 3 technical spike (`spike/week3-feasibility`), effort for Sprint 3 integration was calibrated at `6 SP` (`WP-07` total = `14 SP`).

---

## 4. Sprint Load Distribution

| Sprint | Window | Work Packages | Planned SP | Ideal Hours | Strategic Rationale |
| :--- | :--- | :--- | :---: | :---: | :--- |
| **Sprint 1** | `23.10.2026 – 08.11.2026` | `WP-01`, `WP-02`, `WP-03`, `WP-04` + `1 SP` PM-QA | `31 SP` (`30 + 1`) | `~74 h` | Front-loaded while exam load is low; `WP-01` accelerated by Week 3 spike assets |
| **Sprint 2 (M3)** | `09.11.2026 – 22.11.2026` | `WP-05`, `WP-06` + `1 SP` PM-QA | `27 SP` (`26 + 1`) | `~65 h` | Delivers 100% of `Must` MVP scope prior to M3 Midterm Review |
| **Sprint 3** | `23.11.2026 – 06.12.2026` | `WP-07` + `1 SP` PM-QA | `15 SP` (`14 + 1`) | `~36 h` | Delivers Plateau Analyzer and reserves capacity for the Course Change Event |
| **Sprint 4 (M4)** | `07.12.2026 – 20.12.2026` | `WP-08` + `1 SP` PM-QA | `7 SP` (`6 + 1`) | `~17 h` | Secondary UX (`Should`), Change Event adaptation, and full regression QA buffer |
| **Total** | **Weeks 5–12** | **All Baseline Scope** | **80 SP** | **192 h** | **Approved Baseline (v1.0 — 01.11.2026)** |
