import SwiftUI
import SwiftData

@main
struct ProjectTomoApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    private var selectedMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(selectedMode.colorScheme)
        }
        .modelContainer(for: [Friend.self, Story.self])
    }
}
