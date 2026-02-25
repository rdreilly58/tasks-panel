import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var vm: TasksViewModel
    @State private var newTaskText = ""
    @State private var isAdding    = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            taskList
            Divider()
            footer
        }
        .background(.ultraThickMaterial)
        .task { vm.startAutoRefresh() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "checklist")
                .foregroundStyle(.blue)
                .fontWeight(.semibold)
            Text("Google Tasks")
                .font(.headline)
            Spacer()
            if vm.pendingCount > 0 {
                Text("\(vm.pendingCount)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            Button {
                Task { await vm.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .rotationEffect(.degrees(vm.isLoading ? 360 : 0))
            .animation(vm.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                       value: vm.isLoading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Task List

    @ViewBuilder
    private var taskList: some View {
        if vm.isLoading && vm.tasks.isEmpty {
            HStack {
                Spacer()
                ProgressView().scaleEffect(0.8)
                Spacer()
            }
            .frame(height: 80)
        } else if vm.tasks.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("All done!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(vm.tasks) { task in
                        TaskRow(task: task) {
                            Task { await vm.complete(task) }
                        }
                        if task.id != vm.tasks.last?.id {
                            Divider().padding(.leading, 40)
                        }
                    }
                }
            }
            .frame(maxHeight: 320)
        }

        if let error = vm.error {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.orange.opacity(0.08))
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            if isAdding {
                HStack(spacing: 8) {
                    TextField("New task…", text: $newTaskText)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .focused($inputFocused)
                        .onSubmit { submitNewTask() }

                    Button(action: submitNewTask) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                            .foregroundStyle(newTaskText.isEmpty ? Color.secondary : Color.blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(newTaskText.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button {
                        withAnimation { isAdding = false }
                        newTaskText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            } else {
                HStack {
                    Button {
                        withAnimation { isAdding = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            inputFocused = true
                        }
                    } label: {
                        Label("Add Task", systemImage: "plus")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if let date = vm.lastRefreshed {
                        Text("Updated \(date.formatted(.relative(presentation: .named)))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
    }

    private func submitNewTask() {
        let title = newTaskText.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        Task { await vm.add(title: title) }
        newTaskText = ""
        withAnimation { isAdding = false }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: GTask
    let onComplete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onComplete) {
                Image(systemName: hovering ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(hovering ? .green : .secondary)
                    .animation(.easeInOut(duration: 0.15), value: hovering)
            }
            .buttonStyle(.plain)
            .onHover { hovering = $0 }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let due = task.due, !due.isEmpty {
                    Text("Due \(due)")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(hovering ? Color.primary.opacity(0.04) : Color.clear)
        .animation(.easeInOut(duration: 0.1), value: hovering)
        .onHover { hovering = $0 }
    }
}
