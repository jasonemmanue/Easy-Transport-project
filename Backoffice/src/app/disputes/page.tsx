import Shell from "@/components/Shell";

const cases = [
  { id: "#4519", ride: "Course #1284", driver: "Kevin K.", passenger: "Aline P.", duration: "01:47", supplement: "150 XAF", status: "En arbitrage" },
  { id: "#4521", ride: "Course #1259", driver: "Nadege B.", passenger: "Yves S.", duration: "03:12", supplement: "300 XAF", status: "Passager conteste" },
  { id: "#4530", ride: "Course #1301", driver: "Yves S.", passenger: "Prisca L.", duration: "00:52", supplement: "80 XAF", status: "Nouveau" },
];

export default function DisputesPage() {
  return (
    <Shell title="Litiges Pause Arret">
      <div className="card p-4">
        <p className="text-sm text-slate-500 mb-3">
          Arbitrez les Pauses Arret contestees en consultant les logs GPS et le chronometre.
        </p>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-500">
              <th className="py-2">#</th><th>Course</th><th>Chauffeur</th><th>Passager</th><th>Duree</th><th>Supplement</th><th>Statut</th><th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {cases.map((c) => (
              <tr key={c.id} className="border-t border-slate-100">
                <td className="py-2 font-semibold">{c.id}</td>
                <td>{c.ride}</td>
                <td>{c.driver}</td>
                <td>{c.passenger}</td>
                <td>{c.duration}</td>
                <td>{c.supplement}</td>
                <td><span className="px-2 py-0.5 rounded-full bg-yellow-100 text-yellow-700 text-xs">{c.status}</span></td>
                <td className="flex gap-2 py-2">
                  <button className="rounded-md bg-green-500 text-white px-2 py-1 text-xs">Valider</button>
                  <button className="rounded-md bg-red-500 text-white px-2 py-1 text-xs">Rejeter</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
