import { z } from 'zod';

export const accountModeSchema = z.enum(['guest', 'create', 'signIn']);
export const trackTypeSchema = z.enum(['glp', 'peptide', 'both', 'later']);
export const heightUnitSchema = z.enum(['cm', 'ft_in']);
export const weightUnitSchema = z.enum(['kg', 'lb']);

export const onboardingPrivacySchema = z.object({
  discreetNotifications: z.boolean(),
  hideSensitiveLabels: z.boolean(),
  biometricLater: z.boolean(),
  analyticsOptIn: z.boolean(),
});

export const onboardingProfileSchema = z.object({
  gender: z.string().nullable(),
  age: z.number().nullable(),
  goalWeight: z.number().nullable(),
  height: z.number().nullable(),
  heightUnit: heightUnitSchema.nullable(),
  weight: z.number().nullable(),
  weightUnit: weightUnitSchema.nullable(),
});

export const onboardingGlpSchema = z.object({
  medication: z.string().nullable(),
  frequency: z.string().nullable(),
  injectionDay: z.string().nullable(),
  dose: z.string().nullable(),
  duration: z.string().nullable(),
  goal: z.string().nullable(),
  challenge: z.string().nullable(),
});

export const onboardingPeptideSchema = z.object({
  selections: z.array(z.string()),
  frequency: z.string().nullable(),
  experience: z.string().nullable(),
  usualTime: z.string().nullable(),
  dose: z.string().nullable(),
  goal: z.string().nullable(),
});

export const onboardingDraftSchema = z.object({
  accountMode: accountModeSchema.nullable(),
  privacy: onboardingPrivacySchema,
  trackType: trackTypeSchema.nullable(),
  profile: onboardingProfileSchema,
  glp: onboardingGlpSchema,
  peptide: onboardingPeptideSchema,
  healthConnectionPromptSeen: z.boolean(),
});

export const onboardingOutputSchema = z.object({
  accountMode: accountModeSchema,
  privacy: onboardingPrivacySchema,
  trackType: trackTypeSchema,
  profile: onboardingProfileSchema,
  glp: onboardingGlpSchema,
  peptide: onboardingPeptideSchema,
  healthConnectionPromptSeen: z.boolean(),
});

export const accountModeFormSchema = z.object({
  accountMode: accountModeSchema,
});

export type AccountMode = z.infer<typeof accountModeSchema>;
export type HeightUnit = z.infer<typeof heightUnitSchema>;
export type WeightUnit = z.infer<typeof weightUnitSchema>;
export type TrackType = z.infer<typeof trackTypeSchema>;
export type OnboardingPrivacy = z.infer<typeof onboardingPrivacySchema>;
export type OnboardingProfile = z.infer<typeof onboardingProfileSchema>;
export type OnboardingGlp = z.infer<typeof onboardingGlpSchema>;
export type OnboardingPeptide = z.infer<typeof onboardingPeptideSchema>;
export type OnboardingDraft = z.infer<typeof onboardingDraftSchema>;
export type OnboardingOutput = z.infer<typeof onboardingOutputSchema>;
export type AccountModeFormValues = z.infer<typeof accountModeFormSchema>;

export function createEmptyOnboardingDraft(): OnboardingDraft {
  return {
    accountMode: null,
    privacy: {
      discreetNotifications: false,
      hideSensitiveLabels: false,
      biometricLater: false,
      analyticsOptIn: false,
    },
    trackType: null,
    profile: {
      gender: null,
      age: null,
      goalWeight: null,
      height: null,
      heightUnit: null,
      weight: null,
      weightUnit: null,
    },
    glp: {
      medication: null,
      frequency: null,
      injectionDay: null,
      dose: null,
      duration: null,
      goal: null,
      challenge: null,
    },
    peptide: {
      selections: [],
      frequency: null,
      experience: null,
      usualTime: null,
      dose: null,
      goal: null,
    },
    healthConnectionPromptSeen: false,
  };
}
