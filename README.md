# Chorin'

A family chore-tracking app. Kids complete daily chores to earn allowance. Parents manage chores and savings goals. Both roles share household data in real time.

## Monorepo Structure

```
chorin/
├── Chorin/          # iOS app (SwiftUI + Supabase)
└── chorin-web/      # Web app (Next.js + Supabase)
```

Both apps share the same Supabase backend (Postgres + Auth + Realtime).

## Features

- **Parent** creates a household and gets a 6-character invite code
- **Child** joins by entering the code
- Daily chore checklist — check off chores to earn money
- Earnings tracked weekly with daily and per-chore breakdowns
- Savings goals with auto-save (% of each chore) and manual contributions
- Real-time sync between parent and child

---

## Web App (`chorin-web`)

Built with Next.js 16 (App Router), Tailwind CSS, and Supabase.

### Setup

1. Install dependencies:
   ```bash
   cd chorin-web
   npm install
   ```

2. Create `.env.local`:
   ```
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
   ```

3. Run the schema in Supabase SQL Editor (`supabase/schema.sql`), then apply migrations in order from `supabase/migrations/`.

4. Start the dev server:
   ```bash
   npm run dev
   ```

---

## iOS App (`Chorin`)

Built with SwiftUI and Supabase Swift SDK. Requires Xcode on macOS.

### Setup

1. Clone the repo and open `Chorin/` in Xcode (open the `.xcodeproj`).

2. Add the Supabase Swift package:
   - File > Add Package Dependencies
   - URL: `https://github.com/supabase/supabase-swift`
   - Add the `Supabase` product to the Chorin target

3. Remove the CloudKit capability:
   - Signing & Capabilities tab → delete the CloudKit entry

4. Add new files to the Xcode project navigator (drag from Finder):
   - `Utilities/AppState.swift`
   - `Models/HouseholdMember.swift`, `SavingsGoal.swift`, `SavingsContribution.swift`
   - `Views/Auth/LoginView.swift`
   - `Views/SavingsTab/SavingsView.swift`, `GoalFormView.swift`, `ContributeFormView.swift`

5. Fill in your Supabase credentials in `Utilities/CloudKitManager.swift`:
   ```swift
   private let supabaseURL = "https://your-project.supabase.co"
   private let supabaseAnonKey = "your-anon-key"
   ```

6. Build and run on Simulator or a device.

---

## Database

See `chorin-web/supabase/schema.sql` for the full schema. Migrations are in `chorin-web/supabase/migrations/` and must be applied in filename order via the Supabase SQL Editor.
