import SwiftUI

@main
struct WishCraftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var wishlistManager = WishlistManager()
    @AppStorage("isDarkMode") private var isDarkMode: Bool?
    @StateObject private var uiSettings = UISettings()

    var body: some Scene {
        WindowGroup {
            ContentView(isDarkMode: $isDarkMode)
                .environmentObject(wishlistManager)
                .environmentObject(uiSettings)
                .environment(\.sizeCategory, uiSettings.contentSizeCategory)
                .preferredColorScheme(isDarkMode == true ? .dark : (isDarkMode == false ? .light : nil))
                .onAppear {
                    if AppDelegate.launchedFromExtension {
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
        }

        Settings {
            PreferencesView(isDarkMode: $isDarkMode, isPresentedAsSheet: false)
                .environmentObject(uiSettings)
                .environment(\.sizeCategory, uiSettings.contentSizeCategory)
        }
    }
}
