![holdit Logo](holdit_icon_raw.png)

# holdit

A macOS utility accessory that reveals a expanding tray behind the notch when you hover or drag files over it. The tray displays files and folders in a grid, supports drag-and-drop, context menus, batch removal, and keeps its energy impact at Apple’s designated “Low” level.

## Features
- Expanding tray behind the notch on hover or file drag
- Dynamic grid layout of file and folder icons
- Duplicate prevention, drag-out removal, and multi-select
- Context menus for quick actions
- Automatic removal of items whose files no longer exist
- Smooth SwiftUI animations with AppKit tracking for minimal energy use

## Installation (App)
1. See the releases section.

## Installation (source)
1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/holdit.git
   cd holdit
   ```
2. Build & run:
   ```bash
   swift run
   ```

## Usage
- Hover over the notch area or drag files onto it to expand the tray.
- Drag items into the tray to add them, or drag them out to remove.
- Right-click an item for context actions.
- Use the status-bar menu to clear the tray or quit the app.

## Architecture
- **main.swift / AppDelegate**: Sets up a transparent `TriggerPanel` for hover/drag detection and a `TrayPanel` for the expanded UI.
- **LOGIC/TriggerHandler.swift** & **LOGIC/TrayHandler.swift**: Manages `NSTrackingArea` for hover and collapse logic.
- **LOGIC/TrayModel.swift**: `@MainActor` model storing `FileItem`s with O(1) duplicate checks and a background `sanityCheck` on `.utility` QoS.
- **LOGIC/FileItem.swift**: Represents a file/folder item, caches icons with `NSCache` and supports Swift concurrency.
- **GUI**: SwiftUI `Tray` view displaying items in a grid with smooth animations.

## Energy Impact
All event monitoring uses local `NSTrackingArea` and one-time offloaded `.utility` work queues, ensuring “Low” energy impact.
