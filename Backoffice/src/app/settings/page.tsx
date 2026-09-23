import Shell from "@/components/Shell";

export default function SettingsPage() {
  return (
    <Shell title="Parametres de la plateforme">
      <div className="card p-4">
        <h2 className="font-bold mb-3">Parametres generaux</h2>
        <div className="space-y-3 text-sm">
          <Setting label="Commission plateforme" value="8 %" />
          <Setting label="Solde minimum portefeuille passager" value="500 XAF" />
          <Setting label="Delai annulation gratuite" value="15 secondes" />
          <Setting label="Fenetre refus chauffeur (par jour)" value="10 min" />
          <Setting label="Cota mensuel Copilote (Pack Premium)" value="5 000 XAF/mois" />
          <Setting label="Deviation autorisee sur destination" value="10 %" />
        </div>
      </div>

      <div className="card p-4">
        <h2 className="font-bold mb-3">Roles admin</h2>
        <ul className="text-sm space-y-2">
          <li className="border-b border-slate-100 py-2 flex justify-between"><span>Emmanuel Saka - Super Admin</span><span className="text-green-600">Actif</span></li>
          <li className="border-b border-slate-100 py-2 flex justify-between"><span>Support 1 - Moderateur</span><span className="text-green-600">Actif</span></li>
          <li className="py-2 flex justify-between"><span>Finance - Lecture seule</span><span className="text-slate-500">Inactif</span></li>
        </ul>
      </div>
    </Shell>
  );
}

function Setting({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between border-b border-slate-100 py-2">
      <span className="text-slate-600">{label}</span>
      <input className="rounded-lg border border-slate-200 px-2 py-1 w-40 text-right" defaultValue={value} />
    </div>
  );
}
