import { z } from 'zod';

import { privacyRenderModeSchema } from '@/src/lib/database/schemas';

const isoDateSchema = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);

export const selectiveShareScopeKindSchema = z.enum([
  'current_protocol_only',
  'protocol_with_recent_timeline',
  'last_30_days_logs',
  'symptoms_only',
  'inventory_only',
  'summary_only',
  'custom_date_range',
]);

export const selectiveShareInputSchema = z
  .object({
    endDate: isoDateSchema.nullable().default(null),
    passphrase: z.string().min(8, 'Use at least 8 characters for the bundle passphrase.'),
    protocolId: z.string().nullable().default(null),
    renderMode: privacyRenderModeSchema.default('alias'),
    scopeKind: selectiveShareScopeKindSchema,
    shareAfterCreate: z.boolean().default(false),
    startDate: isoDateSchema.nullable().default(null),
  })
  .superRefine((value, ctx) => {
    if (
      (value.scopeKind === 'current_protocol_only' ||
        value.scopeKind === 'protocol_with_recent_timeline') &&
      !value.protocolId
    ) {
      ctx.addIssue({
        code: 'custom',
        message: 'Choose a protocol for this scope.',
        path: ['protocolId'],
      });
    }

    if (value.scopeKind === 'custom_date_range') {
      if (!value.startDate || !value.endDate) {
        ctx.addIssue({
          code: 'custom',
          message: 'Choose both a start and end date.',
          path: ['startDate'],
        });
      }
    }
  });

export type SelectiveShareInput = z.infer<typeof selectiveShareInputSchema>;
export type SelectiveShareScopeKind = z.infer<typeof selectiveShareScopeKindSchema>;
