# Chorin iOS Redesign — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild the Chorin iOS app with dark leather-brown + coral pastel aesthetic, clean-slate SwiftUI views, same Supabase backend.

**Architecture:** SwiftUI with `@Observable` AppState, Supabase Swift SDK for auth/data/realtime, feature-based folder structure. All business logic ported from `Chorin/.old/`, views completely rewritten with new design system.

**Tech Stack:** SwiftUI (iOS 17+), Supabase Swift 2.x, XcodeGen (`project.yml`)

**Design Reference:** `docs/design-preview.html`, `docs/plans/2026-03-03-chorin-redesign-design.md`

---

### Task 0: Project scaffold & XcodeGen

**Files:**
- Create: `Chorin/App/ChorinApp.swift`
- Create: `Chorin/Design/Theme.swift`

**Step 1: Create directory structure**

```bash
mkdir -p Chorin/App Chorin/Design/Components Chorin/Features/Auth Chorin/Features/Chores Chorin/Features/Earnings Chorin/Features/Savings Chorin/Features/Household Chorin/Models Chorin/Services
```

**Step 2: Create placeholder ChorinApp.swift**

Create `Chorin/App/ChorinApp.swift`:

```swift
import SwiftUI

@main
struct ChorinApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Chorin'")
        }
        .preferredColorScheme(.dark)
    }
}
```

**Step 3: Regenerate Xcode project and verify it builds**

```bash
cd /Users/alecwelwood/Dev/chorin && xcodegen generate
```

Open in Xcode, build for simulator. Should show "Chorin'" text on dark background.

**Step 4: Commit**

```bash
git add Chorin/App/ && git commit -m "scaffold: create project structure and placeholder app entry"
```

---

### Task 1: Design system — Theme.swift

**Files:**
- Create: `Chorin/Design/Theme.swift`

**Step 1: Write Theme.swift with full color system**

Create `Chorin/Design/Theme.swift`:

```swift
import SwiftUI

enum ChorinTheme {
    // MARK: - Colors (Dark Leather + Coral Pastel)
    static let background     = Color(hex: "161110")
    static let surface        = Color(hex: "231C19")
    static let surfaceBorder  = Color(hex: "362B26")
    static let surfaceRaised  = Color(hex: "2D2420")
    static let tertiary       = Color(hex: "3A2A24")

    static let primary        = Color(hex: "FF9080")  // Coral
    static let primarySoft    = Color(hex: "FFAB9E")
    static let primaryPressed = Color(hex: "E87868")
    static let secondary      = Color(hex: "FFC4B5")  // Peach

    static let success        = Color(hex: "9FD4B2")  // Sage green
    static let successSoft    = Color(hex: "9FD4B2").opacity(0.12)
    static let warning        = Color(hex: "F5D49A")
    static let danger         = Color(hex: "F08080")

    static let textPrimary    = Color(hex: "F5EAE4")
    static let textSecondary  = Color(hex: "BFB0A8")
    static let textMuted      = Color(hex: "7A6C64")

    // MARK: - Spacing
    static let radiusXS: CGFloat = 6
    static let radiusSM: CGFloat = 10
    static let radius: CGFloat = 16
    static let radiusLG: CGFloat = 20

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, primarySoft],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let progressGradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

**Step 2: Build and verify no errors**

```bash
xcodegen generate && xcodebuild -project Chorin.xcodeproj -scheme Chorin -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**Step 3: Commit**

```bash
git add Chorin/Design/Theme.swift && git commit -m "feat: add design system with dark leather + coral pastel colors"
```

---

### Task 2: Design system — Reusable components

**Files:**
- Create: `Chorin/Design/Components/ChorinButton.swift`
- Create: `Chorin/Design/Components/ChorinCard.swift`
- Create: `Chorin/Design/Components/ChorinTextField.swift`
- Create: `Chorin/Design/Components/ChorinNavBar.swift`

**Step 1: Create ChorinButton.swift**

```swift
import SwiftUI

struct ChorinButton: View {
    let title: String
    var style: Style = .primary
    var isLoading: Bool = false
    let action: () -> Void

    enum Style {
        case primary, secondary, outline, danger
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(style == .primary ? Color(hex: "161110") : ChorinTheme.primary)
                } else {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: style == .outline ? 1.5 : 0)
            )
        }
        .disabled(isLoading)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: ChorinTheme.primary
        case .secondary: ChorinTheme.tertiary
        case .outline: .clear
        case .danger: ChorinTheme.danger.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: Color(hex: "161110")
        case .secondary: ChorinTheme.primary
        case .outline: ChorinTheme.textSecondary
        case .danger: ChorinTheme.danger
        }
    }

    private var borderColor: Color {
        style == .outline ? ChorinTheme.surfaceBorder : .clear
    }
}
```

**Step 2: Create ChorinCard.swift**

```swift
import SwiftUI

struct ChorinCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background(ChorinTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
            )
    }
}
```

**Step 3: Create ChorinTextField.swift**

```swift
import SwiftUI

struct ChorinTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(14)
        .background(ChorinTheme.background)
        .foregroundStyle(ChorinTheme.textPrimary)
        .clipShape(RoundedRectangle(cornerRadius: ChorinTheme.radiusSM))
        .overlay(
            RoundedRectangle(cornerRadius: ChorinTheme.radiusSM)
                .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1.5)
        )
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
    }
}
```

**Step 4: Create ChorinNavBar.swift — the floating pill nav**

```swift
import SwiftUI

enum ChorinTab: String, CaseIterable {
    case chores, earnings, savings, household

    var label: String {
        switch self {
        case .chores: "Chores"
        case .earnings: "Earnings"
        case .savings: "Savings"
        case .household: "Home"
        }
    }

    var icon: String {
        switch self {
        case .chores: "checkmark.square"
        case .earnings: "dollarsign"
        case .savings: "arrow.down.circle"
        case .household: "house"
        }
    }
}

struct ChorinTabBar: View {
    @Binding var selected: ChorinTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ChorinTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))

                        if selected == tab {
                            Text(tab.label)
                                .font(.system(size: 11, weight: .semibold))
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .foregroundStyle(selected == tab ? ChorinTheme.primary : ChorinTheme.textMuted)
                    .padding(.horizontal, selected == tab ? 14 : 12)
                    .padding(.vertical, 10)
                    .background(
                        selected == tab ? ChorinTheme.tertiary : .clear,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
            }
        }
        .padding(6)
        .background(ChorinTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(ChorinTheme.surfaceBorder, lineWidth: 1)
        )
    }
}
```

**Step 5: Build and verify**

```bash
xcodegen generate && xcodebuild -project Chorin.xcodeproj -scheme Chorin -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**Step 6: Commit**

```bash
git add Chorin/Design/Components/ && git commit -m "feat: add reusable UI components — button, card, text field, tab bar"
```

---

### Task 3: Models (port from .old)

**Files:**
- Create: `Chorin/Models/Household.swift`
- Create: `Chorin/Models/HouseholdMember.swift`
- Create: `Chorin/Models/Chore.swift`
- Create: `Chorin/Models/ChoreCompletion.swift`
- Create: `Chorin/Models/SavingsGoal.swift`
- Create: `Chorin/Models/SavingsContribution.swift`

**Step 1: Copy all 6 model files from .old**

Copy each model file from `Chorin/.old/Models/` to `Chorin/Models/` — these are unchanged. The exact code is in:
- `Chorin/.old/Models/Household.swift`
- `Chorin/.old/Models/HouseholdMember.swift`
- `Chorin/.old/Models/Chore.swift`
- `Chorin/.old/Models/ChoreCompletion.swift`
- `Chorin/.old/Models/SavingsGoal.swift`
- `Chorin/.old/Models/SavingsContribution.swift`

**Step 2: Build and verify**

```bash
xcodegen generate && xcodebuild -project Chorin.xcodeproj -scheme Chorin -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**Step 3: Commit**

```bash
git add Chorin/Models/ && git commit -m "feat: add data models — household, chore, savings (ported from .old)"
```

---

### Task 4: Services (port from .old, rename)

**Files:**
- Create: `Chorin/Services/SupabaseClient.swift` (from `CloudKitManager.swift`)
- Create: `Chorin/Services/AppState.swift` (from `AppState.swift`)
- Create: `Chorin/Services/WeekHelper.swift` (from `WeekHelper.swift`)

**Step 1: Create SupabaseClient.swift**

Copy `Chorin/.old/Utilities/CloudKitManager.swift` to `Chorin/Services/SupabaseClient.swift` — same content, just renamed file.

**Step 2: Create AppState.swift**

Copy `Chorin/.old/Utilities/AppState.swift` to `Chorin/Services/AppState.swift` — same content.

**Step 3: Create WeekHelper.swift**

Copy `Chorin/.old/Utilities/WeekHelper.swift` to `Chorin/Services/WeekHelper.swift` — same content.

**Step 4: Build and verify**

```bash
xcodegen generate && xcodebuild -project Chorin.xcodeproj -scheme Chorin -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**Step 5: Commit**

```bash
git add Chorin/Services/ && git commit -m "feat: add services — SupabaseClient, AppState, WeekHelper (ported from .old)"
```

---

### Task 5: App entry point & root navigation

**Files:**
- Modify: `Chorin/App/ChorinApp.swift`
- Create: `Chorin/App/ContentView.swift`

**Step 1: Update ChorinApp.swift with full root navigation**

Replace `Chorin/App/ChorinApp.swift` with:

```swift
import SwiftUI

@main
struct ChorinApp: App {
    @State private var appState = AppState()

    init() {
        // Dark tab bar and nav bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(red: 0.086, green: 0.067, blue: 0.063, alpha: 1) // #161110
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(red: 0.086, green: 0.067, blue: 0.063, alpha: 1)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(red: 0.96, green: 0.92, blue: 0.89, alpha: 1)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(red: 0.96, green: 0.92, blue: 0.89, alpha: 1)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        UITableView.appearance().backgroundColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .task { await appState.bootstrap() }
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isLoading {
                ZStack {
                    ChorinTheme.background.ignoresSafeArea()
                    ProgressView()
                        .tint(ChorinTheme.primary)
                }
            } else if !appState.isAuthenticated {
                LoginView()
            } else if !appState.hasHousehold {
                OnboardingView()
            } else {
                ContentView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: appState.hasHousehold)
    }
}
```

**Step 2: Create ContentView.swift with custom tab bar**

Create `Chorin/App/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @State private var selectedTab: ChorinTab = .chores

    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Active tab content
                Group {
                    switch selectedTab {
                    case .chores:
                        NavigationStack { ChoreListView() }
                    case .earnings:
                        NavigationStack { EarningsView() }
                    case .savings:
                        NavigationStack { SavingsView() }
                    case .household:
                        NavigationStack { HouseholdView() }
                    }
                }
                .frame(maxHeight: .infinity)

                // Floating pill tab bar
                ChorinTabBar(selected: $selectedTab)
                    .padding(.bottom, 8)
            }
        }
    }
}
```

**Step 3: Create placeholder views for each tab** (so it compiles)

Create stub files that just show the tab name — one for each: `ChoreListView`, `EarningsView`, `SavingsView`, `HouseholdView`, `LoginView`, `OnboardingView`. Each file is just:

```swift
import SwiftUI

struct <ViewName>: View {
    var body: some View {
        ZStack {
            ChorinTheme.background.ignoresSafeArea()
            Text("<Tab Name>")
                .foregroundStyle(ChorinTheme.textPrimary)
        }
    }
}
```

Place them at:
- `Chorin/Features/Auth/LoginView.swift`
- `Chorin/Features/Auth/OnboardingView.swift`
- `Chorin/Features/Chores/ChoreListView.swift`
- `Chorin/Features/Earnings/EarningsView.swift`
- `Chorin/Features/Savings/SavingsView.swift`
- `Chorin/Features/Household/HouseholdView.swift`

**Step 4: Build and run on simulator**

```bash
xcodegen generate && xcodebuild -project Chorin.xcodeproj -scheme Chorin -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Verify: app launches with dark leather background and floating pill tab bar.

**Step 5: Commit**

```bash
git add Chorin/App/ Chorin/Features/ && git commit -m "feat: add root navigation with floating pill tab bar and placeholder views"
```

---

### Task 6: Auth — LoginView

**Files:**
- Modify: `Chorin/Features/Auth/LoginView.swift`

**Step 1: Implement LoginView with new design**

Replace `Chorin/Features/Auth/LoginView.swift`. Port logic from `Chorin/.old/Views/Auth/LoginView.swift` but use:
- `ChorinTheme` colors instead of `Theme`
- `ChorinButton` for sign-in/sign-up button
- `ChorinTextField` for email/password inputs
- Fraunces-style logo at top (use SF Rounded Bold italic as fallback): `Text("Chorin'").font(.system(size: 36, weight: .bold, design: .serif))`
- Coral primary color for accents
- Dark leather background

Key logic to port:
- `@Environment(AppState.self)` for auth state
- `supabase.auth.signUp(email:password:)` for sign up
- `supabase.auth.signIn(email:password:)` for sign in
- Toggle between sign-up and sign-in modes
- Error display
- Loading state on button

**Step 2: Build, run, test sign-in flow**

**Step 3: Commit**

```bash
git add Chorin/Features/Auth/LoginView.swift && git commit -m "feat: implement login view with dark leather + coral design"
```

---

### Task 7: Auth — OnboardingView

**Files:**
- Modify: `Chorin/Features/Auth/OnboardingView.swift`

**Step 1: Implement OnboardingView with new design**

Port logic from `Chorin/.old/Views/Sharing/OnboardingView.swift`:
- Create household flow (parent)
- Join household with invite code flow (child)
- Use `ChorinButton`, `ChorinTextField`, `ChorinCard`
- Dark leather background, coral accents
- Same Supabase RPCs: `create_household_with_parent`, `lookup_household_by_invite_code`

**Step 2: Build, run, test both flows**

**Step 3: Commit**

```bash
git add Chorin/Features/Auth/OnboardingView.swift && git commit -m "feat: implement onboarding — create/join household with new design"
```

---

### Task 8: Chores tab — ChoreListView + ChoreRowView

**Files:**
- Modify: `Chorin/Features/Chores/ChoreListView.swift`
- Create: `Chorin/Features/Chores/ChoreRowView.swift`

**Step 1: Implement ChoreRowView**

Port from `Chorin/.old/Views/ChoresTab/ChoreRowView.swift` with new design:
- Rounded checkbox (7px radius) — uses `ChorinTheme.success` when done
- Emoji icon in `tertiary` background rounded rect
- Chore name (strikethrough + muted when done)
- Value in `primary` coral
- Swipe actions for edit/delete (parent only) using `ChorinTheme.warning` and `ChorinTheme.danger`

**Step 2: Implement ChoreListView**

Port from `Chorin/.old/Views/ChoresTab/ChoreListView.swift` with new design:
- Top bar: logo left ("Chorin'" in serif italic, coral), profile avatar right
- Greeting: "Good morning/evening" in serif font
- Date: muted text
- Earnings pill: success green with soft background, rounded pill
- Chore list: `ChoreRowView` items in `ChorinCard` style
- Real-time subscription on `chore_completions` and `chores` tables
- Toggle completion via `toggle_chore_completion` RPC
- Same `get_todays_chores_for_current_user` RPC

**Step 3: Build, run, test chore completion flow**

**Step 4: Commit**

```bash
git add Chorin/Features/Chores/ && git commit -m "feat: implement chores tab with daily checklist and real-time sync"
```

---

### Task 9: Chores tab — ChoreFormView

**Files:**
- Create: `Chorin/Features/Chores/ChoreFormView.swift`

**Step 1: Implement ChoreFormView**

Port from `Chorin/.old/Views/ChoresTab/ChoreFormView.swift` with new design:
- Modal sheet presentation
- `ChorinTextField` for name input
- Decimal value input with coral prefix "$"
- Icon picker: `LazyVGrid` of emoji in `tertiary` background pills
- Selected icon highlighted with `primary` border
- `ChorinButton` primary for save
- Edit mode pre-fills existing chore data
- Same Supabase insert/update queries

**Step 2: Wire into ChoreListView — parent floating "+" button and edit swipe action**

**Step 3: Build, run, test add/edit chore**

**Step 4: Commit**

```bash
git add Chorin/Features/Chores/ && git commit -m "feat: add chore form with icon picker and create/edit flow"
```

---

### Task 10: Earnings tab — EarningsView

**Files:**
- Modify: `Chorin/Features/Earnings/EarningsView.swift`

**Step 1: Implement EarningsView**

Port from `Chorin/.old/Views/EarningsTab/EarningsView.swift` with new design:
- Earnings hero card: coral gradient (`primaryGradient`), dark text on coral
  - "This week's earnings" label + large amount
  - Breakdown: "To savings" and "To be paid" below divider
- "Daily Breakdown" section label (Outfit font style, muted, uppercase)
- Day rows: surface card with day name, progress bar (coral fill), amount
- Per-chore breakdown section
- Past 8 weeks: tappable cards linking to `WeekHistoryView`
- Uses `WeekHelper` for all date calculations
- Fetches `ChoreCompletionWithChore` from Supabase with chore join

**Step 2: Build, run, verify earnings display**

**Step 3: Commit**

```bash
git add Chorin/Features/Earnings/ && git commit -m "feat: implement earnings tab with weekly summary and daily breakdown"
```

---

### Task 11: Earnings tab — WeekHistoryView

**Files:**
- Create: `Chorin/Features/Earnings/WeekHistoryView.swift`

**Step 1: Implement WeekHistoryView**

Port from `Chorin/.old/Views/EarningsTab/WeekHistoryView.swift`:
- Same earnings card style as current week
- Daily breakdown by date
- Per-chore breakdown with completion counts
- Navigation back button
- Same data fetching pattern

**Step 2: Wire navigation from EarningsView past-week cards**

**Step 3: Build, run, test navigation to past weeks**

**Step 4: Commit**

```bash
git add Chorin/Features/Earnings/ && git commit -m "feat: add week history detail view for past earnings"
```

---

### Task 12: Savings tab — SavingsView + GoalCard

**Files:**
- Modify: `Chorin/Features/Savings/SavingsView.swift`

**Step 1: Implement SavingsView**

Port from `Chorin/.old/Views/SavingsTab/SavingsView.swift` with new design:
- "My Savings" heading (Outfit semibold)
- Goal cards: surface card with border
  - Emoji icon in tertiary rounded rect
  - Goal name (semibold, text primary)
  - "$saved of $target" with success-colored saved amount
  - Progress bar: coral-to-peach gradient fill (`progressGradient`)
- Real-time subscription on `savings_goals` and `savings_contributions`
- Floating "+" button for add goal (parent)
- Tap goal to contribute (child)

**Step 2: Build, run, verify savings display**

**Step 3: Commit**

```bash
git add Chorin/Features/Savings/ && git commit -m "feat: implement savings tab with goal cards and progress bars"
```

---

### Task 13: Savings tab — GoalFormView + ContributeFormView

**Files:**
- Create: `Chorin/Features/Savings/GoalFormView.swift`
- Create: `Chorin/Features/Savings/ContributeFormView.swift`

**Step 1: Implement GoalFormView**

Port from `Chorin/.old/Views/SavingsTab/GoalFormView.swift`:
- Name input, target amount, auto-save % slider (0-100, step 5)
- Icon picker (savings emoji set)
- `ChorinButton` save, `ChorinTextField` inputs
- Create/edit modes

**Step 2: Implement ContributeFormView**

Port from `Chorin/.old/Views/SavingsTab/ContributeFormView.swift`:
- Amount input (max = remaining to target)
- `ChorinButton` contribute
- Shows goal name and progress

**Step 3: Wire modals into SavingsView**

**Step 4: Build, run, test create goal and contribute**

**Step 5: Commit**

```bash
git add Chorin/Features/Savings/ && git commit -m "feat: add goal form and contribution flow for savings"
```

---

### Task 14: Household tab — HouseholdView

**Files:**
- Modify: `Chorin/Features/Household/HouseholdView.swift`

**Step 1: Implement HouseholdView**

Port from `Chorin/.old/Views/Sharing/SharingView.swift` with new design:
- Household name display
- Invite code: large monospace text with copy button (coral accent)
- Member list: avatar placeholder + name + role badge
- Sign out button: `ChorinButton` danger style
- Surface cards with borders for each section

**Step 2: Build, run, test invite code copy and sign out**

**Step 3: Commit**

```bash
git add Chorin/Features/Household/ && git commit -m "feat: implement household tab with invite code and member list"
```

---

### Task 15: Polish & final integration

**Files:**
- Potentially modify any view files for consistency

**Step 1: Run through full app flow on simulator**

Test each flow end-to-end:
1. Sign up → Create household → See chores (empty) → Add chore → Complete it
2. Earnings tab shows today's earnings
3. Savings tab → Create goal → Contribute
4. Household tab → Copy invite code → Sign out
5. Sign in with existing account → All data loads

**Step 2: Fix any visual inconsistencies**

Check all views match the design preview colors, spacing, and typography.

**Step 3: Remove .old directory reference from sources** (optional — .old is excluded by directory structure)

**Step 4: Final commit**

```bash
git add -A && git commit -m "polish: final integration pass — verify all flows and visual consistency"
```

---

## Dependency Order

```
Task 0 (scaffold)
  └─ Task 1 (theme)
       └─ Task 2 (components)
            └─ Task 3 (models)
                 └─ Task 4 (services)
                      └─ Task 5 (app entry + nav)
                           ├─ Task 6 (login)
                           ├─ Task 7 (onboarding)
                           ├─ Task 8 (chores list)
                           │    └─ Task 9 (chore form)
                           ├─ Task 10 (earnings)
                           │    └─ Task 11 (week history)
                           ├─ Task 12 (savings)
                           │    └─ Task 13 (goal/contribute forms)
                           └─ Task 14 (household)
                                └─ Task 15 (polish)
```

Tasks 6-14 can be done in any order after Task 5 is complete. Tasks 9, 11, 13 depend on their parent tab being done first.
