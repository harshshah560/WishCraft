import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct ItemEditView: View {
    var itemToEdit: WishlistItem?
    let wishlistId: Wishlist.ID
    var onSave: (WishlistItem) -> Void

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var uiSettings: UISettings
    
    @State private var itemName: String = ""
    @State private var itemLink: String = ""
    @State private var itemNotes: String = ""
    @State private var isFetchingTitle: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: uiSettings.spacing(18)) {
                    // 1. Link Field + Paste Button
                    VStack(alignment: .leading, spacing: uiSettings.spacing(6)) {
                        Text("Link")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(spacing: uiSettings.spacing(8)) {
                            TextField("Paste or type link (e.g., https://website.com)", text: $itemLink)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)
                                .disableAutocorrection(true)
                                .textContentType(.URL)

                            Button(action: pasteLinkAndFetchTitle) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.body.weight(.medium))
                                    .imageScale(uiSettings.imageScale)
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.borderless)
                            .help("Paste Link")
                        }
                    }
                    Divider()

                    // 2. Name Field
                    VStack(alignment: .leading, spacing: uiSettings.spacing(6)) {
                        HStack {
                            Text("Name")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if isFetchingTitle {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 15, height: 15)
                                    .padding(.leading, 2)
                            }
                        }
                        TextField("Item name (required, or autofill from link)", text: $itemName)
                            .textFieldStyle(.roundedBorder)
                            .font(.body)
                            .disabled(isFetchingTitle)
                    }
                    Divider()

                    // 3. Notes Panel (Using TextEditor)
                    VStack(alignment: .leading, spacing: uiSettings.spacing(6)) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $itemNotes)
                                .font(.body)
                                .frame(minHeight: 70 * uiSettings.layoutScaleFactor,
                                       maxHeight: 120 * uiSettings.layoutScaleFactor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Color(NSColor.separatorColor), lineWidth: 0.5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            if itemNotes.isEmpty {
                                Text("Optional details...")
                                    .font(.body)
                                    .foregroundColor(Color(NSColor.placeholderTextColor))
                                    .padding(.leading, 5)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
                .padding(uiSettings.padding())
            }

            Spacer(minLength: uiSettings.spacing(10))
            Divider()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .font(.body)
                    .keyboardShortcut(.cancelAction)
                
                Button(itemToEdit == nil ? "Add Item" : "Save Changes") { saveItem() }
                    .buttonStyle(.borderedProminent)
                    .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isFetchingTitle)
                    .font(.body)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.top, uiSettings.padding(8))
            .padding(.bottom, uiSettings.padding(12))
            .padding(.horizontal, uiSettings.padding())
        }
        .frame(minWidth: 400 * uiSettings.layoutScaleFactor,
               idealWidth: 450 * uiSettings.layoutScaleFactor,
               maxWidth: 500 * uiSettings.layoutScaleFactor,
               minHeight: 340 * uiSettings.layoutScaleFactor,
               idealHeight: 380 * uiSettings.layoutScaleFactor,
               maxHeight: 450 * uiSettings.layoutScaleFactor)
        .onAppear {
            if let item = itemToEdit {
                itemName = item.name
                itemLink = item.link ?? ""
                itemNotes = item.notes ?? ""
            }
        }
    }

    private func pasteLinkAndFetchTitle() {
        print("[DEBUG] pasteLinkAndFetchTitle called.")
        var pastedString: String?
        #if os(macOS)
        pastedString = NSPasteboard.general.string(forType: .string)
        #else
        pastedString = UIPasteboard.general.string
        #endif

        print("[DEBUG] Pasted content from clipboard: \(pastedString ?? "nil or not a string")")

        if let link = pastedString?.trimmingCharacters(in: .whitespacesAndNewlines), !link.isEmpty {
            itemLink = link
            print("[DEBUG] itemLink set to: \(link)")
            attemptToFetchTitle(from: link)
        } else {
            print("[DEBUG] No valid link found on pasteboard or link is empty.")
        }
    }
    
    private func prepareURL(from string: String) -> URL? {
        var urlString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if urlString.isEmpty { return nil }
        
        if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
            if urlString.contains(".") && !urlString.contains(" ") {
                 urlString = "https://" + urlString
                 print("[DEBUG] Prepended https:// to link: \(urlString)")
            } else {
                print("[DEBUG] Link does not look like a web URL, not prepending scheme: \(urlString)")
            }
        }
        guard let url = URL(string: urlString) else {
            print("[DEBUG] Could not create URL from string: \(urlString)")
            return nil
        }
        return url
    }

    private func attemptToFetchTitle(from urlString: String) {
        print("[DEBUG] attemptToFetchTitle called with: \(urlString)")
        
        guard let url = prepareURL(from: urlString) else {
            print("[DEBUG] prepareURL returned nil. Aborting fetch.")
            return
        }
        
        guard let scheme = url.scheme, ["http", "https"].contains(scheme.lowercased()) else {
            print("[DEBUG] URL scheme ('\(String(describing: url.scheme))') is not http or https. Aborting fetch.")
            return
        }

        DispatchQueue.main.async {
            self.isFetchingTitle = true
            if self.itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.itemName = "Fetching title..."
                print("[DEBUG] itemName set to 'Fetching title...'")
            }
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            defer {
                DispatchQueue.main.async {
                    print("[DEBUG] Fetching finished. isFetchingTitle set to false.")
                    self.isFetchingTitle = false
                    if self.itemName == "Fetching title..." { // Clear if still fetching and no title was set
                        self.itemName = ""
                        print("[DEBUG] No title found or error, itemName cleared.")
                    }
                }
            }

            if let error = error {
                print("[DEBUG] Network error fetching URL content: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[DEBUG] Response is not HTTPURLResponse: \(String(describing: response))")
                return
            }
            
            print("[DEBUG] HTTP Status Code: \(httpResponse.statusCode)")
            if !(200...299).contains(httpResponse.statusCode) {
                print("[DEBUG] HTTP Error: Status code \(httpResponse.statusCode)")
                return
            }
            
            guard let data = data else {
                print("[DEBUG] No data received.")
                return
            }
            
            print("[DEBUG] Received \(data.count) bytes. MimeType: \(httpResponse.mimeType ?? "N/A"). Suggested encoding: \(httpResponse.textEncodingName ?? "N/A")")

            let htmlString: String?

            // Helper for fallback encodings
            func decodeWithFallbacks(data: Data) -> String? {
                if let utf8String = String(data: data, encoding: .utf8) {
                    print("[DEBUG] Decoded using fallback UTF-8.")
                    return utf8String
                } else if let isoLatin1String = String(data: data, encoding: .isoLatin1) {
                    print("[DEBUG] Decoded using fallback ISO Latin 1.")
                    return isoLatin1String
                } else if let asciiString = String(data: data, encoding: .ascii) {
                    print("[DEBUG] Decoded using fallback ASCII.")
                    return asciiString
                } else if let winString = String(data: data, encoding: .windowsCP1252) {
                    print("[DEBUG] Decoded using fallback WindowsCP1252.")
                    return winString
                } else {
                    print("[DEBUG] Could not decode HTML string with common fallback encodings.")
                    return nil
                }
            }
            
            // This is the corrected section for encoding
            if let encodingNameFromHeader = httpResponse.textEncodingName {
                let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingNameFromHeader as CFString)
                // Check if the CFEncoding is valid before trying to use it
                if cfEncoding != kCFStringEncodingInvalidId {
                    let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
                    let swiftEncoding = String.Encoding(rawValue: nsEncoding)
                    if let decodedString = String(data: data, encoding: swiftEncoding) {
                        htmlString = decodedString
                        print("[DEBUG] Decoded using explicit encoding from header: \(encodingNameFromHeader)")
                    } else {
                        print("[DEBUG] Failed to decode with explicit encoding '\(encodingNameFromHeader)', trying fallbacks.")
                        htmlString = decodeWithFallbacks(data: data)
                    }
                } else {
                    print("[DEBUG] Explicit encoding name '\(encodingNameFromHeader)' from header was invalid/unknown. Trying fallbacks.")
                    htmlString = decodeWithFallbacks(data: data)
                }
            } else {
                print("[DEBUG] No explicit encoding name in HTTP header. Trying fallbacks.")
                htmlString = decodeWithFallbacks(data: data)
            }

            guard let finalHtmlString = htmlString else {
                print("[DEBUG] Failed to convert data to HTML string with any attempted encoding.")
                return
            }
            
            let regexPattern = "<title[^>]*>(.*?)</title[^>]*>"
            do {
                let regex = try NSRegularExpression(pattern: regexPattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
                if let match = regex.firstMatch(in: finalHtmlString, options: [], range: NSRange(location: 0, length: finalHtmlString.utf16.count)) {
                    if let titleRange = Range(match.range(at: 1), in: finalHtmlString) {
                        var title = String(finalHtmlString[titleRange])
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        title = title.replacingOccurrences(of: "&amp;", with: "&", options: .literal)
                        title = title.replacingOccurrences(of: "&lt;", with: "<", options: .literal)
                        title = title.replacingOccurrences(of: "&gt;", with: ">", options: .literal)
                        title = title.replacingOccurrences(of: "&quot;", with: "\"", options: .literal)
                        title = title.replacingOccurrences(of: "&#39;", with: "'", options: .literal)
                        title = title.replacingOccurrences(of: "&nbsp;", with: " ", options: .literal)
                        
                        let tagRemovalRegex = try NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive)
                        title = tagRemovalRegex.stringByReplacingMatches(in: title, options: [], range: NSRange(location: 0, length: title.utf16.count), withTemplate: "")
                        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        print("[DEBUG] Extracted title: '\(title)'")

                        if !title.isEmpty {
                            DispatchQueue.main.async {
                                if self.itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || self.itemName == "Fetching title..." {
                                    self.itemName = title
                                    print("[DEBUG] Autofilled name in UI: \(title)")
                                } else {
                                    print("[DEBUG] Name field ('\(self.itemName)') already has user content. Fetched title ('\(title)') not applied automatically.")
                                }
                            }
                        } else {
                            print("[DEBUG] Extracted title was empty.")
                        }
                        return
                    }
                }
                print("[DEBUG] No title tag match found in HTML via regex.")
            } catch {
                print("[DEBUG] Regex error processing title: \(error.localizedDescription)")
            }
        }.resume()
    }

    private func saveItem() {
            let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty && trimmedName != "Fetching title..." else {
                print("Item name cannot be empty or is currently being fetched.")
                return
            }

            let trimmedLink = itemLink.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedNotes = itemNotes.trimmingCharacters(in: .whitespacesAndNewlines)

            let newItem = WishlistItem(
                id: itemToEdit?.id ?? UUID(),
                name: trimmedName,
                link: trimmedLink,  // Pass the (possibly empty) trimmed string
                notes: trimmedNotes, // Pass the (possibly empty) trimmed string
                dateAdded: itemToEdit?.dateAdded ?? Date()
            )
            onSave(newItem)
            dismiss()
        }
}

