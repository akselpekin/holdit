import SwiftUI
import Cocoa

public struct Tray: View {

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            Color.green
                .background(.ultraThinMaterial)
                .frame(width: geo.size.width, height: geo.size.height)
                .cornerRadius(geo.size.height / 2)
        }
    }
}