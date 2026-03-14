import AsyncStorage from '@react-native-async-storage/async-storage';

export async function readJsonItem<T>(key: string, fallback: T): Promise<T> {
  const rawValue = await AsyncStorage.getItem(key);

  if (!rawValue) {
    return fallback;
  }

  try {
    return JSON.parse(rawValue) as T;
  } catch {
    return fallback;
  }
}

export async function writeJsonItem<T>(key: string, value: T): Promise<void> {
  await AsyncStorage.setItem(key, JSON.stringify(value));
}

export async function removeJsonItem(key: string): Promise<void> {
  await AsyncStorage.removeItem(key);
}
