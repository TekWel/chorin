"use client";

import { useEffect, useState, useCallback } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";
import { todayLabel, formatDate, formatCurrency } from "@/lib/week-helpers";
import ChoreRow from "@/components/ChoreRow";
import ChoreForm from "@/components/ChoreForm";
import BottomNav from "@/components/BottomNav";

import Logo from "@/components/Logo";
import type { Chore, ChoreWithCompletion } from "@/lib/types";

interface ChoreTodayRow {
  id: string;
  household_id: string;
  created_by_user_id?: string | null;
  name: string;
  value: number | string;
  icon: string;
  validation_status?: "pending" | "valid" | "invalid";
  validated_by_user_id?: string | null;
  validated_at?: string | null;
  is_active: boolean;
  created_at: string;
  completed_today: boolean;
  today_completion_id: string | null;
}

export default function ChoresPage() {
  const [chores, setChores] = useState<ChoreWithCompletion[]>([]);
  const [householdId, setHouseholdId] = useState<string | null>(null);
  const [memberRole, setMemberRole] = useState<"parent" | "child" | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [editingChore, setEditingChore] = useState<Chore | undefined>();
  const [actionError, setActionError] = useState("");
  const [loading, setLoading] = useState(true);
  const supabase = createClient();
  const router = useRouter();
  const today = formatDate(new Date());

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
      .select("household_id, role")
      .eq("user_id", user.id)
      .single();

    if (!membership) {
      router.push("/onboarding");
      return;
    }

    setHouseholdId(membership.household_id);
    setMemberRole(membership.role as "parent" | "child");

    const { data: choresData, error: choresError } = await supabase.rpc(
      "get_todays_chores_for_current_user",
      { p_date: today }
    );

    if (choresError) {
      setActionError(choresError.message);
      setLoading(false);
      return;
    }

    const merged: ChoreWithCompletion[] = ((choresData ?? []) as ChoreTodayRow[]).map(
      (chore) => ({
        id: chore.id,
        household_id: chore.household_id,
        created_by_user_id: chore.created_by_user_id ?? null,
        name: chore.name,
        value: Number(chore.value),
        icon: chore.icon,
        validation_status: chore.validation_status ?? "pending",
        validated_by_user_id: chore.validated_by_user_id ?? null,
        validated_at: chore.validated_at ?? null,
        is_active: chore.is_active,
        created_at: chore.created_at,
        completedToday: !!chore.completed_today,
        todayCompletionId: chore.today_completion_id ?? undefined,
      })
    );

    setChores(merged);
    setActionError("");
    setLoading(false);
  }, [supabase, router, today]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  useEffect(() => {
    const channel = supabase
      .channel("chore-completions-changes")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "chore_completions" },
        () => {
          loadData();
        }
      )
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "chores" },
        () => {
          loadData();
        }
      )
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "chore_assignments" },
        () => {
          loadData();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [supabase, loadData]);

  async function toggleChore(chore: ChoreWithCompletion) {
    if (chore.validation_status === "pending") {
      setActionError("This chore is pending approval.");
      return;
    }

    const { error } = await supabase.rpc("toggle_chore_completion", {
      p_chore_id: chore.id,
      p_date: today,
    });

    if (error) {
      setActionError(error.message);
      return;
    }

    setActionError("");
    loadData();
  }

  async function archiveChore(chore: ChoreWithCompletion) {
    const { error } = await supabase
      .from("chores")
      .update({ is_active: false })
      .eq("id", chore.id);

    if (error) {
      setActionError(error.message);
      return;
    }

    setActionError("");
    loadData();
  }

  const canManageChores = memberRole === "parent";
  const canCreateChores = memberRole === "parent" || memberRole === "child";

  const todayTotal = chores
    .filter((c) => c.completedToday)
    .reduce((sum, c) => sum + c.value, 0);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-950">
        <div className="text-gray-500">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-950 pb-20">
      <div className="bg-gray-900 border-b border-gray-800 px-4 pt-6 pb-4">
        <Logo size="md" />
        <div className="mt-1 text-sm text-gray-400">{todayLabel()}</div>
      </div>

      <div className="bg-gray-900 mt-2 divide-y divide-gray-800">
        {actionError && (
          <div className="px-4 py-3 text-sm bg-red-900/30 text-red-300 border-b border-red-900/50">
            {actionError}
          </div>
        )}

        {chores.length === 0 ? (
          <div className="py-16 text-center text-gray-500">
            <p className="font-medium">No Chores Yet</p>
            <p className="text-sm mt-1">
              {canManageChores
                ? "Tap + to add your first chore"
                : "Tap + to add one for parent approval"}
            </p>
          </div>
        ) : (
          chores.map((chore) => (
            <ChoreRow
              key={chore.id}
              chore={chore}
              onToggle={toggleChore}
              onEdit={(c) => {
                setEditingChore(c);
                setShowForm(true);
              }}
              onDelete={archiveChore}
              canManage={canManageChores}
              toggleDisabled={chore.validation_status === "pending"}
            />
          ))
        )}
      </div>

      {chores.length > 0 && (
        <div className="bg-gray-900 mt-2 px-4 py-3 flex items-center justify-between">
          <span className="font-medium text-gray-300">Today&apos;s Earnings</span>
          <span className="text-lg font-bold text-green-400">
            {formatCurrency(todayTotal)}
          </span>
        </div>
      )}

      {canCreateChores && (
        <button
          onClick={() => {
            setEditingChore(undefined);
            setShowForm(true);
          }}
          className="fixed bottom-24 right-4 w-14 h-14 bg-blue-600 text-white rounded-full shadow-lg flex items-center justify-center text-2xl hover:bg-blue-700 active:scale-95 transition-all z-40"
        >
          +
        </button>
      )}

      {canCreateChores && showForm && householdId && (
        <ChoreForm
          householdId={householdId}
          chore={editingChore}
          canApprove={canManageChores}
          onClose={() => {
            setShowForm(false);
            setEditingChore(undefined);
          }}
          onSaved={loadData}
        />
      )}

      <BottomNav />
    </div>
  );
}
