# Exercise Catalog Curation & Schema (`152` Exercises)

- **Upstream Repository:** [hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset)
- **Pinned Commit:** `7455efae41b330c265e7cd4b78dfa848e7ce5ebd`
- **Data License:** MIT License
- **Media Attribution:** `© Gym visual — https://gymvisual.com/` (`180x180` GIF/JPG media)

## 1. Curation Criteria & Distribution

From the upstream catalog (`1,324` raw entries), `scripts/clean_dataset.py` validates and extracts a deterministic subset of **`152` exercises** tailored for standard gym equipment (`barbell`, `dumbbell`, `cable`, `machine`, `bodyweight`) and grouped into **6 primary muscle groups**:

1. **Category Mapping:** `chest` -> `chest`, `back` -> `back`, `upper legs` + `lower legs` -> `legs`, `shoulders` -> `shoulders`, `upper arms` + `lower arms` -> `arms`, `waist` -> `core` (`cardio` and `neck` excluded).
2. **Data Cleaning:** Removes stretching/mobility drills, acrobatic/gymnastics holds, camera-angle duplicates (`(back pov)`, `(side pov)`), duplicate exercise titles, and repairs character encoding anomalies (e.g., `sled 45в° leg press` -> `Sled 45° Leg Press`).
3. **Media Verification:** Verifies `GIF87a`/`GIF89a` headers, `180x180` pixel dimensions, JPEG thumbnail signatures, and bilingual (`en` + `tr`) step-by-step instructions.

| Primary Muscle Group | Total | Compound | Isolation | Target Muscle Breakdown | Equipment (`barbell / dumbbell / cable / machine / bodyweight`) |
| :--- | :---: | :---: | :---: | :--- | :---: |
| **Chest (`chest`)** | 26 | 17 | 9 | pectorals (26) | 3 / 6 / 6 / 6 / 5 |
| **Back (`back`)** | 28 | 22 | 6 | lats (12), upper back (12), traps (3), spine (1) | 3 / 4 / 7 / 8 / 6 |
| **Legs (`legs`)** | 30 | 18 | 12 | glutes (16), calves (5), hamstrings (4), quads (3), abductors (1), adductors (1) | 9 / 7 / 1 / 10 / 3 |
| **Shoulders (`shoulders`)** | 24 | 12 | 12 | delts (24) | 5 / 8 / 6 / 5 / 0 |
| **Arms (`arms`)** | 28 | 7 | 21 | triceps (13), biceps (11), forearms (4) | 7 / 9 / 5 / 4 / 3 |
| **Core (`core`)** | 16 | 4 | 12 | abs (16) | 1 / 1 / 4 / 2 / 8 |
| **Total** | **152** | **80** | **72** | | **28 / 35 / 29 / 35 / 25** |

## 2. JSON Schema (`assets/data/exercises.json`)

```json
{
  "schemaVersion": 1,
  "generatedAt": "2026-10-22T10:59:10Z",
  "count": 152,
  "source": {
    "repo": "https://github.com/hasaneyldrm/exercises-dataset",
    "commit": "7455efae41b330c265e7cd4b78dfa848e7ce5ebd",
    "dataLicense": "MIT",
    "mediaLicense": "© Gym visual (180x180 attribution required)"
  },
  "attribution": "© Gym visual — https://gymvisual.com/",
  "exercises": [
    {
      "id": "0025",
      "name": "Barbell Bench Press",
      "nameTr": null,
      "primaryMuscle": "chest",
      "targetMuscle": "pectorals",
      "secondaryMuscles": ["shoulders", "triceps"],
      "equipment": "barbell",
      "equipmentSource": "barbell",
      "movementType": "compound",
      "splitTags": ["push", "upper", "full_body"],
      "instructions": { "en": "...", "tr": "..." },
      "instructionSteps": { "en": ["..."], "tr": ["..."] },
      "gifPath": "assets/gifs/0025-EIeI8Vf.gif",
      "thumbPath": "assets/thumbs/0025-EIeI8Vf.jpg",
      "mediaId": "EIeI8Vf",
      "attribution": "© Gym visual — https://gymvisual.com/"
    }
  ]
}
```

## 3. Complete 152-Exercise Manifest

### Chest (`chest`) — 26 Exercises
| ID | Name | Target | Equipment | Type |
| :--- | :--- | :--- | :--- | :---: |
| `0025` | Barbell Bench Press | pectorals | barbell | C |
| `0047` | Barbell Incline Bench Press | pectorals | barbell | C |
| `0033` | Barbell Decline Bench Press | pectorals | barbell | C |
| `0289` | Dumbbell Bench Press | pectorals | dumbbell | C |
| `0314` | Dumbbell Incline Bench Press | pectorals | dumbbell | C |
| `0301` | Dumbbell Decline Bench Press | pectorals | dumbbell | C |
| `0308` | Dumbbell Fly | pectorals | dumbbell | I |
| `0319` | Dumbbell Incline Fly | pectorals | dumbbell | I |
| `0375` | Dumbbell Pullover | pectorals | dumbbell | I |
| `0155` | Cable Cross-over Variation | pectorals | cable | I |
| `0179` | Cable Low Fly | pectorals | cable | I |
| `0171` | Cable Incline Fly | pectorals | cable | I |
| `0158` | Cable Decline Fly | pectorals | cable | I |
| `2144` | Cable Seated Chest Press | pectorals | cable | C |
| `0227` | Cable Standing Fly | pectorals | cable | I |
| `0576` | Lever Chest Press | pectorals | machine | C |
| `1299` | Lever Incline Chest Press | pectorals | machine | C |
| `1300` | Lever Decline Chest Press | pectorals | machine | C |
| `0596` | Lever Seated Fly | pectorals | machine | I |
| `0748` | Smith Bench Press | pectorals | machine | C |
| `0757` | Smith Incline Bench Press | pectorals | machine | C |
| `0662` | Push-up | pectorals | bodyweight | C |
| `0279` | Decline Push-up | pectorals | bodyweight | C |
| `0493` | Incline Push-up | pectorals | bodyweight | C |
| `0251` | Chest Dip | pectorals | bodyweight | C |
| `1311` | Wide Hand Push Up | pectorals | bodyweight | C |

### Back (`back`) — 28 Exercises
| ID | Name | Target | Equipment | Type |
| :--- | :--- | :--- | :--- | :---: |
| `0652` | Pull-up | lats | bodyweight | C |
| `1326` | Chin-up | lats | bodyweight | C |
| `1429` | Wide Grip Pull-up | lats | bodyweight | C |
| `0651` | Pull Up (Neutral Grip) | lats | bodyweight | C |
| `0017` | Assisted Pull-up | lats | machine | C |
| `0150` | Cable Bar Lateral Pulldown | lats | cable | C |
| `2616` | Cable Lateral Pulldown With V-bar | lats | cable | C |
| `0818` | Twin Handle Parallel Grip Lat Pulldown | lats | cable | C |
| `0238` | Cable Straight Arm Pulldown | lats | cable | I |
| `0579` | Lever Front Pulldown | lats | machine | C |
| `2285` | Lever Pullover | lats | machine | I |
| `1347` | Lever One Arm Lateral Wide Pulldown | lats | machine | C |
| `0027` | Barbell Bent Over Row | upper back | barbell | C |
| `3017` | Barbell Pendlay Row | upper back | barbell | C |
| `0293` | Dumbbell Bent Over Row | upper back | dumbbell | C |
| `0292` | Dumbbell One Arm Bent-over Row | upper back | dumbbell | C |
| `0327` | Dumbbell Incline Row | upper back | dumbbell | C |
| `0861` | Cable Seated Row | upper back | cable | C |
| `0218` | Cable Seated Wide-grip Row | upper back | cable | C |
| `0189` | Cable One Arm Bent Over Row | upper back | cable | C |
| `1350` | Lever Seated Row | upper back | machine | C |
| `0606` | Lever T Bar Row | upper back | machine | C |
| `0581` | Lever High Row | upper back | machine | C |
| `0499` | Inverted Row | upper back | bodyweight | C |
| `0095` | Barbell Shrug | traps | barbell | I |
| `0406` | Dumbbell Shrug | traps | dumbbell | I |
| `0604` | Lever Shrug | traps | machine | I |
| `0489` | Hyperextension | spine | bodyweight | I |

### Legs (`legs`) — 30 Exercises
| ID | Name | Target | Equipment | Type |
| :--- | :--- | :--- | :--- | :---: |
| `0043` | Barbell Full Squat | glutes | barbell | C |
| `0042` | Barbell Front Squat | glutes | barbell | C |
| `0413` | Dumbbell Squat | glutes | dumbbell | C |
| `1760` | Dumbbell Goblet Squat | quads | dumbbell | C |
| `0054` | Barbell Lunge | glutes | barbell | C |
| `0336` | Dumbbell Lunge | glutes | dumbbell | C |
| `1460` | Walking Lunge | glutes | bodyweight | C |
| `0743` | Sled Hack Squat | glutes | machine | C |
| `0739` | Sled 45° Leg Press | glutes | machine | C |
| `0585` | Lever Leg Extension | quads | machine | I |
| `0770` | Smith Squat | glutes | machine | C |
| `0410` | Dumbbell Single Leg Split Squat | quads | dumbbell | C |
| `0032` | Barbell Deadlift | glutes | barbell | C |
| `0085` | Barbell Romanian Deadlift | glutes | barbell | C |
| `1459` | Dumbbell Romanian Deadlift | glutes | dumbbell | C |
| `0811` | Trap Bar Deadlift | glutes | barbell | C |
| `1409` | Barbell Glute Bridge | glutes | barbell | C |
| `0044` | Barbell Good Morning | hamstrings | barbell | C |
| `0599` | Lever Seated Leg Curl | hamstrings | machine | I |
| `0586` | Lever Lying Leg Curl | hamstrings | machine | I |
| `0196` | Cable Pull Through (With Rope) | glutes | cable | I |
| `0431` | Dumbbell Step-up | glutes | dumbbell | C |
| `3193` | Glute-ham Raise | hamstrings | bodyweight | I |
| `0605` | Lever Standing Calf Raise | calves | machine | I |
| `0594` | Lever Seated Calf Raise | calves | machine | I |
| `0417` | Dumbbell Standing Calf Raise | calves | dumbbell | I |
| `1373` | Bodyweight Standing Calf Raise | calves | bodyweight | I |
| `1372` | Barbell Standing Calf Raise | calves | barbell | I |
| `0597` | Lever Seated Hip Abduction | abductors | machine | I |
| `0598` | Lever Seated Hip Adduction | adductors | machine | I |

### Shoulders (`shoulders`) — 24 Exercises
| ID | Name | Target | Equipment | Type |
| :--- | :--- | :--- | :--- | :---: |
| `0091` | Barbell Seated Overhead Press | delts | barbell | C |
| `1456` | Barbell Standing Close Grip Military Press | delts | barbell | C |
| `0426` | Dumbbell Standing Overhead Press | delts | dumbbell | C |
| `0405` | Dumbbell Seated Shoulder Press | delts | dumbbell | C |
| `2137` | Dumbbell Arnold Press | delts | dumbbell | C |
| `0603` | Lever Shoulder Press | delts | machine | C |
| `0587` | Lever Military Press | delts | machine | C |
| `0766` | Smith Shoulder Press | delts | machine | C |
| `0219` | Cable Shoulder Press | delts | cable | C |
| `0334` | Dumbbell Lateral Raise | delts | dumbbell | I |
| `0178` | Cable Lateral Raise | delts | cable | I |
| `0584` | Lever Lateral Raise | delts | machine | I |
| `0192` | Cable One Arm Lateral Raise | delts | cable | I |
| `0310` | Dumbbell Front Raise | delts | dumbbell | I |
| `0041` | Barbell Front Raise | delts | barbell | I |
| `0162` | Cable Front Raise | delts | cable | I |
| `0380` | Dumbbell Rear Lateral Raise | delts | dumbbell | I |
| `0602` | Lever Seated Reverse Fly | delts | machine | I |
| `0203` | Cable Rear Delt Row (With Rope) | delts | cable | I |
| `0378` | Dumbbell Rear Fly | delts | dumbbell | I |
| `0075` | Barbell Rear Delt Raise | delts | barbell | I |
| `0120` | Barbell Upright Row | delts | barbell | C |
| `0437` | Dumbbell Upright Row | delts | dumbbell | C |
| `0246` | Cable Upright Row | delts | cable | C |

### Arms (`arms`) — 28 Exercises
| ID | Name | Target | Equipment | Type |
| :--- | :--- | :--- | :--- | :---: |
| `0031` | Barbell Curl | biceps | barbell | I |
| `0447` | EZ Barbell Curl | biceps | barbell | I |
| `0070` | Barbell Preacher Curl | biceps | barbell | I |
| `0294` | Dumbbell Biceps Curl | biceps | dumbbell | I |
| `0313` | Dumbbell Hammer Curl | biceps | dumbbell | I |
| `0318` | Dumbbell Incline Curl | biceps | dumbbell | I |
| `0297` | Dumbbell Concentration Curl | biceps | dumbbell | I |
| `0868` | Cable Curl | biceps | cable | I |
| `0165` | Cable Hammer Curl (With Rope) | biceps | cable | I |
| `0592` | Lever Preacher Curl | biceps | machine | I |
| `0439` | Dumbbell Zottman Curl | biceps | dumbbell | I |
| `0030` | Barbell Close-grip Bench Press | triceps | barbell | C |
| `0296` | Dumbbell Close-grip Press | triceps | dumbbell | C |
| `0751` | Smith Close-grip Bench Press | triceps | machine | C |
| `0814` | Triceps Dip | triceps | bodyweight | C |
| `0129` | Bench Dip (Knees Bent) | triceps | bodyweight | C |
| `0283` | Diamond Push-up | triceps | bodyweight | C |
| `0591` | Lever Overhand Triceps Dip | triceps | machine | C |
| `0060` | Barbell Lying Triceps Extension Skull Crusher | triceps | barbell | I |
| `0201` | Cable Pushdown | triceps | cable | I |
| `0200` | Cable Pushdown (With Rope Attachment) | triceps | cable | I |
| `0194` | Cable Overhead Triceps Extension (Rope Attachment) | triceps | cable | I |
| `0333` | Dumbbell Kickback | triceps | dumbbell | I |
| `0607` | Lever Triceps Extension | triceps | machine | I |
| `0126` | Barbell Wrist Curl | forearms | barbell | I |
| `0082` | Barbell Reverse Wrist Curl | forearms | barbell | I |
| `0369` | Dumbbell Over Bench Wrist Curl | forearms | dumbbell | I |
| `0385` | Dumbbell Reverse Wrist Curl | forearms | dumbbell | I |

### Core (`core`) — 16 Exercises
| ID | Name | Target | Equipment | Type |
| :--- | :--- | :--- | :--- | :---: |
| `0274` | Crunch Floor | abs | bodyweight | I |
| `0872` | Reverse Crunch | abs | bodyweight | I |
| `0687` | Russian Twist | abs | bodyweight | I |
| `0472` | Hanging Leg Raise | abs | bodyweight | C |
| `0276` | Dead Bug | abs | bodyweight | C |
| `0705` | Side Bridge V. 2 | abs | bodyweight | C |
| `0277` | Decline Crunch | abs | bodyweight | I |
| `0003` | Air Bike | abs | bodyweight | I |
| `0084` | Barbell Rollerout | abs | barbell | C |
| `0175` | Cable Kneeling Crunch | abs | cable | I |
| `0226` | Cable Standing Crunch | abs | cable | I |
| `0222` | Cable Side Bend | abs | cable | I |
| `0243` | Cable Twist | abs | cable | I |
| `0407` | Dumbbell Side Bend | abs | dumbbell | I |
| `1452` | Lever Seated Crunch | abs | machine | I |
| `0583` | Lever Kneeling Twist | abs | machine | I |
