import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Carlinq - Admin",
  description: "Panneau d'administration Carlinq (Carlinq Flexible + Carlinq Taxi).",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <body>{children}</body>
    </html>
  );
}
