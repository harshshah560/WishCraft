import SwiftUI
import AppKit // Required for NSWorkspace

struct WishlistItemView: View {
    let item: WishlistItem // item.link and item.notes are non-optional String here
    var onEdit: () -> Void
    var onDelete: () -> Void

    @EnvironmentObject var uiSettings: UISettings
    @State private var showingNotes = false
    @State private var showingDeleteItemAlert = false

    // Helper to prepare link (ensure scheme)
    private func prepareLinkForOpening(_ link: String) -> String {
        var urlString = link.trimmingCharacters(in: .whitespacesAndNewlines)
        if urlString.isEmpty { return "" }
        
        if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
            if urlString.contains(".") && !urlString.contains(" ") {
                urlString = "https://" + urlString
            }
        }
        return urlString
    }

    // Helper to extract a displayable marketplace name or hostname
    private func extractMarketplaceName(from link: String) -> String? {
        guard !link.isEmpty else { return nil } // Check for empty link early
        let preparedLink = prepareLinkForOpening(link)
        guard let url = URL(string: preparedLink), var host = url.host else {
            return nil
        }

        if host.lowercased().hasPrefix("www.") { host = String(host.dropFirst(4)) }
        if host.lowercased().hasPrefix("m.") { host = String(host.dropFirst(2)) }
        if host.lowercased().hasPrefix("shop.") { host = String(host.dropFirst(5)) }

        if host.contains("amazon.") { return "Amazon" }
        if host.contains("etsy.com") { return "Etsy" }
        if host.contains("ebay.") { return "eBay" }
        if host.contains("walmart.com") { return "Walmart" }
        if host.contains("target.com") { return "Target" }
        // Add more specific domains as needed
        
        let components = host.split(separator: ".")
        if let firstComponent = components.first, firstComponent.count > 1 && components.count > 1 {
            if (firstComponent.lowercased() == "store" || firstComponent.lowercased() == "shop") && components.count > 1 {
                return String(components[1]).capitalized
            }
            return String(firstComponent).capitalized
        }
        return host.isEmpty ? nil : host // Return nil if host somehow became empty
    }

    private func openLink() {
        guard !item.link.isEmpty else { return } // Check if link string is empty
        let urlString = prepareLinkForOpening(item.link)
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        } else {
            print("Could not create URL from: \(urlString)")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: uiSettings.spacing(10)) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: uiSettings.spacing(4)) {
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    // Display Marketplace Name if link is not empty and name can be extracted
                    if !item.link.isEmpty, let marketplaceName = extractMarketplaceName(from: item.link) {
                        Text(marketplaceName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                HStack(spacing: uiSettings.spacing(10)) {
                    // "Visit" button if link is not empty
                    if !item.link.isEmpty {
                        Button(action: openLink) {
                            Label("Visit", systemImage: "arrow.up.right.square")
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.accentColor)
                        .help("Open link: \(item.link)")
                    }
                    
                    // Notes Toggle Button - check if non-optional notes string is empty
                    if !item.notes.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingNotes.toggle()
                            }
                        } label: {
                            Image(systemName: showingNotes ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .help(showingNotes ? "Hide Notes" : "Show Notes")
                    }
                    
                    Button { onEdit() } label: { Image(systemName: "pencil.circle") }
                        .buttonStyle(.borderless)
                        .help("Edit Item")
                    
                    Button { showingDeleteItemAlert = true } label: { Image(systemName: "trash.circle") }
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                        .help("Delete Item")
                }
                .imageScale(uiSettings.imageScale)
                .font(.body)
            }

            // Conditional Notes Display (Animated)
            // Corrected: No optional binding for item.notes as it's String
            if showingNotes && !item.notes.isEmpty {
                Text(item.notes) // Use item.notes directly
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, uiSettings.padding(4))
                    .lineLimit(5)
                    .transition(.opacity.combined(with: .slide))
            }
            
            Text("Added: \(item.dateAdded, style: .date)")
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.top, uiSettings.padding(5))
        }
        .padding(uiSettings.padding(12))
        .background(Material.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: uiSettings.cornerRadius(12)))
        .shadow(color: Color.black.opacity(0.1), radius: uiSettings.cornerRadius(4), x: 0, y: 2 * uiSettings.layoutScaleFactor)
        .padding(.horizontal, uiSettings.padding(16))
        .padding(.vertical, uiSettings.padding(6))
        .alert("Delete Item?", isPresented: $showingDeleteItemAlert) {
            Button("Delete \"\(item.name)\"", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to permanently delete this item?")
        }
    }
}
