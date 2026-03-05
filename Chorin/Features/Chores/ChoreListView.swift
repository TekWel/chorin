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
            .filter { $0.completedToday }
            .reduce(Decimal.zero) { $0 + $1.value }
    }

    private var pendingCount: Int {
        chores.filter { !$0.completedToday }.count
    }

    private var greeting: String {
        Calendar.current.component(.hour, from: Date()) < 12
            ? "Good morning"
            : "Good evening"
    }

    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Top bar
                HStack {
                    Text("Chorin'")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .italic()
                        .foregroundStyle(ChorinTheme.primary)

                    Spacer()

                    RoundedRectangle(cornerRadius: 8)
                        .fill(ChorinTheme.tertiary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(ChorinTheme.textMuted)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)

                // MARK: - Greeting & date
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .foregroundStyle(ChorinTheme.textPrimary)

                    Text(Date(), format: .dateTime.weekday(.wide).month().day())
                        .font(.system(size: 13))
                        .foregroundStyle(ChorinTheme.textMuted)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // MARK: - Earned-today pill
                if !chores.isEmpty {
                    HStack {
                        Text("$\(todayTotal.formatted(.number.precision(.fractionLength(2)))) earned today")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(ChorinTheme.success)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Color(hex: "9FD4B2").opacity(0.12),
                        in: Capsule()
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }

                // MARK: - Chore list
                if isLoading {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(ChorinTheme.textMuted)
                        Spacer()
                    }
                    Spacer()
                } else if chores.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "checklist")
                            .font(.system(size: 40))
                            .foregroundStyle(ChorinTheme.textMuted)
                        Text("No Chores")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(ChorinTheme.textPrimary)
                        Text(appState.member?.isParent == true
                             ? "Tap + to add your first chore"
                             : "No chores assigned yet")
                            .font(.system(size: 14))
                            .foregroundStyle(ChorinTheme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    List {
                        ForEach(chores) { chore in
                            ChoreRowView(
                                chore: chore,
                                isParent: appState.member?.isParent == true,
                                onToggle: { Task { await toggle(chore) } },
                                onEdit: { Task { await loadChoreForEdit(chore.id) } },
                                onDelete: { Task { await archiveChore(chore.id) } }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                if appState.member?.isParent == true {
                                    Button { Task { await loadChoreForEdit(chore.id) } } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(ChorinTheme.primary)
                                    Button(role: .destructive) { Task { await archiveChore(chore.id) } } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }

                        // Spacer for FAB
                        Color.clear
                            .frame(height: 60)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(ChorinTheme.danger)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
            }

            // MARK: - Floating add button (parents only)
            if appState.member?.isParent == true {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingAddChore = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(ChorinTheme.primary, in: Circle())
                                .shadow(color: ChorinTheme.primary.opacity(0.4), radius: 12, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 50) // clear the tab bar
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
                todayCompletionId: chore.completedToday ? nil : UUID(),
                completedToday: !chore.completedToday
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
