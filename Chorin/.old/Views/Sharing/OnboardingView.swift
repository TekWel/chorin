import SwiftUI
import Supabase

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    enum Mode { case choose, create, join }
    @State private var mode: Mode = .choose

    var body: some View {
        NavigationStack {
            switch mode {
            case .choose:
                ChooseView(mode: $mode)
            case .create:
                CreateHouseholdView(mode: $mode)
            case .join:
                JoinHouseholdView(mode: $mode)
            }
        }
    }
}

// MARK: - Choose

private struct ChooseView: View {
    @Binding var mode: OnboardingView.Mode

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 72))
                        .foregroundStyle(Theme.blue)
                    Text("Chorin'")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Track chores. Earn allowance.")
                        .font(.title3)
                        .foregroundStyle(Theme.textMuted)
                }

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        mode = .create
                    } label: {
                        Label("Create Household", systemImage: "house.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        mode = .join
                    } label: {
                        Label("Join with Invite Code", systemImage: "person.badge.plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .navigationTitle("Welcome")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Create Household

private struct CreateHouseholdView: View {
    @Binding var mode: OnboardingView.Mode
    @Environment(AppState.self) private var appState

    @State private var householdName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    var body: some View {
        Form {
            Section("Household Name") {
                TextField("e.g. The Smiths", text: $householdName)
            }

            Section {
                Text("You'll be added as a parent. Share the invite code from the Household tab so your children can join.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(Theme.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("New Household")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back") { mode = .choose }
            }
            ToolbarItem(placement: .confirmationAction) {
                if isLoading {
                    ProgressView()
                } else {
                    Button("Create") {
                        Task { await create() }
                    }
                    .disabled(householdName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func create() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.rpc(
                "create_household_with_parent",
                params: ["p_household_name": householdName.trimmingCharacters(in: .whitespaces)]
            ).execute()
            await appState.loadHouseholdAndMember()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Join Household

private struct JoinHouseholdView: View {
    @Binding var mode: OnboardingView.Mode
    @Environment(AppState.self) private var appState

    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    var body: some View {
        Form {
            Section("Invite Code") {
                TextField("6-character code", text: $inviteCode)
                    .autocapitalization(.allCharacters)
                    .onChange(of: inviteCode) { _, new in
                        inviteCode = String(new.prefix(6)).uppercased()
                    }
            }

            Section {
                Text("Ask a parent in your household for the invite code from the Household tab.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(Theme.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Join Household")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back") { mode = .choose }
            }
            ToolbarItem(placement: .confirmationAction) {
                if isLoading {
                    ProgressView()
                } else {
                    Button("Join") {
                        Task { await join() }
                    }
                    .disabled(inviteCode.count < 6)
                }
            }
        }
    }

    private func join() async {
        guard let userId = appState.session?.user.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Look up household by invite code
            let results: [Household] = try await supabase
                .rpc("lookup_household_by_invite_code", params: ["p_invite_code": inviteCode])
                .execute()
                .value

            guard let found = results.first else {
                errorMessage = "No household found with that code. Check the code and try again."
                return
            }

            // Insert membership as child
            try await supabase
                .from("household_members")
                .insert([
                    "household_id": found.id.uuidString,
                    "user_id": userId.uuidString,
                    "role": "child"
                ])
                .execute()

            await appState.loadHouseholdAndMember()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
