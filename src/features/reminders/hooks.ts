import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { dayLoopQueryKeys } from '@/src/features/day-loop/hooks';
import {
  getReminderPreferences,
  type ReminderPreferenceUpdateInput,
  updateReminderPreferences,
} from '@/src/features/reminders/service';
import { protocolQueryKeys } from '@/src/features/protocols/hooks';

export const reminderQueryKeys = {
  preferences: ['reminders', 'preferences'] as const,
};

export function useReminderPreferencesQuery() {
  return useQuery({
    queryFn: () => getReminderPreferences(),
    queryKey: reminderQueryKeys.preferences,
  });
}

export function useUpdateReminderPreferencesMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: ReminderPreferenceUpdateInput) => updateReminderPreferences(input),
    onSuccess: async () => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: reminderQueryKeys.preferences }),
        queryClient.invalidateQueries({ queryKey: dayLoopQueryKeys.today }),
        queryClient.invalidateQueries({ queryKey: ['day-loop', 'timeline'] }),
        queryClient.invalidateQueries({ queryKey: protocolQueryKeys.list }),
      ]);
    },
  });
}
