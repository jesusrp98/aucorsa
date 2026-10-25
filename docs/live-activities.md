# Bus arrivals in Live Activities

Arrivals come from two places. While Aucorsa is open, the app fetches them
itself with the existing AUCORSA client. While it is suspended, a small Firebase
backend in [`backend/`](../backend/README.md) fetches them every 30 seconds and
sends them to the activity as ActivityKit pushes, which iOS applies without
waking the app. No notification permission or background mode is needed.

The backend is self-hosted, so the feature is opt-in per build: only the
`personal` flavor, built with your own backend's host, has it. Every other
build, including App Store builds, hides Live Activities entirely and contains
no backend address or push entitlement. If a configured backend is briefly
unreachable, activities still refresh while the app is open.

## Build variants

| | `personal` flavor | Default (App Store) |
|---|---|---|
| Command | `flutter run --release --flavor personal`, or the `personal` scheme in Xcode | `flutter build ipa`, or the `Runner` scheme |
| Configurations | `Debug-personal`, `Release-personal`, `Profile-personal` | `Debug`, `Release`, `Profile` |
| Backend host | from `ios/LiveActivityBackend.xcconfig` (not tracked) | none |
| Entitlements | `Runner/RunnerPersonal.entitlements`, with `aps-environment` | `Runner/Runner.entitlements`, without |
| `NSSupportsLiveActivities` | `YES` | `NO` |
| Live Activities | on, when the host is set | off; the controls are hidden |
| "Get Next Bus On Line" shortcut | has a **Start Live Activity** option | no option |
| Minimum iOS | 17.0 | 16.0 |

To set up the `personal` flavor, deploy the backend as described in
[backend/README.md](../backend/README.md#run-your-own-backend), then copy
`ios/LiveActivityBackend.example.xcconfig` to `ios/LiveActivityBackend.xcconfig`
and set the host of your `liveActivitySessions` function. The flavor's
`ios/Flutter/Personal-*.xcconfig` files include it if it exists; without it the
flavor still builds, with the feature off. The flavor is iOS-only.

At runtime, `LiveActivityBackend.configured` reads `LiveActivityBackendHost`
from Info.plist. When it is empty, the native channel reports
`supported: false`, exactly as on iOS versions without ActivityKit, so Flutter
shows no tracking controls, and any activity left over from a personal build
is ended at launch. The widget extension is embedded in every build, but
nothing starts an activity without a backend.

## Behavior

- Expand a stop and tap the line you want to target. A floating snackbar and a
  light haptic confirm the target. The line row keeps its normal appearance,
  without a tap ripple.
  Starting another session replaces the previous one. Custom stop names are
  used when tracking starts and kept in sync when edited or cleared, without
  restarting the session or changing the estimates’ fetch time.
- On iOS 16.2 and later, the selected line and its latest minute estimate appear
  in the Dynamic Island on supported iPhones, with a circular line badge in the
  compact and expanded views. The expanded Island has no action buttons; tapping it opens the
  tracked stop. The expanded Island shows only the selected line and stop, with
  a larger secondary row: “Next in 25 min” on the left and “Last updated 20:30”
  on the right. Missing next arrivals display a dash. The Lock Screen card
  shows the same content and layout as the expanded Island, with the same
  circular badge and no buttons; tapping it also opens the tracked stop.
- Zero-minute estimates read “Now”
  (“Ahora” in Spanish) in green. The primary Now label has a brief opacity pulse
  on content updates; WidgetKit does not support the app's continuous animation.
  Reduce Motion and reduced-luminance displays disable that transition.
- Expanded stop cards refresh every 30 seconds while the app is active.
- **The backend refreshes the activity every 30 seconds, also in the
  background.** Each activity is requested with a push token, which the app
  registers with the backend along with the stop, line, display name and
  deadline. Every refresh fetches AUCORSA and pushes the new content: high
  priority when the minutes changed, low priority when only the fetch time did,
  to stay within iOS's update budget. `NSSupportsLiveActivitiesFrequentUpdates`
  raises that budget; users can turn it off under Settings › Aucorsa GO! ›
  Live Activities › More Frequent Updates. Renames are sent to the backend so
  later pushes keep the custom name. Rotated push tokens are registered again.
- While the backend owns an activity, the app's own 30-second poll is off, so
  AUCORSA is not asked twice. If registration fails, the native coordinator
  polls every 30 seconds while the app is active, as before, and retries
  registration whenever the app becomes active. That poll uses common run-loop
  modes so scrolling does not defer it. Coming back to the app always triggers
  one immediate refresh. Failures retain the last successful timestamp. The
  displayed time omits seconds, so two refreshes within one minute can show
  the same time.
- After 90 seconds without a successful fetch, estimates become stale: the
  compact estimate changes to an amber dash, and the expanded Island and Lock
  Screen ask users to open Aucorsa to refresh. Failed requests do not advance the timestamp. Displayed minutes are
  source estimates, not a locally simulated countdown or a guarantee of arrival.
- In `personal` builds, the **Get Next Bus On Line** shortcut action has a
  **Start Live Activity** option (under the action's expanded options in
  Shortcuts). When it is on, running the shortcut, including through Siri,
  speaks the next arrivals as before and also starts following that line at
  that stop, even while Aucorsa is closed. It replaces any current session and
  is refreshed by the backend like one started in the app. If starting fails,
  the spoken answer is unaffected.
- The app has no separate tracking screen or stop control. A session ends at
  its deadline, when another line is targeted, or when the activity is
  dismissed from the Lock Screen.
- A session expires 15 minutes after activation. A separate deadline timer ends
  the Live Activity and clears tracking while the app is running, independently
  of polling or an in-flight request. Refreshes and name edits never extend the
  deadline. Existing 30-minute sessions are also capped at 15 minutes from their
  original start. Expired sessions are omitted from tracking status and ended
  when the app resumes.
  While the app is suspended, the backend ends the activity at the deadline with
  an `end` push that dismisses it immediately; the backend also caps every
  session at 15 minutes itself. Without the backend, iOS does not guarantee
  execution at the deadline, so the card may remain until the app resumes or
  the user or system removes it.
- Targeting another line, dismissing the activity in the system, and the
  deadline all end the backend session, which stops its pushes.
- Tapping the activity opens `aucorsa://app/stops/<id>` on both a cold launch and
  an already running app. Favorites opens with that stop expanded and scrolled
  into view. Stops outside Favorites open in the same bottom sheet used by the
  map, above Favorites. Invalid IDs show a floating unavailable-stop message.

## Implementation

- `lib/live_activity/`: tracking controls and a lifecycle-aware method channel.
- `lib/common/cubits/bus_stop_cubit.dart`: coalesced foreground refreshes, timer
  cleanup, late-response protection, and preservation of the last good data.
- `ios/Runner/LiveActivityChannel.swift`: native ActivityKit ownership, activity
  restoration, push token registration, the fallback 30-second foreground
  timer, and state notifications to Flutter.
- `ios/LiveActivities/`: shared attributes, compiled into both the host and the
  widget extension. The activity has no buttons, so there are no
  `LiveActivityIntent`s.
- `ios/AucorsaLiveActivity/`: compact, minimal, expanded and Lock Screen layouts.
  The Lock Screen card reuses the expanded Island's badge, estimate and details.
- `ios/AucorsaKit/.../BusArrivalSnapshot.swift`: bounded, Codable content model.
  Decoding applies the same limits as the initializers, since pushed content
  comes from the backend.
- `ios/AucorsaKit/.../LiveActivityBackend.swift`: decides whether the build has
  a backend, then registers, renames and ends backend sessions. Builds whose
  provisioning profile is development-signed, including Release builds
  installed from Xcode, and simulator builds use the APNs sandbox; App Store
  and TestFlight builds use production.
- The host's `Info.plist` takes `NSSupportsLiveActivities`,
  `NSSupportsLiveActivitiesFrequentUpdates` and `LiveActivityBackendHost` from
  the `LIVE_ACTIVITIES_ENABLED` and `LIVE_ACTIVITY_BACKEND_HOST` build settings
  (see [Build variants](#build-variants)).
- `backend/`: the Firebase functions, Firestore storage and APNs sender. See its
  [README](../backend/README.md).
- The shared native parser recognizes AUCORSA's `ahora` marker, including its
  `blinker` HTML class, so an arriving bus is not skipped in favor of a later bus.

The host keeps its iOS 16.0 deployment target. Controls are hidden where
ActivityKit is unsupported or the build has no backend.
The new `com.chechu.aucorsa.LiveActivity` extension is embedded before Flutter's
Thin Binary phase to avoid an Xcode dependency cycle. Its version is inherited
from Flutter's generated build configuration. Xcode automatic signing must
provision that additional bundle identifier for physical-device/App Store builds.
For the `personal` flavor it must also add the Push Notifications capability to
the host's App ID; building the `personal` scheme once from Xcode does both.

### Starting from the shortcut

Only an intent that conforms to `LiveActivityIntent` (iOS 17) may start an
activity while the app is in the background, and it must run in the app's
process. So, in `personal` builds only (the `LIVE_ACTIVITIES` compilation
condition):

- `GetNextBusForLineIntent` gains the `startsLiveActivity` parameter and the
  `LiveActivityIntent` conformance, and the flavor's minimum iOS is 17.0.
- The intents extension excludes `GetNextBusForLineIntent.swift`
  (`EXCLUDED_SOURCE_FILE_NAMES` in its `*-personal` configurations), so iOS
  launches Aucorsa in the background to run it instead. The quick, extension-only
  answer remains in default builds.
- `BusArrivalActivityStarter` in `LiveActivityChannel.swift` holds the start
  logic shared with the Flutter channel. The shortcut waits up to 8 seconds for
  the new activity's push token and registers it before returning, since iOS
  may suspend the app right after. It then posts a notification so a running
  Flutter coordinator adopts the activity.

`parameterSummary` is declared once per variant because the App Intents
metadata processor rejects `#if` inside its body.

### Data sent to the backend

For each session the app sends the activity's push token, an APNs environment,
a random session ID, the stop ID, the line, the stop's display name (including
a custom name, if set) and the deadline. Firestore keeps it in
`liveActivitySessions` until the session ends; a TTL policy deletes anything
left one hour after the deadline. Nothing identifies the user or the device
beyond the per-activity push token.

## Verification

The 15-minute expiry revision passed all seven Runner integration tests. A real
ActivityKit session created with one second remaining ended on its deadline and
emitted an empty Following state, without waiting for a network poll. Renaming
did not move that deadline. Restoring an already-expired activity ended it and
cleared tracking; decoding a legacy 30-minute session applied the new limit.

Implemented and checked on 2026-10-24: 176 Flutter tests, 39 Swift package tests,
and 4 Runner integration tests passed. The simulator build and Flutter hot
restart passed. Analysis reports only 9 existing informational lints in unrelated
files. Device Hub checks covered following a line, swiping Home, compact and
expanded Island views, the Lock Screen, background Refresh, stale data, opening
the tracked stop, and stopping from the Island with in-app state synchronization.
Cold-launch stop links and Back navigation to Favorites were also verified.
The revised controls were checked in Device Hub: tapping a line shows the
targeting snackbar and Following icon; the sheet displays that line and stop;
canceling closes the sheet and removes the icon. The 9 tracking/refresh tests,
targeted analysis, the iOS build, and hot restart passed after this revision.
The Favorites navigation revision passed all 181 Flutter tests, including five
navigation regressions for cold/warm links, repeated links, offscreen favorites,
empty favorites, and invalid IDs. Targeted analysis and hot restart passed.
The circular expanded badge and live custom-name updates were verified in
Device Hub by renaming an actively followed stop and restoring its original
custom name. All 13 tracking/navigation tests and 41 Swift package tests passed,
as did targeted analysis, the iOS simulator build, and hot reload.
The expanded Island layout was checked in Device Hub with Crta. Trassierra
3ª D.C.: the circular badge is fully visible, the arrival rows fit,
and the last-check label and time share one unclipped line. Expanded content
uses explicit margins around the curved edges; long stop names may wrap to
two lines. The iOS simulator build passed after this layout revision.
The sentence-style arrivals were checked in Device Hub on the simulator with
Casa and three lines: the complete summary and last-check timestamp fit without
clipping. Simulator and signed iPhone release builds passed, and the update was
installed on the personal iPhone. The live feed had no zero-minute estimate at
verification time, so the green Now transition was not visually observed.
For the subsequent single-row expanded layout, a Device Hub session confirmed
foreground fetches at 20:27:18.922 and 20:27:48.886 (29.964 seconds apart), then
polling paused when Home was pressed at 20:27:54. The iPhone release build was
installed. Device Hub's live window capture became blank during visual QA;
saved simulator screenshots omit the Dynamic Island overlay.
The personal iPhone then refreshed successfully at 20:33:04.370 and
20:33:34.346 (29.976 seconds apart) while Aucorsa remained open. The signed
release and simulator builds passed. The native test build also passed, but
Xcode stalled before executing the tests; that run was stopped. On-device
visual verification of the single-row layout remains incomplete because the
Device Hub image feed remained blank even after unlocking and reconnecting.
The exact activity URLs were opened on the running simulator and checked through
Device Hub: favorite 141 expanded in Favorites; non-favorite 105 used the map
stop sheet. Device Hub screen capture was unavailable during this final check.

Background refreshes from the backend were verified on 2026-10-25 on an
iPhone 18 Pro simulator running iOS 27.0. Following line 9 at stop 105
registered the activity's sandbox push token about two seconds after starting.
After pressing Home, the backend pushed at 10:48:27, 10:48:57, 10:49:27 and
10:49:57, and APNs accepted each one. The suspended app's Island changed from
3 min to 1 min, and the Lock Screen card showed "Last checked 10:49". Tapping
the card's close button removed the activity, and the next backend refresh
found no session and ended the chain. 52 Swift package tests and 47 backend
tests, including the Firestore emulator, passed, as did the simulator build.
An earlier backend check with a dummy token confirmed that APNs accepted the
provider token and that a rejected device token deletes the session. A
physical iPhone has not been checked yet.
The Lock Screen card was then changed to match the expanded Island and checked
on the same simulator with line 2 at Fátima: a circular red badge, "8 min",
the stop name, and "Next in 25 min" beside "Last updated 11:03", with no
Refresh or close button. The now-unused Refresh and Stop intents were removed
afterwards; the simulator build and all 52 Swift package tests passed.
The build variants were verified the same day. The default simulator build had
an empty `LiveActivityBackendHost`, `NSSupportsLiveActivities` set to NO, no
`aps-environment` entitlement and no backend host anywhere in the bundle; it
showed no Following control, and tapping a line started nothing. The
`personal` simulator build started an activity, registered with the backend,
and received pushes at 11:34:34 and 11:35:03 while suspended, the Island going
from 12 to 10 min. Both variants also built in Release. 54 Swift package tests
and 47 backend tests passed.
The Following icon and its sheet were then removed. On the `personal`
simulator build, the Favorites header showed only About, and targeting line 2
at Fátima showed "Targeting line 2 at Fátima" and registered with the backend.
The haptic cannot be felt on the simulator. All 184 Flutter tests passed and
analysis reported no issues.
The shortcut option was verified on the `personal` simulator build: with
Aucorsa closed, a Shortcuts action for line 2 with Start Live Activity on ran
`GetNextBusForLineIntent.perform()` in the app's process, answered "Line 2
arrives at Fátima in 20 minutes, then in 38 minutes", started the activity
(the Island showed 2 and 20 min), and registered it; the backend pushed at
17:28:17 and 17:28:44. The default build's metadata had no such parameter and
kept the intent in the extension. Both variants built, including the
`personal` Release build.

```sh
flutter test
swift test --package-path ios/AucorsaKit
(cd backend/functions && npm run test:firestore)
```

Build the `personal` scheme for an iPhone simulator with Dynamic Island, then check:

1. Start following a line, swipe Home and inspect compact/expanded presentations.
2. Lock the device, allow Live Activities if prompted, and check that the card
   matches the expanded Island.
3. With Aucorsa in the background, verify that the last-update time advances
   every 30 seconds to a minute without touching anything.
4. Turn off the network for at least 90 seconds; verify the amber stale state,
   then that refreshes resume once it is back.
5. Tap the activity to expand its favorite stop, including one below the fold.
   Check cold launches, repeated taps, and the map stop sheet for non-favorites.
6. Dismiss the Lock Screen activity, then target the same line again; a new
   activity should start.
7. Leave a session running with the device locked; verify that it disappears at
   its 15-minute deadline.
8. Check unavailable service, disabled Live Activities, and longer stop names.

Simulator checks cannot replace signing and on-device verification on the oldest
supported OS versions. AUCORSA's own update frequency is independent of our
30-second refresh interval.

### Native API session recovery

On a personal iPhone running iOS 27.0.1, starting an activity failed with HTTP 403
and WordPress's `rest_cookie_invalid_nonce`, although the Flutter stop card loaded
arrivals successfully. Bypassing cached responses alone did not resolve it.
Disabling stored-cookie handling for the native public API requests resolved the
failure; the updated release build was installed and the owner confirmed tracking
worked. Existing web-session cookies and user data are left intact.

Native arrival requests bypass the HTTP cache. A rejected nonce triggers one
homepage fetch with a fresh URL, followed by one estimation retry. Logs include
the HTTP status/API error code and native error domain/code without recording
nonce values, cookies, or response bodies. Four network regression tests cover
cookie isolation, rejected stored nonces, stale homepage recovery, and bounded
retries; all 45 AucorsaKit tests pass.

Apple's implementation references:

- [Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- [Starting and updating Live Activities with ActivityKit push notifications](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications)
