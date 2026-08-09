import SwiftUI
import UIKit
import os

/// Resolves the interface style the snippet should be drawn in.
///
/// Snippet views are rendered by the system, and that render environment does
/// not inherit the device's appearance — it reports light regardless of the
/// user's setting, which is why the snippet came out light on a dark phone. The
/// appearance is therefore read here, inside the app's own process while
/// `perform()` runs, and forced onto the view.
///
/// Verified on a dark simulator: all three sources below report `dark` in this
/// process while the snippet's own environment reports light.
///
/// Known limitation: a process that is already resident keeps the appearance it
/// last saw. If the user flips light/dark (or auto-appearance does at sunset)
/// while the app sits in the background, the next snippet can use the previous
/// scheme until the app is foregrounded or relaunched. A freshly launched
/// process always reads correctly, and there is no public API to read the
/// system appearance without going through this process's traits.
enum SystemAppearance {
    private static let logger = Logger(
        subsystem: "com.chechu.aucorsa", category: "SystemAppearance"
    )

    /// The colour scheme to force on a snippet, or nil when it cannot be
    /// determined (in which case the view should inherit).
    @MainActor
    static var colorScheme: ColorScheme? {
        switch resolvedStyle() {
        case .dark: .dark
        case .light: .light
        default: nil
        }
    }

    @MainActor
    private static func resolvedStyle() -> UIUserInterfaceStyle {
#if APP_INTENTS_EXTENSION
        // ExtensionKit has no UIApplication, but its process traits still
        // reflect the device appearance before Siri hosts the returned view in
        // its own (incorrectly light) snippet environment.
        let sceneStyle: UIUserInterfaceStyle? = nil
        let preferScreenStyle = true
#else
        // A live window scene is the most accurate source: it reflects the
        // system setting and any app-level override.
        let sceneStyle = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .traitCollection
            .userInterfaceStyle
        let preferScreenStyle = false
#endif

        let currentStyle = UITraitCollection.current.userInterfaceStyle
        let screenStyle = UIScreen.main.traitCollection.userInterfaceStyle

        logger.debug(
            """
            appearance probe — scene=\(describe(sceneStyle), privacy: .public) \
            current=\(describe(currentStyle), privacy: .public) \
            screen=\(describe(screenStyle), privacy: .public)
            """
        )

        return selectStyle(
            scene: sceneStyle,
            current: currentStyle,
            screen: screenStyle,
            preferScreen: preferScreenStyle
        )
    }

    /// Kept separate so the extension fallback order stays covered by a unit
    /// test even though RunnerTests cannot execute inside ExtensionKit.
    static func selectStyle(
        scene: UIUserInterfaceStyle?,
        current: UIUserInterfaceStyle,
        screen: UIUserInterfaceStyle,
        preferScreen: Bool = false
    ) -> UIUserInterfaceStyle {
        if let scene, scene != .unspecified { return scene }
        if preferScreen, screen != .unspecified { return screen }
        if current != .unspecified { return current }
        return screen
    }

    private static func describe(_ style: UIUserInterfaceStyle?) -> String {
        switch style {
        case .some(.dark): "dark"
        case .some(.light): "light"
        case .some(.unspecified): "unspecified"
        default: "nil"
        }
    }
}

extension View {
    /// Pins a snippet to a colour scheme when one could be determined, leaving
    /// it to inherit otherwise.
    ///
    /// `.environment(\.colorScheme, _)` rather than `.preferredColorScheme`:
    /// only the former re-resolves the dynamic `UIColor`s the palette is built
    /// from.
    @ViewBuilder
    func snippetColorScheme(_ scheme: ColorScheme?) -> some View {
        if let scheme {
            environment(\.colorScheme, scheme)
        } else {
            self
        }
    }
}
