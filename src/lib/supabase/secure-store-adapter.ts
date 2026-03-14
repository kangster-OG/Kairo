export type SupabaseStorageAdapter = {
  getItem: (key: string) => Promise<string | null>;
  removeItem: (key: string) => Promise<void>;
  setItem: (key: string, value: string) => Promise<void>;
};

function getSecureStoreModule(): typeof import('expo-secure-store') {
  // Load the native module lazily so pure service tests can inject storage without parsing Expo code.
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  return require('expo-secure-store') as typeof import('expo-secure-store');
}

export const secureStoreAdapter: SupabaseStorageAdapter = {
  async getItem(key) {
    const SecureStore = getSecureStoreModule();
    return SecureStore.getItemAsync(key);
  },
  async removeItem(key) {
    const SecureStore = getSecureStoreModule();
    await SecureStore.deleteItemAsync(key);
  },
  async setItem(key, value) {
    const SecureStore = getSecureStoreModule();
    await SecureStore.setItemAsync(key, value);
  },
};
