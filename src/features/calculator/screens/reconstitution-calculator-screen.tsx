import { useState } from 'react';
import { ActivityIndicator, StyleSheet, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppInput } from '@/src/components/ui/app-input';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { ShellHeader } from '@/src/features/app-shell/components/shell-header';
import { StatusPill } from '@/src/features/app-shell/components/status-pill';
import {
  useCalculatorProfilesQuery,
  useDeleteCalculatorProfileMutation,
  useSaveCalculatorProfileMutation,
} from '@/src/features/calculator/hooks';
import { calculateReconstitution } from '@/src/features/calculator/math';
import { ProtocolChoicePill } from '@/src/features/protocols/components/protocol-choice-pill';
import { atlasTheme } from '@/src/theme/tokens';

const amountUnits = ['mg', 'mcg', 'units'] as const;
const volumeUnits = ['mL'] as const;

export function ReconstitutionCalculatorScreen() {
  const profilesQuery = useCalculatorProfilesQuery();
  const saveProfileMutation = useSaveCalculatorProfileMutation();
  const deleteProfileMutation = useDeleteCalculatorProfileMutation();

  const [label, setLabel] = useState('2 mg vial baseline');
  const [powderAmount, setPowderAmount] = useState('2');
  const [powderUnit, setPowderUnit] = useState<(typeof amountUnits)[number]>('mg');
  const [diluentVolume, setDiluentVolume] = useState('2');
  const [diluentUnit, setDiluentUnit] = useState<(typeof volumeUnits)[number]>('mL');
  const [drawVolume, setDrawVolume] = useState('0.25');
  const [drawUnit, setDrawUnit] = useState<(typeof volumeUnits)[number]>('mL');

  const canCalculate = powderAmount.trim() && diluentVolume.trim() && drawVolume.trim();
  const result = canCalculate
    ? calculateReconstitution({
        diluentUnit,
        diluentVolume: Number(diluentVolume),
        drawUnit,
        drawVolume: Number(drawVolume),
        label,
        powderAmount: Number(powderAmount),
        powderUnit,
      })
    : null;

  return (
    <AppScreen scroll>
      <View style={styles.container}>
        <ShellHeader
          description="This is neutral math only. Atlas explains the calculation but never recommends what to take."
          eyebrow="Calculator"
          title="Reconstitution helper"
          trailing={<StatusPill label={`${profilesQuery.data?.length ?? 0} saved`} tone="muted" />}
        />

        <AppCard>
          <View style={styles.section}>
            <AppInput
              label="Profile label"
              onChangeText={setLabel}
              placeholder="2 mg vial baseline"
              value={label}
            />
            <AppInput
              keyboardType="decimal-pad"
              label="Powder amount"
              onChangeText={setPowderAmount}
              placeholder="2"
              value={powderAmount}
            />
            <AppText style={styles.fieldLabel} variant="caption">
              Powder unit
            </AppText>
            <View style={styles.pillStack}>
              {amountUnits.map((unit) => (
                <ProtocolChoicePill
                  key={unit}
                  isSelected={powderUnit === unit}
                  label={unit}
                  onPress={() => {
                    setPowderUnit(unit);
                  }}
                />
              ))}
            </View>
            <AppInput
              keyboardType="decimal-pad"
              label="Diluent volume"
              onChangeText={setDiluentVolume}
              placeholder="2"
              value={diluentVolume}
            />
            <AppText style={styles.fieldLabel} variant="caption">
              Diluent unit
            </AppText>
            <View style={styles.pillStack}>
              {volumeUnits.map((unit) => (
                <ProtocolChoicePill
                  key={unit}
                  isSelected={diluentUnit === unit}
                  label={unit}
                  onPress={() => {
                    setDiluentUnit(unit);
                  }}
                />
              ))}
            </View>
            <AppInput
              keyboardType="decimal-pad"
              label="Draw volume"
              onChangeText={setDrawVolume}
              placeholder="0.25"
              value={drawVolume}
            />
            <AppText style={styles.fieldLabel} variant="caption">
              Draw unit
            </AppText>
            <View style={styles.pillStack}>
              {volumeUnits.map((unit) => (
                <ProtocolChoicePill
                  key={unit}
                  isSelected={drawUnit === unit}
                  label={unit}
                  onPress={() => {
                    setDrawUnit(unit);
                  }}
                />
              ))}
            </View>
            <AppButton
              label={saveProfileMutation.isPending ? 'Saving profile...' : 'Save calculator profile'}
              onPress={() => {
                if (!result) {
                  return;
                }

                void saveProfileMutation.mutateAsync({
                  diluentUnit,
                  diluentVolume: Number(diluentVolume),
                  drawUnit,
                  drawVolume: Number(drawVolume),
                  label,
                  powderAmount: Number(powderAmount),
                  powderUnit,
                });
              }}
            />
          </View>
        </AppCard>

        <AppCard style={styles.resultCard}>
          <View style={styles.section}>
            <AppText variant="heading">Result</AppText>
            {result ? (
              <>
                <AppText>{result.concentrationLabel}</AppText>
                <AppText>{result.deliveredLabel}</AppText>
                {result.explanation.map((line) => (
                  <AppText key={line} variant="caption">
                    {line}
                  </AppText>
                ))}
              </>
            ) : (
              <AppText variant="caption">
                Add powder, diluent, and draw values to see the neutral math.
              </AppText>
            )}
          </View>
        </AppCard>

        <AppCard>
          <View style={styles.section}>
            <AppText variant="heading">Saved profiles</AppText>
            {profilesQuery.isLoading ? (
              <View style={styles.loadingRow}>
                <ActivityIndicator color={atlasTheme.colors.primary} />
                <AppText variant="caption">Loading saved profiles.</AppText>
              </View>
            ) : profilesQuery.data && profilesQuery.data.length > 0 ? (
              <View style={styles.section}>
                {profilesQuery.data.map((profile) => {
                  const profileResult = calculateReconstitution({
                    diluentUnit: profile.diluentUnit,
                    diluentVolume: profile.diluentVolume,
                    drawUnit: profile.drawUnit,
                    drawVolume: profile.drawVolume,
                    label: profile.label,
                    powderAmount: profile.powderAmount,
                    powderUnit: profile.powderUnit,
                  });

                  return (
                    <AppCard key={profile.id} style={styles.profileCard}>
                      <View style={styles.section}>
                        <View style={styles.profileHeader}>
                          <View style={styles.copyStack}>
                            <AppText variant="heading">{profile.label}</AppText>
                            <AppText variant="caption">{profileResult.deliveredLabel}</AppText>
                          </View>
                          <StatusPill label="Saved locally" tone="muted" />
                        </View>
                        <AppText variant="caption">{profileResult.concentrationLabel}</AppText>
                        <View style={styles.buttonRow}>
                          <AppButton
                            label="Load"
                            onPress={() => {
                              setLabel(profile.label);
                              setPowderAmount(String(profile.powderAmount));
                              setPowderUnit(profile.powderUnit as (typeof amountUnits)[number]);
                              setDiluentVolume(String(profile.diluentVolume));
                              setDiluentUnit(profile.diluentUnit as (typeof volumeUnits)[number]);
                              setDrawVolume(String(profile.drawVolume));
                              setDrawUnit(profile.drawUnit as (typeof volumeUnits)[number]);
                            }}
                            variant="secondary"
                          />
                          <AppButton
                            label="Delete"
                            onPress={() => {
                              void deleteProfileMutation.mutateAsync(profile.id);
                            }}
                            variant="ghost"
                          />
                        </View>
                      </View>
                    </AppCard>
                  );
                })}
              </View>
            ) : (
              <AppText variant="caption">No saved calculator profiles yet.</AppText>
            )}
          </View>
        </AppCard>
      </View>
    </AppScreen>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.lg,
  },
  section: {
    gap: atlasTheme.spacing.md,
  },
  resultCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
  },
  fieldLabel: {
    color: atlasTheme.colors.primary,
    fontWeight: '700',
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },
  pillStack: {
    gap: atlasTheme.spacing.sm,
  },
  loadingRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: atlasTheme.spacing.sm,
  },
  profileCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
  },
  profileHeader: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: atlasTheme.spacing.md,
    justifyContent: 'space-between',
  },
  copyStack: {
    flex: 1,
    gap: atlasTheme.spacing.xs,
  },
  buttonRow: {
    gap: atlasTheme.spacing.sm,
  },
});
