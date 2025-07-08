import Foundation
import Combine

public class TrayModel: ObservableObject {
    @Published public private(set) var items: [FileItem]

    public init(initialItems: [FileItem] = []) {
        self.items = initialItems
    }

    public func add(_ item: FileItem) {
        items.append(item)
    }

    public func clear() {
        items.removeAll()
    }
}
