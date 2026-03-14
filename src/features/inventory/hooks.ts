import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import {
  applyInventoryCorrection,
  deleteVial,
  getInventorySnapshot,
  getProtocolSiteOptions,
  saveSite,
  saveVial,
  updateProtocolInventorySettings,
} from '@/src/features/inventory/service';
import type {
  InventoryCorrectionInput,
  SaveSiteInput,
  SaveVialInput,
  UpdateProtocolInventorySettingsInput,
} from '@/src/features/inventory/schema';

export const inventoryQueryKeys = {
  protocolSiteOptions: (protocolId: string) => ['inventory', 'protocol-sites', protocolId] as const,
  snapshot: ['inventory', 'snapshot'] as const,
};

export function useInventorySnapshotQuery() {
  return useQuery({
    queryFn: () => getInventorySnapshot(),
    queryKey: inventoryQueryKeys.snapshot,
  });
}

export function useProtocolSiteOptionsQuery(protocolId: string | null) {
  return useQuery({
    enabled: Boolean(protocolId),
    queryFn: () => getProtocolSiteOptions(protocolId!),
    queryKey: inventoryQueryKeys.protocolSiteOptions(protocolId ?? 'none'),
  });
}

export function useSaveVialMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: SaveVialInput) => saveVial(input),
    onSuccess: async () => {
      await invalidateInventoryQueries(queryClient);
    },
  });
}

export function useUpdateProtocolInventorySettingsMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: UpdateProtocolInventorySettingsInput) =>
      updateProtocolInventorySettings(input),
    onSuccess: async (_, input) => {
      await Promise.all([
        invalidateInventoryQueries(queryClient),
        queryClient.invalidateQueries({
          queryKey: inventoryQueryKeys.protocolSiteOptions(input.protocolId),
        }),
      ]);
    },
  });
}

export function useDeleteVialMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteVial(id),
    onSuccess: async () => {
      await invalidateInventoryQueries(queryClient);
    },
  });
}

export function useApplyInventoryCorrectionMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: InventoryCorrectionInput) => applyInventoryCorrection(input),
    onSuccess: async () => {
      await invalidateInventoryQueries(queryClient);
    },
  });
}

export function useSaveSiteMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: SaveSiteInput) => saveSite(input),
    onSuccess: async () => {
      await invalidateInventoryQueries(queryClient);
    },
  });
}

async function invalidateInventoryQueries(queryClient: ReturnType<typeof useQueryClient>) {
  await Promise.all([
    queryClient.invalidateQueries({ queryKey: inventoryQueryKeys.snapshot }),
    queryClient.invalidateQueries({ queryKey: ['day-loop', 'today'] }),
    queryClient.invalidateQueries({ queryKey: ['day-loop', 'timeline'] }),
    queryClient.invalidateQueries({ queryKey: ['protocols', 'list'] }),
    queryClient.invalidateQueries({ queryKey: ['protocols', 'today-summary'] }),
  ]);
}
