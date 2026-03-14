import { z } from 'zod';

const supabaseEnvSchema = z.object({
  anonKey: z.string().trim().min(1),
  url: z.string().trim().url(),
});

export type SupabaseConfig = z.infer<typeof supabaseEnvSchema>;

export function getSupabaseConfig(): SupabaseConfig | null {
  const parsed = supabaseEnvSchema.safeParse({
    anonKey: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY,
    url: process.env.EXPO_PUBLIC_SUPABASE_URL,
  });

  if (!parsed.success) {
    return null;
  }

  return parsed.data;
}

export function hasSupabaseConfig() {
  return getSupabaseConfig() !== null;
}
