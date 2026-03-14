import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { inventoryQueryKeys } from '@/src/features/inventory/hooks';
import { regenerateProtocolReminders } from '@/src/features/reminders/service';
import {
  createProtocolFromWizard,
  getTodayProtocolSummary,
  listAvailableCompounds,
  listProtocolListItems,
} from '@/src/features/protocols/service';

export const protocolQueryKeys = {
  compounds: ['protocols', 'compounds'] as const,
  list: ['protocols', 'list'] as const,
  todaySummary: ['protocols', 'today-summary'] as const,
};

export function useAvailableCompoundsQuery() {
  return useQuery({
    queryFn: listAvailableCompounds,
    queryKey: protocolQueryKeys.compounds,
  });
}

export function useProtocolListQuery() {
  return useQuery({
    queryFn: () => listProtocolListItems(),
    queryKey: protocolQueryKeys.list,
  });
}

export function useTodayProtocolSummaryQuery() {
  return useQuery({
    queryFn: () => getTodayProtocolSummary(),
    queryKey: protocolQueryKeys.todaySummary,
  });
}

export function useCreateProtocolMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: createProtocolFromWizard,
    onSuccess: async (result) => {
      try {
        await regenerateProtocolReminders(result.protocol.id);
      } catch (error) {
        console.warn(
          '[Atlas] Reminder regeneration after protocol create failed.',
          error instanceof Error ? error.message : error
        );
      }

      await Promise.all([
        queryClient.invalidateQueries({ queryKey: inventoryQueryKeys.snapshot }),
        queryClient.invalidateQueries({ queryKey: protocolQueryKeys.list }),
        queryClient.invalidateQueries({ queryKey: protocolQueryKeys.todaySummary }),
        queryClient.invalidateQueries({ queryKey: protocolQueryKeys.compounds }),
      ]);
    },
  });
}
