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

    private var triggerRect: NSRect!
    private let triggerPadding: CGFloat = 65
    private var isExpanded = false
    private var globalMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("AppDelegate: applicationDidFinishLaunching called")
        NSApp.setActivationPolicy(.accessory)
        print("App is set to accessory mode")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.grid.2x2.fill", accessibilityDescription: "HoldIt")
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Tray [DEBUG]", action: #selector(showTray), keyEquivalent: ""))
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

        let triggerX = collapsed.origin.x - triggerPadding
        let triggerWidth = collapsed.width + triggerPadding * 2
        let triggerY = collapsed.origin.y
        triggerRect = NSRect(x: triggerX, y: triggerY, width: triggerWidth, height: screen.frame.height)

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
        // Install a global mouse-moved monitor to detect hover near notch
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            self?.handleGlobalMouseMoved()
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
        isExpanded = true
    }
    @objc private func quit() {
        print("AppDelegate: quit invoked")
        NSApp.terminate(nil)
    }

    private func handleGlobalMouseMoved() {
        let mousePoint = NSEvent.mouseLocation
        
        if triggerRect.contains(mousePoint) && !isExpanded {
            print("GlobalMonitor: cursor entered notch region")
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.2
                trayWindow.animator().setFrame(expandedRect, display: true)
            })
            isExpanded = true
        }

        else if !triggerRect.contains(mousePoint) && isExpanded {
            print("GlobalMonitor: cursor exited notch region")
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.2
                trayWindow.animator().setFrame(collapsedRect, display: true)
            })
            isExpanded = false
        }
    }
}
