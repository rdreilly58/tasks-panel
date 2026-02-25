import Foundation
import Combine
import SwiftUI

// MARK: - Task Model

struct GTask: Identifiable, Equatable {
    let id: String
    let title: String
    let status: String
    let due: String?

    var isCompleted: Bool { status == "completed" }
}

// MARK: - ViewModel

@MainActor
final class TasksViewModel: ObservableObject {
    @Published var tasks: [GTask] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastRefreshed: Date?

    private let listId      = "MDE3Mjg4NDY4MTYwNjc5NDE0MDY6MDow"
    private let account     = "rdreilly2010@gmail.com"
    private let gogPath     = "/opt/homebrew/bin/gog"
    private var refreshTask: Task<Void, Never>?

    var hasPending: Bool {
        tasks.contains { !$0.isCompleted }
    }

    var pendingCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    // MARK: - Auto-refresh (every 5 min)

    func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(300)) // 5 min
                guard !Task.isCancelled else { break }
                await refresh()
            }
        }
    }

    deinit { refreshTask?.cancel() }

    // MARK: - Fetch

    func refresh() async {
        isLoading = true
        error = nil

        let result = await shell(gogPath,
            "tasks", "list", listId,
            "--account", account,
            "--plain"
        )

        switch result {
        case .success(let output):
            tasks = parse(output)
            lastRefreshed = Date()
        case .failure(let msg):
            error = msg
        }

        isLoading = false
    }

    // MARK: - Complete

    func complete(_ task: GTask) async {
        let result = await shell(gogPath,
            "tasks", "complete", listId, task.id,
            "--account", account,
            "--force"
        )
        if case .success = result {
            tasks.removeAll { $0.id == task.id }
        } else if case .failure(let msg) = result {
            error = msg
        }
    }

    // MARK: - Add

    func add(title: String) async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let result = await shell(gogPath,
            "tasks", "add", listId,
            "--title", title,
            "--account", account
        )
        if case .success = result {
            await refresh()
        } else if case .failure(let msg) = result {
            error = msg
        }
    }

    // MARK: - Parse plain TSV output

    private func parse(_ output: String) -> [GTask] {
        let lines = output.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard lines.count > 1 else { return [] }

        return lines.dropFirst().compactMap { line -> GTask? in
            // TSV: ID  TITLE  STATUS  DUE  UPDATED
            let cols = line.components(separatedBy: "\t")
                          .map { $0.trimmingCharacters(in: .whitespaces) }
            guard cols.count >= 3 else { return nil }
            let id     = cols[0]
            let title  = cols[1]
            let status = cols[2]
            let due    = cols.count > 3 && !cols[3].isEmpty ? cols[3] : nil
            guard !id.isEmpty, !title.isEmpty else { return nil }
            return GTask(id: id, title: title, status: status, due: due)
        }
    }

    // MARK: - Shell helper

    private enum ShellResult {
        case success(String)
        case failure(String)
    }

    private func shell(_ path: String, _ args: String...) async -> ShellResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: path)
                proc.arguments = args

                let out = Pipe()
                let err = Pipe()
                proc.standardOutput = out
                proc.standardError  = err

                do {
                    try proc.run()
                    proc.waitUntilExit()
                    let outData = out.fileHandleForReading.readDataToEndOfFile()
                    let errData = err.fileHandleForReading.readDataToEndOfFile()
                    let outStr = String(data: outData, encoding: .utf8) ?? ""
                    let errStr = String(data: errData, encoding: .utf8) ?? ""

                    if proc.terminationStatus == 0 {
                        continuation.resume(returning: .success(outStr))
                    } else {
                        continuation.resume(returning: .failure(errStr.isEmpty ? "Exit \(proc.terminationStatus)" : errStr))
                    }
                } catch {
                    continuation.resume(returning: .failure(error.localizedDescription))
                }
            }
        }
    }
}
