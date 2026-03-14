import { z } from 'zod';

export const saveVialInputSchema = z.object({
  compoundId: z.string().nullable().optional(),
  concentrationUnit: z.string().nullable().optional(),
  concentrationValue: z.number().positive().nullable().optional(),
  expiresAt: z.string().nullable().optional(),
  label: z.string().trim().min(1, 'Add a vial label.'),
  lowStockThreshold: z.number().min(0).nullable().optional(),
  openedAt: z.string().nullable().optional(),
  protocolId: z.string().nullable().optional(),
  quantityUnit: z.string().trim().min(1, 'Add a quantity unit.'),
  remainingQuantity: z.number().min(0, 'Remaining quantity cannot be negative.'),
  startingQuantity: z.number().min(0, 'Starting quantity cannot be negative.'),
  volumeMl: z.number().positive().nullable().optional(),
});

export const updateProtocolInventorySettingsInputSchema = z.object({
  linkedVialId: z.string().nullable(),
  protocolId: z.string(),
  siteRotationEnabled: z.boolean(),
  siteTrackingEnabled: z.boolean(),
});

export const inventoryCorrectionInputSchema = z.object({
  nextRemainingQuantity: z.number().min(0, 'Remaining quantity cannot be negative.'),
  notes: z.string().trim().max(280).nullable().optional(),
  vialId: z.string(),
});

export const saveSiteInputSchema = z.object({
  archivedAt: z.string().nullable().optional(),
  bodyArea: z.string().trim().min(1).nullable().optional(),
  id: z.string().optional(),
  name: z.string().trim().min(1, 'Add a site name.'),
  notes: z.string().trim().max(280).nullable().optional(),
});

export type SaveVialInput = z.infer<typeof saveVialInputSchema>;
export type UpdateProtocolInventorySettingsInput = z.infer<
  typeof updateProtocolInventorySettingsInputSchema
>;
export type InventoryCorrectionInput = z.infer<typeof inventoryCorrectionInputSchema>;
export type SaveSiteInput = z.infer<typeof saveSiteInputSchema>;
