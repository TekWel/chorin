# Chorin iOS App Redesign — Design Document

**Date:** 2026-03-03
**Status:** Approved
**Preview:** `docs/design-preview.html`

## Overview

Complete visual redesign of the Chorin iOS app (SwiftUI + Supabase) with a dark leather/wood-brown aesthetic and coral pastel accents. Same feature set, clean-slate view layer.

## Audience

- Primary users: tweens/teens (12+)
- Parents manage chores; kids complete them daily
- Aesthetic: modern, polished, warm — not childish

## Approach

**Clean Slate** — fresh SwiftUI views in `Chorin/`, referencing `.old/` for all business logic and Supabase queries. No changes to the backend or data models.

## Project Structure

```
Chorin/
├── App/                  # ChorinApp.swift, ContentView
├── Design/               # Theme.swift, reusable components
│   ├── Theme.swift       # Color system, typography, spacing
│   └── Components/       # Buttons, cards, inputs, nav bar
├── Features/
│   ├── Auth/             # LoginView, OnboardingView
│   ├── Chores/           # ChoreListView, ChoreRowView, ChoreFormView
│   ├── Earnings/         # EarningsView, WeekHistoryView
│   ├── Savings/          # SavingsView, GoalFormView, ContributeFormView
│   └── Household/        # HouseholdView (members, invite code, sign-out)
├── Models/               # Same data models from .old/
└── Services/             # AppState, SupabaseClient, WeekHelper
```

## Color System (Dark Mode Only)

| Role | Hex | Description |
|------|-----|-------------|
| Background | `#161110` | Deep dark leather brown |
| Surface | `#231C19` | Card/container background |
| Border | `#362B26` | Subtle warm brown borders |
| Tertiary | `#3A2A24` | Icon backgrounds, subtle fills |
| Primary | `#FF9080` | Coral — main action color |
| Primary Soft | `#FFAB9E` | Hover/lighter coral |
| Primary Pressed | `#E87868` | Pressed state |
| Secondary | `#FFC4B5` | Peach — secondary accent |
| Success | `#9FD4B2` | Sage green — completions, earnings |
| Warning | `#F5D49A` | Warm amber |
| Danger | `#F08080` | Muted rose — destructive actions |
| Text Primary | `#F5EAE4` | Warm off-white |
| Text Secondary | `#BFB0A8` | Warm medium gray |
| Text Muted | `#7A6C64` | Warm light gray |

## Typography

- **Logo/Display:** Fraunces (italic serif) — or SF Pro Rounded bold for native feel
- **Headings/Numbers:** Outfit (or SF Pro Rounded)
- **Body:** DM Sans (or SF Pro) — system default is fine
- **Currency:** Outfit weight 600

*Note: Web preview uses Google Fonts. iOS build will use SF Pro variants for native consistency, with Fraunces imported for the logo if desired.*

## Navigation

Floating pill-shaped bottom tab bar:
- 4 tabs: Chores, Earnings, Savings, Home
- Clean SVG/SF Symbol line icons
- Active tab: highlighted pill background with label text
- Inactive tabs: icon only, muted color
- Container: surface background with border, rounded pill shape

## Features (unchanged from current app)

1. **Authentication** — Email/password via Supabase Auth
2. **Onboarding** — Create household (parent) or join with invite code (child)
3. **Chores** — Daily checklist with emoji icons, completion toggle, real-time sync
4. **Earnings** — Weekly summary card, daily/per-chore breakdown, 8 weeks history
5. **Savings** — Goals with progress bars, auto-save %, manual contributions
6. **Household** — Member list, invite code, sign out

## Key Design Details

- Earnings card: coral gradient (`primary → primary-soft`), dark text
- Chore completion checkmarks: success green with dark checkmark
- Progress bars: coral-to-peach gradient
- Earned-today pill: success green with subtle green background
- Icon backgrounds: tertiary brown with emoji content
- All cards: surface background + border, 14-16px radius
- Shadows: minimal, warm-toned (`rgba(0,0,0,...)`)
- `.preferredColorScheme(.dark)` forced — dark mode only

## Backend

No changes. Same Supabase instance, same RPC functions, same real-time subscriptions, same RLS policies. Credentials in existing `CloudKitManager.swift` (to be renamed `SupabaseClient.swift`).
