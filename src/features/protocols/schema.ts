import { z } from 'zod';

const timeOfDaySchema = z
  .string()
  .trim()
  .regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Use 24-hour time like 08:00.');
const decimalStringSchema = z
  .string()
  .trim()
  .regex(/^\d+([.,]\d+)?$/, 'Enter a valid number.');
const integerStringSchema = z.string().trim().regex(/^\d+$/, 'Enter a whole number.');

export const protocolWizardFormSchema = z
  .object({
    compoundMode: z.enum(['saved', 'new']),
    compoundName: z.string().trim(),
    doseAmount: decimalStringSchema,
    doseUnit: z.string().trim().min(1, 'Add a dose unit.'),
    existingCompoundId: z.string().nullable(),
    intervalDays: integerStringSchema,
    kind: z.enum(['glp', 'peptide', 'custom']),
    notes: z.string().trim().max(280, 'Keep notes under 280 characters.'),
    scheduleType: z.enum(['weekly', 'every_n_days']),
    timeOfDay: timeOfDaySchema,
    weekday: z.number().int().min(0).max(6).nullable(),
  })
  .superRefine((value, ctx) => {
    if (value.compoundMode === 'saved' && !value.existingCompoundId) {
      ctx.addIssue({
        code: 'custom',
        message: 'Choose a saved compound or switch to a new name.',
        path: ['existingCompoundId'],
      });
    }

    if (value.compoundMode === 'new' && value.compoundName.length < 2) {
      ctx.addIssue({
        code: 'custom',
        message: 'Add a compound name.',
        path: ['compoundName'],
      });
    }

    if (value.scheduleType === 'weekly' && value.weekday === null) {
      ctx.addIssue({
        code: 'custom',
        message: 'Select a day of the week.',
        path: ['weekday'],
      });
    }

    if (value.scheduleType === 'every_n_days' && Number(value.intervalDays) < 1) {
      ctx.addIssue({
        code: 'custom',
        message: 'Interval must be at least 1 day.',
        path: ['intervalDays'],
      });
    }

    if (Number(value.doseAmount) <= 0) {
      ctx.addIssue({
        code: 'custom',
        message: 'Dose amount must be greater than 0.',
        path: ['doseAmount'],
      });
    }
  });

export const protocolWizardValuesSchema = protocolWizardFormSchema.transform((value) => ({
  compoundMode: value.compoundMode,
  compoundName: value.compoundName,
  doseAmount: Number(value.doseAmount.replace(',', '.')),
  doseUnit: value.doseUnit,
  existingCompoundId: value.existingCompoundId,
  intervalDays: Number(value.intervalDays),
  kind: value.kind,
  notes: value.notes.length > 0 ? value.notes : null,
  scheduleType: value.scheduleType,
  timeOfDay: value.timeOfDay,
  weekday: value.weekday,
}));

export type ProtocolWizardFormValues = z.input<typeof protocolWizardFormSchema>;
export type ProtocolWizardValues = z.output<typeof protocolWizardValuesSchema>;
