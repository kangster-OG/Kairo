import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-atlas-review-token",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
    },
  });
}

function html(body: string, status = 200) {
  return new Response(body, {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
      "X-Robots-Tag": "noindex, nofollow, noarchive",
    },
  });
}

async function sha256(input: string) {
  const data = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest))
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("");
}

async function purgeStaleSessions(admin: ReturnType<typeof createClient>) {
  const { error } = await admin
    .from("atlas_live_review_sessions")
    .delete()
    .lte("purge_after", new Date().toISOString());

  if (error) {
    console.error("live-review purge failed", error);
  }
}

function defaultPurgeAfter(expiresAt: string | null) {
  if (expiresAt) {
    return new Date(new Date(expiresAt).getTime() + 24 * 60 * 60 * 1000).toISOString();
  }
  return new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
}

function revokedPurgeAfter() {
  return new Date(Date.now() + 60 * 60 * 1000).toISOString();
}

function reviewBootstrapHtml(sessionId: string) {
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Atlas Review</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f3f1ea;
      --card: rgba(255, 255, 255, 0.9);
      --border: rgba(31, 46, 74, 0.12);
      --text: #142133;
      --muted: #5a6678;
      --accent: #264978;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: ui-rounded, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background:
        radial-gradient(circle at top, rgba(38, 73, 120, 0.12), transparent 36%),
        linear-gradient(180deg, #f9f8f3 0%, var(--bg) 100%);
      color: var(--text);
    }
    main {
      max-width: 860px;
      margin: 0 auto;
      padding: 32px 20px 56px;
    }
    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 28px;
      box-shadow: 0 18px 50px rgba(22, 33, 51, 0.08);
      backdrop-filter: blur(18px);
      padding: 24px;
    }
    h1, h2, p { margin: 0; }
    h1 { font-size: 28px; line-height: 1.1; }
    h2 { font-size: 15px; color: var(--accent); margin-bottom: 12px; }
    .meta, .line {
      color: var(--muted);
      font-size: 15px;
      line-height: 1.5;
    }
    .meta { margin-top: 10px; }
    .summary {
      margin-top: 18px;
      font-size: 16px;
      line-height: 1.55;
    }
    .section {
      margin-top: 18px;
      padding-top: 18px;
      border-top: 1px solid var(--border);
    }
    .line + .line { margin-top: 8px; }
    .status {
      margin-top: 20px;
      color: var(--muted);
      font-size: 15px;
    }
  </style>
</head>
<body>
  <main>
    <div class="card">
      <h1>Atlas review</h1>
      <p class="status" id="status">Loading review...</p>
      <div id="content" hidden>
        <p class="meta" id="meta"></p>
        <p class="summary" id="summary"></p>
        <div id="sections"></div>
      </div>
    </div>
  </main>
  <script>
    const sessionId = ${JSON.stringify(sessionId)};
    const statusEl = document.getElementById("status");
    const contentEl = document.getElementById("content");
    const metaEl = document.getElementById("meta");
    const summaryEl = document.getElementById("summary");
    const sectionsEl = document.getElementById("sections");

    const hash = new URLSearchParams(window.location.hash.startsWith("#") ? window.location.hash.slice(1) : window.location.hash);
    const token = hash.get("token");

    if (!token) {
      statusEl.textContent = "This review link is incomplete. Ask the owner to resend it.";
    } else {
      fetch(\`\${window.location.pathname}?session_id=\${encodeURIComponent(sessionId)}\`, {
        headers: {
          "Accept": "application/json",
          "x-atlas-review-token": token
        }
      }).then(async (response) => {
        const body = await response.json().catch(() => ({}));
        if (!response.ok) {
          throw new Error(body.error || "This review could not be opened.");
        }
        return body;
      }).then((payload) => {
        const session = payload.session || {};
        const workspace = payload.workspace || {};
        const metaBits = [];
        if (session.title) metaBits.push(session.title);
        if (session.scopeKind) metaBits.push(session.scopeKind.replaceAll("_", " "));
        if (session.expiresAt) {
          metaBits.push(\`Expires \${new Date(session.expiresAt).toLocaleString()}\`);
        }
        metaEl.textContent = metaBits.join(" • ");
        summaryEl.textContent = workspace.summary || session.summary || "";
        for (const section of workspace.sections || []) {
          const wrapper = document.createElement("section");
          wrapper.className = "section";
          const heading = document.createElement("h2");
          heading.textContent = section.title || "";
          wrapper.appendChild(heading);
          for (const line of section.lines || []) {
            const lineEl = document.createElement("p");
            lineEl.className = "line";
            lineEl.textContent = line;
            wrapper.appendChild(lineEl);
          }
          sectionsEl.appendChild(wrapper);
        }
        contentEl.hidden = false;
        statusEl.hidden = true;
      }).catch((error) => {
        statusEl.textContent = error.message || "This review could not be opened.";
      });
    }
  </script>
</body>
</html>`;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    return json({ error: "Missing Supabase environment." }, 500);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  await purgeStaleSessions(admin);

  const url = new URL(request.url);

  if (request.method === "GET") {
    const sessionID = url.searchParams.get("session_id");
    const token = url.searchParams.get("token") ?? request.headers.get("x-atlas-review-token");

    if (!sessionID) {
      return json({ error: "session_id is required." }, 400);
    }

    if (!token) {
      const acceptsHtml = (request.headers.get("accept") || "").includes("text/html");
      return acceptsHtml
        ? html(reviewBootstrapHtml(sessionID))
        : json({ error: "Review token is required." }, 401);
    }

    const tokenHash = await sha256(token);
    const { data, error } = await admin
      .from("atlas_live_review_sessions")
      .select("id,title,scope_kind,render_mode,row_count,summary,workspace_json,expires_at,revoked_at,created_at")
      .eq("id", sessionID)
      .eq("session_token_hash", tokenHash)
      .maybeSingle();

    if (error) {
      return json({ error: error.message }, 500);
    }
    if (!data) {
      return json({ error: "Session not found." }, 404);
    }
    if (data.revoked_at) {
      return json({ error: "Session revoked." }, 410);
    }
    if (data.expires_at && new Date(data.expires_at).getTime() < Date.now()) {
      return json({ error: "Session expired." }, 410);
    }

    return json({
      session: {
        id: data.id,
        title: data.title,
        scopeKind: data.scope_kind,
        renderMode: data.render_mode,
        rowCount: data.row_count,
        summary: data.summary,
        createdAt: data.created_at,
        expiresAt: data.expires_at,
      },
      workspace: data.workspace_json,
    });
  }

  if (request.method === "POST") {
    const authHeader = request.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Authorization is required." }, 401);
    }

    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const userClient = createClient(supabaseUrl, anonKey, {
      auth: { persistSession: false, autoRefreshToken: false },
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return json({ error: "Invalid user session." }, 401);
    }

    let body: Record<string, unknown>;
    try {
      body = await request.json();
    } catch {
      return json({ error: "Invalid JSON body." }, 400);
    }

    const title = typeof body.title === "string" ? body.title.trim() : "";
    const scopeKind = typeof body.scope_kind === "string" ? body.scope_kind.trim() : "";
    const renderMode = typeof body.render_mode === "string" ? body.render_mode.trim() : "";
    const rowCount = typeof body.row_count === "number" ? body.row_count : 0;
    const summary = typeof body.summary === "string" ? body.summary.trim() : "";
    const workspaceJson = body.workspace_json;
    const expiresAt = typeof body.expires_at === "string" && body.expires_at.length > 0
      ? body.expires_at
      : null;
    const purgeAfter = defaultPurgeAfter(expiresAt);

    if (!title || !scopeKind || !renderMode || !summary || !workspaceJson) {
      return json({ error: "Missing required session fields." }, 400);
    }
    if (expiresAt && Number.isNaN(Date.parse(expiresAt))) {
      return json({ error: "expires_at must be a valid ISO date string." }, 400);
    }
    if (expiresAt && new Date(expiresAt).getTime() <= Date.now()) {
      return json({ error: "expires_at must be in the future." }, 400);
    }

    const sessionId = crypto.randomUUID().toLowerCase();
    const token = crypto.randomUUID().replaceAll("-", "") + crypto.randomUUID().replaceAll("-", "");
    const tokenHash = await sha256(token);

    const { error } = await admin
      .from("atlas_live_review_sessions")
      .insert({
        id: sessionId,
        owner_id: user.id,
        title,
        scope_kind: scopeKind,
        render_mode: renderMode,
        row_count: rowCount,
        summary,
        workspace_json: workspaceJson,
        bundle_json: { workspace: workspaceJson },
        session_token_hash: tokenHash,
        expires_at: expiresAt,
        purge_after: purgeAfter,
      });

    if (error) {
      return json({ error: error.message }, 500);
    }

    const shareUrl = `${supabaseUrl}/functions/v1/live-review-session?session_id=${encodeURIComponent(sessionId)}#token=${encodeURIComponent(token)}`;

    return json({
      session: {
        id: sessionId,
        share_url: shareUrl,
        expires_at: expiresAt,
      },
    });
  }

  if (request.method === "DELETE") {
    const authHeader = request.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Authorization is required." }, 401);
    }

    const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY") ?? "", {
      auth: { persistSession: false, autoRefreshToken: false },
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return json({ error: "Invalid user session." }, 401);
    }

    const sessionID = url.searchParams.get("session_id");
    if (!sessionID) {
      return json({ error: "session_id is required." }, 400);
    }

    const { error } = await admin
      .from("atlas_live_review_sessions")
      .update({
        revoked_at: new Date().toISOString(),
        purge_after: revokedPurgeAfter(),
      })
      .eq("id", sessionID)
      .eq("owner_id", user.id);

    if (error) {
      return json({ error: error.message }, 500);
    }

    return json({ ok: true });
  }

  return json({ error: "Method not allowed." }, 405);
});
