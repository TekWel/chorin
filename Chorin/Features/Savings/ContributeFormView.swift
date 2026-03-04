import SwiftUI
import Supabase

struct ContributeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    let goal: SavingsGoal
    let totalSaved: Decimal
    let onSave: () -> Void

    @State private var amountString = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    private var maxContribution: Decimal {
        max(goal.targetAmount - totalSaved, 0)
    }

    private var progress: Double {
        guard goal.targetAmount > 0 else { return 0 }
        return min(
            Double(truncating: totalSaved as NSDecimalNumber)
                / Double(truncating: goal.targetAmount as NSDecimalNumber),
            1.0
        )
    }

    private var isFormValid: Bool {
        guard let amount = Decimal(string: amountString),
              amount > 0 else { return false }
        return amount <= maxContribution
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ChorinTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Goal Info
                        HStack(spacing: 12) {
                            Image(systemName: goal.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(ChorinTheme.primary)
                                .frame(width: 42, height: 42)
                                .background(ChorinTheme.tertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(ChorinTheme.textPrimary)

                                HStack(spacing: 4) {
                                    Text(totalSaved.formatted(.currency(code: "USD")))
                                        .foregroundStyle(ChorinTheme.success)
                                    Text("of \(goal.targetAmount.formatted(.currency(code: "USD")))")
                                        .foregroundStyle(ChorinTheme.textMuted)
                                }
                                .font(.system(size: 13))
                            }

                            Spacer()

                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ChorinTheme.textSecondary)
                        }
                        .padding(14)
                        .background(ChorinTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
                        )

                        // MARK: - Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(ChorinTheme.surfaceBorder)
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(ChorinTheme.progressGradient)
                                    .frame(width: max(geo.size.width * progress, 0), height: 8)
                            }
                        }
                        .frame(height: 8)

                        // MARK: - Amount Input
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Contribution Amount")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(ChorinTheme.textSecondary)

                                Spacer()

                                Text("Max: \(maxContribution.formatted(.currency(code: "USD")))")
                                    .font(.system(size: 12))
                                    .foregroundStyle(ChorinTheme.textMuted)
                            }

                            HStack(spacing: 8) {
                                Text("$")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(ChorinTheme.textMuted)

                                ChorinTextField(placeholder: "0.00", text: $amountString)
                                    .keyboardType(.decimalPad)
                            }

                            if let amount = Decimal(string: amountString),
                               amount > maxContribution {
                                Text("Amount exceeds remaining goal balance")
                                    .font(.system(size: 12))
                                    .foregroundStyle(ChorinTheme.danger)
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

                        // MARK: - Contribute Button
                        ChorinButton(
                            title: "Contribute",
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
            .navigationTitle("Add Contribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ChorinTheme.textSecondary)
                }
            }
        }
        .presentationBackground(ChorinTheme.background)
    }

    // MARK: - Save

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

// MARK: - Preview

#Preview {
    ContributeFormView(
        goal: SavingsGoal(
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
        totalSaved: 45.00,
        onSave: {}
    )
    .environment(AppState())
}
