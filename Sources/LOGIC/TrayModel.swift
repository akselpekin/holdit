import Foundation
import Combine

public class TrayModel: ObservableObject {
    @Published public private(set) var items: [FileItem]

    public init(initialItems: [FileItem] = []) {
        self.items = initialItems
    }

    public func add(_ item: FileItem) -> Bool {
        let newPath = item.url.path
        guard !items.contains(where: { $0.url.path == newPath }) else { return false }
        items.append(item)
        return true
    }

    public func clear() {
        items.removeAll()
    }

    public func remove(_ item: FileItem) {
        items.removeAll { $0.id == item.id }
    }
}
