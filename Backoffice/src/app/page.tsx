import Shell from "@/components/Shell";
import {
  Users, Car, MapPin, AlertTriangle, TrendingUp, Wallet,
  Percent, Route, Clock, Bell
} from "lucide-react";

const kpis = [
  { label: "Courses actives", value: "126", icon: Route, tint: "bg-brand-flexible text-white" },
  { label: "Chauffeurs en ligne", value: "412", icon: Car, tint: "bg-brand-eco text-white" },
  { label: "Passagers actifs", value: "2 148", icon: Users, tint: "bg-brand-serenity text-white" },
  { label: "Revenus jour", value: "1 240 000 XAF", icon: Wallet, tint: "bg-brand-prestige text-white" },
];

export default function Dashboard() {
  return (
    <Shell title="Tableau de bord">
      <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {kpis.map((k) => {
          const I = k.icon;
          return (
            <div key={k.label} className="card p-4 flex items-center gap-3">
              <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${k.tint}`}>
                <I size={20} />
              </div>
              <div>
                <p className="text-xs text-slate-500">{k.label}</p>
                <p className="text-xl font-extrabold">{k.value}</p>
              </div>
            </div>
          );
        })}
      </section>

      <section className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="card p-4 lg:col-span-2">
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-bold">Carte en direct - courses actives</h2>
            <span className="text-xs text-slate-500">Mise a jour temps reel</span>
          </div>
          <div className="rounded-xl bg-gradient-to-br from-blue-100 to-blue-200 h-72 relative overflow-hidden">
            <div className="absolute inset-0 opacity-40 bg-[radial-gradient(circle_at_20%_30%,#fff,transparent),radial-gradient(circle_at_70%_60%,#fff,transparent),radial-gradient(circle_at_40%_80%,#fff,transparent)]" />
            <div className="absolute left-8 top-10 rounded-full bg-brand-flexible text-white text-[10px] px-2 py-1">
              Course #1284 - Flexible
            </div>
            <div className="absolute right-16 top-24 rounded-full bg-brand-taxi text-white text-[10px] px-2 py-1">
              Course #1287 - Taxi
            </div>
            <div className="absolute left-40 bottom-14 rounded-full bg-brand-eco text-white text-[10px] px-2 py-1">
              Chauffeur libre - Eco
            </div>
            <div className="absolute right-24 bottom-6 rounded-full bg-brand-traffic text-white text-[10px] px-2 py-1">
              Zone embouteillage
            </div>
          </div>
        </div>

        <div className="card p-4">
          <h2 className="font-bold mb-3">Repartition mode / classe</h2>
          <ul className="space-y-3 text-sm">
            <Row label="Easy Flexible - Eco" value="42%" color="bg-brand-eco" />
            <Row label="Easy Flexible - Serenity" value="27%" color="bg-brand-serenity" />
            <Row label="Easy Flexible - Prestige" value="12%" color="bg-brand-prestige" />
            <Row label="Easy Taxi" value="19%" color="bg-brand-taxi" />
          </ul>
          <div className="mt-6">
            <h3 className="font-bold text-sm mb-2">Alertes en cours</h3>
            <div className="rounded-lg border border-orange-200 bg-orange-50 p-2 text-xs flex items-center gap-2">
              <AlertTriangle size={14} className="text-orange-500" />
              3 Pauses Arret contestees a arbitrer.
            </div>
            <div className="rounded-lg border border-red-200 bg-red-50 p-2 text-xs mt-2 flex items-center gap-2">
              <Bell size={14} className="text-red-500" />
              Un chauffeur au dessous de 20 points.
            </div>
          </div>
        </div>
      </section>

      <section className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MiniStat label="Commission (jour)" value="99 200 XAF" icon={Percent} />
        <MiniStat label="Duree moyenne course" value="18 min" icon={Clock} />
        <MiniStat label="Trafic detecte" value="14 zones" icon={TrendingUp} />
      </section>

      <section className="card p-4">
        <h2 className="font-bold mb-3">Derniers evenements</h2>
        <ul className="text-sm space-y-2">
          <li className="flex justify-between border-b border-slate-100 py-1"><span>Nouvelle inscription Copilote (Societe Kribi Move)</span><span className="text-slate-500">il y a 3 min</span></li>
          <li className="flex justify-between border-b border-slate-100 py-1"><span>Litige Pause Arret #4519 signale</span><span className="text-slate-500">il y a 12 min</span></li>
          <li className="flex justify-between border-b border-slate-100 py-1"><span>Validation documents - Kevin K.</span><span className="text-slate-500">il y a 21 min</span></li>
          <li className="flex justify-between py-1"><span>Route degradee signalee - Bonaberi</span><span className="text-slate-500">il y a 34 min</span></li>
        </ul>
      </section>
    </Shell>
  );
}

function Row({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <li>
      <div className="flex justify-between text-xs mb-1">
        <span>{label}</span>
        <span className="font-bold">{value}</span>
      </div>
      <div className="h-2 rounded-full bg-slate-100 overflow-hidden">
        <div className={`h-2 ${color}`} style={{ width: value }} />
      </div>
    </li>
  );
}

function MiniStat({ label, value, icon: Icon }: { label: string; value: string; icon: any }) {
  return (
    <div className="card p-4 flex items-center gap-3">
      <div className="w-10 h-10 rounded-lg bg-brand-flexible/10 text-brand-flexible flex items-center justify-center"><Icon size={18} /></div>
      <div>
        <p className="text-xs text-slate-500">{label}</p>
        <p className="text-lg font-extrabold">{value}</p>
      </div>
    </div>
  );
}
