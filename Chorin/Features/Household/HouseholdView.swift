import SwiftUI
import Supabase

struct HouseholdView: View {
    @Environment(AppState.self) private var appState

    @State private var members: [HouseholdMember] = []
    @State private var isLoading = false
    @State private var codeCopied = false
    @State private var isSigningOut = false

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Household name heading
                if let household = appState.household {
                    Text(household.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(ChorinTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // MARK: - Invite Code Card
                    ChorinCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Invite Code")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ChorinTheme.textMuted)

                            HStack {
                                Text(household.inviteCode)
                                    .font(.system(size: 24, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(ChorinTheme.textPrimary)
                                    .tracking(4)

                                Spacer()

                                Button {
                                    UIPasteboard.general.string = household.inviteCode
                                    withAnimation { codeCopied = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { codeCopied = false }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 14, weight: .medium))
                                        if codeCopied {
                                            Text("Copied!")
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                    }
                                    .foregroundStyle(codeCopied ? ChorinTheme.success : ChorinTheme.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        codeCopied
                                            ? ChorinTheme.success.opacity(0.12)
                                            : ChorinTheme.primary.opacity(0.12)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: ChorinTheme.radiusXS))
                                }

                            }

                            Text("Share this code with family members so they can join your household.")
                                .font(.system(size: 13))
                                .foregroundStyle(ChorinTheme.textMuted)
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Members Card
                    ChorinCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Members")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ChorinTheme.textMuted)

                            if isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(ChorinTheme.textMuted)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                                        memberRow(member)

                                        if index < members.count - 1 {
                                            Divider()
                                                .background(ChorinTheme.surfaceBorder)
                                                .padding(.vertical, 4)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 20)

                // MARK: - Sign Out
                ChorinButton(title: "Sign Out", style: .danger, isLoading: isSigningOut) {
                    isSigningOut = true
                    Task {
                        await appState.signOut()
                        isSigningOut = false
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(ChorinTheme.background.ignoresSafeArea())
        .task { await loadMembers() }
        .refreshable { await loadMembers() }
    }

    // MARK: - Member Row

    @ViewBuilder
    private func memberRow(_ member: HouseholdMember) -> some View {
        HStack(spacing: 12) {
            // Avatar circle with initial
            avatarView(for: member)

            // Name
            VStack(alignment: .leading, spacing: 2) {
                if member.userId == appState.session?.user.id {
                    Text("You")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ChorinTheme.textPrimary)
                } else {
                    Text("Member")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ChorinTheme.textPrimary)
                }
            }

            Spacer()

            // Role badge pill
            Text(member.isParent ? "Parent" : "Child")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(member.isParent ? ChorinTheme.primary : ChorinTheme.success)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    (member.isParent ? ChorinTheme.primary : ChorinTheme.success).opacity(0.12)
                )
                .clipShape(Capsule())
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func avatarView(for member: HouseholdMember) -> some View {
        let initial = member.userId == appState.session?.user.id ? "Y" : "M"
        let color = member.isParent ? ChorinTheme.primary : ChorinTheme.success

        Text(initial)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background(color.opacity(0.12))
            .clipShape(Circle())
    }

    // MARK: - Data Loading

    private func loadMembers() async {
        guard let householdId = appState.household?.id else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            members = try await supabase
                .from("household_members")
                .select()
                .eq("household_id", value: householdId.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
        } catch {
            print("Error loading members: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        HouseholdView()
            .environment(AppState())
    }
}
