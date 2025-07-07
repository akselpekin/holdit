import SwiftUI
import Cocoa

public struct Tray: View {
    // Placeholder items: (SF Symbol icon, label)
    private let items: [(icon: String, name: String)]
    private let topPadding: CGFloat

    // Parameters: items are fallback here the auhoritative source is in main.swift
    // Parameters: topPadding disallows items to go under the notch
    public init(items: [(String, String)]? = nil, topPadding: CGFloat = 0) {
        self.items = items ?? (1...20).map { ("folder.fill", "Item \($0)") }
        self.topPadding = topPadding
    }

    public var body: some View {
        GeometryReader { geo in
            let itemSize: CGFloat = 64
            let spacing: CGFloat = 12
            let columns = Array(repeating: GridItem(.fixed(itemSize), spacing: spacing), count: 5)

            VStack(spacing: 0) {
                Spacer().frame(height: topPadding)
                ScrollView { //grid
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
            }
            .background(Color.green)
            .frame(width: geo.size.width, height: geo.size.height)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
}