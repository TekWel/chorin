import SwiftUI

struct ChoreRowView: View {
    let chore: ChoreWithCompletion
    let isParent: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Checkbox
            Button(action: onToggle) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(chore.completedToday ? ChorinTheme.success : .clear)
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(
                                chore.completedToday ? ChorinTheme.success : ChorinTheme.surfaceBorder,
                                lineWidth: 1.5
                            )
                    )
                    .overlay(
                        Group {
                            if chore.completedToday {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    )
            }
            .buttonStyle(.plain)

            // MARK: - Emoji icon
            Text(chore.icon)
                .font(.system(size: 18))
                .frame(width: 36, height: 36)
                .background(ChorinTheme.tertiary)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // MARK: - Chore name
            Text(chore.name)
                .font(.system(size: 14))
                .foregroundStyle(chore.completedToday ? ChorinTheme.textMuted : ChorinTheme.textPrimary)
                .strikethrough(chore.completedToday, color: ChorinTheme.textMuted)

            Spacer()

            // MARK: - Dollar value
            Text(chore.value.formatted(.currency(code: "USD")))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ChorinTheme.primary)
        }
        .padding(14)
        .background(ChorinTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: chore.completedToday)
    }
}

#Preview {
    VStack(spacing: 10) {
        ChoreRowView(
            chore: ChoreWithCompletion(
                id: UUID(), name: "Make bed", value: 1.00,
                icon: "🛏️", todayCompletionId: nil, completedToday: false
            ),
            isParent: true,
            onToggle: {}, onEdit: {}, onDelete: {}
        )
        ChoreRowView(
            chore: ChoreWithCompletion(
                id: UUID(), name: "Load dishwasher", value: 2.50,
                icon: "🍽️", todayCompletionId: UUID(), completedToday: true
            ),
            isParent: false,
            onToggle: {}, onEdit: {}, onDelete: {}
        )
    }
    .padding()
    .background(ChorinTheme.background)
}
