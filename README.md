# GameDay Live

GameDay Live is an athlete readiness app for pre-game preparation.

It combines manual + HealthKit metrics, computes a transparent readiness score, generates AI coach guidance, and publishes the current state to Live Activities (Lock Screen + Dynamic Island) and widgets.

## What It Does

- Tracks game context: title + kickoff time
- Captures athlete metrics:
  - Sleep hours
  - Soreness (1-10)
  - Stress (1-10)
  - Hydration (oz)
  - Training intensity (1-10)
  - Athlete type (soccer, basketball, football, baseball, hockey, tennis, runner, combat)
- Computes readiness score (0-100) with labeled status + top factors
- Generates:
  - `nextAction` (time-aware priority)
  - 3 short coaching tips
- Supports coach chat (text + voice input)
- Reads recovery/training context from HealthKit
- Starts, updates, and ends a Live Activity from the main app

## Product Scope

This app is intentionally focused on athlete readiness and preparation coaching.

- Not a checklist app
- Not a generic countdown app
- Not team scoreboard logic

## Screens

- `Home` (Dashboard): readiness score, top factors, next action, Live Activity controls
- `Metrics`: game + athlete input, HealthKit import, coach tips generation
- `Plan`: concise action plan + 3 priority tips
- `Chat`: on-device coach Q&A with optional voice input

## Widget + Live Activity

### Widget

Shows:
- Game title
- Time-to-kickoff badge
- Readiness score + label
- Next action

### Live Activity

`ActivityAttributes`
- `gameTitle`
- `kickoffTime`

`ContentState`
- `readinessScore`
- `readinessLabel`
- `nextAction`
- `tip`

Displayed on:
- Lock Screen
- Dynamic Island (expanded/compact/minimal)

## AI Strategy

Hybrid AI design:

- Primary: on-device Foundation Models (`iOS 26+`, when available)
- Fallback: deterministic rules-based service

This guarantees usable recommendations even when Apple Intelligence is unavailable.

## Architecture

Core shared domain:
- `Shared/Models.swift`
- `Shared/ReadinessEngine.swift`
- `Shared/AIRecommendationService.swift`
- `Shared/LiveActivityModels.swift`
- `Shared/DemoData.swift`

App layer:
- `GameDay/GameDayViewModel.swift`
- `GameDay/CoachAssistantServices.swift`
- `GameDay/HealthKitMetricsService.swift`
- `GameDay/VoiceInputService.swift`
- `GameDay/DashboardView.swift`
- `GameDay/InputsView.swift`
- `GameDay/CoachPlanView.swift`
- `GameDay/CoachChatView.swift`
- `GameDay/GameDayTheme.swift`

Widget extension:
- `GameDayWidget/GameDayWidget.swift`
- `GameDayWidget/GameDayWidgetLiveActivity.swift`
- `GameDayWidget/GameDayWidgetBundle.swift`

## Requirements

- Xcode 26+
- iOS deployment target: `26.2`
- Physical iPhone recommended for full feature validation:
  - Live Activities
  - HealthKit
  - Speech recognition / microphone
  - Foundation Models availability checks

## Setup

1. Open `/Users/halilturankaya/Documents/Apps/GameDay/GameDay.xcodeproj` in Xcode.
2. Select `GameDay` target and set your Development Team + signing.
3. Select `GameDayWidgetExtension` target and set matching signing.
4. Build and run on device.
5. Grant permissions when prompted:
   - Health data
   - Microphone
   - Speech recognition

## Run / Build

From CLI (simulator build without codesign):

```bash
xcodebuild \
  -project GameDay.xcodeproj \
  -scheme GameDay \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/GameDayDerived \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
```

## How to Use

1. Go to `Metrics`, set game + athlete inputs.
2. Tap `Generate Coach Tips`.
3. Review readiness + factors on `Home`.
4. Start Live Activity with `Start`.
5. Update inputs and tap `Update` to push new readiness/tips to Live Activity.
6. Stop with `End`.

## Troubleshooting

### Live Activity will not start

Check:
- Live Activities are enabled on device (`Settings > Face ID & Passcode > Live Activities` or app-specific setting).
- App contains `NSSupportsLiveActivities = YES` (already configured in project build settings).
- Run on a physical device for best validation.

If you see an old plist-key error, clean build folder and reinstall app.

### Foundation model not active

Expected behavior on unsupported devices/locales:
- App automatically falls back to rule-based coach mode.

### HealthKit import fails

Check:
- Health permissions granted
- Health app has recent data for supported metrics

### Voice input unavailable

Check:
- Microphone permission granted
- Speech recognition permission granted

## Current MVP Notes

- Manual-first input flow with optional HealthKit import
- No remote push Live Activity updates
- No multi-screen onboarding/auth flow

## License

No license file is included yet.

