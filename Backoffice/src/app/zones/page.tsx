import Shell from "@/components/Shell";

const zones = [
  { name: "Akwa - Rue Joss", district: "Akwa", capacity: 8, active: 3, available: true },
  { name: "Bonapriso - Boulevard", district: "Bonapriso", capacity: 6, active: 5, available: true },
  { name: "Deido - Marche", district: "Deido", capacity: 12, active: 12, available: false },
  { name: "Bali - Hopital Laquintinie", district: "Bali", capacity: 4, active: 1, available: true },
];

export default function ZonesPage() {
  return (
    <Shell title="Zones Carlinq Taxi">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {zones.map((z) => (
          <div key={z.name} className="card p-4">
            <div className="flex justify-between items-center">
              <div>
                <h3 className="font-bold">{z.name}</h3>
                <p className="text-xs text-slate-500">Quartier {z.district}</p>
              </div>
              <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${z.available ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>
                {z.available ? "Disponible" : "Complete"}
              </span>
            </div>
            <div className="mt-3 h-24 rounded-lg bg-gradient-to-br from-blue-100 to-blue-200" />
            <div className="mt-3 text-sm flex justify-between">
              <span>Capacite : <b>{z.capacity}</b></span>
              <span>Actifs : <b>{z.active}</b></span>
            </div>
          </div>
        ))}
      </div>
    </Shell>
  );
}
