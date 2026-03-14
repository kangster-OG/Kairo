import { z } from 'zod';

import {
  customMetricValueTypeSchema,
  weightUnitSchema,
} from '@/src/lib/database/schemas';

export const saveWeightEntryInputSchema = z.object({
  loggedAt: z.string().optional(),
  notes: z.string().nullable().optional(),
  unit: weightUnitSchema,
  value: z.number().positive(),
});

export const saveSymptomEntryInputSchema = z.object({
  loggedAt: z.string().optional(),
  notes: z.string().nullable().optional(),
  severity: z.number().int().min(1).max(5),
  symptomKey: z.string().min(1),
});

export const saveCustomMetricEntryInputSchema = z
  .object({
    booleanValue: z.boolean().nullable().optional(),
    loggedAt: z.string().optional(),
    metricId: z.string().nullable().optional(),
    metricLabel: z.string().nullable().optional(),
    numberValue: z.number().nullable().optional(),
    protocolId: z.string().nullable().optional(),
    textValue: z.string().nullable().optional(),
    unit: z.string().nullable().optional(),
    valueType: customMetricValueTypeSchema,
  })
  .refine(
    (value) =>
      Boolean(value.metricId) || Boolean(value.metricLabel && value.metricLabel.trim().length > 0),
    'Choose an existing metric or provide a new metric label.'
  )
  .refine(
    (value) => {
      switch (value.valueType) {
        case 'number':
          return value.numberValue !== undefined && value.numberValue !== null;
        case 'text':
          return value.textValue !== undefined && value.textValue !== null && value.textValue.trim().length > 0;
        case 'boolean':
          return value.booleanValue !== undefined && value.booleanValue !== null;
        default:
          return false;
      }
    },
    'Metric entries require a value that matches the selected type.'
  );

export type SaveWeightEntryInput = z.infer<typeof saveWeightEntryInputSchema>;
export type SaveSymptomEntryInput = z.infer<typeof saveSymptomEntryInputSchema>;
export type SaveCustomMetricEntryInput = z.infer<typeof saveCustomMetricEntryInputSchema>;
