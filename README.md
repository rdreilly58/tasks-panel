# TasksPanel

A lightweight macOS menu bar app for **Google Tasks** — built with SwiftUI, no Electron, no web views.

![TasksPanel screenshot](screenshot.png)

---

## Features

- 🗂 **Menu bar icon** with live pending-task badge count
- ✅ **Complete tasks** with a single click
- ➕ **Add tasks** inline — type and press Return
- 🔄 **Auto-refresh** every 5 minutes
- 🕐 **"Updated X ago"** timestamp in the footer
- 🪶 **Lightweight** — pure SwiftUI, shells out to `gog` CLI for API access

---

## Requirements

| Requirement | Version |
|---|---|
| macOS | 14.0 Sonoma+ |
| Xcode | 15+ |
| [XcodeGen](https://github.com/yonaskolb/XcodeGen) | Any |
| [gog CLI](https://github.com/benbournas/gog) | Latest |

### Install dependencies

```bash
brew install xcodegen
brew install benbournas/tap/gog
```

### Authenticate Google account

```bash
gog auth login --account your@gmail.com
```

---

## Build & Install

```bash
git clone https://github.com/rdreilly58/tasks-panel
cd tasks-panel

# Generate Xcode project
xcodegen generate

# Build Release
xcodebuild \
  -project TasksPanel.xcodeproj \
  -scheme TasksPanel \
  -configuration Release \
  -derivedDataPath .build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
  build

# Install to /Applications
cp -R .build/Build/Products/Release/TasksPanel.app /Applications/

# Launch
open /Applications/TasksPanel.app
```

---

## Project Structure

```
tasks-panel/
├── project.yml                    # XcodeGen source of truth
├── TasksPanel.xcodeproj/          # Generated — do not edit manually
└── TasksPanel/
    ├── TasksPanelApp.swift        # App entry point + MenuBarIcon view
    ├── TasksView.swift            # Main panel UI (header, list, footer)
    ├── TasksViewModel.swift       # Data model, gog integration, auto-refresh
    ├── Info.plist                 # LSUIElement = true (menu bar only)
    └── TasksPanel.entitlements    # Sandbox disabled (required for shell-out)
```

### Key files

**`TasksPanelApp.swift`**  
Defines the `MenuBarExtra` scene with a compact icon-only label and optional red badge when tasks are pending.

**`TasksView.swift`**  
SwiftUI panel with three sections:
- **Header** — title, pending count badge, refresh button
- **Task list** — scrollable `LazyVStack` with hover-to-complete circles
- **Footer** — inline add-task field with submit/cancel, last-updated timestamp

**`TasksViewModel.swift`**  
`@MainActor ObservableObject` that:
- Shells out to `gog tasks list <listId>` and parses TSV output
- Supports `complete()` and `add()` mutations
- Auto-refreshes on a 5-minute background `Task` loop

**`project.yml`**  
XcodeGen config — macOS 14 target, sandbox disabled, `LSUIElement: true` so the app lives only in the menu bar (no Dock icon, no app switcher entry).

---

## Configuration

Edit `TasksViewModel.swift` to point at your list:

```swift
private let listId  = "YOUR_TASK_LIST_ID"
private let account = "your@gmail.com"
```

To find your list ID:

```bash
gog tasks lists --account your@gmail.com
```

---

## How It Works

```
MenuBarExtra (SwiftUI)
    └── TasksView
            └── TasksViewModel
                    └── gog tasks list <listId>   ← shells out
                            └── Google Tasks API (OAuth via gog)
```

The app has **no direct Google API dependency** — it delegates all auth and API calls to the `gog` CLI, which manages OAuth tokens in the system keychain.

---

## License

MIT
