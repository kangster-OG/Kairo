import { zodResolver } from '@hookform/resolvers/zod';
import { router } from 'expo-router';
import { useEffect, useMemo, useState } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { ActivityIndicator, Pressable, StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppInput } from '@/src/components/ui/app-input';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { ShellHeader } from '@/src/features/app-shell/components/shell-header';
import {
  compoundSuggestions,
  doseUnitSuggestions,
  protocolKindOptions,
  scheduleTypeOptions,
  weekdayOptions,
} from '@/src/features/protocols/constants';
import { useAvailableCompoundsQuery, useCreateProtocolMutation } from '@/src/features/protocols/hooks';
import { ProtocolChoicePill } from '@/src/features/protocols/components/protocol-choice-pill';
import {
  protocolWizardFormSchema,
  type ProtocolWizardFormValues,
} from '@/src/features/protocols/schema';
import { atlasTheme } from '@/src/theme/tokens';

const WIZARD_STEPS = [
  {
    description: 'Choose the routine type and the name Atlas will store locally.',
    title: 'What are you tracking?',
  },
  {
    description: 'Keep the cadence simple for V1: weekly or every set number of days.',
    title: 'When should it repeat?',
  },
  {
    description: 'Atlas stores what you enter. It does not recommend amounts or timing.',
    title: 'Add the saved details',
  },
] as const;

const STEP_FIELDS: (keyof ProtocolWizardFormValues)[][] = [
  ['kind', 'compoundMode', 'existingCompoundId', 'compoundName'],
  ['scheduleType', 'weekday', 'intervalDays', 'timeOfDay'],
  ['doseAmount', 'doseUnit', 'notes'],
];

export function ProtocolCreateScreen() {
  const [stepIndex, setStepIndex] = useState(0);
  const compoundsQuery = useAvailableCompoundsQuery();
  const createProtocolMutation = useCreateProtocolMutation();
  const today = useMemo(() => new Date(), []);

  const form = useForm<ProtocolWizardFormValues>({
    defaultValues: {
      compoundMode: 'new',
      compoundName: '',
      doseAmount: '',
      doseUnit: 'mg',
      existingCompoundId: null,
      intervalDays: '1',
      kind: 'glp',
      notes: '',
      scheduleType: 'weekly',
      timeOfDay: '08:00',
      weekday: today.getDay(),
    },
    resolver: zodResolver(protocolWizardFormSchema),
  });

  const { control, formState, getValues, handleSubmit, setValue, trigger, watch } = form;
  const kind = watch('kind');
  const compoundMode = watch('compoundMode');
  const scheduleType = watch('scheduleType');
  const weekday = watch('weekday');
  const doseUnit = watch('doseUnit');

  const savedCompounds = useMemo(() => {
    const targetType = kind === 'custom' ? 'other' : kind;
    return (compoundsQuery.data ?? []).filter((compound) => compound.compoundType === targetType);
  }, [compoundsQuery.data, kind]);

  useEffect(() => {
    const currentCompoundId = getValues('existingCompoundId');
    const selectedStillAvailable = savedCompounds.some((compound) => compound.id === currentCompoundId);

    if (compoundMode === 'saved' && savedCompounds.length === 0) {
      setValue('compoundMode', 'new');
      setValue('existingCompoundId', null);
      return;
    }

    if (compoundMode === 'saved' && !selectedStillAvailable) {
      setValue('existingCompoundId', savedCompounds[0]?.id ?? null);
    }
  }, [compoundMode, getValues, savedCompounds, setValue]);

  useEffect(() => {
    if (stepIndex !== 2) {
      return;
    }

    if (!getValues('doseAmount')) {
      setValue('doseAmount', '0.25');
    }

    if (!getValues('doseUnit')) {
      setValue('doseUnit', 'mg');
    }
  }, [getValues, setValue, stepIndex]);

  const currentStep = WIZARD_STEPS[stepIndex];

  const saveProtocol = handleSubmit(async (values) => {
    await createProtocolMutation.mutateAsync(values);
    router.replace('/today');
  });

  const advanceStep = async () => {
    const isStepValid = await trigger(STEP_FIELDS[stepIndex]);
    if (!isStepValid) {
      return;
    }

    if (stepIndex === WIZARD_STEPS.length - 1) {
      await saveProtocol();
      return;
    }

    setStepIndex((current) => current + 1);
  };

  return (
    <AppScreen scroll>
      <View pointerEvents="none" style={styles.topGlow} />
      <View style={styles.container}>
        <Pressable
          accessibilityRole="button"
          onPress={() => {
            if (stepIndex === 0) {
              router.back();
              return;
            }

            setStepIndex((current) => current - 1);
          }}>
          <AppText style={styles.backLink} variant="caption">
            {stepIndex === 0 ? 'Back to Today' : 'Back'}
          </AppText>
        </Pressable>

        <ShellHeader
          description={currentStep.description}
          eyebrow={`New protocol · Step ${stepIndex + 1} of ${WIZARD_STEPS.length}`}
          title={currentStep.title}
        />

        <View style={styles.progressRow}>
          {WIZARD_STEPS.map((_, index) => (
            <View key={index} style={[styles.progressSegment, index <= stepIndex ? styles.progressSegmentActive : null]} />
          ))}
        </View>

        {compoundsQuery.isLoading ? (
          <View style={styles.loadingCard}>
            <ActivityIndicator color={atlasTheme.colors.primary} />
            <AppText variant="caption">Preparing local protocol options.</AppText>
          </View>
        ) : null}

        {stepIndex === 0 ? (
          <View style={styles.stack}>
            <AppCard>
              <View style={styles.section}>
                <AppText variant="heading">Protocol type</AppText>
                <View style={styles.stack}>
                  {protocolKindOptions.map((option) => (
                    <ProtocolChoicePill
                      key={option.value}
                      description={option.description}
                      isSelected={kind === option.value}
                      label={option.label}
                      onPress={() => {
                        setValue('kind', option.value);
                      }}
                    />
                  ))}
                </View>
              </View>
            </AppCard>

            <AppCard>
              <View style={styles.section}>
                <AppText variant="heading">Name selection</AppText>
                {savedCompounds.length > 0 ? (
                  <View style={styles.modeRow}>
                    <ProtocolChoicePill
                      isSelected={compoundMode === 'saved'}
                      label="Use a saved name"
                      onPress={() => {
                        setValue('compoundMode', 'saved');
                        setValue('existingCompoundId', savedCompounds[0]?.id ?? null);
                      }}
                    />
                    <ProtocolChoicePill
                      isSelected={compoundMode === 'new'}
                      label="Create a new name"
                      onPress={() => {
                        setValue('compoundMode', 'new');
                        setValue('existingCompoundId', null);
                      }}
                    />
                  </View>
                ) : null}

                {compoundMode === 'saved' && savedCompounds.length > 0 ? (
                  <View style={styles.stack}>
                    {savedCompounds.map((compound) => (
                      <ProtocolChoicePill
                        key={compound.id}
                        description={compound.notes ?? 'Already saved locally on this device.'}
                        isSelected={getValues('existingCompoundId') === compound.id}
                        label={compound.displayName}
                        onPress={() => {
                          setValue('existingCompoundId', compound.id);
                        }}
                      />
                    ))}
                    {formState.errors.existingCompoundId ? (
                      <AppText style={styles.errorText} variant="caption">
                        {formState.errors.existingCompoundId.message}
                      </AppText>
                    ) : null}
                  </View>
                ) : (
                  <View style={styles.stack}>
                    {compoundSuggestions[kind].length > 0 ? (
                      <View style={styles.inlineOptions}>
                        {compoundSuggestions[kind].map((suggestion) => (
                          <ProtocolChoicePill
                            key={suggestion}
                            isSelected={watch('compoundName') === suggestion}
                            label={suggestion}
                            onPress={() => {
                              setValue('compoundName', suggestion, { shouldValidate: true });
                            }}
                          />
                        ))}
                      </View>
                    ) : null}
                    <Controller
                      control={control}
                      name="compoundName"
                      render={({ field: { onBlur, onChange, value } }) => (
                        <AppInput
                          autoCapitalize="words"
                          error={formState.errors.compoundName?.message ?? null}
                          label="Compound or protocol name"
                          onBlur={onBlur}
                          onChangeText={onChange}
                          placeholder={kind === 'custom' ? 'Enter a custom name' : 'Enter the name to track'}
                          value={value}
                        />
                      )}
                    />
                  </View>
                )}
              </View>
            </AppCard>
          </View>
        ) : null}

        {stepIndex === 1 ? (
          <View style={styles.stack}>
            <AppCard>
              <View style={styles.section}>
                <AppText variant="heading">Schedule type</AppText>
                <View style={styles.stack}>
                  {scheduleTypeOptions.map((option) => (
                    <ProtocolChoicePill
                      key={option.value}
                      description={option.description}
                      isSelected={scheduleType === option.value}
                      label={option.label}
                      onPress={() => {
                        setValue('scheduleType', option.value);
                      }}
                    />
                  ))}
                </View>
              </View>
            </AppCard>

            <AppCard>
              <View style={styles.section}>
                <AppText variant="heading">Timing</AppText>
                {scheduleType === 'weekly' ? (
                  <View style={styles.stack}>
                    <View style={styles.weekdayGrid}>
                      {weekdayOptions.map((option) => (
                        <ProtocolChoicePill
                          key={option.value}
                          isSelected={weekday === option.value}
                          label={option.label}
                          onPress={() => {
                            setValue('weekday', option.value, { shouldValidate: true });
                          }}
                        />
                      ))}
                    </View>
                    {formState.errors.weekday ? (
                      <AppText style={styles.errorText} variant="caption">
                        {formState.errors.weekday.message}
                      </AppText>
                    ) : null}
                  </View>
                ) : (
                  <Controller
                    control={control}
                    name="intervalDays"
                    render={({ field: { onBlur, onChange, value } }) => (
                      <AppInput
                        error={formState.errors.intervalDays?.message ?? null}
                        keyboardType="number-pad"
                        label="Repeat every N days"
                        onBlur={onBlur}
                        onChangeText={onChange}
                        value={value}
                      />
                    )}
                  />
                )}

                <Controller
                  control={control}
                  name="timeOfDay"
                  render={({ field: { onBlur, onChange, value } }) => (
                    <AppInput
                      autoCapitalize="none"
                      error={formState.errors.timeOfDay?.message ?? null}
                      label="Default time of day"
                      onBlur={onBlur}
                      onChangeText={onChange}
                      placeholder="08:00"
                      value={value}
                    />
                  )}
                />
              </View>
            </AppCard>
          </View>
        ) : null}

        {stepIndex === 2 ? (
          <View style={styles.stack}>
            <AppCard>
              <View style={styles.section}>
                <AppText variant="heading">Saved amount</AppText>
                <Controller
                  control={control}
                  name="doseAmount"
                  render={({ field: { onBlur, onChange, value } }) => (
                    <AppInput
                      error={formState.errors.doseAmount?.message ?? null}
                      keyboardType="decimal-pad"
                      label="Dose amount"
                      onBlur={onBlur}
                      onChangeText={onChange}
                      placeholder="0.25"
                      value={value}
                    />
                  )}
                />

                <View style={styles.stack}>
                  <AppText style={styles.fieldLabel} variant="caption">
                    Dose unit
                  </AppText>
                  <View style={styles.inlineOptions}>
                    {doseUnitSuggestions.map((unit) => (
                      <ProtocolChoicePill
                        key={unit}
                        isSelected={doseUnit === unit}
                        label={unit}
                        onPress={() => {
                          setValue('doseUnit', unit, { shouldValidate: true });
                        }}
                      />
                    ))}
                  </View>
                  {formState.errors.doseUnit ? (
                    <AppText style={styles.errorText} variant="caption">
                      {formState.errors.doseUnit.message}
                    </AppText>
                  ) : null}
                </View>
              </View>
            </AppCard>

            <AppCard>
              <View style={styles.section}>
                <Controller
                  control={control}
                  name="notes"
                  render={({ field: { onBlur, onChange, value } }) => (
                    <AppInput
                      error={formState.errors.notes?.message ?? null}
                      label="Optional notes"
                      multiline
                      numberOfLines={4}
                      onBlur={onBlur}
                      onChangeText={onChange}
                      placeholder="Anything neutral you want to remember about this protocol."
                      style={styles.notesInput}
                      textAlignVertical="top"
                      value={value}
                    />
                  )}
                />
              </View>
            </AppCard>
          </View>
        ) : null}

        <View style={styles.actionRow}>
          <AppButton
            label={stepIndex === WIZARD_STEPS.length - 1 ? 'Save protocol' : 'Continue'}
            onPress={() => {
              void advanceStep();
            }}
          />
          <AppButton
            label={stepIndex === 0 ? 'Cancel' : 'Back'}
            onPress={() => {
              if (stepIndex === 0) {
                router.back();
                return;
              }

              setStepIndex((current) => current - 1);
            }}
            variant="ghost"
          />
          {createProtocolMutation.isPending ? (
            <View style={styles.pendingRow}>
              <ActivityIndicator color={atlasTheme.colors.primary} />
              <AppText variant="caption">Saving locally.</AppText>
            </View>
          ) : null}
        </View>
      </View>
    </AppScreen>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.lg,
  },
  topGlow: {
    backgroundColor: atlasTheme.colors.surfaceGlow,
    borderRadius: 999,
    height: 220,
    opacity: 0.9,
    position: 'absolute',
    right: -70,
    top: -24,
    width: 220,
  },
  backLink: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
  },
  progressRow: {
    flexDirection: 'row',
    gap: atlasTheme.spacing.sm,
  },
  progressSegment: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
    borderRadius: atlasTheme.radii.pill,
    flex: 1,
    height: 6,
  },
  progressSegmentActive: {
    backgroundColor: atlasTheme.colors.primary,
  },
  loadingCard: {
    alignItems: 'center',
    backgroundColor: atlasTheme.colors.surfaceMuted,
    borderRadius: atlasTheme.radii.card,
    gap: atlasTheme.spacing.sm,
    padding: atlasTheme.spacing.lg,
  },
  stack: {
    gap: atlasTheme.spacing.md,
  },
  section: {
    gap: atlasTheme.spacing.md,
  },
  modeRow: {
    gap: atlasTheme.spacing.sm,
  },
  inlineOptions: {
    gap: atlasTheme.spacing.sm,
  },
  weekdayGrid: {
    gap: atlasTheme.spacing.sm,
  },
  fieldLabel: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
  errorText: {
    color: '#B53F3F',
  },
  notesInput: {
    minHeight: 120,
  },
  actionRow: {
    gap: atlasTheme.spacing.sm,
    paddingBottom: atlasTheme.spacing.lg,
  },
  pendingRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: atlasTheme.spacing.sm,
    justifyContent: 'center',
  },
});
