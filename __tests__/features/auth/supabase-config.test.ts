import { getSupabaseConfig, hasSupabaseConfig } from '@/src/lib/supabase/config';

describe('supabase config', () => {
  const originalUrl = process.env.EXPO_PUBLIC_SUPABASE_URL;
  const originalAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

  afterEach(() => {
    process.env.EXPO_PUBLIC_SUPABASE_URL = originalUrl;
    process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY = originalAnonKey;
  });

  it('returns null when required env values are missing', () => {
    delete process.env.EXPO_PUBLIC_SUPABASE_URL;
    delete process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

    expect(getSupabaseConfig()).toBeNull();
    expect(hasSupabaseConfig()).toBe(false);
  });

  it('parses valid env values', () => {
    process.env.EXPO_PUBLIC_SUPABASE_URL = 'https://atlas.supabase.co';
    process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY = 'anon-key';

    expect(getSupabaseConfig()).toEqual({
      anonKey: 'anon-key',
      url: 'https://atlas.supabase.co',
    });
    expect(hasSupabaseConfig()).toBe(true);
  });
});
