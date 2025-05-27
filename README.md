# **WishCraft**

**WishCraft** is a beautifully designed macOS wishlist manager with a seamless Chrome extension for clipping products from the web. Built to help you remember what you want, stay organized, and track your dream purchases — both locally and while browsing.

---

## 📌 Purpose

**WishCraft was created to:**

* Serve as a lightweight, elegant macOS app for managing multiple categorized wishlists
* Let users clip product links while browsing (like Zotero or Pinterest, but offline)
* Stay local-first and private — no cloud accounts or online syncing required
* Seamlessly bridge web + desktop with deep URL scheme integration

---

## 🖥 App Functionality

### ✅ Core Features

* **Multiple Wishlists**: Create, rename, and delete wishlists for categories like tech, clothes, gifts, etc.
* **Wishlist Items**:

  * Each item has a **name**, **link**, **notes**, and **date added**
  * Items are stored persistently using JSON in the app's document directory
* **Dark Mode + UI Scaling**: Supports light/dark themes and adjustable UI size
* **Cover Photo Support**: Set a banner image for each wishlist
* **Sorting & Editing**: Sort items by date and edit them inline

### 💾 Local Storage

WishCraft stores all data locally on disk and preferences using `@AppStorage`. No syncing. No cloud. 100% private.

### 🌐 Local Web Server (for Extension)

WishCraft launches a tiny local HTTP server using [Swifter](https://github.com/httpswift/swifter) when the app is open. It exposes:

* `GET /getWishlists` — returns JSON of all wishlists
* `POST /addItem` — accepts new wishlist items via JSON payload

This allows the Chrome extension to interface directly with the app.

### 🔗 Custom URL Scheme Support

* Registers `wishcraft://` protocol
* Chrome extension uses `wishcraft://launch` to open the app if closed
* App listens via `NSAppleEventManager` and brings itself to the foreground

---

## 🧩 Chrome Extension: WishCraft Clipper

### 📂 Folder: `WishCraftClipper`

This Chrome extension allows saving products from any webpage directly into a selected wishlist.

### 🧠 How It Works

* On launch:

  * Pre-fills product **name** from the current tab title
  * Lets user input **optional notes**
  * Loads local wishlists via `GET http://localhost:8080/getWishlists`
  * Dropdown lets you select one
  * `POST` is sent to `http://localhost:8080/addItem`
* If the app isn’t open, `wishcraft://launch` is opened to launch the app

### 🛠 How to Install

1. Go to `chrome://extensions`
2. Enable **Developer Mode**
3. Click **Load Unpacked**
4. Select the `WishCraftClipper` folder
5. Click the extension icon on any shopping/product page to save it!

### 🧪 Requirements

* WishCraft app must be running
* Chrome must have permissions for `localhost`:

```json
"host_permissions": [
  "http://localhost:8080/*"
]
```

* Custom URL protocol `wishcraft://` must be accepted by macOS once

---

## 🛠 Developer Setup

```bash
git clone https://github.com/harshshah560/WishCraft.git
cd WishCraft
open WishCraft.xcodeproj
```

* Build + run the macOS app via Xcode
* Open `WishCraftClipper/` in any code editor to modify the Chrome extension

---

## ✅ Roadmap

* [x] Add Chrome extension support
* [x] Launch app from extension if closed
* [x] Cover photos and UI scaling
* [ ] Drag-and-drop support
* [ ] Price tracking or auto-preview
* [ ] Optional iOS companion

---

## 📝 License

MIT License — Free to use, modify, or fork.

---

## 🙌 Credits

Built by [@harshshah560](https://github.com/harshshah560) using:

* SwiftUI
* Swifter
* Chrome Extension APIs

For bug reports or feature requests, open an [Issue](https://github.com/harshshah560/WishCraft/issues).

---

**Made with ❤️ and frustration while fighting macOS URL handlers.**
