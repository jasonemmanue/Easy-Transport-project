"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard, Map, Users, Car, MapPin, Route, DollarSign,
  Bell, AlertTriangle, BarChart2, Settings, ShieldCheck, MessageSquareWarning, Handshake
} from "lucide-react";

const nav = [
  { href: "/", label: "Tableau de bord", icon: LayoutDashboard },
  { href: "/live-map", label: "Carte en direct", icon: Map },
  { href: "/drivers", label: "Chauffeurs (Drivers)", icon: Car },
  { href: "/copilotes", label: "Copilote (societes)", icon: ShieldCheck },
  { href: "/passengers", label: "Passagers", icon: Users },
  { href: "/zones", label: "Zones Carlinq Taxi", icon: MapPin },
  { href: "/routes", label: "Routes degradees", icon: Route },
  { href: "/pricing", label: "Tarifs & Supplements", icon: DollarSign },
  { href: "/goals", label: "Objectifs & partages", icon: Handshake },
  { href: "/disputes", label: "Litiges Pause Arret", icon: MessageSquareWarning },
  { href: "/notifications", label: "Notifications push", icon: Bell },
  { href: "/moderation", label: "Moderation", icon: AlertTriangle },
  { href: "/analytics", label: "Analytics", icon: BarChart2 },
  { href: "/settings", label: "Parametres", icon: Settings },
];

export default function Sidebar() {
  const pathname = usePathname();
  return (
    <aside className="w-64 border-r border-slate-200 bg-white min-h-screen p-4 hidden md:block">
      <div className="flex items-center gap-2 mb-6">
        <div className="w-9 h-9 rounded-lg bg-brand-flexible flex items-center justify-center text-white font-bold">E</div>
        <div>
          <p className="font-extrabold">Carlinq</p>
          <p className="text-[11px] text-slate-500">Panneau administrateur</p>
        </div>
      </div>
      <nav className="space-y-1">
        {nav.map((it) => {
          const Icon = it.icon;
          const active = pathname === it.href;
          return (
            <Link
              key={it.href}
              href={it.href}
              className={`flex items-center gap-2 rounded-lg px-3 py-2 text-sm transition ${
                active
                  ? "bg-brand-flexible text-white font-semibold"
                  : "text-slate-700 hover:bg-slate-100"
              }`}
            >
              <Icon size={16} />
              {it.label}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
