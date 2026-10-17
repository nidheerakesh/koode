# Koode (കൂടെ) — "With Me"

A Malayalam-first mobile companion that helps young people with Down syndrome
and autism **shop, travel and leave home on their own**. Point the camera,
and Koode checks the world for them, answering with one calm, clear yes or no
in Malayalam voice and pictures.

## What works now (MVP)

| Module | Feature |
|---|---|
| 💰 Money | **What do I give?** Photo of the price tag, the shopkeeper saying it aloud (Malayalam STT), or typed in; shows the exact notes using the *next-rupee-up* method and says the change due |
| 💰 Money | **Is my change right?** Photo of the change; catches short change and shows a polite phrase card for the shopkeeper |
| 🚌 Travel | **Is this my bus?** Reads the Malayalam bus board and fuzzy-matches it against the trip the caregiver saved |
| 🚌 Travel | **Get-off alert.** GPS geofence: "your stop is next", "get off here", "you passed it — call Amma" (with a simulated demo journey) |
| 🏠 Home | **Leaving-home check.** Photo checklist set by the caregiver (gas, door, taps) with a stricter safety threshold |
| 🆘 Safety | **I'm lost** card read aloud + location SMS to a parent; big **call** buttons for safe people |
| 👪 Caregiver | PIN-gated setup for trips, checklist and contacts, plus a "today" activity log |

## Design principle: AI perceives, code decides

The vision model only *reads* the world: amounts, notes, place names, knob
positions, each with a confidence score. Every decision is plain Dart:

- `lib/core/money_logic.dart`: next-rupee-up and change checking (tested for every price from ₹1 to ₹2000)
- `lib/core/route_match.dart`: Malayalam/English fuzzy place-name matching
- `lib/core/confidence.dart`: low confidence → **"I'm not sure, ask for help"**, never a guess. Home safety needs 0.85.

## Running

```bash
flutter pub get
flutter run                                         # demo mode: scripted readings, no key needed
flutter run --dart-define=GEMINI_API_KEY=your_key   # real vision with Gemini 2.5 Flash
flutter test
```

Demo mode follows Anu's day from the pitch: the first bus board is the wrong bus
and the second is right, the first change is ₹2 short and the second is correct,
and every home-check item passes.

Default caregiver PIN: `1234`.

## Layout

```
lib/core/       pure decision logic (unit tested)
lib/ai/         VisionService interface, Gemini implementation, demo mock
lib/voice/      Malayalam TTS / STT (Bhashini can drop in behind the same API)
lib/data/       profile, trips, checklist, activity log (local storage)
lib/features/   money, travel, home, safety, caregiver screens
```

## Next

- On-device TFLite currency detector (offline, faster): needs a dataset of worn notes and coins
- Kottayam bus-board dataset to measure match accuracy
- Firebase sync so the caregiver gets notifications on their own phone
- Bhashini for Malayalam voice
- Phase 2: Seller Mode for BUDS stalls, Count Check, "What does this say?", Social Story Maker

## Privacy

Photos are sent for reading and then discarded; nothing is stored. Location is
used only during a trip or when the user taps "I'm lost".
