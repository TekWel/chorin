import SwiftUI
import Supabase

struct ChoreFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    var existingChore: Chore?
    let onSave: () -> Void

    @State private var name: String = ""
    @State private var valueString: String = ""
    @State private var icon: String = "\u{2705}"
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var isEditing: Bool { existingChore != nil }
    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    private let iconOptions = [
        "\u{2705}", "\u{1F6CF}\u{FE0F}", "\u{1F37D}\u{FE0F}",
        "\u{1F5D1}\u{FE0F}", "\u{1F455}", "\u{1F33F}",
        "\u{1F43E}", "\u{1F4DA}", "\u{1F392}",
        "\u{1F6BF}", "\u{1F9F9}", "\u{1F6D2}",
        "\u{2728}", "\u{1F3E0}", "\u{1F697}",
        "\u{2709}\u{FE0F}"
    ]

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Decimal(string: valueString) != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ChorinTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Chore Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Chore Name")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ChorinTheme.textSecondary)

                            ChorinTextField(placeholder: "e.g. Make the bed", text: $name)
                        }

                        // MARK: - Dollar Value
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Dollar Value")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ChorinTheme.textSecondary)

                            HStack(spacing: 8) {
                                Text("$")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(ChorinTheme.textMuted)

                                ChorinTextField(placeholder: "0.00", text: $valueString)
                                    .keyboardType(.decimalPad)
                            }
                        }

                        // MARK: - Icon Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Icon")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ChorinTheme.textSecondary)

                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible()), count: 4),
                                spacing: 12
                            ) {
                                ForEach(iconOptions, id: \.self) { emoji in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            icon = emoji
                                        }
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 24))
                                            .frame(width: 52, height: 52)
                                            .background(ChorinTheme.tertiary)
                                            .clipShape(RoundedRectangle(cornerRadius: ChorinTheme.radiusSM))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: ChorinTheme.radiusSM)
                                                    .strokeBorder(
                                                        icon == emoji
                                                            ? ChorinTheme.primary
                                                            : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // MARK: - Error
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundStyle(ChorinTheme.danger)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    ChorinTheme.danger.opacity(0.1),
                                    in: RoundedRectangle(cornerRadius: ChorinTheme.radiusSM)
                                )
                        }

                        // MARK: - Save Button
                        ChorinButton(
                            title: isEditing ? "Save Changes" : "Add Chore",
                            style: .primary,
                            isLoading: isLoading
                        ) {
                            Task { await save() }
                        }
                        .disabled(!isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.5)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "Edit Chore" : "Add Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ChorinTheme.textSecondary)
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
        .presentationBackground(ChorinTheme.background)
    }

    // MARK: - Save

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

#Preview("Add") {
    ChoreFormView(onSave: {})
        .environment(AppState())
}

#Preview("Edit") {
    ChoreFormView(
        existingChore: Chore(
            id: UUID(),
            householdId: UUID(),
            name: "Make the bed",
            value: 1.50,
            icon: "\u{1F6CF}\u{FE0F}",
            isActive: true,
            createdByUserId: nil,
            validationStatus: nil,
            createdAt: Date()
        ),
        onSave: {}
    )
    .environment(AppState())
}
