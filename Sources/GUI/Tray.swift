import SwiftUI
import Cocoa

public struct Tray: View {
    // Placeholder items: (SF Symbol icon, label)
    private let items: [(icon: String, name: String)]

    public init(items: [(String, String)]? = nil) {
        //  10 placeholders, 2 rows of 5
        self.items = items ?? [
            ("folder.fill", "Folder"),
            ("doc.text.fill", "Document"),
            ("photo.fill", "Image"),
            ("video.fill", "Video"),
            ("music.note", "Music"),
            ("paperclip", "Link"),
            ("bookmark.fill", "Bookmark"),
            ("calendar", "Calendar"),
            ("map.fill", "Map"),
            ("gearshape.fill", "Settings"),
        ]
    }

    public var body: some View {
        GeometryReader { geo in
            let itemSize: CGFloat = 64
            let spacing: CGFloat = 12
            let columns = Array(repeating: GridItem(.fixed(itemSize), spacing: spacing), count: 5)
            ScrollView { //grid of items
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(items, id: \.name) { item in
                        VStack(spacing: 10) {
                            Image(systemName: item.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: itemSize, height: itemSize)
                                .foregroundColor(.white)
                            Text(item.name)
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(width: itemSize)
                        }
                    }
                }
                .padding(.all, spacing)
            }
            .background(Color.green)
            .frame(width: geo.size.width, height: geo.size.height)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
}