import SwiftUI

enum AppUISize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    var id: String { self.rawValue }
}

struct WishlistItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String = "New Item"
    var link: String = ""
    var notes: String = ""
    var dateAdded: Date = Date()
}

struct Wishlist: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String = "New Wishlist"
    var items: [WishlistItem] = []
    var coverImageData: Data? = nil
    var coverImageOffsetX: CGFloat = 0.0
    var coverImageOffsetY: CGFloat = 0.0
    // var coverImageZoom: CGFloat = 1.0 // << REMOVED

    var coverImageOffset: CGSize {
        get { CGSize(width: coverImageOffsetX, height: coverImageOffsetY) }
        set {
            coverImageOffsetX = newValue.width
            coverImageOffsetY = newValue.height
        }
    }
    var dateCreated: Date = Date()
}
