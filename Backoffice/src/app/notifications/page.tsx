import Shell from "@/components/Shell";

export default function NotificationsPage() {
  return (
    <Shell title="Notifications push">
      <div className="card p-4 space-y-3">
        <h2 className="font-bold">Nouvelle notification</h2>
        <input className="w-full rounded-lg border border-slate-200 px-3 py-2" placeholder="Titre" />
        <textarea className="w-full rounded-lg border border-slate-200 px-3 py-2 h-24" placeholder="Contenu" />
        <div className="flex gap-2">
          {["Tous", "Passagers", "Drivers", "Copilotes", "Easy Flexible", "Easy Taxi"].map((t) => (
            <label key={t} className="flex items-center gap-1 text-sm border border-slate-200 rounded-lg px-2 py-1">
              <input type="checkbox" /> {t}
            </label>
          ))}
        </div>
        <button className="rounded-lg bg-brand-flexible text-white px-4 py-2 text-sm">Envoyer via Firebase FCM</button>
      </div>

      <div className="card p-4">
        <h2 className="font-bold mb-2">Historique des envois</h2>
        <ul className="text-sm space-y-2">
          <li className="flex justify-between border-b border-slate-100 py-1"><span>Promo pluie - 20% off Easy Taxi</span><span className="text-slate-500">Envoye 09:12 - 2 148 utilisateurs</span></li>
          <li className="flex justify-between border-b border-slate-100 py-1"><span>Maintenance servers 22h-23h</span><span className="text-slate-500">Hier - 3 240 utilisateurs</span></li>
          <li className="flex justify-between py-1"><span>Nouveau bouton Retour Maison</span><span className="text-slate-500">Il y a 3 j - 8 902 utilisateurs</span></li>
        </ul>
      </div>
    </Shell>
  );
}
