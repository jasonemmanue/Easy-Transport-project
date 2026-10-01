"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";

async function run(body: object): Promise<string> {
  const res = await fetch("/api/goals", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = await res.json();
  if (!res.ok) return `Erreur : ${data?.error?.message ?? res.statusText}`;
  if ("settled" in data) {
    return `Semaine cloturee : ${data.settled.length} versement(s), ${data.failed.length} objectif(s) echoue(s), ${data.in_grace_period.length} en reprise.`;
  }
  return `Versement effectue : ${data.bonus_xaf} XAF (dont ${data.shared_total_xaf} XAF partages).`;
}

export function CloseWeekButton({ week }: { week: string }) {
  const router = useRouter();
  const [pending, start] = useTransition();
  const [msg, setMsg] = useState<string | null>(null);
  return (
    <div className="flex items-center gap-3">
      <button
        disabled={pending}
        onClick={() =>
          start(async () => {
            if (!confirm(`Cloturer la semaine du ${week} ? Les bonus seront verses et repartis.`)) return;
            setMsg(await run({ action: "close-week", week_start: week }));
            router.refresh();
          })
        }
        className="rounded-lg bg-brand-flexible text-white px-3 py-2 text-sm font-semibold disabled:opacity-50"
      >
        {pending ? "Cloture..." : "Cloturer la semaine et verser"}
      </button>
      {msg && <span className="text-sm text-slate-600">{msg}</span>}
    </div>
  );
}

export function SettleButton({ goalId }: { goalId: number }) {
  const router = useRouter();
  const [pending, start] = useTransition();
  return (
    <button
      disabled={pending}
      onClick={() =>
        start(async () => {
          alert(await run({ action: "settle", goal_id: goalId }));
          router.refresh();
        })
      }
      className="rounded-md bg-green-600 text-white px-2 py-1 text-xs disabled:opacity-50"
    >
      Verser
    </button>
  );
}
