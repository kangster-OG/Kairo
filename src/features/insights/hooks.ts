import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import {
  getInsightsSnapshot,
  saveCustomMetricEntry,
  saveSymptomEntry,
  saveWeightEntry,
} from '@/src/features/insights/service';
import type {
  SaveCustomMetricEntryInput,
  SaveSymptomEntryInput,
  SaveWeightEntryInput,
} from '@/src/features/insights/schema';

export const insightsQueryKeys = {
  snapshot: ['insights', 'snapshot'] as const,
};

export function useInsightsSnapshotQuery() {
  return useQuery({
    queryFn: () => getInsightsSnapshot(),
    queryKey: insightsQueryKeys.snapshot,
  });
}

export function useSaveWeightEntryMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: SaveWeightEntryInput) => saveWeightEntry(input),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: insightsQueryKeys.snapshot });
    },
  });
}

export function useSaveSymptomEntryMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: SaveSymptomEntryInput) => saveSymptomEntry(input),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: insightsQueryKeys.snapshot });
    },
  });
}

export function useSaveCustomMetricEntryMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: SaveCustomMetricEntryInput) => saveCustomMetricEntry(input),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: insightsQueryKeys.snapshot });
    },
  });
}
