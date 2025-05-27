import SwiftUI

@main
struct WishCraftApp: App {
    @StateObject private var wishlistManager = WishlistManager()
    @AppStorage("isDarkMode") private var isDarkMode: Bool?
    @StateObject private var uiSettings = UISettings()

    var body: some Scene {
        WindowGroup {
            ContentView(isDarkMode: $isDarkMode)
                .environmentObject(wishlistManager)
                .environmentObject(uiSettings)
                .environment(\.sizeCategory, uiSettings.contentSizeCategory) // << SETS DYNAMIC TYPE CATEGORY
                .preferredColorScheme(isDarkMode == true ? .dark : (isDarkMode == false ? .light : nil))
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Wishlist") {
                    wishlistManager.addWishlist()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }

        Settings {
            PreferencesView(isDarkMode: $isDarkMode, isPresentedAsSheet: false)
                .environmentObject(uiSettings)
                .environment(\.sizeCategory, uiSettings.contentSizeCategory) // << ALSO FOR PREFERENCES WINDOW
        }
    }
}
