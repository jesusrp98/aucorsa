import ActivityKit
import AucorsaKit
import Flutter
import UIKit

@MainActor
enum LiveActivityChannel {
    private static var coordinator: AnyObject?

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "com.chechu.aucorsa/live_activity", binaryMessenger: messenger)
        // Without a backend, activities could only refresh while the app is
        // open, so builds without one (App Store builds) leave the feature off.
        guard #available(iOS 16.2, *), let backend = LiveActivityBackend.configured else {
            channel.setMethodCallHandler { _, result in result(["supported": false]) }
            if #available(iOS 16.2, *) { endLeftoverActivities() }
            return
        }
        let manager = BusArrivalActivityCoordinator(backend: backend) { status in
            channel.invokeMethod("changed", arguments: status)
        }
        coordinator = manager
        channel.setMethodCallHandler { [weak manager] call, result in
            Task { @MainActor in
                guard let manager else { result(nil); return }
                do {
                    switch call.method {
                    case "status":
                        await manager.restore()
                    case "start":
                        guard let arguments = call.arguments as? [String: Any],
                              let stopID = arguments["stopID"] as? Int,
                              let lineID = arguments["lineID"] as? String else {
                            throw ActivityError.invalidStop
                        }
                        try await manager.start(stopID: stopID, lineID: lineID,
                                                name: arguments["stopName"] as? String,
                                                language: arguments["language"] as? String ?? "es")
                    case "updateStopName":
                        guard let arguments = call.arguments as? [String: Any],
                              let stopID = arguments["stopID"] as? Int,
                              let lineID = arguments["lineID"] as? String,
                              let name = arguments["stopName"] as? String else {
                            throw ActivityError.invalidStop
                        }
                        await manager.updateStopName(stopID: stopID, lineID: lineID, name: name)
                    case "stop": await manager.stop()
                    default: result(FlutterMethodNotImplemented); return
                    }
                    result(manager.status)
                } catch {
                    let nativeError = error as NSError
                    NSLog("Live Activity %@ failed: %@ (%@/%ld)", call.method,
                          String(reflecting: error), nativeError.domain, nativeError.code)
                    result(FlutterError(code: (error as? ActivityError)?.code ?? "failed",
                                        message: error.localizedDescription,
                                        details: ["domain": nativeError.domain, "code": nativeError.code]))
                }
            }
        }
    }

    /// A build without a backend may replace one that had it, for example an
    /// App Store install over a personal build.
    @available(iOS 16.2, *)
    private static func endLeftoverActivities() {
        Task {
            for activity in Activity<BusArrivalAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}

enum ActivityError: Error {
    case invalidStop, disabled, busy, noPushToken
    var code: String {
        switch self {
        case .invalidStop: "invalid_stop"
        case .disabled: "disabled"
        case .busy: "busy"
        case .noPushToken: "no_push_token"
        }
    }
}

/// Starts bus arrival Live Activities. Shared by the Flutter channel and the
/// "Get next bus" shortcut, which can run while Aucorsa is closed.
@available(iOS 16.2, *)
@MainActor
enum BusArrivalActivityStarter {
    /// Posted after a shortcut starts an activity, so a running app adopts it.
    static let didStartNotification = Notification.Name("BusArrivalActivityStarter.didStart")

    /// Validates the line, fetches its first estimates, runs `endingPrevious`
    /// (only one activity runs at a time), then requests the new activity.
    static func start(
        stopID: Int, lineID: String, name: String?, language: String,
        endingPrevious: () async -> Void
    ) async throws -> Activity<BusArrivalAttributes> {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { throw ActivityError.disabled }
        let catalog = TransitCatalog.shared
        guard let busStop = catalog.stop(id: stopID),
              catalog.lines(servingStop: stopID).contains(where: { $0.id == lineID }) else {
            throw ActivityError.invalidStop
        }
        let estimations = try await AucorsaClient.shared.estimations(forStop: stopID)
        let snapshot = BusArrivalSnapshot(estimations: estimations, preferredLineID: lineID)
        await endingPrevious()
        let startedAt = Date.now.timeIntervalSince1970
        let attributes = BusArrivalAttributes(
            stopID: stopID, stopName: String((name?.isEmpty == false ? name! : busStop.name).prefix(80)),
            preferredLineID: lineID, language: language == "es" ? "es" : "en",
            endsAt: startedAt + BusArrivalAttributes.sessionDuration,
            sessionID: UUID().uuidString,
            startedAt: startedAt
        )
        let content = ActivityContent(state: snapshot,
                                      staleDate: snapshot.staleDate(endingAt: attributes.deadline))
        do {
            return try Activity.request(attributes: attributes, content: content, pushType: .token)
        } catch {
            // Without the push entitlement, keep on-device refreshes only.
            NSLog("Live Activity push updates unavailable: %@", String(reflecting: error))
            return try Activity.request(attributes: attributes, content: content, pushType: nil)
        }
    }

    /// Ends every activity and its backend session, for callers without the
    /// Flutter channel's coordinator.
    static func endAll(unregisteringFrom backend: LiveActivityBackend) async {
        for activity in Activity<BusArrivalAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
            try? await backend.unregister(sessionID: activity.attributes.sessionID)
        }
    }

    /// Hands the activity's refreshes to the backend.
    static func register(
        _ activity: Activity<BusArrivalAttributes>, token: Data, with backend: LiveActivityBackend
    ) async throws {
        try await backend.register(
            sessionID: activity.attributes.sessionID, pushToken: token,
            stopID: activity.attributes.stopID, lineID: activity.attributes.preferredLineID,
            stopName: activity.content.state.stopName ?? activity.attributes.stopName,
            endsAt: activity.attributes.deadline
        )
    }

    /// For a shortcut, which iOS may suspend as soon as it returns: waits a few
    /// seconds for the new activity's push token and registers it.
    static func registerFirstPushToken(
        of activity: Activity<BusArrivalAttributes>, with backend: LiveActivityBackend
    ) async throws {
        let token: Data? = await withTaskGroup(of: Data?.self) { group in
            group.addTask {
                if let token = activity.pushToken { return token }
                for await token in activity.pushTokenUpdates { return token }
                return nil
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(8))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        guard let token else { throw ActivityError.noPushToken }
        try await register(activity, token: token, with: backend)
    }
}

@available(iOS 16.2, *)
@MainActor
final class BusArrivalActivityCoordinator {
    private let backend: LiveActivityBackend
    private let onStateChanged: ([String: Any]) -> Void
    private var timer: Timer?
    private var expirationTimers: [String: Timer] = [:]
    private var observations: [NSObjectProtocol] = []
    private var stateTasks: [String: Task<Void, Never>] = [:]
    private var tokenTasks: [String: Task<Void, Never>] = [:]
    /// Activities the backend refreshes; the foreground poll skips these.
    private var serverBacked: Set<String> = []
    private var refreshing = false
    private var changing = false

    private var current: Activity<BusArrivalAttributes>? {
        Activity<BusArrivalAttributes>.activities.first {
            $0.activityState == .active || $0.activityState == .stale
        }
    }

    var status: [String: Any] {
        var value: [String: Any] = [
            "supported": true, "enabled": ActivityAuthorizationInfo().areActivitiesEnabled
        ]
        if let activity = current, !activity.attributes.hasExpired {
            value["stopID"] = activity.attributes.stopID
            value["lineID"] = activity.attributes.preferredLineID
            value["stopName"] = activity.content.state.stopName ?? activity.attributes.stopName
            value["endsAt"] = activity.attributes.deadline
        }
        return value
    }

    init(backend: LiveActivityBackend, onStateChanged: @escaping ([String: Any]) -> Void) {
        self.backend = backend
        self.onStateChanged = onStateChanged
        observations.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.restore()
                await self?.refresh()
            }
        })
        // A shortcut can start an activity while Flutter is running.
        observations.append(NotificationCenter.default.addObserver(
            forName: BusArrivalActivityStarter.didStartNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in await self?.restore() }
        })
        observations.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.timer?.invalidate()
                self?.timer = nil
                if self?.current != nil { NSLog("Live Activity polling paused: app entered background") }
            }
        })
        Task { await restore() }
    }

    func restore() async {
        for activity in Activity<BusArrivalAttributes>.activities {
            if activity.attributes.hasExpired {
                await finish(activity)
            } else if activity.activityState == .active || activity.activityState == .stale {
                observe(activity)
                // Retries a registration that failed, for example while offline.
                if !serverBacked.contains(activity.id), let token = activity.pushToken {
                    Task { await register(activity, token: token) }
                }
            }
        }
        startTimer()
        notify()
    }

    func start(stopID: Int, lineID: String, name: String?, language: String) async throws {
        guard !changing else { throw ActivityError.busy }
        changing = true
        defer { changing = false }
        let activity = try await BusArrivalActivityStarter.start(
            stopID: stopID, lineID: lineID, name: name, language: language,
            endingPrevious: { await self.stop() }
        )
        observe(activity)
        startTimer()
        notify()
    }

    func stop() async {
        for activity in Activity<BusArrivalAttributes>.activities { await finish(activity) }
        timer?.invalidate()
        timer = nil
        notify()
    }

    func updateStopName(stopID: Int, lineID: String, name: String) async {
        guard let activity = current,
              activity.attributes.stopID == stopID,
              activity.attributes.preferredLineID == lineID else { return }
        guard !activity.attributes.hasExpired else {
            await finish(activity)
            notify()
            return
        }
        let displayName = name.isEmpty
            ? (TransitCatalog.shared.stop(id: stopID)?.name ?? activity.attributes.stopName)
            : name
        let snapshot = activity.content.state.withStopName(displayName)
        await activity.update(ActivityContent(state: snapshot,
            staleDate: snapshot.staleDate(endingAt: activity.attributes.deadline)))
        if serverBacked.contains(activity.id) {
            let sessionID = activity.attributes.sessionID
            Task {
                do {
                    try await backend.rename(sessionID: sessionID, stopName: displayName)
                } catch {
                    NSLog("Live Activity server rename failed: %@", String(reflecting: error))
                }
            }
        }
        notify()
    }

    private func finish(_ activity: Activity<BusArrivalAttributes>) async {
        expirationTimers.removeValue(forKey: activity.id)?.invalidate()
        stateTasks.removeValue(forKey: activity.id)?.cancel()
        stopServerRefreshes(activity)
        await activity.end(nil, dismissalPolicy: .immediate)
    }

    // MARK: - Server refreshes

    /// Hands refreshes to the backend, which pushes them every 30 seconds while
    /// the app is suspended. Tokens can rotate, so every new one is registered.
    private func observePushTokens(_ activity: Activity<BusArrivalAttributes>) {
        guard tokenTasks[activity.id] == nil else { return }
        tokenTasks[activity.id] = Task { [weak self] in
            for await token in activity.pushTokenUpdates {
                guard !Task.isCancelled else { return }
                await self?.register(activity, token: token)
            }
        }
    }

    private func register(_ activity: Activity<BusArrivalAttributes>, token: Data) async {
        guard activity.activityState == .active || activity.activityState == .stale,
              !activity.attributes.hasExpired else { return }
        do {
            try await BusArrivalActivityStarter.register(activity, token: token, with: backend)
            serverBacked.insert(activity.id)
            if current?.id == activity.id {
                timer?.invalidate()
                timer = nil
            }
            NSLog("Live Activity registered for server refreshes")
        } catch {
            // Keep refreshing on device while open; resuming the app retries.
            serverBacked.remove(activity.id)
            startTimer()
            NSLog("Live Activity server registration failed: %@", String(reflecting: error))
        }
    }

    /// Best-effort: the backend also ends sessions itself at the deadline.
    private func stopServerRefreshes(_ activity: Activity<BusArrivalAttributes>) {
        tokenTasks.removeValue(forKey: activity.id)?.cancel()
        serverBacked.remove(activity.id)
        let sessionID = activity.attributes.sessionID
        Task {
            do {
                try await backend.unregister(sessionID: sessionID)
            } catch {
                NSLog("Live Activity server unregister failed: %@", String(reflecting: error))
            }
        }
    }

    private func scheduleExpiration(_ activity: Activity<BusArrivalAttributes>) {
        expirationTimers.removeValue(forKey: activity.id)?.invalidate()
        let activityID = activity.id
        let expiration = Timer(fire: Date(timeIntervalSince1970: activity.attributes.deadline),
                               interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                guard let activity = Activity<BusArrivalAttributes>.activities.first(where: { $0.id == activityID }) else {
                    self.expirationTimers.removeValue(forKey: activityID)?.invalidate()
                    self.notify()
                    return
                }
                guard activity.attributes.hasExpired else {
                    self.scheduleExpiration(activity)
                    return
                }
                // Clear Following immediately; ending the system UI is async.
                self.notify()
                await self.finish(activity)
                if self.current == nil {
                    self.timer?.invalidate()
                    self.timer = nil
                }
                self.notify()
            }
        }
        expirationTimers[activity.id] = expiration
        // Independent of the 30-second network poll, including during scrolling.
        // iOS can suspend this timer in the background; restore() handles that.
        RunLoop.main.add(expiration, forMode: .common)
    }

    private func observe(_ activity: Activity<BusArrivalAttributes>) {
        guard stateTasks[activity.id] == nil else { return }
        scheduleExpiration(activity)
        observePushTokens(activity)
        stateTasks[activity.id] = Task { [weak self] in
            for await state in activity.activityStateUpdates {
                guard !Task.isCancelled else { return }
                if state == .ended || state == .dismissed {
                    self?.expirationTimers.removeValue(forKey: activity.id)?.invalidate()
                    self?.stateTasks.removeValue(forKey: activity.id)
                    self?.stopServerRefreshes(activity)
                    if self?.current == nil {
                        self?.timer?.invalidate()
                        self?.timer = nil
                    }
                    self?.notify()
                    return
                }
            }
        }
    }

    private func startTimer() {
        guard let activity = current, !serverBacked.contains(activity.id) else {
            timer?.invalidate()
            timer = nil
            return
        }
        guard timer == nil, UIApplication.shared.applicationState == .active else { return }
        let pollTimer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
        // Keep polling while scroll views are tracking touches, too.
        RunLoop.main.add(pollTimer, forMode: .common)
        timer = pollTimer
        NSLog("Live Activity foreground polling started: interval=30s")
    }

    private func refresh() async {
        guard !refreshing, !changing, UIApplication.shared.applicationState == .active,
              let activity = current else { return }
        guard !activity.attributes.hasExpired else { await stop(); return }
        refreshing = true
        defer { refreshing = false }
        let requestedAt = Date.now.timeIntervalSince1970
        do {
            let estimations = try await AucorsaClient.shared.estimations(forStop: activity.attributes.stopID)
            guard current?.id == activity.id else { return }
            guard !activity.attributes.hasExpired else { await stop(); return }
            let snapshot = BusArrivalSnapshot(estimations: estimations, preferredLineID: activity.attributes.preferredLineID)
                .withStopName(activity.content.state.stopName)
            // A Refresh intent may have supplied newer data during the fetch.
            if requestedAt >= activity.content.state.fetchedAt {
                await activity.update(ActivityContent(state: snapshot,
                    staleDate: snapshot.staleDate(endingAt: activity.attributes.deadline)))
                NSLog("Live Activity refreshed: fetchedAt=%.3f", snapshot.fetchedAt)
            }
        } catch {
            // Keep the last successful timestamp: the system marks it stale.
            NSLog("Live Activity refresh failed: %@", String(reflecting: error))
        }
    }

    private func notify() { onStateChanged(status) }
}
