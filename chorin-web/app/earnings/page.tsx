"use client";

import { useEffect, useState, useCallback } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import Link from "next/link";
import {
  weekRange,
  weekLabel,
  pastWeekStarts,
  formatDate,
  formatCurrency,
} from "@/lib/week-helpers";
import WeekSummaryCard from "@/components/WeekSummaryCard";
import BottomNav from "@/components/BottomNav";

import Logo from "@/components/Logo";
import type { ChoreCompletion, Chore } from "@/lib/types";

export default function EarningsPage() {
  const [completions, setCompletions] = useState<ChoreCompletion[]>([]);
  const [chores, setChores] = useState<Chore[]>([]);
  const [weekSavings, setWeekSavings] = useState(0);
  const [loading, setLoading] = useState(true);
  const supabase = createClient();
  const router = useRouter();

  const currentWeek = weekRange();

  const loadData = useCallback(async () => {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      router.push("/login");
      return;
    }

    const { data: membership } = await supabase
      .from("household_members")
      .select("household_id")
      .eq("user_id", user.id)
      .single();

    if (!membership) {
      router.push("/onboarding");
      return;
    }

    const { data: choresData } = await supabase
      .from("chores")
      .select("*")
      .eq("household_id", membership.household_id);

    setChores(choresData ?? []);

    const choreIds = (choresData ?? []).map((c) => c.id);
    if (choreIds.length > 0) {
      const { data: completionsData } = await supabase
        .from("chore_completions")
        .select("*")
        .in("chore_id", choreIds)
        .order("date", { ascending: true });

      setCompletions(completionsData ?? []);
    }

    // Fetch this week's savings contributions
    const { data: goalsData } = await supabase
      .from("savings_goals")
      .select("id")
      .eq("household_id", membership.household_id);

    const goalIds = (goalsData ?? []).map((g) => g.id);
    if (goalIds.length > 0) {
      const week = weekRange();
      const { data: contribs } = await supabase
        .from("savings_contributions")
        .select("amount, created_at")
        .in("goal_id", goalIds)
        .gte("created_at", week.start)
        .lte("created_at", week.end + "T23:59:59.999Z");

      const totalSaved = (contribs ?? []).reduce(
        (sum, c) => sum + Number(c.amount),
        0
      );
      setWeekSavings(totalSaved);
    } else {
      setWeekSavings(0);
    }

    setLoading(false);
  }, [supabase, router]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const currentWeekCompletions = completions.filter(
    (c) => c.date >= currentWeek.start && c.date <= currentWeek.end
  );

  const currentWeekTotal = currentWeekCompletions.reduce(
    (sum, c) => sum + Number(c.earned_amount),
    0
  );

  const dailyBreakdown = new Map<string, number>();
  currentWeekCompletions.forEach((c) => {
    dailyBreakdown.set(
      c.date,
      (dailyBreakdown.get(c.date) ?? 0) + Number(c.earned_amount)
    );
  });

  const choreBreakdown = chores
    .map((chore) => {
      const total = currentWeekCompletions
        .filter((c) => c.chore_id === chore.id)
        .reduce((sum, c) => sum + Number(c.earned_amount), 0);
      return { name: chore.name, total };
    })
    .filter((item) => item.total > 0)
    .sort((a, b) => b.total - a.total);

  const pastWeeks = pastWeekStarts(8).slice(1);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-950">
        <div className="text-gray-500">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-950 pb-20">
      {/* Header */}
      <div className="bg-gray-900 border-b border-gray-800 px-4 pt-6 pb-4">
        <Logo size="md" />
      </div>

      {/* This Week Total */}
      <div className="p-4">
        <WeekSummaryCard total={currentWeekTotal} />
        {currentWeekTotal > 0 && (
          <div className="bg-gray-900 rounded-xl border border-gray-800 mt-3 px-4 py-3 flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-400">To Be Paid</p>
              {weekSavings > 0 && (
                <p className="text-xs text-gray-500">
                  {formatCurrency(weekSavings)} going to savings
                </p>
              )}
            </div>
            <span className="text-xl font-bold text-green-400">
              {formatCurrency(currentWeekTotal - weekSavings)}
            </span>
          </div>
        )}
        <Link
          href={`/earnings/${currentWeek.start}`}
          className="block mt-3 text-sm text-center text-blue-400 hover:underline"
        >
          View and Manage This Week
        </Link>
      </div>

      {/* Daily Breakdown */}
      {dailyBreakdown.size > 0 && (
        <div className="bg-gray-900 mt-2">
          <h3 className="px-4 py-3 text-sm font-medium text-gray-400 uppercase tracking-wide">
            Daily Breakdown
          </h3>
          <div className="divide-y divide-gray-800">
            {Array.from(dailyBreakdown.entries())
              .sort(([a], [b]) => a.localeCompare(b))
              .map(([date, total]) => {
                const d = new Date(date + "T12:00:00");
                return (
                  <div
                    key={date}
                    className="px-4 py-3 flex justify-between items-center"
                  >
                    <span className="text-gray-300">
                      {new Intl.DateTimeFormat("en-US", {
                        weekday: "short",
                        month: "short",
                        day: "numeric",
                      }).format(d)}
                    </span>
                    <span className="text-green-400 font-medium">
                      {formatCurrency(total)}
                    </span>
                  </div>
                );
              })}
          </div>
        </div>
      )}

      {/* Per-Chore Breakdown */}
      {choreBreakdown.length > 0 && (
        <div className="bg-gray-900 mt-2">
          <h3 className="px-4 py-3 text-sm font-medium text-gray-400 uppercase tracking-wide">
            By Chore
          </h3>
          <div className="divide-y divide-gray-800">
            {choreBreakdown.map((item) => (
              <div
                key={item.name}
                className="px-4 py-3 flex justify-between items-center"
              >
                <span className="text-gray-300">{item.name}</span>
                <span className="text-gray-400">{formatCurrency(item.total)}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Past Weeks */}
      <div className="bg-gray-900 mt-2">
        <h3 className="px-4 py-3 text-sm font-medium text-gray-400 uppercase tracking-wide">
          Past Weeks
        </h3>
        <div className="divide-y divide-gray-800">
          {pastWeeks.map((weekStart) => {
            const range = weekRange(weekStart);
            const total = completions
              .filter(
                (c) => c.date >= range.start && c.date <= range.end
              )
              .reduce((sum, c) => sum + Number(c.earned_amount), 0);

            return (
              <Link
                key={formatDate(weekStart)}
                href={`/earnings/${formatDate(weekStart)}`}
                className="px-4 py-3 flex justify-between items-center hover:bg-gray-800"
              >
                <span className="text-gray-300">
                  {weekLabel(weekStart)}
                </span>
                <div className="flex items-center gap-2">
                  <span
                    className={`font-medium ${
                      total > 0 ? "text-green-400" : "text-gray-500"
                    }`}
                  >
                    {formatCurrency(total)}
                  </span>
                  <svg
                    className="w-4 h-4 text-gray-600"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth={2}
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                </div>
              </Link>
            );
          })}
        </div>
      </div>

      <BottomNav />
    </div>
  );
}
