import SwiftUI
import GUI
import AppKit

@main
struct HoldItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var trayWindow: NSPanel!
    var statusItem: NSStatusItem!
    private var collapsedRect: NSRect!
    private var expandedRect: NSRect!

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("AppDelegate: applicationDidFinishLaunching called")
        NSApp.setActivationPolicy(.accessory)
        print("App is set to accessory mode")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.grid.2x2.fill", accessibilityDescription: "HoldIt")
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Tray", action: #selector(showTray), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit HoldIt", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        guard let screen = NSScreen.main else { return }
        let notchHeight = screen.safeAreaInsets.top
        let notchWidth = notchHeight * 2
        let expandedWidth = notchWidth * 8

        let collapsedX = (screen.frame.width - notchWidth) / 2
        let expandedX = (screen.frame.width - expandedWidth) / 2
        let y = screen.frame.height - notchHeight
        let collapsed = NSRect(x: collapsedX, y: y, width: notchWidth, height: notchHeight)
        let expanded = NSRect(x: expandedX, y: y, width: expandedWidth, height: notchHeight)
        collapsedRect = collapsed
        expandedRect = expanded

        trayWindow = NSPanel(
            contentRect: collapsed,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        trayWindow.isFloatingPanel = true
        trayWindow.becomesKeyOnlyIfNeeded = true
        trayWindow.isOpaque = false
        trayWindow.backgroundColor = .clear
        trayWindow.acceptsMouseMovedEvents = true
        trayWindow.level = .statusBar
        trayWindow.hasShadow = false
        trayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hosting = NSHostingController(rootView: Tray())
        trayWindow.contentViewController = hosting
        trayWindow.makeKeyAndOrderFront(nil)
        if let contentView = trayWindow.contentView {
            contentView.trackingAreas.forEach { contentView.removeTrackingArea($0) }
            let area = NSTrackingArea(
                rect: contentView.bounds,
                options: [.mouseEnteredAndExited, .mouseMoved, .activeInActiveApp, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            contentView.addTrackingArea(area)
        }
    }

    @objc private func showTray() {
        print("AppDelegate: showTray invoked, collapsedRect=\(collapsedRect!), expandedRect=\(expandedRect!), currentFrame=\(trayWindow.frame)")
        trayWindow.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            print("Animating to expandedRect=\(expandedRect!)")
            trayWindow.animator().setFrame(expandedRect, display: true)
        } completionHandler: {
            print("Animation complete, newFrame=\(self.trayWindow.frame)")
            // Automatically collapse (hide) the tray after 5 seconds DEBUG
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.2
                    self.trayWindow.animator().setFrame(self.collapsedRect, display: true)
                }
            }
        }
    }
    @objc private func quit() {
        print("AppDelegate: quit invoked")
        NSApp.terminate(nil)
    }
    @objc func mouseEntered(with event: NSEvent) {
        print("AppDelegate: mouseEntered window")
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            trayWindow.animator().setFrame(expandedRect, display: true)
        }
    }
    @objc func mouseExited(with event: NSEvent) {
        print("AppDelegate: mouseExited window")
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            trayWindow.animator().setFrame(collapsedRect, display: true)
        }
    }
}
