import Shell from "@/components/Shell";
import { ShieldCheck, Building2 } from "lucide-react";

const copilotes = [
  { name: "Douala Move SARL", type: "Societe de transport", fleet: 24, subscription: "Pack Premium", status: "Actif", nextBill: "15/10/2026" },
  { name: "Kribi Wheels", type: "Flotte VTC", fleet: 12, subscription: "Pack Premium", status: "Actif", nextBill: "22/10/2026" },
  { name: "Alain Nkolo", type: "Chauffeur independant", fleet: 1, subscription: "Standard", status: "Actif", nextBill: "05/10/2026" },
  { name: "Cameroun Transit", type: "Societe de transport", fleet: 60, subscription: "Pack Premium", status: "Renouvellement en attente", nextBill: "-" },
];

export default function CopilotesPage() {
  return (
    <Shell title="Copilote - Chauffeurs independants & societes">
      <section className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card icon={ShieldCheck} label="Comptes actifs" value="128" />
        <Card icon={Building2} label="Societes enregistrees" value="27" />
        <Card icon={ShieldCheck} label="Revenus abonnements (mois)" value="1 480 000 XAF" />
      </section>

      <div className="card p-4">
        <h2 className="font-bold mb-3">Copilotes enregistres</h2>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-500">
              <th className="py-2">Entite</th><th>Type</th><th>Flotte</th><th>Abonnement</th><th>Prochain prelevement</th><th>Statut</th>
            </tr>
          </thead>
          <tbody>
            {copilotes.map((c) => (
              <tr key={c.name} className="border-t border-slate-100">
                <td className="py-3 font-semibold">{c.name}</td>
                <td>{c.type}</td>
                <td>{c.fleet} vehicule(s)</td>
                <td>{c.subscription}</td>
                <td>{c.nextBill}</td>
                <td><span className="px-2 py-0.5 rounded-full bg-orange-100 text-orange-700 text-xs">{c.status}</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}

function Card({ icon: Icon, label, value }: { icon: any; label: string; value: string }) {
  return (
    <div className="card p-4 flex items-center gap-3">
      <div className="w-11 h-11 rounded-xl bg-brand-taxi text-white flex items-center justify-center"><Icon size={20} /></div>
      <div>
        <p className="text-xs text-slate-500">{label}</p>
        <p className="text-xl font-extrabold">{value}</p>
      </div>
    </div>
  );
}
