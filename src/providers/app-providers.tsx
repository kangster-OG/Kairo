import { useEffect, type PropsWithChildren } from 'react';

import { QueryClientProvider } from '@tanstack/react-query';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { atlasQueryClient } from '@/src/lib/query-client';

const ROOT_STYLE = { flex: 1 } as const;

export function AppProviders({ children }: PropsWithChildren) {
  useEffect(() => {
    let cleanup: (() => void) | undefined;
    let isMounted = true;

    void import('@/src/features/reminders/service')
      .then(({ bootstrapReminderNotifications }) => bootstrapReminderNotifications())
      .then((unsubscribe) => {
        if (!isMounted) {
          unsubscribe?.();
          return;
        }

        cleanup = unsubscribe;
      })
      .catch((error) => {
        console.warn(
          '[Atlas] Reminder notification bootstrap failed.',
          error instanceof Error ? error.message : error
        );
      });

    return () => {
      isMounted = false;
      cleanup?.();
    };
  }, []);

  useEffect(() => {
    void import('@/src/features/auth/store')
      .then(({ useAuthStore }) => useAuthStore.getState().bootstrap())
      .catch((error) => {
        console.warn(
          '[Atlas] Auth bootstrap failed.',
          error instanceof Error ? error.message : error
        );
      });
  }, []);

  return (
    <GestureHandlerRootView style={ROOT_STYLE}>
      <SafeAreaProvider>
        <QueryClientProvider client={atlasQueryClient}>{children}</QueryClientProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
