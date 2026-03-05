import SwiftUI
import Supabase

struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    var existingGoal: SavingsGoal?
    let onSave: () -> Void

    @State private var name = ""
    @State private var targetString = ""
    @State private var icon = "piggybank.fill"
    @State private var autoPercent = 0.0
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var isEditing: Bool { existingGoal != nil }
    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    private let iconOptions = [
        "piggybank.fill", "star.fill", "bicycle",
        "gamecontroller.fill", "airplane", "book.fill",
        "music.note", "camera.fill", "gift.fill",
        "sportscourt.fill", "car.fill", "house.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal name", text: $name)

                    HStack {
                        Text("Target $")
                        TextField("0.00", text: $targetString)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Auto-save from earnings")
                            Spacer()
                            Text("\(Int(autoPercent))%")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $autoPercent, in: 0...100, step: 5)
                            .tint(Theme.green)
                    }
                } footer: {
                    Text("Automatically deposit this % of each chore completion into this goal.")
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(iconOptions, id: \.self) { symbolName in
                            Button {
                                icon = symbolName
                            } label: {
                                Image(systemName: symbolName)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(icon == symbolName ? Theme.blue.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .foregroundStyle(icon == symbolName ? Theme.blue : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(Theme.red).font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") { Task { await save() } }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || Decimal(string: targetString) == nil)
                    }
                }
            }
            .onAppear {
                if let g = existingGoal {
                    name = g.name
                    targetString = "\(g.targetAmount)"
                    icon = g.icon
                    autoPercent = Double(truncating: g.autoPercent as NSDecimalNumber)
                }
            }
        }
    }

    private func save() async {
        guard let target = Decimal(string: targetString),
              let householdId = appState.household?.id,
              let userId = appState.session?.user.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let percent = Decimal(Int(autoPercent))

        do {
            if let g = existingGoal {
                try await supabase
                    .from("savings_goals")
                    .update([
                        "name": name.trimmingCharacters(in: .whitespaces),
                        "target_amount": "\(target)",
                        "icon": icon,
                        "auto_percent": "\(percent)"
                    ])
                    .eq("id", value: g.id.uuidString)
                    .execute()
            } else {
                try await supabase
                    .from("savings_goals")
                    .insert([
                        "household_id": householdId.uuidString,
                        "user_id": userId.uuidString,
                        "name": name.trimmingCharacters(in: .whitespaces),
                        "target_amount": "\(target)",
                        "icon": icon,
                        "auto_percent": "\(percent)"
                    ])
                    .execute()
            }
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    GoalFormView(onSave: {})
        .environment(AppState())
}
