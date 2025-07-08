import Foundation
import SwiftUI

public struct FileItem: Identifiable, Hashable {
    public let id = UUID()
    public let url: URL

    public var name: String { url.lastPathComponent }

    public var icon: Image {
        let nsImage = NSWorkspace.shared.icon(forFile: url.path)
        nsImage.size = NSSize(width: 64, height: 64)
        return Image(nsImage: nsImage)
    }

    public init(url: URL) {
        self.url = url
    }
}
