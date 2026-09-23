"use client";
import { Bell, Search, User } from "lucide-react";

export default function Topbar({ title }: { title: string }) {
  return (
    <header className="flex items-center justify-between border-b border-slate-200 bg-white px-6 py-3">
      <h1 className="text-lg font-bold">{title}</h1>
      <div className="flex items-center gap-3">
        <div className="hidden md:flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 px-3 py-1.5 text-sm w-72">
          <Search size={14} />
          <input className="bg-transparent outline-none flex-1" placeholder="Rechercher..." />
        </div>
        <button className="rounded-full p-2 hover:bg-slate-100 relative">
          <Bell size={18} />
          <span className="absolute -top-0.5 -right-0.5 w-2 h-2 rounded-full bg-red-500" />
        </button>
        <div className="flex items-center gap-2 rounded-full border border-slate-200 py-1 pr-3 pl-1">
          <div className="w-7 h-7 rounded-full bg-brand-flexible text-white flex items-center justify-center">
            <User size={14} />
          </div>
          <span className="text-sm">Admin</span>
        </div>
      </div>
    </header>
  );
}
