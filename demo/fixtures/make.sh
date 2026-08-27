#!/usr/bin/env bash
# A fake project that is IDENTICAL every time it is built.
#
# Demos are re-recorded on every release. If the fixture drifts — a different file order, a
# timestamp, a random token count — every GIF changes for no reason and the diff is unreadable.
# So: fixed names, fixed contents, fixed order, no dates, no randomness.
set -euo pipefail
DEST="${1:?usage: make.sh <dir>}"
rm -rf "$DEST"
mkdir -p "$DEST/src/auth" "$DEST/src/api" "$DEST/src/ui" "$DEST/tests"

cat > "$DEST/src/auth/session.ts" <<'TS'
import { verify } from "./token";

export interface Session {
  userId: string;
  expiresAt: number;
}

export async function loadSession(cookie: string): Promise<Session | null> {
  const claims = await verify(cookie);
  if (!claims) return null;
  return { userId: claims.sub, expiresAt: claims.exp * 1000 };
}
TS

cat > "$DEST/src/auth/token.ts" <<'TS'
const KEY = process.env.SESSION_KEY;

export async function verify(raw: string) {
  if (!KEY) throw new Error("SESSION_KEY is not configured");
  const [payload, signature] = raw.split(".");
  if (!payload || !signature) return null;
  return JSON.parse(atob(payload)) as { sub: string; exp: number };
}
TS

cat > "$DEST/src/api/routes.ts" <<'TS'
import { loadSession } from "../auth/session";

export const routes = {
  "GET /me": async (req: Request) => {
    const session = await loadSession(req.headers.get("cookie") ?? "");
    if (!session) return new Response("unauthorized", { status: 401 });
    return Response.json({ userId: session.userId });
  },
};
TS

cat > "$DEST/src/api/client.ts" <<'TS'
export async function get<T>(path: string): Promise<T> {
  const res = await fetch(path, { credentials: "include" });
  if (!res.ok) throw new Error(`${res.status} ${path}`);
  return res.json() as Promise<T>;
}
TS

cat > "$DEST/src/ui/Avatar.tsx" <<'TSX'
export function Avatar({ userId }: { userId: string }) {
  return <img alt="" src={`/avatars/${userId}.png`} width={32} height={32} />;
}
TSX

cat > "$DEST/src/ui/Nav.tsx" <<'TSX'
import { Avatar } from "./Avatar";

export function Nav({ userId }: { userId: string | null }) {
  return (
    <nav>
      <a href="/">Home</a>
      {userId ? <Avatar userId={userId} /> : <a href="/login">Sign in</a>}
    </nav>
  );
}
TSX

cat > "$DEST/tests/session.test.ts" <<'TS'
import { loadSession } from "../src/auth/session";

test("a malformed cookie is not a session", async () => {
  expect(await loadSession("nonsense")).toBeNull();
});
TS

cat > "$DEST/package.json" <<'JSON'
{
  "name": "acme-app",
  "version": "1.0.0",
  "private": true
}
JSON

# A git repo, because `checkpoint` and `diff` need one — with a fixed identity and a fixed date,
# so the commit hash is identical on every machine and no demo ever shows a changing SHA.
export GIT_AUTHOR_NAME="Demo" GIT_AUTHOR_EMAIL="demo@example.com"
export GIT_COMMITTER_NAME="Demo" GIT_COMMITTER_EMAIL="demo@example.com"
export GIT_AUTHOR_DATE="2026-01-01T00:00:00Z" GIT_COMMITTER_DATE="2026-01-01T00:00:00Z"
git -C "$DEST" init -q -b main
git -C "$DEST" add -A
git -C "$DEST" commit -qm "acme-app"
