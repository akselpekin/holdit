import AppKit

final class MainWindowController: NSWindowController {

    init() {
        let windowSize = NSSize(width: 800, height: 600)
        let style: NSWindow.StyleMask = [.titled, .closable, .resizable, .miniaturizable]

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: style,
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "holdit"
        window.backgroundColor = .systemGreen

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}