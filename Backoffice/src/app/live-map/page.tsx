import Shell from "@/components/Shell";

export default function LiveMapPage() {
  return (
    <Shell title="Carte en direct">
      <div className="card p-4">
        <div className="rounded-xl bg-gradient-to-br from-blue-100 to-slate-200 h-[560px] relative overflow-hidden">
          <div className="absolute inset-0 opacity-30 bg-[radial-gradient(circle_at_15%_20%,#fff,transparent),radial-gradient(circle_at_70%_60%,#fff,transparent)]" />
          <Pill className="left-6 top-8 bg-brand-flexible">Course active #1284 - Flexible/Serenity</Pill>
          <Pill className="left-40 top-24 bg-brand-taxi">Course #1287 - Carlinq Taxi</Pill>
          <Pill className="left-72 top-40 bg-brand-eco">Chauffeur libre #0421 - Eco</Pill>
          <Pill className="right-16 top-16 bg-brand-prestige">Chauffeur libre #0912 - Prestige</Pill>
          <Pill className="right-24 top-60 bg-brand-serenity">Course #1259 - Flexible</Pill>
          <Pill className="left-24 bottom-16 bg-brand-traffic">Zone embouteillage Akwa</Pill>
          <Pill className="right-40 bottom-24 bg-brand-stop">Zone Carlinq Taxi Bonapriso</Pill>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-3 mt-4 text-sm">
          <div className="rounded-lg border p-3"><b>126</b> courses en cours</div>
          <div className="rounded-lg border p-3"><b>412</b> chauffeurs disponibles</div>
          <div className="rounded-lg border p-3"><b>14</b> zones embouteillees</div>
          <div className="rounded-lg border p-3"><b>3</b> pauses arret contestees</div>
        </div>
      </div>
    </Shell>
  );
}

function Pill({ children, className }: { children: React.ReactNode; className: string }) {
  return (
    <div className={`absolute rounded-full text-white text-xs px-2 py-1 shadow ${className}`}>{children}</div>
  );
}
