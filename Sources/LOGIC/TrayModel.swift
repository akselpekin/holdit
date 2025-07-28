import Foundation
import Combine

@MainActor
public class TrayModel: ObservableObject {
    @Published public private(set) var items: [FileItem]

    private var pathSet = Set<String>()
    private var idSet = Set<String>()

    public init(initialItems: [FileItem] = []) {
        self.items = initialItems
        pathSet = Set(initialItems.map { $0.url.path })
 
       idSet = Set(initialItems.compactMap { fsID(of: $0) })
    }

    public func add(_ item: FileItem) -> Bool {
        if let id = fsID(of: item) {
            if idSet.contains(id) { return false }
        } else if pathSet.contains(item.url.path) {
            return false
        }
        items.append(item)
        pathSet.insert(item.url.path)
        if let id = fsID(of: item) { idSet.insert(id) }
        return true
    }

    public func clear() {
        items.removeAll()
        pathSet.removeAll()
        idSet.removeAll()
    }

    public func remove(_ item: FileItem) {
        items.removeAll { $0.id == item.id }
        pathSet.remove(item.url.path)
        if let id = fsID(of: item) { idSet.remove(id) }
    }

    public func sanityCheck() {
       
        let currentItems = items
       
        DispatchQueue.global(qos: .utility).async {

            var buffer = [FileItem]()
            buffer.reserveCapacity(currentItems.count)
            var seen = Set<String>()
            for item in currentItems {
                let url = item.url
                let isReachable = (try? url.checkResourceIsReachable()) ?? false
                guard isReachable else { continue }
                let p = url.path
                if !seen.contains(p) {
                    seen.insert(p)
                    buffer.append(item)
                }
            }
            let oldPaths = currentItems.map { $0.url.path }
            let newPaths = buffer.map { $0.url.path }
            guard newPaths != oldPaths else { return }
             DispatchQueue.main.async {
                 self.items = buffer
                 self.pathSet = Set(buffer.map { $0.url.path })
            }
        }
    }
    
    private func fsID(of item: FileItem) -> String? {
        let fm = FileManager.default
        guard let attrs = try? fm.attributesOfItem(atPath: item.url.path),
              let num = (attrs[.systemFileNumber] as? NSNumber)?.uint64Value,
              let dev = (attrs[.systemNumber] as? NSNumber)?.uint64Value else {
            return nil
        }
        return "\(dev):\(num)"
    }
}