import { z } from 'zod';

import {
  protocolMissedDosePolicySchema,
  protocolRevisionTimezoneStrategySchema,
} from '@/src/lib/database/schemas';

const dateSchema = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Use YYYY-MM-DD.');
const timeSchema = z
  .string()
  .trim()
  .regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Use 24-hour time like 08:00.');
const wholeNumberStringSchema = z.string().trim().regex(/^\d+$/, 'Enter a whole number.');
const decimalStringSchema = z.string().trim().regex(/^\d+([.,]\d+)?$/, 'Enter a valid number.');

export const protocolChangeTypeSchema = z.enum([
  'future_dose',
  'future_time',
  'day_of_week',
  'every_n_days',
  'pause',
  'resume',
  'titration',
  'rest_period',
  'missed_dose_policy',
  'timezone',
  'vial_switch',
]);

export const previewWindowSchema = z.union([z.literal(7), z.literal(14), z.literal(30)]);

export const protocolChangeDraftSchema = z
  .object({
    changeType: protocolChangeTypeSchema,
    doseAmount: z.string().trim().default(''),
    doseUnit: z.string().trim().default(''),
    effectiveDate: dateSchema,
    intervalDays: wholeNumberStringSchema.default('1'),
    linkedVialId: z.string().nullable().default(null),
    missedDosePolicy: protocolMissedDosePolicySchema.default('skip_and_continue'),
    notes: z.string().trim().max(280, 'Keep notes under 280 characters.').default(''),
    previewWindowDays: previewWindowSchema.default(14),
    restLengthDays: wholeNumberStringSchema.default('7'),
    timeOfDay: timeSchema.default('08:00'),
    titrationDoseAmount: z.string().trim().default(''),
    titrationDoseUnit: z.string().trim().default(''),
    titrationLengthDays: wholeNumberStringSchema.default('14'),
    timezone: z.string().trim().default('UTC'),
    timezoneStrategy: protocolRevisionTimezoneStrategySchema.default('keep_local_clock'),
    weekday: z.number().int().min(0).max(6).nullable().default(null),
  })
  .superRefine((value, ctx) => {
    if (value.changeType === 'future_dose') {
      if (!decimalStringSchema.safeParse(value.doseAmount).success) {
        ctx.addIssue({ code: 'custom', message: 'Add a future saved amount.', path: ['doseAmount'] });
      }

      if (value.doseUnit.length < 1) {
        ctx.addIssue({ code: 'custom', message: 'Add a dose unit.', path: ['doseUnit'] });
      }
    }

    if (value.changeType === 'future_time' && !timeSchema.safeParse(value.timeOfDay).success) {
      ctx.addIssue({ code: 'custom', message: 'Add a time of day.', path: ['timeOfDay'] });
    }

    if (value.changeType === 'day_of_week' && value.weekday === null) {
      ctx.addIssue({ code: 'custom', message: 'Select a weekday.', path: ['weekday'] });
    }

    if (value.changeType === 'every_n_days' && Number(value.intervalDays) < 1) {
      ctx.addIssue({ code: 'custom', message: 'Interval must be at least 1 day.', path: ['intervalDays'] });
    }

    if (value.changeType === 'titration') {
      if (!decimalStringSchema.safeParse(value.titrationDoseAmount).success) {
        ctx.addIssue({
          code: 'custom',
          message: 'Add a titration amount.',
          path: ['titrationDoseAmount'],
        });
      }

      if (value.titrationDoseUnit.length < 1) {
        ctx.addIssue({
          code: 'custom',
          message: 'Add a titration unit.',
          path: ['titrationDoseUnit'],
        });
      }

      if (Number(value.titrationLengthDays) < 1) {
        ctx.addIssue({
          code: 'custom',
          message: 'Titration length must be at least 1 day.',
          path: ['titrationLengthDays'],
        });
      }
    }

    if (value.changeType === 'rest_period' && Number(value.restLengthDays) < 1) {
      ctx.addIssue({
        code: 'custom',
        message: 'Rest length must be at least 1 day.',
        path: ['restLengthDays'],
      });
    }

    if (value.changeType === 'timezone' && value.timezone.length < 2) {
      ctx.addIssue({
        code: 'custom',
        message: 'Add a timezone identifier.',
        path: ['timezone'],
      });
    }

    if (value.changeType === 'vial_switch' && !value.linkedVialId) {
      ctx.addIssue({
        code: 'custom',
        message: 'Choose the vial to switch to.',
        path: ['linkedVialId'],
      });
    }
  });

export const protocolChangeDraftValuesSchema = protocolChangeDraftSchema.transform((value) => ({
  ...value,
  doseAmount: value.doseAmount ? Number(value.doseAmount.replace(',', '.')) : null,
  intervalDays: Number(value.intervalDays),
  notes: value.notes.length > 0 ? value.notes : null,
  restLengthDays: Number(value.restLengthDays),
  titrationDoseAmount: value.titrationDoseAmount
    ? Number(value.titrationDoseAmount.replace(',', '.'))
    : null,
  titrationLengthDays: Number(value.titrationLengthDays),
}));

export type ProtocolChangeType = z.infer<typeof protocolChangeTypeSchema>;
export type ProtocolChangeDraft = z.input<typeof protocolChangeDraftSchema>;
export type ProtocolChangeDraftValues = z.output<typeof protocolChangeDraftValuesSchema>;
