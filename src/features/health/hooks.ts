import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import {
  attemptHealthConnection,
  getHealthConnectionItems,
  setHealthConnectionEnabled,
} from '@/src/features/health/service';
import type { HealthProviderKey } from '@/src/lib/database/schemas';

export const healthQueryKeys = {
  connections: ['health', 'connections'] as const,
};

export function useHealthConnectionItemsQuery() {
  return useQuery({
    queryFn: () => getHealthConnectionItems(),
    queryKey: healthQueryKeys.connections,
  });
}

export function useSetHealthConnectionEnabledMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ enabled, providerKey }: { enabled: boolean; providerKey: HealthProviderKey }) =>
      setHealthConnectionEnabled(providerKey, enabled),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: healthQueryKeys.connections });
    },
  });
}

export function useAttemptHealthConnectionMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (providerKey: HealthProviderKey) => attemptHealthConnection(providerKey),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: healthQueryKeys.connections });
    },
  });
}
