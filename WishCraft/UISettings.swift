import SwiftUI

// Ensure AppUISize enum is defined (e.g., in WishlistModels.swift)

class UISettings: ObservableObject {
    @AppStorage("appUISizePreference") var appSize: AppUISize = .medium {
        willSet {
            objectWillChange.send()
        }
    }

    // 1. For Text: Map AppUISize to ContentSizeCategory
    var contentSizeCategory: ContentSizeCategory {
        switch appSize {
        case .small: return .medium
        case .medium: return .large
        case .large: return .extraLarge
        }
    }

    // 2. For Non-Text elements (padding, spacing, simple geometry):
    var layoutScaleFactor: CGFloat {
        switch appSize {
        case .small: return 0.90
        case .medium: return 1.0
        case .large: return 1.10
        }
    }

    // Methods to get scaled layout values
    func padding(_ base: CGFloat = 16) -> CGFloat {
        return base * layoutScaleFactor
    }

    func spacing(_ base: CGFloat = 8) -> CGFloat {
        return base * layoutScaleFactor
    }
    
    var imageScale: Image.Scale {
        switch appSize {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }

    func cornerRadius(_ base: CGFloat = 8) -> CGFloat {
        return base * layoutScaleFactor
    }

    func edgeInsets(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) -> EdgeInsets {
        EdgeInsets(
            top: top * layoutScaleFactor,
            leading: leading * layoutScaleFactor,
            bottom: bottom * layoutScaleFactor,
            trailing: trailing * layoutScaleFactor
        )
    }
    
    func scaledFontSize(_ baseSize: CGFloat) -> CGFloat {
        return baseSize * layoutScaleFactor
    }
}
