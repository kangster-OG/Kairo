import { router } from 'expo-router';
import { useState } from 'react';
import { ActivityIndicator, StyleSheet, Switch, View } from 'react-native';

import { AppButton } from '@/src/components/ui/app-button';
import { AppCard } from '@/src/components/ui/app-card';
import { AppInput } from '@/src/components/ui/app-input';
import { AppScreen } from '@/src/components/ui/app-screen';
import { AppText } from '@/src/components/ui/app-text';
import { EmptyStateCard } from '@/src/features/app-shell/components/empty-state-card';
import { ShellHeader } from '@/src/features/app-shell/components/shell-header';
import { StatusPill } from '@/src/features/app-shell/components/status-pill';
import {
  useApplyInventoryCorrectionMutation,
  useDeleteVialMutation,
  useInventorySnapshotQuery,
  useSaveSiteMutation,
  useSaveVialMutation,
  useUpdateProtocolInventorySettingsMutation,
} from '@/src/features/inventory/hooks';
import { ProtocolChoicePill } from '@/src/features/protocols/components/protocol-choice-pill';
import { atlasTheme } from '@/src/theme/tokens';

const quantityUnits = ['dose', 'mg', 'mcg', 'units', 'mL'] as const;
const concentrationUnits = ['mg', 'mcg', 'units'] as const;
const bodyAreas = ['abdomen', 'thigh', 'arm', 'glute', 'other'] as const;
const defaultVialForm: Record<
  | 'concentrationValue'
  | 'lowStockThreshold'
  | 'remainingQuantity'
  | 'startingQuantity'
  | 'vialLabel'
  | 'volumeMl',
  string
> = {
  concentrationValue: '0.25',
  lowStockThreshold: '1',
  remainingQuantity: '4',
  startingQuantity: '4',
  vialLabel: 'Starter pen',
  volumeMl: '2',
};
const defaultSiteForm: Record<'siteName' | 'siteNotes', string> = {
  siteName: 'Left abdomen',
  siteNotes: '',
};

export function InventoryScreen() {
  const inventoryQuery = useInventorySnapshotQuery();
  const saveVialMutation = useSaveVialMutation();
  const deleteVialMutation = useDeleteVialMutation();
  const updateProtocolSettingsMutation = useUpdateProtocolInventorySettingsMutation();
  const correctionMutation = useApplyInventoryCorrectionMutation();
  const saveSiteMutation = useSaveSiteMutation();

  const [vialLabel, setVialLabel] = useState(defaultVialForm.vialLabel);
  const [protocolId, setProtocolId] = useState<string | null>(null);
  const [startingQuantity, setStartingQuantity] = useState(defaultVialForm.startingQuantity);
  const [remainingQuantity, setRemainingQuantity] = useState(defaultVialForm.remainingQuantity);
  const [quantityUnit, setQuantityUnit] = useState<(typeof quantityUnits)[number]>('dose');
  const [lowStockThreshold, setLowStockThreshold] = useState(defaultVialForm.lowStockThreshold);
  const [concentrationValue, setConcentrationValue] = useState(defaultVialForm.concentrationValue);
  const [concentrationUnit, setConcentrationUnit] = useState<(typeof concentrationUnits)[number]>('mg');
  const [volumeMl, setVolumeMl] = useState(defaultVialForm.volumeMl);

  const [siteName, setSiteName] = useState(defaultSiteForm.siteName);
  const [siteBodyArea, setSiteBodyArea] = useState<(typeof bodyAreas)[number]>('abdomen');
  const [siteNotes, setSiteNotes] = useState(defaultSiteForm.siteNotes);

  const [correctionValues, setCorrectionValues] = useState<Record<string, string>>({});
  const [correctionNotes, setCorrectionNotes] = useState<Record<string, string>>({});

  if (inventoryQuery.isLoading) {
    return (
      <AppScreen scroll>
        <View style={styles.loadingState}>
          <ActivityIndicator color={atlasTheme.colors.primary} />
          <AppText variant="caption">Loading inventory and sites.</AppText>
        </View>
      </AppScreen>
    );
  }

  if (inventoryQuery.isError) {
    return (
      <AppScreen scroll>
        <View style={styles.loadingState}>
          <AppText variant="heading">Inventory could not load</AppText>
          <AppText variant="caption">Atlas could not read the local inventory layer.</AppText>
        </View>
      </AppScreen>
    );
  }

  const snapshot = inventoryQuery.data ?? {
    protocolSettings: [],
    protocols: [],
    sites: [],
    vials: [],
  };
  const lowStockCount = snapshot.vials.filter((vial) => vial.isLowStock).length;

  return (
    <AppScreen scroll>
      <View style={styles.container}>
        <ShellHeader
          description="Inventory stays local-first. Link a vial, track what remains, and keep optional site rotation ready for logging."
          eyebrow="Inventory"
          title="Vials, stock, and sites"
          trailing={
            <View style={styles.statusRow}>
              <StatusPill
                label={lowStockCount > 0 ? `${lowStockCount} low stock` : 'Stock looks stable'}
                tone={lowStockCount > 0 ? 'default' : 'success'}
              />
              <StatusPill label={`${snapshot.vials.length} vials`} tone="muted" />
            </View>
          }
        />

        <AppCard style={styles.sectionCard}>
          <View style={styles.section}>
            <AppText variant="heading">Quick tools</AppText>
            <AppText variant="caption">
              Use the calculator for neutral reconstitution math, then come back here to keep stock current.
            </AppText>
            <AppButton
              label="Open calculator"
              onPress={() => {
                router.push('/calculator' as never);
              }}
              variant="secondary"
            />
          </View>
        </AppCard>

        <AppCard>
          <View style={styles.section}>
            <AppText variant="heading">Add a vial</AppText>
            <AppInput
              label="Vial label"
              onChangeText={setVialLabel}
              placeholder="Starter pen"
              value={vialLabel}
            />
            <AppText style={styles.fieldLabel} variant="caption">
              Attach to protocol
            </AppText>
            <View style={styles.pillStack}>
              <ProtocolChoicePill
                isSelected={protocolId === null}
                label="Not linked yet"
                onPress={() => {
                  setProtocolId(null);
                }}
              />
              {snapshot.protocols.map((protocol) => (
                <ProtocolChoicePill
                  key={protocol.id}
                  isSelected={protocolId === protocol.id}
                  label={protocol.name}
                  onPress={() => {
                    setProtocolId(protocol.id);
                  }}
                />
              ))}
            </View>
            <AppInput
              keyboardType="decimal-pad"
              label="Starting quantity"
              onChangeText={setStartingQuantity}
              placeholder="4"
              value={startingQuantity}
            />
            <AppInput
              keyboardType="decimal-pad"
              label="Current remaining quantity"
              onChangeText={setRemainingQuantity}
              placeholder="4"
              value={remainingQuantity}
            />
            <AppText style={styles.fieldLabel} variant="caption">
              Quantity unit
            </AppText>
            <View style={styles.pillStack}>
              {quantityUnits.map((unit) => (
                <ProtocolChoicePill
                  key={unit}
                  isSelected={quantityUnit === unit}
                  label={unit}
                  onPress={() => {
                    setQuantityUnit(unit);
                  }}
                />
              ))}
            </View>
            <AppInput
              keyboardType="decimal-pad"
              label="Low stock threshold"
              onChangeText={setLowStockThreshold}
              placeholder="1"
              value={lowStockThreshold}
            />
            <AppInput
              keyboardType="decimal-pad"
              label="Concentration value (optional)"
              onChangeText={setConcentrationValue}
              placeholder="0.25"
              value={concentrationValue}
            />
            <AppText style={styles.fieldLabel} variant="caption">
              Concentration unit
            </AppText>
            <View style={styles.pillStack}>
              {concentrationUnits.map((unit) => (
                <ProtocolChoicePill
                  key={unit}
                  isSelected={concentrationUnit === unit}
                  label={unit}
                  onPress={() => {
                    setConcentrationUnit(unit);
                  }}
                />
              ))}
            </View>
            <AppInput
              keyboardType="decimal-pad"
              label="Volume mL (optional)"
              onChangeText={setVolumeMl}
              placeholder="2"
              value={volumeMl}
            />
            <AppButton
              label={saveVialMutation.isPending ? 'Saving vial...' : 'Save vial'}
              onPress={() => {
                if (!vialLabel.trim() || !startingQuantity.trim() || !remainingQuantity.trim()) {
                  return;
                }

                void saveVialMutation
                  .mutateAsync({
                    concentrationUnit: concentrationValue.trim() ? concentrationUnit : null,
                    concentrationValue: parseOptionalNumber(concentrationValue),
                    label: vialLabel,
                    lowStockThreshold: parseOptionalNumber(lowStockThreshold),
                    protocolId,
                    quantityUnit,
                    remainingQuantity: parseRequiredNumber(remainingQuantity),
                    startingQuantity: parseRequiredNumber(startingQuantity),
                    volumeMl: parseOptionalNumber(volumeMl),
                  })
                  .then(() => {
                    setVialLabel(defaultVialForm.vialLabel);
                    setProtocolId(null);
                    setStartingQuantity(defaultVialForm.startingQuantity);
                    setRemainingQuantity(defaultVialForm.remainingQuantity);
                    setLowStockThreshold(defaultVialForm.lowStockThreshold);
                    setConcentrationValue(defaultVialForm.concentrationValue);
                    setVolumeMl(defaultVialForm.volumeMl);
                  });
              }}
            />
          </View>
        </AppCard>

        {snapshot.vials.length === 0 ? (
          <EmptyStateCard
            body="Add one vial to unlock low-stock monitoring, projected depletion, and automatic inventory decrement during logging."
            eyebrow="No vials yet"
            title="Inventory starts with one local vial record"
          />
        ) : (
          <View style={styles.stack}>
            {snapshot.vials.map((vial) => (
              <AppCard key={vial.id}>
                <View style={styles.section}>
                  <View style={styles.rowBetween}>
                    <View style={styles.copyStack}>
                      <AppText variant="heading">{vial.label}</AppText>
                      <AppText variant="caption">{vial.quantityLabel}</AppText>
                    </View>
                    <StatusPill
                      label={vial.isLowStock ? 'Low stock' : 'Tracked locally'}
                      tone={vial.isLowStock ? 'default' : 'muted'}
                    />
                  </View>
                  {vial.linkedProtocolName ? (
                    <AppText variant="caption">Linked protocol: {vial.linkedProtocolName}</AppText>
                  ) : null}
                  {vial.compoundName ? <AppText variant="caption">Compound: {vial.compoundName}</AppText> : null}
                  {vial.autoDecrementLabel ? <AppText variant="caption">{vial.autoDecrementLabel}</AppText> : null}
                  {vial.lowStockLabel ? <AppText variant="caption">{vial.lowStockLabel}</AppText> : null}
                  {vial.projectedDepletionLabel ? (
                    <AppText variant="caption">{vial.projectedDepletionLabel}</AppText>
                  ) : null}
                  <AppInput
                    keyboardType="decimal-pad"
                    label="Manual correction"
                    onChangeText={(value) => {
                      setCorrectionValues((current) => ({
                        ...current,
                        [vial.id]: value,
                      }));
                    }}
                    placeholder={String(vial.remainingQuantity)}
                    value={correctionValues[vial.id] ?? ''}
                  />
                  <AppInput
                    label="Correction note"
                    onChangeText={(value) => {
                      setCorrectionNotes((current) => ({
                        ...current,
                        [vial.id]: value,
                      }));
                    }}
                    placeholder="Why did the count change?"
                    value={correctionNotes[vial.id] ?? ''}
                  />
                  <AppButton
                    label="Save correction"
                    onPress={() => {
                      const value = correctionValues[vial.id];
                      if (!value || Number.isNaN(Number(value))) {
                        return;
                      }

                      void correctionMutation
                        .mutateAsync({
                          nextRemainingQuantity: parseRequiredNumber(value),
                          notes: correctionNotes[vial.id]?.trim() || null,
                          vialId: vial.id,
                        })
                        .then(() => {
                          setCorrectionValues((current) => ({
                            ...current,
                            [vial.id]: '',
                          }));
                          setCorrectionNotes((current) => ({
                            ...current,
                            [vial.id]: '',
                          }));
                        });
                    }}
                    variant="secondary"
                  />
                  <AppButton
                    label={deleteVialMutation.isPending ? 'Removing vial...' : 'Delete vial'}
                    onPress={() => {
                      void deleteVialMutation.mutateAsync(vial.id);
                    }}
                    variant="ghost"
                  />
                </View>
              </AppCard>
            ))}
          </View>
        )}

        <AppCard>
          <View style={styles.section}>
            <AppText variant="heading">Protocol inventory settings</AppText>
            <AppText variant="caption">
              Link each protocol to one tracked vial and choose whether Today should ask for injection sites.
            </AppText>
            {snapshot.protocolSettings.map((protocol) => (
              <View key={protocol.id} style={styles.protocolSettingsCard}>
                <View style={styles.copyStack}>
                  <View style={styles.statusRow}>
                    <AppText variant="heading">{protocol.name}</AppText>
                    <StatusPill label={protocol.kindLabel} tone="muted" />
                  </View>
                  <AppText variant="caption">{protocol.cadenceLabel}</AppText>
                  {protocol.doseLabel ? <AppText variant="caption">Saved amount: {protocol.doseLabel}</AppText> : null}
                </View>
                <AppText style={styles.fieldLabel} variant="caption">
                  Linked vial
                </AppText>
                <View style={styles.pillStack}>
                  <ProtocolChoicePill
                    isSelected={protocol.linkedVialId === null}
                    label="No vial linked"
                    onPress={() => {
                      void updateProtocolSettingsMutation.mutateAsync({
                        linkedVialId: null,
                        protocolId: protocol.id,
                        siteRotationEnabled: protocol.siteRotationEnabled,
                        siteTrackingEnabled: protocol.siteTrackingEnabled,
                      });
                    }}
                  />
                  {snapshot.vials.map((vial) => (
                    <ProtocolChoicePill
                      key={`${protocol.id}:${vial.id}`}
                      isSelected={protocol.linkedVialId === vial.id}
                      label={vial.label}
                      onPress={() => {
                        void updateProtocolSettingsMutation.mutateAsync({
                          linkedVialId: vial.id,
                          protocolId: protocol.id,
                          siteRotationEnabled: protocol.siteRotationEnabled,
                          siteTrackingEnabled: protocol.siteTrackingEnabled,
                        });
                      }}
                    />
                  ))}
                </View>
                <View style={styles.switchRow}>
                  <View style={styles.copyStack}>
                    <AppText>Track injection sites</AppText>
                    <AppText variant="caption">If enabled, Today can save a site with a taken log.</AppText>
                  </View>
                  <Switch
                    onValueChange={(value) => {
                      void updateProtocolSettingsMutation.mutateAsync({
                        linkedVialId: protocol.linkedVialId,
                        protocolId: protocol.id,
                        siteRotationEnabled: value ? protocol.siteRotationEnabled : false,
                        siteTrackingEnabled: value,
                      });
                    }}
                    thumbColor="#FFFFFF"
                    trackColor={{ false: '#D7E1F2', true: atlasTheme.colors.primary }}
                    value={protocol.siteTrackingEnabled}
                  />
                </View>
                <View style={styles.switchRow}>
                  <View style={styles.copyStack}>
                    <AppText>Rotate suggested sites</AppText>
                    <AppText variant="caption">Atlas will suggest the next body site instead of repeating the last one.</AppText>
                  </View>
                  <Switch
                    disabled={!protocol.siteTrackingEnabled}
                    onValueChange={(value) => {
                      void updateProtocolSettingsMutation.mutateAsync({
                        linkedVialId: protocol.linkedVialId,
                        protocolId: protocol.id,
                        siteRotationEnabled: value,
                        siteTrackingEnabled: protocol.siteTrackingEnabled,
                      });
                    }}
                    thumbColor="#FFFFFF"
                    trackColor={{ false: '#D7E1F2', true: atlasTheme.colors.primary }}
                    value={protocol.siteRotationEnabled}
                  />
                </View>
              </View>
            ))}
          </View>
        </AppCard>

        <AppCard>
          <View style={styles.section}>
            <AppText variant="heading">Injection sites</AppText>
            <AppText variant="caption">
              Site tracking is optional. Save body regions here so dose logging can stay fast later.
            </AppText>
            <AppInput
              label="Site name"
              onChangeText={setSiteName}
              placeholder="Left abdomen"
              value={siteName}
            />
            <AppText style={styles.fieldLabel} variant="caption">
              Body area
            </AppText>
            <View style={styles.pillStack}>
              {bodyAreas.map((area) => (
                <ProtocolChoicePill
                  key={area}
                  isSelected={siteBodyArea === area}
                  label={area}
                  onPress={() => {
                    setSiteBodyArea(area);
                  }}
                />
              ))}
            </View>
            <AppInput
              label="Optional site note"
              onChangeText={setSiteNotes}
              placeholder="Anything private you want to remember."
              value={siteNotes}
            />
            <AppButton
              label={saveSiteMutation.isPending ? 'Saving site...' : 'Save site'}
              onPress={() => {
                if (!siteName.trim()) {
                  return;
                }

                void saveSiteMutation
                  .mutateAsync({
                    bodyArea: siteBodyArea,
                    name: siteName,
                    notes: siteNotes.trim() || null,
                  })
                  .then(() => {
                    setSiteName(defaultSiteForm.siteName);
                    setSiteNotes(defaultSiteForm.siteNotes);
                  });
              }}
              variant="secondary"
            />
            <View style={styles.stack}>
              {snapshot.sites.map((site) => (
                <View key={site.id} style={styles.rowBetween}>
                  <View style={styles.copyStack}>
                    <AppText>{site.name}</AppText>
                    {site.notes ? <AppText variant="caption">{site.notes}</AppText> : null}
                  </View>
                  <StatusPill label={site.bodyArea ?? 'site'} tone="muted" />
                </View>
              ))}
            </View>
          </View>
        </AppCard>
      </View>
    </AppScreen>
  );
}

function parseOptionalNumber(value: string) {
  if (!value.trim()) {
    return null;
  }

  return Number(value);
}

function parseRequiredNumber(value: string) {
  return Number(value || '0');
}

const styles = StyleSheet.create({
  container: {
    gap: atlasTheme.spacing.lg,
  },
  loadingState: {
    alignItems: 'center',
    flex: 1,
    gap: atlasTheme.spacing.sm,
    justifyContent: 'center',
  },
  section: {
    gap: atlasTheme.spacing.md,
  },
  sectionCard: {
    backgroundColor: atlasTheme.colors.surfaceMuted,
  },
  stack: {
    gap: atlasTheme.spacing.md,
  },
  rowBetween: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: atlasTheme.spacing.md,
    justifyContent: 'space-between',
  },
  statusRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: atlasTheme.spacing.sm,
  },
  copyStack: {
    flex: 1,
    gap: atlasTheme.spacing.xs,
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
  protocolSettingsCard: {
    borderColor: atlasTheme.colors.border,
    borderTopWidth: 1,
    gap: atlasTheme.spacing.md,
    paddingTop: atlasTheme.spacing.md,
  },
  switchRow: {
    alignItems: 'center',
    flexDirection: 'row',
    gap: atlasTheme.spacing.md,
    justifyContent: 'space-between',
  },
});
