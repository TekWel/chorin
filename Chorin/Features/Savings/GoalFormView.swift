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

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Decimal(string: targetString) != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ChorinTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Goal Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Goal Name")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ChorinTheme.textSecondary)

                            ChorinTextField(placeholder: "e.g. New Bicycle", text: $name)
                        }

                        // MARK: - Target Amount
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Amount")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ChorinTheme.textSecondary)

                            HStack(spacing: 8) {
                                Text("$")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(ChorinTheme.textMuted)

                                ChorinTextField(placeholder: "0.00", text: $targetString)
                                    .keyboardType(.decimalPad)
                            }
                        }

                        // MARK: - Auto-Save Percentage
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Auto-save from earnings")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(ChorinTheme.textSecondary)

                                Spacer()

                                Text("\(Int(autoPercent))%")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(ChorinTheme.primary)
                            }

                            Slider(value: $autoPercent, in: 0...100, step: 5)
                                .tint(ChorinTheme.primary)

                            Text("Automatically deposit this % of each chore completion into this goal.")
                                .font(.system(size: 12))
                                .foregroundStyle(ChorinTheme.textMuted)
                        }
                        .padding(14)
                        .background(ChorinTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: ChorinTheme.radius))
                        .overlay(
                            RoundedRectangle(cornerRadius: ChorinTheme.radius)
                                .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
                        )

                        // MARK: - Icon Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Icon")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ChorinTheme.textSecondary)

                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible()), count: 4),
                                spacing: 12
                            ) {
                                ForEach(iconOptions, id: \.self) { symbolName in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            icon = symbolName
                                        }
                                    } label: {
                                        Image(systemName: symbolName)
                                            .font(.system(size: 20))
                                            .foregroundStyle(
                                                icon == symbolName
                                                    ? ChorinTheme.primary
                                                    : ChorinTheme.textSecondary
                                            )
                                            .frame(width: 52, height: 52)
                                            .background(ChorinTheme.tertiary)
                                            .clipShape(RoundedRectangle(cornerRadius: ChorinTheme.radiusSM))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: ChorinTheme.radiusSM)
                                                    .strokeBorder(
                                                        icon == symbolName
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
                            title: isEditing ? "Save Changes" : "Create Goal",
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
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ChorinTheme.textSecondary)
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
        .presentationBackground(ChorinTheme.background)
    }

    // MARK: - Save

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

// MARK: - Previews

#Preview("New Goal") {
    GoalFormView(onSave: {})
        .environment(AppState())
}

#Preview("Edit Goal") {
    GoalFormView(
        existingGoal: SavingsGoal(
            id: UUID(),
            householdId: UUID(),
            userId: UUID(),
            name: "New Bicycle",
            targetAmount: 150.00,
            icon: "bicycle",
            autoPercent: 10,
            isActive: true,
            createdAt: Date()
        ),
        onSave: {}
    )
    .environment(AppState())
}
