//
//  AppDelegate.swift
//  WishCraft
//
//  Created by Harsh Shah on 5/27/25.
//


import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    static var launchedFromExtension = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent _: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else { return }

        if url.scheme == "wishcraft" {
            print("🟢 Received custom URL: \(url)")
            Self.launchedFromExtension = true
        }
    }
}
