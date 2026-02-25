import SwiftUI

@main
struct TasksPanelApp: App {
    @StateObject private var viewModel = TasksViewModel()

    var body: some Scene {
        MenuBarExtra {
            TasksView()
                .environmentObject(viewModel)
                .frame(width: 320)
        } label: {
            MenuBarIcon(count: viewModel.pendingCount)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Compact icon with optional badge

struct MenuBarIcon: View {
    let count: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "checklist")
                .font(.system(size: 14, weight: .medium))

            if count > 0 {
                Text(count < 10 ? "\(count)" : "9+")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.red, in: Capsule())
                    .offset(x: 8, y: -6)
            }
        }
        .padding(.horizontal, 2)
    }
}
