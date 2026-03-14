import {
  onboardingOutputSchema,
  type OnboardingDraft,
  type OnboardingOutput,
  type TrackType,
} from '@/src/features/onboarding/schema';

export type OnboardingBranch = 'glp' | 'peptide';

export type OnboardingCompletionStatus = {
  completedBranches: OnboardingBranch[];
  isComplete: boolean;
  missingFields: string[];
  output: OnboardingOutput | null;
  requiredBranches: OnboardingBranch[];
};

const GLP_REQUIRED_FIELDS = [
  'glp.medication',
  'glp.frequency',
  'glp.injectionDay',
  'glp.dose',
  'glp.duration',
  'glp.goal',
  'glp.challenge',
] as const;

const PEPTIDE_REQUIRED_FIELDS = [
  'peptide.selections',
  'peptide.frequency',
  'peptide.experience',
  'peptide.usualTime',
  'peptide.dose',
  'peptide.goal',
] as const;

export function hasGlpBranch(trackType: TrackType | null): boolean {
  return trackType === 'glp' || trackType === 'both';
}

export function hasPeptideBranch(trackType: TrackType | null): boolean {
  return trackType === 'peptide' || trackType === 'both';
}

export function isLaterTrack(trackType: TrackType | null): boolean {
  return trackType === 'later';
}

export function getRequiredBranches(trackType: TrackType | null): OnboardingBranch[] {
  const branches: OnboardingBranch[] = [];

  if (hasGlpBranch(trackType)) {
    branches.push('glp');
  }

  if (hasPeptideBranch(trackType)) {
    branches.push('peptide');
  }

  return branches;
}

export function getMissingRequiredFields(draft: OnboardingDraft): string[] {
  const missingFields: string[] = [];

  if (!draft.accountMode) {
    missingFields.push('accountMode');
  }

  if (!draft.trackType) {
    missingFields.push('trackType');
  }

  if (!draft.healthConnectionPromptSeen) {
    missingFields.push('healthConnectionPromptSeen');
  }

  if (hasGlpBranch(draft.trackType)) {
    if (!draft.glp.medication) {
      missingFields.push(GLP_REQUIRED_FIELDS[0]);
    }
    if (!draft.glp.frequency) {
      missingFields.push(GLP_REQUIRED_FIELDS[1]);
    }
    if (!draft.glp.injectionDay) {
      missingFields.push(GLP_REQUIRED_FIELDS[2]);
    }
    if (!draft.glp.dose) {
      missingFields.push(GLP_REQUIRED_FIELDS[3]);
    }
    if (!draft.glp.duration) {
      missingFields.push(GLP_REQUIRED_FIELDS[4]);
    }
    if (!draft.glp.goal) {
      missingFields.push(GLP_REQUIRED_FIELDS[5]);
    }
    if (!draft.glp.challenge) {
      missingFields.push(GLP_REQUIRED_FIELDS[6]);
    }
  }

  if (hasPeptideBranch(draft.trackType)) {
    if (draft.peptide.selections.length === 0) {
      missingFields.push(PEPTIDE_REQUIRED_FIELDS[0]);
    }
    if (!draft.peptide.frequency) {
      missingFields.push(PEPTIDE_REQUIRED_FIELDS[1]);
    }
    if (!draft.peptide.experience) {
      missingFields.push(PEPTIDE_REQUIRED_FIELDS[2]);
    }
    if (!draft.peptide.usualTime) {
      missingFields.push(PEPTIDE_REQUIRED_FIELDS[3]);
    }
    if (!draft.peptide.dose) {
      missingFields.push(PEPTIDE_REQUIRED_FIELDS[4]);
    }
    if (!draft.peptide.goal) {
      missingFields.push(PEPTIDE_REQUIRED_FIELDS[5]);
    }
  }

  return missingFields;
}

export function getOnboardingOutput(draft: OnboardingDraft): OnboardingOutput | null {
  const validation = onboardingOutputSchema.safeParse(draft);

  if (!validation.success) {
    return null;
  }

  return validation.data;
}

export function getOnboardingCompletionStatus(
  draft: OnboardingDraft
): OnboardingCompletionStatus {
  const missingFields = getMissingRequiredFields(draft);
  const output = missingFields.length === 0 ? getOnboardingOutput(draft) : null;
  const requiredBranches = getRequiredBranches(draft.trackType);
  const completedBranches = requiredBranches.filter((branch) =>
    branch === 'glp'
      ? GLP_REQUIRED_FIELDS.every((field) => !missingFields.includes(field))
      : PEPTIDE_REQUIRED_FIELDS.every((field) => !missingFields.includes(field))
  );

  return {
    completedBranches,
    isComplete: missingFields.length === 0 && output !== null,
    missingFields,
    output,
    requiredBranches,
  };
}
