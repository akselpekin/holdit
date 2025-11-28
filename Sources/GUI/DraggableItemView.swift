import SwiftUI
import AppKit

struct DraggableItemView<Content: View>: View {
    let fileURL: URL
    let onTap: () -> Void
    let onDragEnded: (NSDragOperation) -> Void
    let content: () -> Content

    var body: some View {
        DraggableItemWrapper(fileURL: fileURL, onTap: onTap, onDragEnded: onDragEnded, content: content)
    }
}

fileprivate struct DraggableItemWrapper<Content: View>: NSViewRepresentable {
    let fileURL: URL
    let onTap: () -> Void
    let onDragEnded: (NSDragOperation) -> Void
    let content: () -> Content

    func makeNSView(context: Context) -> DraggableNSView {
        let view = DraggableNSView()
        view.fileURL = fileURL
        view.onTap = onTap
        view.onDragEnded = onDragEnded
        
        let hostingView = NSHostingView(rootView: content())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }

    func updateNSView(_ nsView: DraggableNSView, context: Context) {
        nsView.fileURL = fileURL
        nsView.onTap = onTap
        nsView.onDragEnded = onDragEnded
        if let hostingView = nsView.subviews.first as? NSHostingView<Content> {
            hostingView.rootView = content()
        }
    }
}

fileprivate class DraggableNSView: NSView, NSDraggingSource {
    var fileURL: URL?
    var onTap: (() -> Void)?
    var onDragEnded: ((NSDragOperation) -> Void)?
    
    private var downEvent: NSEvent?

    // Capture all mouse events
    override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        return hit != nil ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        self.downEvent = event
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let downEvent = downEvent else { return }
        let location = event.locationInWindow
        let downLocation = downEvent.locationInWindow
        
        // Threshold to distinguish
        if abs(location.x - downLocation.x) > 3 || abs(location.y - downLocation.y) > 3 {
            self.downEvent = nil
            startDrag(with: event)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if downEvent != nil {
            onTap?()
            downEvent = nil
        }
    }
    
    // Forward right clicks to the hosting view
    override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
    }

    private func startDrag(with event: NSEvent) {
        guard let fileURL = fileURL else { return }
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(fileURL.absoluteString, forType: .fileURL)
        
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        let image = self.imageRepresentation()
        draggingItem.setDraggingFrame(self.bounds, contents: image)

        let session = beginDraggingSession(with: [draggingItem], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    // MARK: - NSDraggingSource
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return [.move, .copy]
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        DispatchQueue.main.async {
            self.onDragEnded?(operation)
        }
    }
}

extension NSView {
    func imageRepresentation() -> NSImage {
        let rep = self.bitmapImageRepForCachingDisplay(in: bounds)!
        cacheDisplay(in: bounds, to: rep)
        let img = NSImage(size: bounds.size)
        img.addRepresentation(rep)
        return img
    }
}
