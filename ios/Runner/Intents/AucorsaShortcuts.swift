import AppIntents

/// The phrases Siri recognises without the user building a shortcut first.
///
/// Every phrase must be a compile-time literal and must contain
/// `\(.applicationName)`; iOS allows at most ten shortcuts per app and ten
/// phrases each. Translations live in `AppShortcuts.xcstrings` — the Spanish
/// phrasings are what most users of this app will actually say, so they are not
/// an afterthought.
struct AucorsaShortcuts: AppShortcutsProvider {
    // The app is seeded from `Colors.green`; AppIntents has no plain green, and
    // `.grayGreen` is the nearest tile colour in its palette.
    static var shortcutTileColor: ShortcutTileColor { .grayGreen }

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetStopArrivalsIntent(),
            phrases: [
                "Bus arrivals with \(.applicationName)",
                "Check my stop with \(.applicationName)",
                "\(.applicationName) arrivals at \(\.$stop)",
                "Next bus at \(\.$stop) with \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Bus Arrivals", table: "Intents"),
            systemImageName: "clock"
        )

        AppShortcut(
            intent: GetNextBusForLineIntent(),
            phrases: [
                "Next \(\.$line) bus with \(.applicationName)",
                "\(.applicationName) line \(\.$line)"
            ],
            shortTitle: LocalizedStringResource("Next Bus On Line", table: "Intents"),
            systemImageName: "arrow.triangle.swap"
        )
    }
}
