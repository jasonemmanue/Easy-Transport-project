import Shell from "@/components/Shell";

const roads = [
  { name: "Bonaberi - Rue 42", district: "Bonaberi", severity: "Majoritaire (+10%)", validated: true },
  { name: "Deido - Descente marche", district: "Deido", severity: "Partielle (+5%)", validated: true },
  { name: "Bepanda - Piste sud", district: "Bepanda", severity: "Piste (+15%)", validated: false },
];

export default function RoutesPage() {
  return (
    <Shell title="Routes degradees">
      <div className="card p-4">
        <p className="text-sm text-slate-500 mb-3">
          Base de donnees geographique des routes degradees. Signalements chauffeurs a valider.
        </p>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-500">
              <th className="py-2">Route</th><th>Quartier</th><th>Severite</th><th>Statut</th><th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {roads.map((r) => (
              <tr key={r.name} className="border-t border-slate-100">
                <td className="py-3 font-semibold">{r.name}</td>
                <td>{r.district}</td>
                <td>{r.severity}</td>
                <td>
                  <span className={`px-2 py-0.5 rounded-full text-xs ${r.validated ? "bg-green-100 text-green-700" : "bg-yellow-100 text-yellow-700"}`}>
                    {r.validated ? "Validee" : "Signalement en attente"}
                  </span>
                </td>
                <td className="py-3">
                  <button className="rounded-md border border-slate-200 px-2 py-1 text-xs mr-2">Voir</button>
                  <button className="rounded-md bg-brand-flexible text-white px-2 py-1 text-xs">Valider</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
