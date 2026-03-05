import SwiftUI

struct ChoreRowView: View {
    let chore: ChoreWithCompletion
    let isParent: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(chore.isCompleted ? Theme.green : .gray)
            }
            .buttonStyle(.plain)

            // Chore icon
            Image(systemName: chore.icon)
                .font(.title3)
                .foregroundStyle(Theme.blue)
                .frame(width: 28)

            // Chore name
            Text(chore.name)
                .strikethrough(chore.isCompleted, color: .gray)
                .foregroundStyle(chore.isCompleted ? .secondary : .primary)

            Spacer()

            // Dollar value
            Text(chore.value.formatted(.currency(code: "USD")))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(chore.isCompleted ? Theme.green : Theme.textMuted)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.2), value: chore.isCompleted)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if isParent {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(Theme.orange)
            }
        }
    }
}

#Preview {
    List {
        ChoreRowView(
            chore: ChoreWithCompletion(id: UUID(), name: "Make bed", value: 1.00, icon: "bed.double.fill", completionId: nil, isCompleted: false),
            isParent: true,
            onToggle: {}, onEdit: {}, onDelete: {}
        )
        ChoreRowView(
            chore: ChoreWithCompletion(id: UUID(), name: "Load dishwasher", value: 2.50, icon: "fork.knife", completionId: UUID(), isCompleted: true),
            isParent: false,
            onToggle: {}, onEdit: {}, onDelete: {}
        )
    }
}
