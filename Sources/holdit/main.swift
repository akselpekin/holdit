import SwiftUI
import GUI
import LOGIC
import AppKit

// MARK: - TriggerView
// handles hover and file drag enter/exit
class TriggerView: NSView {
    weak var hoverDelegate: AppDelegate?
    private var hoverTrackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
            layer?.backgroundColor = NSColor.black.withAlphaComponent(0.001).cgColor

        registerForDraggedTypes([.fileURL])
        installHoverTracking()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:)") }

    func installHoverTracking() {
        TriggerHandler.installHoverTracking(on: self, areaRef: &hoverTrackingArea)
    }

    func removeHoverTracking() {
        TriggerHandler.removeHoverTracking(from: self, areaRef: &hoverTrackingArea)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        installHoverTracking()
    }

    override func mouseEntered(with event: NSEvent) {
       
        if let delegate = hoverDelegate, !delegate.isTrayEmpty {
            delegate.expandTray()
        }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return TriggerHandler.handleDraggingEntered { [weak self] in self?.hoverDelegate?.expandTray() }
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return TriggerHandler.handleDraggingUpdated { [weak self] in self?.hoverDelegate?.expandTray() }
    }
}

// MARK: - TriggerPanel
// NSPanel that hosts TriggerView
class TriggerPanel: NSPanel {
    weak var hoverDelegate: AppDelegate?

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backing, defer: flag)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:)") }
}

// MARK: - TrayPanel
// NSPanel subclass that tracks mouse exit on expanded tray
class TrayPanel: NSPanel {
    weak var trayDelegate: AppDelegate?
    private var trackingArea: NSTrackingArea?

    func installTrackingArea() {
        TrayHandler.installCollapseTracking(on: self, areaRef: &trackingArea)
    }

    func removeTrackingArea() {
        TrayHandler.removeCollapseTracking(from: self, areaRef: &trackingArea)
    }

    override func mouseExited(with event: NSEvent) {
        TrayHandler.handleMouseExited { [weak self] in self?.trayDelegate?.collapseTray() }
    }
}

// MARK: - App Entry
@main
struct HoldItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { }
    }
}

// MARK: - AppDelegate
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let trayModel = TrayModel()
  
    var isTrayEmpty: Bool {
        trayModel.items.isEmpty
    }

    private let triggerPadding: CGFloat = 60  // horizontal padding around notch
    private let triggerVerticalPadding: CGFloat = 1 // vertical padding around notch
    
    var triggerPanel: TriggerPanel!
    var trayWindow: TrayPanel!
    var statusItem: NSStatusItem!
    private var collapsedRect: NSRect!
    private var expandedRect: NSRect!
    private var isExpanded = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched")
        NSApp.setActivationPolicy(.accessory)
        print("Accessory mode set")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "rectangle.and.paperclip", accessibilityDescription: nil)
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Clear Tray", action: #selector(clearTray), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu

        guard let screen = NSScreen.main else { return }
        let notchHeight = screen.safeAreaInsets.top
        let notchWidth = notchHeight * 2
        let expandedWidth = notchWidth * 7

        let collapsedX = (screen.frame.width - notchWidth) / 2
        let expandedX = (screen.frame.width - expandedWidth) / 2
        let y = screen.frame.height - notchHeight
        let collapsed = NSRect(x: collapsedX, y: y, width: notchWidth, height: notchHeight)
    
        let expandedHeight = notchHeight + 200
        let expandedY = screen.frame.height - expandedHeight
        let expanded = NSRect(x: expandedX, y: expandedY, width: expandedWidth, height: expandedHeight)
        collapsedRect = collapsed
        expandedRect = expanded

        let triggerX = collapsed.origin.x - triggerPadding
        let triggerWidth = collapsed.width + triggerPadding * 2

        let triggerY = collapsed.origin.y - triggerVerticalPadding
        let triggerHeight = collapsed.height + triggerVerticalPadding * 2
        let triggerRect = NSRect(x: triggerX, y: triggerY, width: triggerWidth, height: triggerHeight)
      
        triggerPanel = TriggerPanel(
             contentRect: triggerRect,
             styleMask: [.borderless, .nonactivatingPanel],
             backing: .buffered,
             defer: false
         )
   
        triggerPanel.hoverDelegate = self
        let tv = TriggerView(frame: NSRect(origin: .zero, size: triggerRect.size))
        tv.hoverDelegate = self
        tv.autoresizingMask = [.width, .height]
        triggerPanel.contentView = tv

        triggerPanel.isFloatingPanel = true
        triggerPanel.becomesKeyOnlyIfNeeded = true
        triggerPanel.isOpaque = false
        triggerPanel.backgroundColor = .clear
        triggerPanel.acceptsMouseMovedEvents = true
        triggerPanel.level = .statusBar
        triggerPanel.hasShadow = false
        triggerPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    
        triggerPanel.makeKeyAndOrderFront(nil)

    
        trayWindow = TrayPanel(
            contentRect: collapsed,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        (trayWindow as TrayPanel).trayDelegate = self
        trayWindow.isFloatingPanel = true
        trayWindow.becomesKeyOnlyIfNeeded = true
        trayWindow.isOpaque = false
        trayWindow.backgroundColor = .clear
        trayWindow.acceptsMouseMovedEvents = true
        trayWindow.level = .statusBar
        trayWindow.hasShadow = false
        trayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hosting = NSHostingController(rootView: Tray(model: trayModel, topPadding: notchHeight))
        trayWindow.contentViewController = hosting
        trayWindow.makeKeyAndOrderFront(nil)
       
        triggerPanel.makeKeyAndOrderFront(nil)

   
    }

    @objc private func quit() {
        print("AppDelegate: quit invoked")
        NSApp.terminate(nil)
    }
    
    @objc private func clearTray() {
        print("AppDelegate: clearTray invoked")
        trayModel.clear()
    }

    func expandTray() {
         guard !isExpanded else { return }
    
        trayModel.sanityCheck()
         isExpanded = true
         
         if let tv = triggerPanel.contentView as? TriggerView { tv.removeHoverTracking() }
         triggerPanel.orderOut(nil)
         
         trayWindow.makeKeyAndOrderFront(nil)
         NSAnimationContext.runAnimationGroup({ ctx in
             ctx.duration = 0.2
             trayWindow.animator().setFrame(expandedRect, display: true)
         }, completionHandler: {
             self.trayWindow.installTrackingArea()
             self.trayWindow.makeKeyAndOrderFront(nil)
             // Cursor sanity check
             let mouseLoc = NSEvent.mouseLocation
             if !self.expandedRect.contains(mouseLoc) {
                 self.collapseTray()
             }
         })
     }

     func collapseTray() {
         guard isExpanded else { return }
         isExpanded = false
        
         self.trayWindow.removeTrackingArea()
         NSAnimationContext.runAnimationGroup({ ctx in
             ctx.duration = 0.2
             trayWindow.animator().setFrame(collapsedRect, display: true)
         }, completionHandler: {
             if let tv = self.triggerPanel.contentView as? TriggerView { tv.installHoverTracking() }
             self.triggerPanel.makeKeyAndOrderFront(nil)
         })
     }
}
