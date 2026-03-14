import { z } from 'zod';

export const reconstitutionCalculatorInputSchema = z.object({
  diluentUnit: z.string().trim().min(1),
  diluentVolume: z.number().positive('Diluent volume must be greater than 0.'),
  drawUnit: z.string().trim().min(1),
  drawVolume: z.number().positive('Draw volume must be greater than 0.'),
  label: z.string().trim().max(80).optional(),
  powderAmount: z.number().positive('Powder amount must be greater than 0.'),
  powderUnit: z.string().trim().min(1),
});

export type ReconstitutionCalculatorInput = z.infer<typeof reconstitutionCalculatorInputSchema>;
