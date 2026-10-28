# Competitor Gap Review — Strong vs. Hevy

- **Review Date:** 14 October 2026
- **Apps Evaluated:** Strong Workout Tracker Gym Log (`v5.x`, Android) and Hevy — Gym Log Workout Tracker (`v2.x`, Android)
- **Reviewer:** Doğukan Direksiz (Product Owner Representative)

## 1. Purpose

In our M0 report, our initial hypothesis was that displaying previous-session weights/reps ("ghost values") alongside an on-demand 30-day plateau analyzer would differentiate GymGym-A from existing workout loggers. During Week 3, both leading mobile workout trackers were tested through a full 3-exercise logging flow to verify this hypothesis against their current mobile builds.

## 2. Feature Comparison Matrix

| Capability | Strong (`v5.x` Free Tier) | Hevy (`v2.x` Free Tier) | GymGym-A (MVP Target) |
| :--- | :--- | :--- | :--- |
| **Previous Session Values ("Ghost Values")** | Yes — shows previous weight × reps column and pre-fills set inputs | Yes — displays previous session weight × reps per set | Yes — pre-fills previous weight and reps faintly (`< 200 ms` from local cache) |
| **Custom Routine Limit (Free Tier)** | **Restricted to 3 routines** (Paywall for unlimited routines) | **Restricted to 4 routines** (Pro subscription required for more) | **Unlimited custom routines** (1–15 exercises per routine, free) |
| **Offline Workout Logging** | Supported | Supported | Supported (`Cloud Firestore` local persistence + active draft recovery) |
| **Exercise Media & Instructions** | Static illustrations / Pro videos | Animations + community custom exercises | Curated **152-exercise** local catalog with `180×180` GIFs (`© Gym visual`) and EN/TR steps |
| **On-Demand 30-Day Plateau Detection** | **None** (shows charts only; Pro paywall for analytics) | **None** (shows volume/weight graphs; no automated stall detection) | **Built-in deterministic rule engine** (`≥ 3` sessions in 30 days with `0` gain in max weight & volume) |
| **Library-Constrained Alternative Suggestions** | **None** | **None** | **Gemini Flash explanation + 2–3 whitelist-verified alternatives** from the 152-exercise catalog (with rule-based offline fallback) |
| **Social Feed / Leaderboards** | Minimal | Heavy social feed, followers, leaderboards | **Intentionally excluded** (`Won't Have`) to keep logging frictionless |

## 3. Key Findings & Scope Impact

1. **Ghost Values Are Table Stakes, Not a Standalone Differentiator:** Both Strong and Hevy already display previous-session values inside active workout rows. Therefore, ghost values remain a **Must** usability baseline in GymGym-A (`WP-05`), but our primary value proposition centers on combining **unrestricted free routine creation** with **explainable, library-constrained 30-day plateau detection (`WP-07`)**.
2. **Free-Tier Routine Paywalls Frustrate Amateur Lifters:** Strong caps free users at 3 custom routines (making even a 4-day Upper/Lower split impossible without paying). GymGym-A allows unlimited custom routines (`WP-04`) plus 3 one-tap static starter templates (`WP-08`: Push/Pull/Legs, Upper/Lower, Full Body).
3. **Actionable Plateau Guidance Is Missing in Competitors:** Existing apps plot raw charts and leave interpretation to the user. Amateur lifters often repeat stalled movements for weeks without knowing which alternative exercise targets the same primary muscle group with different equipment. GymGym-A's deterministic rule engine flags stalls automatically and recommends 2–3 verified movements from the local 152-exercise catalog.
