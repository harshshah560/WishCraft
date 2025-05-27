import SwiftUI
import Swifter

class WishlistManager: ObservableObject {
    @Published var wishlists: [Wishlist] = []
    @Published var selectedWishlistId: Wishlist.ID?

    private var documentsUrl: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    private let wishlistsFilename = "wishlists.json"

    private var server = HttpServer()

    init() {
        loadWishlists()
        if wishlists.isEmpty {
            addWishlist(name: "My First Wishlist")
        } else if selectedWishlistId == nil && !wishlists.isEmpty {
            selectedWishlistId = wishlists.first?.id
        }
        startServer()
    }

    var selectedWishlist: Wishlist? {
        get {
            guard let selectedId = selectedWishlistId else { return nil }
            return wishlists.first(where: { $0.id == selectedId })
        }
        set {
            guard let newValue = newValue, let index = wishlists.firstIndex(where: { $0.id == newValue.id }) else {
                if newValue == nil { selectedWishlistId = nil }
                return
            }
            wishlists[index] = newValue
            if selectedWishlistId != newValue.id {
                selectedWishlistId = newValue.id
            }
            saveWishlists()
        }
    }

    var selectedWishlistBinding: Binding<Wishlist?> {
        Binding<Wishlist?>(
            get: { self.selectedWishlist },
            set: { newValue in
                if let newWishlist = newValue, let index = self.wishlists.firstIndex(where: { $0.id == newWishlist.id }) {
                    self.wishlists[index] = newWishlist
                    self.selectedWishlistId = newWishlist.id
                }
                self.saveWishlists()
            }
        )
    }

    func addWishlist(name: String = "New Wishlist") {
        let newWishlist = Wishlist(name: name)
        wishlists.append(newWishlist)
        selectedWishlistId = newWishlist.id
        saveWishlists()
    }

    func renameWishlist(wishlistId: Wishlist.ID, newName: String) {
        if let index = wishlists.firstIndex(where: { $0.id == wishlistId }) {
            wishlists[index].name = newName
            saveWishlists()
        }
    }

    func deleteWishlist(wishlistId: Wishlist.ID) {
        wishlists.removeAll { $0.id == wishlistId }
        if selectedWishlistId == wishlistId {
            selectedWishlistId = wishlists.first?.id
        }
        saveWishlists()
    }

    func addItem(to wishlistId: Wishlist.ID, item: WishlistItem) {
        if let index = wishlists.firstIndex(where: { $0.id == wishlistId }) {
            wishlists[index].items.append(item)
            saveWishlists()
        }
    }

    func updateItem(in wishlistId: Wishlist.ID, item: WishlistItem) {
        if let wishlistIndex = wishlists.firstIndex(where: { $0.id == wishlistId }),
           let itemIndex = wishlists[wishlistIndex].items.firstIndex(where: { $0.id == item.id }) {
            wishlists[wishlistIndex].items[itemIndex] = item
            saveWishlists()
        }
    }

    func updateWishlist(_ wishlist: Wishlist) {
        if let index = wishlists.firstIndex(where: { $0.id == wishlist.id }) {
            wishlists[index] = wishlist
            saveWishlists()
        }
    }

    func deleteItem(from wishlistId: Wishlist.ID, itemId: WishlistItem.ID) {
        if let wishlistIndex = wishlists.firstIndex(where: { $0.id == wishlistId }) {
            wishlists[wishlistIndex].items.removeAll { $0.id == itemId }
            saveWishlists()
        }
    }

    func saveWishlists() {
        guard let url = documentsUrl?.appendingPathComponent(wishlistsFilename) else { return }
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        do { try encoder.encode(wishlists).write(to: url, options: [.atomicWrite, .completeFileProtection]) }
        catch { print("Error saving wishlists: \(error.localizedDescription)") }
    }

    func loadWishlists() {
        guard let url = documentsUrl?.appendingPathComponent(wishlistsFilename) else { return }
        guard FileManager.default.fileExists(atPath: url.path) else { wishlists = []; return }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
            wishlists = try decoder.decode([Wishlist].self, from: data)
        } catch {
            print("Error loading wishlists: \(error.localizedDescription). Starting fresh.")
            wishlists = []
        }
    }

    // MARK: - Server

    private func startServer() {
        do {
            try server.start(6521, forceIPv4: true)
            print("✅ WishCraft server running at http://localhost:6521")
            setupServerRoutes()
        } catch {
            print("❌ Server failed to start: \(error.localizedDescription)")
        }
    }

    private func setupServerRoutes() {
        server["/getWishlists"] = { request in
            let result = self.wishlists.map { ["id": $0.id.uuidString, "name": $0.name] }
            let data = try! JSONSerialization.data(withJSONObject: result)
            
            return HttpResponse.raw(200, "OK", [
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            ]) { writer in
                try writer.write([UInt8](data))
            }
        }



        server["/addItem"] = { request in
            if request.method == "OPTIONS" {
                return HttpResponse.raw(200, "OK", [
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "POST, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type"
                ]) { writer in try writer.write([]) }
            }

            guard request.method == "POST" else {
                return HttpResponse.raw(405, "Method Not Allowed", [
                    "Content-Type": "text/plain",
                    "Access-Control-Allow-Origin": "*"
                ]) { writer in
                    try writer.write([UInt8]("Method Not Allowed".utf8))
                }
            }

            do {
                let decoder = JSONDecoder()

                struct AddItemRequest: Codable {
                    let wishlistId: UUID
                    let name: String
                    let link: String?
                    let notes: String?
                }

                let itemRequest = try decoder.decode(AddItemRequest.self, from: Data(request.body))

                let newItem = WishlistItem(
                    name: itemRequest.name,
                    link: itemRequest.link ?? "",
                    notes: itemRequest.notes ?? "",
                    dateAdded: Date()
                )

                DispatchQueue.main.async {
                    self.addItem(to: itemRequest.wishlistId, item: newItem)
                }

                return .corsOk(text: "Item added successfully")
            } catch {
                print("❌ Error decoding item: \(error)")
                return .corsBadRequest(reason: "Decoding error")
            }
        }
    }
}

// MARK: - CORS Helper

private extension HttpResponse {
    static func corsOk(text: String) -> HttpResponse {
        return .raw(200, "OK", [
            "Content-Type": "text/plain",
            "Access-Control-Allow-Origin": "*"
        ]) { writer in
            try writer.write([UInt8](text.utf8))
        }
    }

    static func corsBadRequest(reason: String) -> HttpResponse {
        return .raw(400, "Bad Request", [
            "Content-Type": "text/plain",
            "Access-Control-Allow-Origin": "*"
        ]) { writer in
            try writer.write([UInt8](reason.utf8))
        }
    }
}
