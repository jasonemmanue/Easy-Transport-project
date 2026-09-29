import Shell from "@/components/Shell";

export default function AnalyticsPage() {
  return (
    <Shell title="Analytics">
      <section className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {[
          { l: "Courses (mois)", v: "12 418" },
          { l: "Utilisateurs actifs", v: "34 210" },
          { l: "Chauffeurs actifs", v: "4 812" },
          { l: "Revenus commission (mois)", v: "58 900 000 XAF" },
        ].map((k) => (
          <div key={k.l} className="card p-4">
            <p className="text-xs text-slate-500">{k.l}</p>
            <p className="text-xl font-extrabold">{k.v}</p>
          </div>
        ))}
      </section>

      <div className="card p-4">
        <h2 className="font-bold mb-3">Courses par mode</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Bar label="Eco" value={42} color="bg-brand-eco" />
          <Bar label="Serenity" value={27} color="bg-brand-serenity" />
          <Bar label="Prestige" value={12} color="bg-brand-prestige" />
          <Bar label="Carlinq Taxi" value={19} color="bg-brand-taxi" />
        </div>
      </div>

      <div className="card p-4">
        <h2 className="font-bold mb-3">Heures de pointe</h2>
        <div className="flex gap-1 items-end h-40">
          {[20, 32, 45, 60, 80, 65, 40, 28, 55, 90, 88, 62, 40, 55, 78, 92, 72, 48, 30, 24, 18, 15, 12, 10].map((h, i) => (
            <div key={i} className="flex-1 bg-brand-flexible rounded-t" style={{ height: `${h}%` }} title={`${i}h : ${h}`} />
          ))}
        </div>
        <div className="flex justify-between text-[10px] text-slate-500 mt-1"><span>00h</span><span>12h</span><span>23h</span></div>
      </div>
    </Shell>
  );
}

function Bar({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div>
      <div className="flex justify-between text-xs mb-1"><span>{label}</span><span className="font-bold">{value}%</span></div>
      <div className="h-3 rounded-full bg-slate-100 overflow-hidden">
        <div className={`h-3 ${color}`} style={{ width: `${value}%` }} />
      </div>
    </div>
  );
}
