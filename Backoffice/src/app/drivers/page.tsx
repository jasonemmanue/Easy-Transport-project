import Shell from "@/components/Shell";
import { Car, Check, Ban } from "lucide-react";

const drivers = [
  { name: "Kevin Kamga", plate: "LT 8342", mode: "Easy Flexible", class: "Serenity", points: 82, rides: 612, status: "Actif" },
  { name: "Nadege Bikoro", plate: "CE 4210", mode: "Easy Taxi", class: "-", points: 74, rides: 421, status: "Actif" },
  { name: "Yves Sami", plate: "LT 9990", mode: "Easy Flexible", class: "Eco", points: 91, rides: 894, status: "Actif" },
  { name: "Prisca Longue", plate: "LT 1231", mode: "Easy Flexible", class: "Prestige", points: 18, rides: 45, status: "Suspendu" },
  { name: "Ekue Amougou", plate: "CE 5522", mode: "Easy Taxi", class: "-", points: 67, rides: 220, status: "Validation" },
];

export default function DriversPage() {
  return (
    <Shell title="Chauffeurs (Drivers)">
      <div className="card p-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <Car className="text-brand-flexible" />
            <h2 className="font-bold">Liste des chauffeurs Drivers</h2>
          </div>
          <div className="flex gap-2 text-sm">
            <button className="rounded-lg border border-slate-200 px-3 py-1.5">Filtrer</button>
            <button className="rounded-lg bg-brand-flexible text-white px-3 py-1.5">+ Ajouter</button>
          </div>
        </div>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-500">
              <th className="py-2">Chauffeur</th>
              <th>Immatriculation</th>
              <th>Mode / Classe</th>
              <th>Points</th>
              <th>Courses</th>
              <th>Statut</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {drivers.map((d) => (
              <tr key={d.plate} className="border-t border-slate-100">
                <td className="py-3 font-semibold">{d.name}</td>
                <td>{d.plate}</td>
                <td>{d.mode} - {d.class}</td>
                <td>
                  <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
                    d.points >= 70 ? "bg-green-100 text-green-700" :
                    d.points >= 40 ? "bg-yellow-100 text-yellow-700" :
                    "bg-red-100 text-red-700"
                  }`}>{d.points}/100</span>
                </td>
                <td>{d.rides}</td>
                <td>
                  <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
                    d.status === "Actif" ? "bg-green-100 text-green-700" :
                    d.status === "Suspendu" ? "bg-red-100 text-red-700" :
                    "bg-blue-100 text-blue-700"
                  }`}>{d.status}</span>
                </td>
                <td className="flex gap-2 py-3">
                  <button className="rounded-md border border-green-200 text-green-600 p-1"><Check size={14} /></button>
                  <button className="rounded-md border border-red-200 text-red-600 p-1"><Ban size={14} /></button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Shell>
  );
}
