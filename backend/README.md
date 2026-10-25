# Live Activity backend

Keeps a followed bus's Live Activity up to date every 30 seconds while the app
is suspended. iOS stops the app's own timer in the background, so the
backend fetches AUCORSA and sends the new arrivals to the activity as an
ActivityKit push. It does nothing else.

The backend is self-hosted: this repository has no Firebase project attached.
Live Activities only exist in builds of the app's `personal` flavor that point
at a backend you deployed yourself (see [Run your own backend](#run-your-own-backend)).
App Store builds don't include the feature.

## How it works

1. When the app starts following a line, it calls `PUT /liveActivitySessions/<sessionID>`
   with the activity's push token. The session is saved in Firestore and the
   first refresh is queued as a Cloud Task 30 seconds later.
2. Each refresh (`liveActivityTick`) queues the next one, fetches the stop
   from AUCORSA, and pushes the new content to APNs. It uses high priority
   when the minutes changed and low priority when only the fetch time did.
3. At the 15-minute deadline the last refresh sends an `end` push and deletes
   the session. If the app stops following first (`DELETE`), the next refresh
   finds no session and the chain ends.

Nothing runs while nobody is following a bus. The app side, including what
happens when the backend is unreachable, is described in
[docs/live-activities.md](../docs/live-activities.md).

| File | Purpose |
|---|---|
| `functions/src/sessions.ts` | App-facing API: `PUT`, `PATCH` (rename), `DELETE` |
| `functions/src/tick.ts` | One refresh, and the 30-second schedule |
| `functions/src/apns.ts` | ES256 provider token and HTTP/2 pushes to APNs |
| `functions/src/aucorsa.ts`, `parser.ts` | Ports of the app's native AUCORSA client and parser |
| `functions/src/snapshot.ts` | Port of `BusArrivalSnapshot`, the activity's content state |
| `functions/src/store.ts` | Firestore sessions, plus the shared nonce and provider token |
| `functions/src/catalog.json` | Stops and line order, generated from `transit_data.json` |

## Commands

Run these from `functions/`:

```sh
npm test                 # unit tests; Firestore tests are skipped
npm run test:firestore   # all tests, with the Firestore emulator (needs Java)
npm run catalog          # after tools/update_transit_data.py changes the stops
npm run probe -- 105     # checks this machine can reach AUCORSA
```

`snapshot.test` and the Swift `BusArrivalSnapshotTests` both check
`ios/AucorsaKit/Tests/AucorsaKitTests/Fixtures/live_activity_content_state.json`,
so the content state can't drift between the backend and the app.

## Run your own backend

You need an Apple Developer account and the Firebase CLI. Your project ID, key
ID and backend host only ever go in files git ignores.

1. Create a Firebase project and upgrade it to the Blaze plan. Add a small
   budget alert while you're there. Then select it from this folder; this
   writes `.firebaserc`:

   ```sh
   firebase use --add
   ```

2. Create the Firestore database. The functions run in `europe-west1`, so put
   it there too:

   ```sh
   firebase firestore:databases:create "(default)" --location europe-west1
   ```

3. In Certificates, Identifiers & Profiles › Keys, create a key with the Apple
   Push Notifications service (APNs) for sandbox and production, and download
   `AuthKey_<KEY ID>.p8`. Apple only lets you download it once.
4. Store the key in Secret Manager:

   ```sh
   firebase functions:secrets:set APNS_PRIVATE_KEY --data-file AuthKey_<KEY ID>.p8
   ```

5. Copy `functions/.env.example` to `functions/.env.<project ID>` and fill in
   the key ID, your team ID and the app's bundle ID.
6. Deploy:

   ```sh
   firebase deploy --only firestore,functions
   ```

   The output includes the `liveActivitySessions` URL.
7. Point the app at it: copy `ios/LiveActivityBackend.example.xcconfig` to
   `ios/LiveActivityBackend.xcconfig` and set `LIVE_ACTIVITY_BACKEND_HOST` to
   the URL's host, for example `europe-west1-<project ID>.cloudfunctions.net`.
8. Build the `personal` flavor (see
   [docs/live-activities.md](../docs/live-activities.md#build-variants)).

Firestore rules deny all client access; only the functions read and write it.
Sessions left behind are deleted by a TTL policy on `expireAt`.

## Push environments

Each session says which APNs server its token belongs to. The app works it out
from its provisioning profile: simulator and development-signed builds,
including Release builds installed from Xcode, use `sandbox`; App Store and
TestFlight builds use `production`. A token sent to the wrong server is
rejected with `BadDeviceToken`, and the session is deleted.

## Cost

Personal use fits well inside the Blaze plan's free allowance: a 15-minute
session is about 32 function calls and 60 Cloud Tasks operations. Set a budget
alert anyway. The first deploy offers a cleanup policy for stored function
images; accept it so old images don't add storage costs.

## Checking it

```sh
firebase functions:log --only liveActivityTick
```

Each refresh logs its session, refresh number and outcome: `pushed`,
`fetch-failed`, `push-failed`, `token-invalid`, `ended`, `missing` (stopped in
the app) or `duplicate`.
