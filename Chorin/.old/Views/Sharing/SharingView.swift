import SwiftUI
import Supabase

struct HouseholdView: View {
    @Environment(AppState.self) private var appState

    @State private var members: [HouseholdMember] = []
    @State private var memberEmails: [UUID: String] = [:]
    @State private var isLoading = false
    @State private var codeCopied = false

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    var body: some View {
        List {
            // Household info
            if let household = appState.household {
                Section {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundStyle(Theme.blue)
                            .font(.title2)
                        Text(household.name)
                            .font(.headline)
                    }
                }

                Section("Invite Code") {
                    HStack {
                        Text(household.inviteCode)
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.activeBlue)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = household.inviteCode
                            withAnimation { codeCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { codeCopied = false }
                            }
                        } label: {
                            Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                                .foregroundStyle(codeCopied ? Theme.green : Theme.blue)
                        }
                    }

                    Text("Share this code with family members so they can join from the app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Members
            Section("Members") {
                if isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else {
                    ForEach(members) { member in
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(member.isParent ? Theme.orange : Theme.blue)
                            VStack(alignment: .leading) {
                                Text(memberEmails[member.userId] ?? "Member")
                                    .font(.subheadline)
                                Text(member.isParent ? "Parent" : "Child")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if member.userId == appState.session?.user.id {
                                Text("You")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }

            // Sign out
            Section {
                Button(role: .destructive) {
                    Task { await appState.signOut() }
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                        Spacer()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Household")
        .task { await loadMembers() }
        .refreshable { await loadMembers() }
    }

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
