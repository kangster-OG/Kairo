import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
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

  const url = new URL(request.url);

  if (request.method === "GET") {
    const sessionID = url.searchParams.get("session_id");
    const token = url.searchParams.get("token");

    if (!sessionID || !token) {
      return json({ error: "session_id and token are required." }, 400);
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

    if (!title || !scopeKind || !renderMode || !summary || !workspaceJson) {
      return json({ error: "Missing required session fields." }, 400);
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
      });

    if (error) {
      return json({ error: error.message }, 500);
    }

    const shareUrl = `${supabaseUrl}/functions/v1/live-review-session?session_id=${encodeURIComponent(sessionId)}&token=${encodeURIComponent(token)}`;

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
      .update({ revoked_at: new Date().toISOString() })
      .eq("id", sessionID)
      .eq("owner_id", user.id);

    if (error) {
      return json({ error: error.message }, 500);
    }

    return json({ ok: true });
  }

  return json({ error: "Method not allowed." }, 405);
});
