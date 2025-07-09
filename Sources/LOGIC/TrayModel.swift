import Foundation
import Combine

@MainActor
public class TrayModel: ObservableObject {
    @Published public private(set) var items: [FileItem]

    private var pathSet = Set<String>()

    public init(initialItems: [FileItem] = []) {
        self.items = initialItems
        pathSet = Set(initialItems.map { $0.url.path })
    }

    public func add(_ item: FileItem) -> Bool {
        let newPath = item.url.path
        guard !pathSet.contains(newPath) else { return false }
        items.append(item)
        pathSet.insert(newPath)
        return true
    }

    public func clear() {
        items.removeAll()
        pathSet.removeAll()
    }

    public func remove(_ item: FileItem) {
        items.removeAll { $0.id == item.id }
        pathSet.remove(item.url.path)
    }


    public func sanityCheck() {
       
        let currentItems = items
       
        DispatchQueue.global(qos: .utility).async {
            let validItems = currentItems.filter { FileManager.default.fileExists(atPath: $0.url.path) }
            guard validItems.count != currentItems.count else { return }
            
            DispatchQueue.main.async {
                self.items = validItems
                self.pathSet = Set(validItems.map { $0.url.path })
            }
        }
    }
}
