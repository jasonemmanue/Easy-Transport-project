import { NextRequest, NextResponse } from "next/server";

/**
 * Protection HTTP Basic du backoffice deploye (Railway), en attendant la vraie
 * session administrateur. Inactive si BACKOFFICE_BASIC_AUTH_USER ou
 * BACKOFFICE_BASIC_AUTH_PASSWORD est vide (developpement local).
 */
export function middleware(req: NextRequest) {
  const user = process.env.BACKOFFICE_BASIC_AUTH_USER;
  const password = process.env.BACKOFFICE_BASIC_AUTH_PASSWORD;
  if (!user || !password) return NextResponse.next();

  const header = req.headers.get("authorization") ?? "";
  if (header.startsWith("Basic ")) {
    const decoded = atob(header.slice(6));
    const sep = decoded.indexOf(":");
    if (sep >= 0 && decoded.slice(0, sep) === user && decoded.slice(sep + 1) === password) {
      return NextResponse.next();
    }
  }
  return new NextResponse("Authentification requise", {
    status: 401,
    headers: { "WWW-Authenticate": 'Basic realm="Carlinq Backoffice", charset="UTF-8"' },
  });
}

export const config = {
  // Tout sauf la sonde de sante Railway et les fichiers statiques Next.
  matcher: ["/((?!api/health|_next/static|_next/image|favicon.ico).*)"],
};
