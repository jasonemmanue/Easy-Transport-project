import Sidebar from "./Sidebar";
import Topbar from "./Topbar";

export default function Shell({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <div className="flex-1 flex flex-col">
        <Topbar title={title} />
        <main className="flex-1 p-6 space-y-6">{children}</main>
      </div>
    </div>
  );
}
