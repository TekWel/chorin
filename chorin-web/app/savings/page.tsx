"use client";

import { useEffect, useState, useCallback } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import GoalCard from "@/components/GoalCard";
import GoalForm from "@/components/GoalForm";
import ContributeForm from "@/components/ContributeForm";
import BottomNav from "@/components/BottomNav";

import Logo from "@/components/Logo";
import type { SavingsGoal, GoalWithProgress } from "@/lib/types";

export default function SavingsPage() {
  const [goals, setGoals] = useState<GoalWithProgress[]>([]);
  const [householdId, setHouseholdId] = useState<string | null>(null);
  const [userId, setUserId] = useState<string | null>(null);
  const [showGoalForm, setShowGoalForm] = useState(false);
  const [editingGoal, setEditingGoal] = useState<SavingsGoal | undefined>();
  const [contributingGoal, setContributingGoal] =
    useState<GoalWithProgress | null>(null);
  const [loading, setLoading] = useState(true);
  const supabase = createClient();
  const router = useRouter();

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

    setUserId(user.id);
    setHouseholdId(membership.household_id);

    const { data: goalsData } = await supabase
      .from("savings_goals")
      .select("*")
      .eq("household_id", membership.household_id)
      .eq("is_active", true)
      .order("created_at", { ascending: true });

    const goalIds = (goalsData ?? []).map((g) => g.id);
    let totalsByGoal = new Map<string, number>();

    if (goalIds.length > 0) {
      const { data: contribs } = await supabase
        .from("savings_contributions")
        .select("goal_id, amount")
        .in("goal_id", goalIds);

      (contribs ?? []).forEach((c) => {
        totalsByGoal.set(
          c.goal_id,
          (totalsByGoal.get(c.goal_id) ?? 0) + Number(c.amount)
        );
      });
    }

    const merged: GoalWithProgress[] = (goalsData ?? []).map((goal) => {
      const totalSaved = totalsByGoal.get(goal.id) ?? 0;
      const progressPercent = Math.min(
        100,
        goal.target_amount > 0 ? (totalSaved / goal.target_amount) * 100 : 0
      );
      return {
        ...goal,
        totalSaved,
        progressPercent,
        isComplete: totalSaved >= goal.target_amount,
      };
    });

    setGoals(merged);
    setLoading(false);
  }, [supabase, router]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  useEffect(() => {
    const channel = supabase
      .channel("savings-changes")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "savings_goals" },
        () => loadData()
      )
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "savings_contributions" },
        () => loadData()
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [supabase, loadData]);

  async function archiveGoal(goal: GoalWithProgress) {
    await supabase
      .from("savings_goals")
      .update({ is_active: false })
      .eq("id", goal.id);
    loadData();
  }

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
        <h1 className="text-lg font-semibold text-white mt-1">
          Savings Goals
        </h1>
      </div>

      {/* Goals list */}
      <div className="p-4 space-y-3">
        {goals.length === 0 ? (
          <div className="py-16 text-center text-gray-500">
            <div className="text-4xl mb-3">🎯</div>
            <p className="font-medium">No Savings Goals Yet</p>
            <p className="text-sm mt-1">Tap + to create your first goal</p>
          </div>
        ) : (
          goals.map((goal) => (
            <GoalCard
              key={goal.id}
              goal={goal}
              onContribute={setContributingGoal}
              onEdit={(g) => {
                setEditingGoal(g);
                setShowGoalForm(true);
              }}
              onArchive={archiveGoal}
            />
          ))
        )}
      </div>

      {/* Add Button */}
      <button
        onClick={() => {
          setEditingGoal(undefined);
          setShowGoalForm(true);
        }}
        className="fixed bottom-24 right-4 w-14 h-14 bg-blue-600 text-white rounded-full shadow-lg flex items-center justify-center text-2xl hover:bg-blue-700 active:scale-95 transition-all z-40"
      >
        +
      </button>

      {showGoalForm && householdId && userId && (
        <GoalForm
          householdId={householdId}
          userId={userId}
          goal={editingGoal}
          onClose={() => {
            setShowGoalForm(false);
            setEditingGoal(undefined);
          }}
          onSaved={loadData}
        />
      )}

      {contributingGoal && userId && (
        <ContributeForm
          goal={contributingGoal}
          userId={userId}
          onClose={() => setContributingGoal(null)}
          onSaved={() => {
            setContributingGoal(null);
            loadData();
          }}
        />
      )}

      <BottomNav />
    </div>
  );
}
