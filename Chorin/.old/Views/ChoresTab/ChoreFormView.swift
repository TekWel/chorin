import SwiftUI
import Supabase

struct ChoreFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    var existingChore: Chore?
    let onSave: () -> Void

    @State private var name: String = ""
    @State private var valueString: String = ""
    @State private var icon: String = "checkmark.circle"
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var isEditing: Bool { existingChore != nil }
    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    private let iconOptions = [
        "checkmark.circle", "bed.double.fill", "fork.knife",
        "trash.fill", "tshirt.fill", "leaf.fill",
        "pawprint.fill", "book.fill", "backpack.fill",
        "shower.fill", "comb.fill", "cart.fill",
        "sparkles", "house.fill", "car.fill",
        "envelope.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Chore Details") {
                    TextField("Chore name", text: $name)

                    HStack {
                        Text("$")
                        TextField("0.00", text: $valueString)
                            .keyboardType(.decimalPad)
                    }
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
                        Text(error)
                            .foregroundStyle(Theme.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Chore" : "New Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await save() }
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || Decimal(string: valueString) == nil)
                    }
                }
            }
            .onAppear {
                if let chore = existingChore {
                    name = chore.name
                    valueString = "\(chore.value)"
                    icon = chore.icon
                }
            }
        }
    }

    private func save() async {
        guard let value = Decimal(string: valueString),
              let householdId = appState.household?.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if let chore = existingChore {
                try await supabase
                    .from("chores")
                    .update([
                        "name": name.trimmingCharacters(in: .whitespaces),
                        "value": "\(value)",
                        "icon": icon
                    ])
                    .eq("id", value: chore.id.uuidString)
                    .execute()
            } else {
                try await supabase
                    .from("chores")
                    .insert([
                        "household_id": householdId.uuidString,
                        "name": name.trimmingCharacters(in: .whitespaces),
                        "value": "\(value)",
                        "icon": icon
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
    ChoreFormView(onSave: {})
        .environment(AppState())
}
