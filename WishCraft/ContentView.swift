import SwiftUI

struct ContentView: View {
    @EnvironmentObject var wishlistManager: WishlistManager
    @EnvironmentObject var uiSettings: UISettings
    @Binding var isDarkMode: Bool?

    @State private var showingRenameAlert = false
    @State private var wishlistToRename: Wishlist?
    @State private var newWishlistName: String = ""

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedWishlistId: $wishlistManager.selectedWishlistId,
                wishlists: $wishlistManager.wishlists,
                isDarkModeEnabled: $isDarkMode,
                onRenameRequest: { wishlist in
                    wishlistToRename = wishlist; newWishlistName = wishlist.name; showingRenameAlert = true
                },
                onDeleteRequest: { wishlistId in wishlistManager.deleteWishlist(wishlistId: wishlistId) },
                onAddWishlist: { wishlistManager.addWishlist() }
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 450)
        } detail: {
            if let selectedId = wishlistManager.selectedWishlistId,
               let selectedWishlist = wishlistManager.wishlists.first(where: { $0.id == selectedId }) {
                let wishlistBinding = Binding<Wishlist>(
                    get: { wishlistManager.wishlists.first(where: { $0.id == selectedId }) ?? selectedWishlist },
                    set: { updatedWishlist in wishlistManager.updateWishlist(updatedWishlist) }
                )
                WishlistDetailView(wishlist: wishlistBinding)
                    .id(selectedId)
            } else {
                VStack(spacing: uiSettings.spacing(20)) {
                    Image(systemName: "list.star")
                        .font(.system(size: 50 * uiSettings.layoutScaleFactor))
                        .padding(.bottom, uiSettings.padding(10))
                    Text("No Wishlist Selected")
                        .font(.title) // Dynamic Type
                    Text("Select or create a wishlist.")
                        .font(.body) // Dynamic Type
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .alert("Rename Wishlist", isPresented: $showingRenameAlert, presenting: wishlistToRename) { wl in
            TextField("New name", text: $newWishlistName) // Text inside TextField will scale with Dynamic Type
            Button("Rename") { if !newWishlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { wishlistManager.renameWishlist(wishlistId: wl.id, newName: newWishlistName) } }
            Button("Cancel", role: .cancel) {}
        } message: { wl in Text("Enter a new name for \"\(wl.name)\".") } // Alert text also scales
    }
}
