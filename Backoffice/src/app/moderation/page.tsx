import Shell from "@/components/Shell";

export default function ModerationPage() {
  return (
    <Shell title="Moderation">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="card p-4">
          <h2 className="font-bold mb-2">Signalements passagers</h2>
          <ul className="text-sm space-y-2">
            <li className="flex justify-between border-b border-slate-100 py-2"><span>Prisca L. - 3 plaintes chauffeurs</span><button className="rounded-md bg-red-500 text-white px-2 py-1 text-xs">Suspendre 48h</button></li>
            <li className="flex justify-between border-b border-slate-100 py-2"><span>Yves S. - 1 plainte insultes</span><button className="rounded-md border border-slate-200 px-2 py-1 text-xs">Voir</button></li>
          </ul>
        </div>
        <div className="card p-4">
          <h2 className="font-bold mb-2">Notations litigieuses</h2>
          <ul className="text-sm space-y-2">
            <li className="flex justify-between border-b border-slate-100 py-2"><span>Course #1284 - 1 etoile chauffeur</span><button className="rounded-md border border-slate-200 px-2 py-1 text-xs">Arbitrer</button></li>
            <li className="flex justify-between py-2"><span>Course #1259 - 2 etoiles passager</span><button className="rounded-md border border-slate-200 px-2 py-1 text-xs">Arbitrer</button></li>
          </ul>
        </div>
      </div>
    </Shell>
  );
}
