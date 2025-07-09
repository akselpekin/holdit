import AppKit

@MainActor
public class TrayHandler {

    public static func installCollapseTracking(on panel: NSPanel, areaRef: inout NSTrackingArea?) {
        guard let view = panel.contentView else { return }
        if let old = areaRef { view.removeTrackingArea(old) }
        let area = NSTrackingArea(rect: view.bounds,
                                  options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                  owner: panel,
                                  userInfo: nil)
        view.addTrackingArea(area)
        areaRef = area
    }
    

    public static func removeCollapseTracking(from panel: NSPanel, areaRef: inout NSTrackingArea?) {
        guard let view = panel.contentView, let old = areaRef else { return }
        view.removeTrackingArea(old)
        areaRef = nil
    }
    
    
    public static func handleMouseExited(_ callback: @escaping () -> Void) {
        callback()
    }
}
