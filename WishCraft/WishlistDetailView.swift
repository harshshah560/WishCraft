import SwiftUI
import UniformTypeIdentifiers

struct WishlistDetailView: View {
    @Binding var wishlist: Wishlist
    @EnvironmentObject var wishlistManager: WishlistManager
    @EnvironmentObject var uiSettings: UISettings

    // Sheet and selection states
    @State private var showingAddItemSheet = false
    @State private var editingItem: WishlistItem? = nil
    @State private var showingImagePicker = false
    @State private var newlyAddedItemId: WishlistItem.ID? = nil
    @State private var showOptionsMenuPopover: Bool = false

    // State for presenting the CoverEditView sheet
    @State private var showingCoverEditView = false

    // Define the CONCEPTUAL target aspect ratio for banner editing (4:1)
    private let conceptualBannerEditWidth: CGFloat = 1200 // 4 parts
    private let conceptualBannerEditHeight: CGFloat = 300  // 1 part

    // Sorting
    enum SortOrder: String, CaseIterable, Identifiable {
        case nameAsc = "Name (A-Z)"
        case nameDesc = "Name (Z-A)"
        case dateAddedNewest = "Date Added (Newest)"
        case dateAddedOldest = "Date Added (Oldest)"
        var id: String { self.rawValue }
    }
    @State private var currentSortOrder: SortOrder = .dateAddedNewest

    var sortedItems: [WishlistItem] {
        // ... (sorting logic remains the same)
        switch currentSortOrder {
        case .nameAsc: return wishlist.items.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDesc: return wishlist.items.sorted { $0.name.lowercased() > $1.name.lowercased() }
        case .dateAddedNewest: return wishlist.items.sorted { $0.dateAdded > $1.dateAdded }
        case .dateAddedOldest: return wishlist.items.sorted { $0.dateAdded < $1.dateAdded }
        }
    }

    // This section is displayed ONLY if there is a cover image
    @ViewBuilder
        private var coverImageBannerSection: some View {
            GeometryReader { bannerSlotGeo in
                let displayFrameWidth = bannerSlotGeo.size.width
                let displayFrameHeight = bannerSlotGeo.size.height

                ZStack(alignment: .bottomTrailing) { // ZStack aligns its children to the bottom trailing edge
                    // Image Display Area (remains the same)
                    Group {
                        if let imageData = wishlist.coverImageData, let nsImage = NSImage(data: imageData) {
                            if displayFrameWidth > 0 && displayFrameHeight > 0 && nsImage.size.width > 0 && nsImage.size.height > 0 {
                                let imageOriginalWidth = nsImage.size.width
                                let imageOriginalHeight = nsImage.size.height
                                let scaleX = displayFrameWidth / imageOriginalWidth
                                let scaleY = displayFrameHeight / imageOriginalHeight
                                let fillScale = max(scaleX, scaleY)
                                let scaledImageWidth = imageOriginalWidth * fillScale
                                let scaledImageHeight = imageOriginalHeight * fillScale
                                let displayOffsetX = wishlist.coverImageOffset.width * fillScale
                                let displayOffsetY = wishlist.coverImageOffset.height * fillScale
                                
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .frame(width: scaledImageWidth, height: scaledImageHeight)
                                    .offset(x: displayOffsetX, y: displayOffsetY)
                                    .frame(width: displayFrameWidth, height: displayFrameHeight) // Clipping frame
                                    .clipped()
                            } else {
                                Rectangle().fill(Color.gray.opacity(0.1))
                                    .overlay(Text("Invalid image/frame").font(.caption).foregroundColor(.red))
                            }
                        } else {
                            Rectangle().fill(Color.gray.opacity(0.3))
                                .overlay(Text("No Cover Image Data").font(.caption).foregroundColor(.secondary))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.secondary.opacity(0.2))

                    // "More Options" Button that triggers a popover
                    Button {
                        showOptionsMenuPopover = true
                    } label: {
                        // This is your custom circular ellipsis button
                        Label("Image Options", systemImage: "ellipsis.circle.fill")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 15 * uiSettings.layoutScaleFactor, weight: .medium))
                            .foregroundColor(.white) // Icon color
                            .frame(width: 30 * uiSettings.layoutScaleFactor, height: 40 * uiSettings.layoutScaleFactor)
                            .background(Circle().fill(Color.black.opacity(0.55)))
                            // .clipShape(Circle()) // Optional: if background doesn't perfectly clip
                    }
                    .buttonStyle(.plain) // Use .plain or .borderless to remove default button chrome
                    .padding(uiSettings.padding(10)) // Spacing around the button
                    .popover(isPresented: $showOptionsMenuPopover, arrowEdge: .top) { // arrowEdge can be .top, .bottom, etc.
                        // Content of the popover - your menu items
                        VStack(alignment: .leading, spacing: 10) { // Added spacing
                            Button {
                                showingImagePicker = true
                                showOptionsMenuPopover = false // Dismiss popover
                            } label: {
                                Label("Change Image", systemImage: "photo.on.rectangle.angled")
                            }
                            .buttonStyle(.plain) // Keep popover buttons clean

                            Button {
                                showingCoverEditView = true
                                showOptionsMenuPopover = false // Dismiss popover
                            } label: {
                                Label("Reposition Image", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                            }
                            .buttonStyle(.plain)

                            Divider()

                            Button(role: .destructive) {
                                var mutableWishlist = wishlist
                                mutableWishlist.coverImageData = nil
                                mutableWishlist.coverImageOffset = .zero
                                wishlist = mutableWishlist
                                showOptionsMenuPopover = false // Dismiss popover
                            } label: {
                                Label("Remove Image", systemImage: "xmark.bin")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding() // Padding inside the popover content
                        .frame(minWidth: 180) // Optional: set a minWidth for the popover
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
            }
            .aspectRatio(CGSize(width: 4, height: 1), contentMode: .fit)
        }

    // This button is displayed ONLY if there is NO cover image
    @ViewBuilder
    private var addCoverImageButtonView: some View {
        HStack {
            Button {
                showingImagePicker = true
            } label: {
                Label("Add Cover Image", systemImage: "photo.badge.plus")
                    .font(.callout) // Subtle but clear
            }
            .buttonStyle(.plain) // Makes it look like a text link/action, similar to Notion
            .padding([.top, .leading], uiSettings.padding(16)) // Give it some space from top/leading edge
            .padding(.bottom, uiSettings.padding(8)) // Space before next section
            Spacer() // Pushes it to the left
        }
        .frame(maxWidth: .infinity) // Allows Spacer to work
    }

    // ViewBuilder for the items list area - NO CHANGES HERE
    @ViewBuilder
    private var itemsListSection: some View {
        // ... (itemsListSection remains the same)
        Text(wishlist.name)
            .font(.largeTitle.weight(.bold))
            .padding(uiSettings.padding())

        HStack(spacing: uiSettings.spacing()) {
            Button {
                editingItem = nil
                showingAddItemSheet = true
            } label: {
                Label("Add Item", systemImage: "plus.circle.fill")
                    .font(.body)
            }
            .keyboardShortcut("a", modifiers: .command)
            Spacer()
            Picker("Sort by", selection: $currentSortOrder) {
                ForEach(SortOrder.allCases) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(.menu)
            .frame(
                maxWidth: 200 * uiSettings.layoutScaleFactor,
                minHeight: 32 * uiSettings.layoutScaleFactor,
                maxHeight: 32 * uiSettings.layoutScaleFactor
            )
        }
        .padding(.horizontal, uiSettings.padding())
        .padding(.bottom, uiSettings.spacing(8))
        
        Divider()

        if sortedItems.isEmpty {
            VStack(spacing: uiSettings.spacing(15)) {
                Spacer()
                Image(systemName: "giftcard")
                    .font(.system(size: 40 * uiSettings.layoutScaleFactor))
                    .foregroundColor(.secondary)
                    .padding(.bottom, uiSettings.padding(5))
                Text("No items yet!")
                    .font(.title2)
                Text("Click \"Add Item\" to add to your wishlist.")
                    .font(.body)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(sortedItems) { item in
                    WishlistItemView(item: item, onEdit: {
                        editingItem = item
                        showingAddItemSheet = true
                    }, onDelete: {
                        wishlistManager.deleteItem(from: wishlist.id, itemId: item.id)
                    })
                    .id(item.id)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
        }
    }

    var body: some View {
        ScrollViewReader { scrollViewProxy in
            VStack(alignment: .leading, spacing: 0) {
                // CONDITIONAL DISPLAY of banner OR "Add Cover" button
                if wishlist.coverImageData != nil {
                    coverImageBannerSection // The 4:1 banner with image and "..." menu
                } else {
                    addCoverImageButtonView   // The simple "Add Cover Image" button
                }
                
                itemsListSection
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // ... (sheets and .fileImporter remain the same)
            .sheet(isPresented: $showingAddItemSheet) {
                ItemEditView(
                    itemToEdit: editingItem,
                    wishlistId: wishlist.id,
                    onSave: { savedItem in
                        if editingItem == nil {
                            wishlistManager.addItem(to: wishlist.id, item: savedItem)
                            self.newlyAddedItemId = savedItem.id
                        } else {
                            wishlistManager.updateItem(in: wishlist.id, item: savedItem)
                        }
                        editingItem = nil
                    }
                )
                .environmentObject(uiSettings)
                .environment(\.sizeCategory, uiSettings.contentSizeCategory)
            }
            .sheet(isPresented: $showingCoverEditView) {
                CoverEditView(
                    originalImageData: $wishlist.coverImageData,
                    currentAppliedOffset: $wishlist.coverImageOffset,
                    targetBannerWidth: conceptualBannerEditWidth,
                    targetBannerHeight: conceptualBannerEditHeight
                )
                .environmentObject(uiSettings)
            }
            .fileImporter(
                isPresented: $showingImagePicker,
                allowedContentTypes: [UTType.image],
                allowsMultipleSelection: false,
                onCompletion: { result in
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        let secured = url.startAccessingSecurityScopedResource()
                        defer { if secured { url.stopAccessingSecurityScopedResource() } }
                        do {
                            let imageData = try Data(contentsOf: url)
                            var mutableWishlist = wishlist
                            mutableWishlist.coverImageData = imageData
                            mutableWishlist.coverImageOffset = .zero
                            wishlist = mutableWishlist
                        } catch { print("Error loading image data: \(error)") }
                    case .failure(let error): print("Error picking image: \(error.localizedDescription)")
                    }
                }
            )
            .onChange(of: wishlist.id) { _ in
                self.newlyAddedItemId = nil
            }
            .onChange(of: newlyAddedItemId) { targetItemId in
                if let itemId = targetItemId {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation {
                            var anchor: UnitPoint = .center
                            if currentSortOrder == .dateAddedNewest { anchor = .top }
                            else if currentSortOrder == .dateAddedOldest { anchor = .bottom }
                            scrollViewProxy.scrollTo(itemId, anchor: anchor)
                        }
                        self.newlyAddedItemId = nil
                    }
                }
            }
        }
    }
}
