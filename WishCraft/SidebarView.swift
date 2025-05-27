import SwiftUI

struct SidebarView: View {
    @Binding var selectedWishlistId: Wishlist.ID?
    @Binding var wishlists: [Wishlist] // For .onChange(of: wishlists) to work optimally, Wishlist should be Equatable
    @Binding var isDarkModeEnabled: Bool?
    @EnvironmentObject var uiSettings: UISettings

    var onRenameRequest: (Wishlist) -> Void
    var onDeleteRequest: (Wishlist.ID) -> Void
    var onAddWishlist: () -> Void
    
    @State private var showingDeleteConfirm: Wishlist? = nil
    @State private var showingPreferencesSheet = false

    @State private var searchText: String = ""
    @State private var isNewWishlistHovered: Bool = false
    @State private var isSettingsHovered: Bool = false

    // New state variable to hold the list actually displayed
    @State private var displayedWishlists: [Wishlist] = []

    // This function will now update the @State variable
    private func updateDisplayedWishlists() {
        if searchText.isEmpty {
            displayedWishlists = wishlists
        } else {
            displayedWishlists = wishlists.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .imageScale(uiSettings.imageScale)
                TextField("Search Wishlists", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14 * uiSettings.layoutScaleFactor))
            }
            .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10))
            .background(Color(nsColor: .unemphasizedSelectedContentBackgroundColor))
            .cornerRadius(8)
            .padding([.horizontal, .top], 12)
            .padding(.bottom, 12)

            // New Wishlist Button
            Button(action: onAddWishlist) {
                Label("New Wishlist", systemImage: "square.and.pencil")
                    .font(.system(size: 14 * uiSettings.layoutScaleFactor, weight: .medium))
                    .imageScale(uiSettings.imageScale)
                    .foregroundColor(.primary)
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(isNewWishlistHovered ? Color.gray.opacity(0.15) : Color.clear)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .onHover { hovering in isNewWishlistHovered = hovering }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)

            // Wishlist List - now uses 'displayedWishlists'
            List(selection: $selectedWishlistId) {
                Section(header: Text(displayedWishlists.isEmpty && searchText.isEmpty ? "No Wishlists" : (displayedWishlists.isEmpty && !searchText.isEmpty ? "No Results" : "Wishlists"))
                                    .font(.system(size: 12 * uiSettings.layoutScaleFactor, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                        ) {
                    ForEach(displayedWishlists) { wishlist in // Use displayedWishlists
                        HStack {
                            Label(wishlist.name, systemImage: "list.bullet.rectangle.portrait")
                                .font(.body)
                                .imageScale(uiSettings.imageScale)
                            
                            Spacer()
                            
                            Button(action: { onRenameRequest(wishlist) }) {
                                Image(systemName: "pencil")
                                    .imageScale(uiSettings.imageScale)
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.borderless)
                            .help("Rename \(wishlist.name)")

                            Button(action: { showingDeleteConfirm = wishlist }) {
                                Image(systemName: "trash")
                                    .imageScale(uiSettings.imageScale)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                            .help("Delete \(wishlist.name)")
                        }
                        .tag(wishlist.id)
                    }
                }
            }
            .listStyle(.sidebar)

            // Settings Button
            Button(action: {
                showingPreferencesSheet = true
            }) {
                Label("Preferences", systemImage: "gearshape.fill")
                    .font(.system(size: 14 * uiSettings.layoutScaleFactor, weight: .medium))
                    .imageScale(uiSettings.imageScale)
                    .foregroundColor(.primary)
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(isSettingsHovered ? Color.gray.opacity(0.15) : Color.clear)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .onHover { hovering in isSettingsHovered = hovering }
            .padding(12)
        }
        .onAppear {
            // Initial update of the displayed list
            updateDisplayedWishlists()
        }
        .onChange(of: searchText) { _ in
            // Update when search text changes
            updateDisplayedWishlists()
        }
        .onChange(of: wishlists) { _ in
            // Update when the source wishlists array changes
            // Note: For this to be efficient and correct, your 'Wishlist' struct
            // should conform to Equatable. If it has simple properties and already
            // conforms to Codable/Hashable, it might already be Equatable.
            // If not, you might need to add `Equatable` conformance to `Wishlist`.
            updateDisplayedWishlists()
        }
        .alert(item: $showingDeleteConfirm) { wltd in
            Alert(
                title: Text("Delete Wishlist?"),
                message: Text("Are you sure you want to delete \"\(wltd.name)\"? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) { onDeleteRequest(wltd.id) },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showingPreferencesSheet) {
            PreferencesView(isDarkMode: $isDarkModeEnabled, isPresentedAsSheet: true)
                .environmentObject(uiSettings)
                .environment(\.sizeCategory, uiSettings.contentSizeCategory)
                .frame(minWidth: 380 * uiSettings.layoutScaleFactor, idealWidth: 420 * uiSettings.layoutScaleFactor,
                       minHeight: 250 * uiSettings.layoutScaleFactor, idealHeight: 300 * uiSettings.layoutScaleFactor)
        }
    }
}

