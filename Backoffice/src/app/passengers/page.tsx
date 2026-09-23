import Shell from "@/components/Shell";

const users = [
  { name: "Aline Poko", phone: "+237 693 22 11 00", wallet: 3200, rides: 42, complaints: 0, status: "Actif" },
  { name: "Yves Sami", phone: "+237 674 65 43 21", wallet: 1500, rides: 19, complaints: 1, status: "Actif" },
  { name: "Prisca Longue", phone: "+237 691 33 22 44", wallet: 500, rides: 8, complaints: 3, status: "Suspendu 48h" },
];

export default function PassengersPage() {
  return (
    <Shell title="Passagers">
      <div className="card p-4">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-500">
              <th className="py-2">Passager</th><th>Telephone</th><th>Portefeuille</th><th>Courses</th><th>Plaintes</th><th>Statut</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.name} className="border-t border-slate-100">
                <td className="py-3 font-semibold">{u.name}</td>
                <td>{u.phone}</td>
                <td>{u.wallet} XAF</td>
                <td>{u.rides}</td>
                <td>{u.complaints}</td>
                <td><span className={`px-2 py-0.5 rounded-full text-xs ${u.status === "Actif" ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>{u.status}</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
