import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import {
  deleteCalculatorProfile,
  listCalculatorProfiles,
  saveCalculatorProfile,
} from '@/src/features/calculator/service';
import type { ReconstitutionCalculatorInput } from '@/src/features/calculator/schema';

export const calculatorQueryKeys = {
  profiles: ['calculator', 'profiles'] as const,
};

export function useCalculatorProfilesQuery() {
  return useQuery({
    queryFn: () => listCalculatorProfiles(),
    queryKey: calculatorQueryKeys.profiles,
  });
}

export function useSaveCalculatorProfileMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: ReconstitutionCalculatorInput) => saveCalculatorProfile(input),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: calculatorQueryKeys.profiles });
    },
  });
}

export function useDeleteCalculatorProfileMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteCalculatorProfile(id),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: calculatorQueryKeys.profiles });
    },
  });
}
