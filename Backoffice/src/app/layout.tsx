import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "EasyTransport - Admin",
  description: "Panneau d'administration EasyTransport (Easy Flexible + Easy Taxi).",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <body>{children}</body>
    </html>
  );
}
