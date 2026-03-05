import SwiftUI
import Supabase

struct ChoreListView: View {
    @Environment(AppState.self) private var appState

    @State private var chores: [ChoreWithCompletion] = []
    @State private var isLoading = false
    @State private var showingAddChore = false
    @State private var choreToEdit: Chore?
    @State private var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    private var todayTotal: Decimal {
        chores
            .filter { $0.isCompleted }
            .reduce(Decimal.zero) { $0 + $1.value }
    }

    private var pendingCount: Int {
        chores.filter { !$0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            List {
                // Date header
                Section {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(Theme.blue)
                        Text(Date(), format: .dateTime.weekday(.wide).month().day())
                            .font(.headline)
                    }
                }

                // Chore list
                Section {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if chores.isEmpty {
                        ContentUnavailableView(
                            "No Chores",
                            systemImage: "checklist",
                            description: Text(appState.member?.isParent == true
                                ? "Tap + to add your first chore"
                                : "No chores assigned yet")
                        )
                    } else {
                        ForEach(chores) { chore in
                            ChoreRowView(
                                chore: chore,
                                isParent: appState.member?.isParent == true,
                                onToggle: { Task { await toggle(chore) } },
                                onEdit: { Task { await loadChoreForEdit(chore.id) } },
                                onDelete: { Task { await archiveChore(chore.id) } }
                            )
                        }
                    }
                }

                // Daily total
                if !chores.isEmpty {
                    Section {
                        HStack {
                            Text("Today's Earnings")
                                .fontWeight(.medium)
                            Spacer()
                            Text(todayTotal.formatted(.currency(code: "USD")))
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.green)
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(Theme.red)
                            .font(.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Chores")
            .toolbar {
                if appState.member?.isParent == true {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showingAddChore = true } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddChore, onDismiss: { Task { await loadChores() } }) {
                ChoreFormView { }
            }
            .sheet(item: $choreToEdit, onDismiss: { Task { await loadChores() } }) { chore in
                ChoreFormView(existingChore: chore) { }
            }
            .task { await loadChores() }
            .task { await subscribeRealtime() }
            .refreshable { await loadChores() }
        }
        .badge(pendingCount > 0 ? pendingCount : 0)
    }

    // MARK: - Data

    private func loadChores() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let dateString = ISO8601DateFormatter.choreDateFormatter.string(from: Date())
        do {
            chores = try await supabase
                .rpc("get_todays_chores_for_current_user", params: ["p_date": dateString])
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func toggle(_ chore: ChoreWithCompletion) async {
        // Optimistic update
        if let idx = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[idx] = ChoreWithCompletion(
                id: chore.id,
                name: chore.name,
                value: chore.value,
                icon: chore.icon,
                completionId: chore.isCompleted ? nil : UUID(),
                isCompleted: !chore.isCompleted
            )
        }

        let dateString = ISO8601DateFormatter.choreDateFormatter.string(from: Date())
        do {
            try await supabase
                .rpc("toggle_chore_completion", params: [
                    "p_chore_id": chore.id.uuidString,
                    "p_date": dateString
                ])
                .execute()
        } catch {
            errorMessage = error.localizedDescription
            await loadChores() // revert on failure
        }
    }

    private func archiveChore(_ choreId: UUID) async {
        do {
            try await supabase
                .from("chores")
                .update(["is_active": false])
                .eq("id", value: choreId.uuidString)
                .execute()
            await loadChores()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadChoreForEdit(_ choreId: UUID) async {
        do {
            let chores: [Chore] = try await supabase
                .from("chores")
                .select()
                .eq("id", value: choreId.uuidString)
                .limit(1)
                .execute()
                .value
            choreToEdit = chores.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Realtime

    private func subscribeRealtime() async {
        guard let householdId = appState.household?.id else { return }
        let channel = supabase.realtimeV2.channel("chores-\(householdId)")
        let changes = await channel.postgresChange(
            AnyAction.self,
            schema: "public"
        )
        await channel.subscribe()
        for await _ in changes {
            await loadChores()
        }
    }
}

// MARK: - Date formatter helper

extension ISO8601DateFormatter {
    static let choreDateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()
}

#Preview {
    ChoreListView()
        .environment(AppState())
}
