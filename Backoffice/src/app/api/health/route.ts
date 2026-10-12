// Sonde de sante Railway (ne depend pas de l'API FastAPI).
export const dynamic = "force-dynamic";

export function GET() {
  return Response.json({ status: "ok" });
}
