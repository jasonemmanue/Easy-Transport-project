import Shell from "@/components/Shell";
import { api, ApiError, Goal, GoalsConfig, mondayOf, Settlement, xaf } from "@/lib/api";

import { CloseWeekButton, SettleButton } from "./GoalActions";

export const dynamic = "force-dynamic";

const STATUS: Record<string, { label: string; cls: string }> = {
  active: { label: "En cours", cls: "bg-blue-100 text-blue-700" },
  paused: { label: "En pause", cls: "bg-slate-100 text-slate-600" },
  achieved: { label: "Atteint", cls: "bg-green-100 text-green-700" },
  settled: { label: "Verse", cls: "bg-emerald-100 text-emerald-800" },
  failed: { label: "Echoue", cls: "bg-red-100 text-red-700" },
  pending: { label: "En attente", cls: "bg-yellow-100 text-yellow-700" },
  accepted: { label: "Accepte", cls: "bg-green-100 text-green-700" },
  declined: { label: "Refuse", cls: "bg-slate-100 text-slate-600" },
  cancelled: { label: "Annule", cls: "bg-slate-100 text-slate-500" },
};

function Badge({ status }: { status: string }) {
  const s = STATUS[status] ?? { label: status, cls: "bg-slate-100" };
  return <span className={`px-2 py-0.5 rounded-full text-xs ${s.cls}`}>{s.label}</span>;
}

function previousMonday(week: string): string {
  const d = new Date(`${week}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() - 7);
  return d.toISOString().slice(0, 10);
}

export default async function GoalsPage({ searchParams }: { searchParams: { week?: string } }) {
  const week = searchParams.week ?? mondayOf();
  let data: { config: GoalsConfig; goals: Goal[]; settlements: Settlement[] } | null = null;
  let error: string | null = null;
  try {
    const [config, goals, settlements] = await Promise.all([
      api.get<GoalsConfig>("/admin/settings/goals"),
      api.get<Goal[]>(`/admin/goals?week=${week}`),
      api.get<Settlement[]>(`/admin/goals/settlements?week=${week}`),
    ]);
    data = { config, goals, settlements };
  } catch (e) {
    error = e instanceof ApiError ? `${e.code} : ${e.message}` : "API Carlinq injoignable";
  }

  return (
    <Shell title="Objectifs & partages">
      {error || !data ? (
        <div className="card p-4 text-sm">
          <p className="font-semibold text-red-600">Impossible de charger les donnees ({error}).</p>
          <p className="text-slate-500 mt-1">
            Demarrez l&apos;API : <code>cd API &amp;&amp; docker compose up -d</code> (http://localhost:8010).
          </p>
        </div>
      ) : (
        <GoalsView week={week} {...data} />
      )}
    </Shell>
  );
}

function GoalsView({ week, config, goals, settlements }: {
  week: string; config: GoalsConfig; goals: Goal[]; settlements: Settlement[];
}) {
  const shared = goals.filter((g) => g.shares.some((s) => s.status === "accepted"));
  const toPay = goals.filter((g) => g.status === "achieved").reduce((s, g) => s + g.bonus_xaf, 0);
  const sharedPaid = settlements.reduce((s, x) => s + x.shared_total_xaf, 0);

  return (
    <>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2 text-sm">
          <a className="rounded-md border px-2 py-1" href={`/goals?week=${previousMonday(week)}`}>&larr; Semaine precedente</a>
          <span className="font-semibold">Semaine du {week}</span>
          <a className="rounded-md border px-2 py-1" href="/goals">Semaine en cours</a>
        </div>
        <CloseWeekButton week={week} />
      </div>

      <div className="grid gap-4 md:grid-cols-4">
        {[
          ["Objectifs fixes", String(goals.length)],
          ["Objectifs partages actifs", String(shared.length)],
          ["Bonus a verser", xaf(toPay)],
          ["Deja reparti aux aidants", xaf(sharedPaid)],
        ].map(([label, value]) => (
          <div key={label} className="card p-4">
            <p className="text-xs text-slate-500">{label}</p>
            <p className="text-xl font-extrabold">{value}</p>
          </div>
        ))}
      </div>

      <div className="card p-4">
        <h2 className="font-bold mb-2">Regles en vigueur</h2>
        <div className="grid md:grid-cols-2 gap-4 text-sm">
          <div>
            <p className="text-slate-500 mb-1">Paliers de bonus</p>
            <ul className="space-y-1">
              {config.tiers.map((t) => (
                <li key={t.target_rides}>{t.target_rides} courses &rarr; <b>{xaf(t.bonus_xaf)}</b></li>
              ))}
            </ul>
            <p className="mt-2 text-slate-500">
              +{config.points_on_achieved} points si atteint · pause {config.pause_max_hours} h max · reprise {config.grace_days} jours
            </p>
          </div>
          <div>
            <p className="text-slate-500 mb-1">Partage d&apos;objectif {config.sharing.enabled ? "(active)" : "(desactive)"}</p>
            <ul className="space-y-1">
              <li>Aidants : chauffeurs ayant <b>atteint</b> leur objectif, {config.sharing.max_helpers} max</li>
              <li>Part par aidant : {config.sharing.min_percent} a {config.sharing.max_percent_per_helper} %</li>
              <li>Total cede au maximum : {config.sharing.max_total_percent} % du bonus</li>
              <li>Aidant sans course apportee : rien, sa part reste au proprietaire</li>
            </ul>
            <p className="mt-2 text-xs text-slate-400">Modifiable via PUT /api/v1/admin/settings/goals (journalise).</p>
          </div>
        </div>
      </div>

      <div className="card p-4 overflow-x-auto">
        <h2 className="font-bold mb-2">Objectifs de la semaine</h2>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-500">
              <th className="py-2">Chauffeur</th><th>Progression</th><th>Bonus</th><th>Aidants</th>
              <th>Repartition prevue</th><th>Statut</th><th></th>
            </tr>
          </thead>
          <tbody>
            {goals.length === 0 && (
              <tr><td colSpan={7} className="py-4 text-slate-500">Aucun objectif cette semaine.</td></tr>
            )}
            {goals.map((g) => (
              <tr key={g.id} className="border-t border-slate-100 align-top">
                <td className="py-2 font-semibold">{g.driver_name}</td>
                <td>
                  {g.progress_rides} / {g.target_rides}
                  {g.shared_rides > 0 && <span className="text-orange-600"> (dont {g.shared_rides} aidants)</span>}
                </td>
                <td>{xaf(g.bonus_xaf)}</td>
                <td className="space-y-1">
                  {g.shares.length === 0 ? <span className="text-slate-400">-</span> : g.shares.map((s) => (
                    <div key={s.id} className="flex items-center gap-2">
                      <span>{s.helper_name} · {s.percent} % · {s.contributed_rides} course(s)</span>
                      <Badge status={s.status} />
                    </div>
                  ))}
                </td>
                <td className="space-y-0.5">
                  {g.projected_split.map((l) => (
                    <div key={l.driver_id}>
                      {l.role === "owner" ? "Proprietaire" : l.driver_name} : <b>{xaf(l.amount_xaf)}</b>
                    </div>
                  ))}
                </td>
                <td><Badge status={g.status} /></td>
                <td>{g.status === "achieved" && <SettleButton goalId={g.id} />}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="card p-4 overflow-x-auto">
        <h2 className="font-bold mb-2">Versements effectues</h2>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-500">
              <th className="py-2">Objectif</th><th>Bonus</th><th>Deduit (aidants)</th><th>Net proprietaire</th><th>Credits portefeuille</th>
            </tr>
          </thead>
          <tbody>
            {settlements.length === 0 && (
              <tr><td colSpan={5} className="py-4 text-slate-500">Aucun versement pour cette semaine.</td></tr>
            )}
            {settlements.map((s) => (
              <tr key={s.id} className="border-t border-slate-100 align-top">
                <td className="py-2">#{s.goal_id}</td>
                <td>{xaf(s.bonus_xaf)}</td>
                <td className="text-orange-600">-{xaf(s.shared_total_xaf)}</td>
                <td className="font-semibold">{xaf(s.owner_net_xaf)}</td>
                <td>
                  {s.lines.map((l) => (
                    <div key={l.driver_id}>{l.driver_name} ({l.role === "owner" ? "proprietaire" : "aidant"}, {l.percent} %) : {xaf(l.amount_xaf)}</div>
                  ))}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
