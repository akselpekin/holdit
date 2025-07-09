import AppKit

public class TriggerHandler {

    @MainActor
    public static func installHoverTracking(on view: NSView, areaRef: inout NSTrackingArea?) {
        if let old = areaRef { view.removeTrackingArea(old) }
        let area = NSTrackingArea(rect: .zero,
                                  options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
                                  owner: view,
                                  userInfo: nil)
        view.addTrackingArea(area)
        areaRef = area
    }


    @MainActor
    public static func removeHoverTracking(from view: NSView, areaRef: inout NSTrackingArea?) {
        if let old = areaRef {
            view.removeTrackingArea(old)
            areaRef = nil
        }
    }

   
    @MainActor
    public static func handleMouseEntered(_ callback: @escaping () -> Void) {
        callback()
    }

    
    @MainActor
    @discardableResult
    public static func handleDraggingEntered(_ callback: @escaping () -> Void) -> NSDragOperation {
        callback()
        return .copy
    }

 
    @MainActor
    @discardableResult
    public static func handleDraggingUpdated(_ callback: @escaping () -> Void) -> NSDragOperation {
        callback()
        return .copy
    }
}
