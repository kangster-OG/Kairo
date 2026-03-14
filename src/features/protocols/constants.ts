export const protocolKindOptions = [
  {
    description: 'For GLP routines and related compounds.',
    label: 'GLP',
    value: 'glp',
  },
  {
    description: 'For peptide routines with the same local-first flow.',
    label: 'Peptide',
    value: 'peptide',
  },
  {
    description: 'For anything custom or not covered by the presets.',
    label: 'Custom',
    value: 'custom',
  },
] as const;

export const scheduleTypeOptions = [
  {
    description: 'Choose one day of the week at a set time.',
    label: 'Weekly',
    value: 'weekly',
  },
  {
    description: 'Repeat every set number of days from today forward.',
    label: 'Every N days',
    value: 'every_n_days',
  },
] as const;

export const weekdayOptions = [
  { label: 'Sun', value: 0 },
  { label: 'Mon', value: 1 },
  { label: 'Tue', value: 2 },
  { label: 'Wed', value: 3 },
  { label: 'Thu', value: 4 },
  { label: 'Fri', value: 5 },
  { label: 'Sat', value: 6 },
] as const;

export const doseUnitSuggestions = ['mg', 'mcg', 'mL', 'units', 'dose'] as const;

export const compoundSuggestions = {
  custom: [],
  glp: ['Wegovy', 'Ozempic', 'Zepbound', 'Mounjaro', 'Semaglutide', 'Tirzepatide'],
  peptide: ['BPC-157', 'TB-500', 'CJC-1295', 'Ipamorelin', 'AOD-9604'],
} as const;
