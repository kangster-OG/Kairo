import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

import { dayLoopQueryKeys } from '@/src/features/day-loop/hooks';
import { inventoryQueryKeys } from '@/src/features/inventory/hooks';
import { protocolQueryKeys } from '@/src/features/protocols/hooks';
import {
  buildProtocolChangePreview,
  commitProtocolChange,
  getProtocolChangeDetail,
} from '@/src/features/protocol-changes/service';
import type { OnboardingDraft } from '@/src/features/onboarding/schema';
import type { ProtocolChangeDraft } from '@/src/features/protocol-changes/schema';

type ProtocolChangeQueryOptions = {
  privacy?: Pick<OnboardingDraft['privacy'], 'discreetNotifications' | 'hideSensitiveLabels'>;
  referenceNow?: string;
};

export const protocolChangeQueryKeys = {
  detail: (protocolId: string, referenceNow: string) =>
    ['protocol-changes', 'detail', protocolId, referenceNow] as const,
  preview: (
    protocolId: string,
    draft: ProtocolChangeDraft,
    discreetNotifications: boolean,
    hideSensitiveLabels: boolean,
    referenceNow: string
  ) =>
    [
      'protocol-changes',
      'preview',
      protocolId,
      draft,
      discreetNotifications,
      hideSensitiveLabels,
      referenceNow,
    ] as const,
};

export function useProtocolChangeDetailQuery(
  protocolId: string | null,
  options: ProtocolChangeQueryOptions = {}
) {
  return useQuery({
    enabled: Boolean(protocolId),
    queryFn: () =>
      getProtocolChangeDetail(protocolId!, {
        referenceNow: options.referenceNow ? new Date(options.referenceNow) : undefined,
      }),
    queryKey: protocolChangeQueryKeys.detail(protocolId ?? 'none', options.referenceNow ?? 'now'),
  });
}

export function useProtocolChangePreviewQuery(
  protocolId: string | null,
  draft: ProtocolChangeDraft,
  options: ProtocolChangeQueryOptions = {}
) {
  return useQuery({
    enabled: Boolean(protocolId),
    queryFn: () =>
      buildProtocolChangePreview(protocolId!, draft, {
        privacy: options.privacy,
        referenceNow: options.referenceNow ? new Date(options.referenceNow) : undefined,
      }),
    queryKey: protocolChangeQueryKeys.preview(
      protocolId ?? 'none',
      draft,
      options.privacy?.discreetNotifications ?? false,
      options.privacy?.hideSensitiveLabels ?? false,
      options.referenceNow ?? 'now'
    ),
  });
}

export function useCommitProtocolChangeMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      protocolId,
      draft,
      referenceNow,
    }: {
      draft: ProtocolChangeDraft;
      protocolId: string;
      referenceNow?: string;
    }) =>
      commitProtocolChange(protocolId, draft, {
        referenceNow: referenceNow ? new Date(referenceNow) : undefined,
      }),
    onSuccess: async (_, variables) => {
      await Promise.all([
        queryClient.invalidateQueries({
          queryKey: ['protocol-changes', 'detail', variables.protocolId],
        }),
        queryClient.invalidateQueries({ queryKey: ['protocol-changes', 'preview', variables.protocolId] }),
        queryClient.invalidateQueries({ queryKey: dayLoopQueryKeys.today }),
        queryClient.invalidateQueries({ queryKey: ['day-loop', 'timeline'] }),
        queryClient.invalidateQueries({ queryKey: inventoryQueryKeys.snapshot }),
        queryClient.invalidateQueries({ queryKey: protocolQueryKeys.list }),
        queryClient.invalidateQueries({ queryKey: protocolQueryKeys.todaySummary }),
      ]);
    },
  });
}
