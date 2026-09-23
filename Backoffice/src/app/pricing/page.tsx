import Shell from "@/components/Shell";

export default function PricingPage() {
  return (
    <Shell title="Tarifs & Supplements">
      <section className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="card p-4">
          <h2 className="font-bold mb-3">Supplement par arret</h2>
          <div className="space-y-2 text-sm">
            <Field label="1er arret intermediaire" placeholder="300 XAF" />
            <Field label="2e arret et suivants" placeholder="300 XAF" />
            <Field label="Arret impromptu (Pause Arret)" placeholder="500 XAF" />
            <Field label="Quota max arrets impromptus / course" placeholder="3" />
          </div>
        </div>

        <div className="card p-4">
          <h2 className="font-bold mb-3">Supplement embouteillage / emballage</h2>
          <div className="space-y-2 text-sm">
            <Field label="Tolerance initiale (min)" placeholder="2" />
            <Field label="Taux par minute (moderé)" placeholder="50 XAF/min" />
            <Field label="Taux par minute (severe)" placeholder="80 XAF/min" />
            <Field label="Seuil de vitesse (km/h)" placeholder="5" />
          </div>
        </div>

        <div className="card p-4">
          <h2 className="font-bold mb-3">Coefficient de classe (Easy Flexible)</h2>
          <div className="space-y-2 text-sm">
            <Field label="Eco" placeholder="x 1.0" />
            <Field label="Serenity" placeholder="x 1.3" />
            <Field label="Prestige" placeholder="x 1.7" />
          </div>
        </div>

        <div className="card p-4">
          <h2 className="font-bold mb-3">Supplement route degradee</h2>
          <div className="space-y-2 text-sm">
            <Field label="Route degradee partielle (< 50%)" placeholder="+5%" />
            <Field label="Route degradee majoritaire (> 50%)" placeholder="+10%" />
            <Field label="Piste / route non revelee" placeholder="+15%" />
          </div>
        </div>
      </section>

      <div className="flex justify-end gap-2">
        <button className="rounded-lg border border-slate-200 px-4 py-2 text-sm">Annuler</button>
        <button className="rounded-lg bg-brand-flexible text-white px-4 py-2 text-sm">Enregistrer</button>
      </div>
    </Shell>
  );
}

function Field({ label, placeholder }: { label: string; placeholder: string }) {
  return (
    <div className="flex items-center justify-between border-b border-slate-100 py-2">
      <span className="text-slate-600">{label}</span>
      <input className="rounded-lg border border-slate-200 px-2 py-1 w-32 text-right" placeholder={placeholder} />
    </div>
  );
}
