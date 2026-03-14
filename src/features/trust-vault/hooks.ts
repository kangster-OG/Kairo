import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { dayLoopQueryKeys } from '@/src/features/day-loop/hooks';
import { insightsQueryKeys } from '@/src/features/insights/hooks';
import { inventoryQueryKeys } from '@/src/features/inventory/hooks';
import { protocolQueryKeys } from '@/src/features/protocols/hooks';
import {
  buildSelectiveSharePreview,
  createSelectiveShareBundle,
  getTrustVaultSnapshot,
  saveProtocolAlias,
  unlockTrustVault,
  updateTrustVaultProfile,
} from '@/src/features/trust-vault/service';
import type { SelectiveShareInput } from '@/src/features/trust-vault/schema';

export const trustVaultQueryKeys = {
  bundlePreview: (input: Partial<Omit<SelectiveShareInput, 'passphrase'>> | null) =>
    ['trust-vault', 'bundle-preview', input] as const,
  snapshot: ['trust-vault', 'snapshot'] as const,
};

export function useTrustVaultQuery() {
  return useQuery({
    queryFn: () => getTrustVaultSnapshot(),
    queryKey: trustVaultQueryKeys.snapshot,
  });
}

export function useSelectiveSharePreviewQuery(
  input: (Omit<SelectiveShareInput, 'passphrase'> & { passphrase?: string }) | null
) {
  return useQuery({
    enabled: Boolean(input),
    queryFn: () => buildSelectiveSharePreview(input!),
    queryKey: trustVaultQueryKeys.bundlePreview(input),
  });
}

export function useUpdateTrustVaultProfileMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: Parameters<typeof updateTrustVaultProfile>[0]) =>
      updateTrustVaultProfile(input),
    onSuccess: async () => {
      await invalidatePrivacyAffectedQueries(queryClient);
    },
  });
}

export function useSaveProtocolAliasMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: Parameters<typeof saveProtocolAlias>[0]) =>
      saveProtocolAlias(input),
    onSuccess: async () => {
      await invalidatePrivacyAffectedQueries(queryClient);
    },
  });
}

export function useUnlockTrustVaultMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: () => unlockTrustVault(),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: trustVaultQueryKeys.snapshot });
    },
  });
}

export function useCreateSelectiveShareBundleMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: Parameters<typeof createSelectiveShareBundle>[0]) =>
      createSelectiveShareBundle(input),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: trustVaultQueryKeys.snapshot });
    },
  });
}

async function invalidatePrivacyAffectedQueries(queryClient: ReturnType<typeof useQueryClient>) {
  await Promise.all([
    queryClient.invalidateQueries({ queryKey: trustVaultQueryKeys.snapshot }),
    queryClient.invalidateQueries({ queryKey: dayLoopQueryKeys.today }),
    queryClient.invalidateQueries({ queryKey: ['day-loop', 'timeline'] }),
    queryClient.invalidateQueries({ queryKey: protocolQueryKeys.list }),
    queryClient.invalidateQueries({ queryKey: protocolQueryKeys.todaySummary }),
    queryClient.invalidateQueries({ queryKey: insightsQueryKeys.snapshot }),
    queryClient.invalidateQueries({ queryKey: inventoryQueryKeys.snapshot }),
  ]);
}
