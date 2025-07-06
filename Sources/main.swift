import AppKit

// MARK: - Entry Point
@main
struct HoldItMain {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        let delegate = AppDelegate()
        app.delegate = delegate

        app.run()
    }
}
