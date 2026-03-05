import SwiftUI
import Supabase

struct ContributeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    let goal: SavingsGoal
    let onSave: () -> Void

    @State private var amountString = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $amountString)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    HStack {
                        Image(systemName: goal.icon)
                            .foregroundStyle(Theme.blue)
                        Text("Saving toward: \(goal.name)")
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(Theme.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Add Contribution")
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
                            .disabled(Decimal(string: amountString) == nil)
                    }
                }
            }
        }
    }

    private func save() async {
        guard let amount = Decimal(string: amountString),
              let userId = appState.session?.user.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase
                .from("savings_contributions")
                .insert([
                    "goal_id": goal.id.uuidString,
                    "user_id": userId.uuidString,
                    "amount": "\(amount)",
                    "source": "manual"
                ])
                .execute()
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
