import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { regenerateProtocolReminders } from '@/src/features/reminders/service';
import { inventoryQueryKeys } from '@/src/features/inventory/hooks';
import { getTimelineFeed, getTodaySnapshot, logTodayAction, type TimelineFilters, type TodayActionInput } from '@/src/features/day-loop/service';
import { protocolQueryKeys } from '@/src/features/protocols/hooks';

export const dayLoopQueryKeys = {
  timeline: (filters: TimelineFilters) => ['day-loop', 'timeline', filters] as const,
  today: ['day-loop', 'today'] as const,
};

export function useTodaySnapshotQuery() {
  return useQuery({
    queryFn: () => getTodaySnapshot(),
    queryKey: dayLoopQueryKeys.today,
  });
}

export function useTimelineFeedQuery(filters: TimelineFilters) {
  return useQuery({
    queryFn: () => getTimelineFeed(filters),
    queryKey: dayLoopQueryKeys.timeline(filters),
  });
}

export function useTodayActionMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: TodayActionInput) => logTodayAction(input),
    onSuccess: async (_, input) => {
      try {
        await regenerateProtocolReminders(input.protocolId);
      } catch (error) {
        console.warn(
          '[Atlas] Reminder regeneration after today action failed.',
          error instanceof Error ? error.message : error
        );
      }

      await Promise.all([
        queryClient.invalidateQueries({ queryKey: dayLoopQueryKeys.today }),
        queryClient.invalidateQueries({ queryKey: ['day-loop', 'timeline'] }),
        queryClient.invalidateQueries({ queryKey: inventoryQueryKeys.snapshot }),
        queryClient.invalidateQueries({ queryKey: protocolQueryKeys.todaySummary }),
        queryClient.invalidateQueries({ queryKey: protocolQueryKeys.list }),
      ]);
    },
  });
}
