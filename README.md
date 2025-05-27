WishCraft

WishCraft is a beautifully designed macOS wishlist manager with a seamless Chrome extension for clipping products from the web. Built to help you remember what you want, stay organized, and track your dream purchases — both locally and while browsing.

📌 Purpose

WishCraft was created to:

Serve as a lightweight, elegant macOS app for managing multiple categorized wishlists

Let users clip product links while browsing (like Zotero or Pinterest, but offline)

Stay local-first and private — no cloud accounts or online syncing required

Seamlessly bridge web + desktop with deep URL scheme integration

🖥 App Functionality

✅ Core Features

Multiple Wishlists: Create, rename, and delete wishlists for categories like tech, clothes, gifts, etc.

Wishlist Items:

Each item has a name, link, notes, and date added

Items are stored persistently using JSON inside the app's local document directory

Dark Mode + UI Scaling: Supports dark/light themes and adjustable UI size for accessibility

Cover Photo: Set a banner image for each wishlist

Sorting & Editing: Sort items by date and edit item info inline

💾 Local Storage

WishCraft uses SwiftUI's local document directory and @AppStorage for preferences. No data ever leaves your machine.

🌐 Local Web Server (for Extension)

The app starts a tiny local HTTP server on localhost:8080 using Swifter. It exposes two routes:

GET /getWishlists — returns a JSON list of your wishlists

POST /addItem — accepts a JSON payload to add an item to a wishlist

The server only runs when the app is open.

🔗 Custom URL Scheme Support

WishCraft registers the wishcraft:// URL scheme

The Chrome extension uses wishcraft://launch to launch the app if it isn’t already running

The app uses NSAppleEventManager to handle incoming URLs and bring itself to the foreground

🧩 Chrome Extension: WishCraft Clipper

📂 Folder: WishCraftClipper

This Chrome extension lets you save products from any site to any of your wishlists.

🧠 How It Works

When you click the extension:

It pre-fills the product name using the current tab title

Lets you write optional notes

Loads your local wishlists using GET http://localhost:8080/getWishlists

Lets you select one from a dropdown

When you click Save, it sends a POST to http://localhost:8080/addItem

If the WishCraft app isn't open, it sends a wishcraft://launch URL to auto-launch it

🛠 How to Install the Extension

Go to chrome://extensions

Turn on Developer Mode (top right)

Click Load Unpacked

Select the WishCraftClipper folder

You're done! Click the extension icon when browsing to save a product

🧪 Requirements

The WishCraft app must be open

macOS must allow the custom wishcraft:// scheme to launch the app

The extension must have localhost access in manifest.json:

"host_permissions": [
  "http://localhost:8080/*"
]

🛠 Developer Setup

Clone this repo

Open WishCraft.xcodeproj in Xcode

Build and run the app (macOS target)

The extension can be edited separately inside WishCraftClipper

✅ Roadmap



📝 License

MIT License — free to use, modify, or build upon.

🙌 Credits

Built by @harshshah560 with SwiftUI, Swifter, and a lot of debugging to make Chrome and macOS play nicely.

For any issues or feature requests, feel free to open an Issue.

