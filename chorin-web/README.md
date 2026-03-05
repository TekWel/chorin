# Chorin'

A chore-tracking web app that lets parents create chores with dollar values and kids check them off to earn their weekly allowance. Built with Next.js, Supabase, and Tailwind CSS.

## Features

- **Chore Checklist** — Daily list of chores with one-tap checkboxes
- **Earnings Tracking** — Weekly totals with daily and per-chore breakdowns
- **Multi-User** — Parent and child each have their own account; data syncs in real-time via Supabase
- **Household Sharing** — Parent creates a household and shares a 6-character invite code with the child
- **Auto Weekly Reset** — Checklists reset each Monday; earnings history is preserved
- **Dark Mode** — Dark theme by default

## Tech Stack

- **Framework**: [Next.js 16](https://nextjs.org/) (App Router, TypeScript)
- **Database & Auth**: [Supabase](https://supabase.com/) (Postgres, Auth, Realtime, RLS)
- **Styling**: [Tailwind CSS](https://tailwindcss.com/)
- **Font**: Pacifico (cursive logo) + Geist (body text)

## Getting Started

### Prerequisites

- Node.js 18+
- A [Supabase](https://supabase.com/) project

### Setup

1. **Clone the repo**

   ```bash
   git clone https://github.com/AlWelwell/chorin-web.git
   cd chorin-web
   npm install
   ```

2. **Create your Supabase project** at [supabase.com](https://supabase.com)

3. **Run the database schema** — copy the contents of `supabase/schema.sql` and paste it into the Supabase SQL Editor

4. **Fix the recursive RLS policy** — run this additional SQL in the Supabase SQL Editor:

   ```sql
   drop policy "Members can view household members" on household_members;

   create or replace function get_my_household_ids()
   returns setof uuid
   language sql
   security definer
   set search_path = ''
   as $$
     select household_id from public.household_members where user_id = auth.uid();
   $$;

   create policy "Members can view household members"
     on household_members for select
     using (household_id in (select get_my_household_ids()));
   ```

5. **Configure environment variables** — update `.env.local`:

   ```
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
   ```

6. **Run the dev server**

   ```bash
   npm run dev
   ```

7. **Open** [http://localhost:3000](http://localhost:3000)

### First Use

1. Sign up as the parent
2. Create a household (you'll get a 6-character invite code)
3. Share the invite code with your child
4. Child signs up and joins with the code
5. Add chores with dollar values
6. Child checks off completed chores daily

## Project Structure

```
chorin-web/
├── app/
│   ├── layout.tsx              # Root layout, fonts, dark mode
│   ├── page.tsx                # Landing redirect
│   ├── login/page.tsx          # Login / signup
│   ├── onboarding/page.tsx     # Create or join household
│   ├── chores/page.tsx         # Daily chore checklist
│   ├── earnings/page.tsx       # Weekly earnings summary
│   ├── earnings/[weekStart]/   # Past week detail
│   ├── household/page.tsx      # Manage household & invite code
│   └── auth/callback/route.ts  # OAuth callback
├── components/
│   ├── BottomNav.tsx           # Bottom tab bar (Chores / Earnings)
│   ├── Logo.tsx                # Cursive "Chorin'" logo
│   ├── ChoreRow.tsx            # Chore with checkbox
│   ├── ChoreForm.tsx           # Add/edit chore modal
│   ├── WeekSummaryCard.tsx     # Earnings total card
│   └── IconPicker.tsx          # Emoji icon selector
├── lib/
│   ├── supabase/               # Supabase client helpers
│   ├── week-helpers.ts         # Week boundary calculations
│   └── types.ts                # TypeScript types
├── supabase/
│   └── schema.sql              # Database schema + RLS policies
└── middleware.ts                # Auth route protection
```

## Database

Four tables with Row Level Security:

- **households** — family unit with invite code
- **household_members** — links users to households (parent/child roles)
- **chores** — chore definitions with name, dollar value, emoji icon
- **chore_completions** — records of completed chores with snapshotted earnings

See `supabase/schema.sql` for the full schema.

## License

MIT
